{* ***************************************************************************

    Copyright (c) 2020 by Lloyd B. Park

    ipdb2_dns_dhcp_config_out - Outputs the ISC DHCP and BIND9 configuration 
    files to the user's XDG cache folder under the lbp\ipdb2\dns-dhcp-config
    folder.

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 2 of the License, or 
    (at your option) any later version.


    This program is distributed in the hope that it will be useful,but 
    WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details.

    You should have received a copy of the GNU Lesser General Public 
    License along with this program.  If not, see 
    <http://www.gnu.org/licenses/>.

*************************************************************************** *}

program ipdb2_dns_dhcp_config_out;

{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   lbp_types,
   lbp_sql_db,  // SQL Exceptions
   ipdb2_home_config,
   ipdb2_tables,
   ipdb2_flags,
   lbp_xdg_basedir,
   lbp_ip_utils,
   lbp_generic_containers,
   sysutils;

// ************************************************************************
// * tSimpleNode class - Hold a subset of Node information.
// *                     Used by tNodeDictionary.
// ************************************************************************
type
   tSimpleNode = class
      FullName: string;
      IPString: string;
      IPWord32: word32;
   end;  // tSimpleNode Class


// ************************************************************************
// * tDynInfo clas - Used to hold the state information about DHCP Dynamic
// * ranges which need output
// ************************************************************************
type
   tDynInfo = class
      InDynRange:  boolean;
      DynStart:     string;
      DynEnd:       string;
   end; // tDynInfo class
   



// ************************************************************************
// * tNodeDictionary - A simple dictionary to hold Node information which 
// *                   is often looked up by Node ID such as DNS servers.
// ************************************************************************
type
   tNodeDictionary = specialize tgDictionary< word64, tSimpleNode>;


// ************************************************************************
// * Global Variable
// ************************************************************************
var
   FullNode:         FullNodeQuery;
   FullAlias:        FullAliasQuery;
   IPRanges:         IPRangesTable;
   Domains:          DomainsTable;
   NodeDict:         tNodeDictionary;
   WorkingFolder:    string;  // The name of the working folder
   StaticFolder:     string;  // The name of the folder where static include data is stored.
   DhcpdConfWorking: string = 'dhcpd.conf';
   NamedConfWorking: string = 'named.conf';
   ProdDnsFolder:    string = '/etc/bind/';
   ProdDhcpFolder:   string = '/etc/dhcp/';
   DhcpdConf:        text;
   NamedConf:        text;
   Zone:             text;
   DhcpMaxLeaseSecs: string = '900'; // 1 hour
   DhcpDefLeaseSecs: string = '900'; // 1 hour
   DhcpDefDomain:    string = 'la-park.org';


// ************************************************************************
// * LookupNode() - Returns the tSimpleNode matching the passed ID value.
// ************************************************************************

function LookupNode( ID: Word64): tSimpleNode;
   var
      SimpleNode: tSimpleNode;
   begin
      result:= nil;
      if( ID = 0) then exit;

      // Try to get it from NodeDict
      if NodeDict.Find( ID) then begin
         result:= NodeDict.Value;
      end else begin

         // Try to look it up in FullNode and add it to NodeDict
         FullNode.NodeID.SetValue( ID);
         FullNode.Query( ' and NodeInfo.ID = ' + FullNode.NodeID.GetSqlValue);
         if( FullNode.Next) then begin
            SimpleNode:= tSimpleNode.Create();
            SimpleNode.FullName:= FullNode.FullName;
            SimpleNode.IPString:= FullNode.CurrentIP.GetValue;
            SimpleNode.IPWord32:= FullNode.CurrentIP.OrigValue;

            NodeDict.Add( FullNode.NodeID.OrigValue, SimpleNode);
            result:= SimpleNode;
         end; // If found in FullNode
      end; // else try FullNode lookup
   end; // LookupNode()


// ************************************************************************
// * ProcessDhcpDynRange()
// ************************************************************************

procedure ProcessDhcpDynRange( DynInfo: tDynInfo);
   begin
      DynInfo.InDynRange:= false;
      writeln( DhcpdConf, '   range ', DynInfo.DynStart, ' ', DynInfo.DynEnd, ';');
      writeln( DhcpdConf);
   end; // ProcessDhcpDynRange()


// ************************************************************************
// * ProcessDhcpNode()  Output the DHCP configuration for a Node.
// ************************************************************************

procedure ProcessDhcpNode( DynInfo: tDynInfo);
   var
      IsDyn:      boolean;
   begin
      IsDyn:= FullNode.Flags.GetBit( ipdb2_flags.IsDynamic);
      if( IsDyn) then begin
         DynInfo.DynEnd:= FullNode.CurrentIP.GetValue;
         if( not DynInfo.InDynRange) then begin
            DynInfo.InDynRange:= true;
            DynInfo.DynStart:= DynInfo.DynEnd;
         end;
      end else begin
         // If a dynamic range was in progress, the output it.
         if( DynInfo.InDynRange) then ProcessDhcpDynRange( DynInfo);

         // Output the Node's DHCP information
         writeln( DhcpdConf, '   host ', FullNode.Name.GetValue, ' {');
         writeln( DhcpdConf, '      hardware ethernet ', 
                              MacWord64ToString( FullNode.NIC.OrigValue, ':', 2), ';');
         writeln( DhcpdConf, '      fixed-address ', FullNode.CurrentIP.GetValue, ';');
         writeln( DhcpdConf, '      option host-name "', FullNode.Name.GetValue, '";');
         writeln( DhcpdConf, '      option domain-name "', FullNode.DomainName.GetValue, '";');
         writeln( DhcpdConf, '   } # ', FullNode.FullName);
         writeln( DhcpdConf);
      end;
   end; // ProcessDhcpNode()


// ************************************************************************
// * ProcessDNSPtr() Output the current FullNode record to the Zone file.
// ************************************************************************

procedure ProcessDNSPtr();
   begin
   end; // ProcessDNSPtr()


// ************************************************************************
// ProcessDhcpNetwork() - Output DHCP configuration for the current
//                        IPRange
// ************************************************************************

procedure ProcessDhcpNetwork();
   var
      DNS:             string = '';
      SimpleNode:      tSimpleNode;
      NodeStartIp:     word32;
      NodeEndIp:       word32;
      NodeStartIpStr:  string;
      NodeEndIpStr:    string;
      DynInfo:         tDynInfo;
   begin
      // Build the list of DNS servers
      SimpleNode:= LookupNode( IPRanges.ClientDNS1.OrigValue);
      if( SimpleNode = nil) then raise SQLdbException.Create( 'A Subnet doesn''t have DNS servers set!');
      DNS:= SimpleNode.IPString;
      SimpleNode:= LookupNode( IPRanges.ClientDNS2.OrigValue);
      if( SimpleNode <> nil) then DNS:= DNS + ', ' + SimpleNode.IPString;
      SimpleNode:= LookupNode( IPRanges.ClientDNS3.OrigValue);
      if( SimpleNode <> nil) then DNS:= DNS + ', ' + SimpleNode.IPString;
      DNS:= DNS + ';';
      
      // Output the shared/common network configuration.
      writeln( DhcpdConf, 'subnet ', IpRanges.StartIP.GetValue(), ' netmask ',
               IpRanges.NetMask.GetValue, ' {');
      writeln( DhcpdConf, '   default-lease-time ', DhcpDefLeaseSecs, ';');
      writeln( DhcpdConf, '   max-lease-time ', DhcpMaxLeaseSecs, ';');
      writeln( DhcpdConf, '   option broadcast-address ', IpRanges.EndIp.GetValue, ';');
      writeln( DhcpdConf, '   option subnet-mask ', IpRanges.NetMask.GetValue, ';');
      writeln( DhcpdConf, '   option routers ', IpRanges.Gateway.GetValue, ';');
      writeln( DhcpdConf, '   option domain-name-servers ', DNS);
      writeln( DhcpdConf, '   option domain-name "', DhcpDefDomain, '";'); 
      writeln( DhcpdConf, '} # End of subnet ', IpRanges.StartIP.GetValue, 
               ' ', IpRanges.EndIP.GetValue);
      writeln( DhcpdConf);

      // Setup our Dynamic DHCP Range state object
      DynInfo:= tDynInfo.Create;
      DynInfo.InDynRange:= false;

      // Step through each FullNode in the DHCP Subnet
      NodeStartIp:=  IPRanges.StartIP.OrigValue + 1;
      NodeEndIp:=    IPRanges.EndIP.OrigValue - 1;
      Str( NodeStartIp, NodeStartIpStr);
      Str( NodeEndIp, NodeEndIpStr);
      FullNode.Query( ' and CurrentIP >= ' + NodeStartIpStr + ' and CurrentIP <= ' +
                      NodeEndIpStr + ' order by NodeInfo.CurrentIP');
      while( FullNode.Next) do begin
         ProcessDhcpNode( DynInfo);   
      end;

      // If a dynamic range was in progress, the output it.
      if( DynInfo.InDynRange) then ProcessDhcpDynRange( DynInfo);
      DynInfo.Destroy;
   end; // ProcessDhcpNetwork()


// ************************************************************************
// * ProcessSubnets() - Iterate through the subnets and process each one
// ************************************************************************

procedure ProcessSubnets();
   var
      Slash0Str:   string;
      Slash32Str:  string;
   begin
      Str( Slash[  0], Slash0Str);
      Str( Slash[ 32], Slash32Str);

      // Query for all the subnets except those with an impossible netmask
      IPRanges.Query( 'where NetMask != ' + Slash0Str + 
                      ' and NetMask != ' + Slash32Str + 
                      ' Order by NetMask, StartIP');
      while( IPRanges.Next) do begin
//         if( IPRanges.Flags.GetBit( OutputDNS)) then ProcessReverseZone();
         if( IPRanges.Flags.GetBit( OutputDhcp)) then ProcessDhcpNetwork();
      end; // For each range
   end; // ProcessSubnets()


// ************************************************************************
// * BuildFolder() - takes an array of strings representing a parent folder
// *    and the child folders which make up the path.  Each subfolder is
// *    created if it doesn't exist.  The single string representing the 
// *    complete path is returned.
// ************************************************************************

function BuildFolder( A: array of string): string;
   var
      SubFolder: string;
   begin
      result:= '';
      for SubFolder in A do begin
         result:= result + SubFolder + DirectorySeparator;
         if( not DirectoryExists( result)) then mkdir( result);
      end;
   end; // BuildFolder()


// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      InsertUsage( '');
      InsertUsage( 'ipdb2_dns_dhcp_config_out output''s the ISC Bind and DHCP configuration from');
      InsertUsage( '         the IPdb2 database.');
      InsertUsage();
      InsertUsage( 'You must pass the input file name through the -f parameter or pipe the file to');
      InsertUsage( '         this program.');
      InsertUsage( '');
      InsertUsage( 'Usage:');
      InsertUsage( '   ipdb2_dns_dhcp_config_out [options]');
      InsertUsage( '');
      InsertUsage();
      ParseParams();
   end;



// ************************************************************************
// * Initialize
// ************************************************************************

procedure Initialize();
   begin
      InitArgvParser();
      FullNode:=   FullNodeQuery.Create();
      FullAlias:=  FullAliasQuery.Create();
      IPRanges:=   IPRangesTable.Create();
      Domains:=    DomainsTable.Create();

      NodeDict:=   tNodeDictionary.Create( tNodeDictionary.tCompareFunction( @CompareWord64s));

      // Set our static and working folders
      StaticFolder:=  lbp_xdg_basedir.CacheFolder;
      StaticFolder:=  BuildFolder(  [ StaticFolder, 'lbp', 'ipdb2_dns_dhcp_config_out', 'static']);
      WorkingFolder:= lbp_xdg_basedir.CacheFolder;
      WorkingFolder:= BuildFolder(  [ WorkingFolder, 'lbp', 'ipdb2_dns_dhcp_config_out', 'working']);
      DhcpdConfWorking:= WorkingFolder + DhcpdConfWorking;
      NamedConfWorking:= WorkingFolder + NamedConfWorking;

      Assign( DhcpdConf, DhcpdConfWorking);
      rewrite( DhcpdConf);
      writeln( DhcpdConf, 'ddns-update-style none;');
      writeln( DhcpdConf, 'authoritative;');
      writeln( DhcpdConf);

      Assign( NamedConf, NamedConfWorking);
      rewrite( NamedConf);

      Writeln( 'StaticFolder = ', StaticFolder);
      Writeln( 'WorkingFolder = ', WorkingFolder);
   end; // Initialize()


// ************************************************************************
// * Finalize
// ************************************************************************

procedure Finalize();
   begin
      Close( NamedConf);
      Close( DhcpdConf);

      NodeDict.RemoveAll( True);
      NodeDict.Destroy;
      Domains.Destroy;
      IPRanges.Destroy;
      FullAlias.Destroy;
      FullNode.Destroy;
   end; // Finalize()


// ************************************************************************
// * main()
// ************************************************************************

begin
   Initialize();

   ProcessSubnets();
 

   Finalize();
end. // ipdb2_dns_dhcp_config_out program
