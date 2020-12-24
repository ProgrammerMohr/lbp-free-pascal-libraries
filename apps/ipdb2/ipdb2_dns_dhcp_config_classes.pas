{* ***************************************************************************

    Copyright (c) 2020 by Lloyd B. Park

    ipdb2_dns_dhcp_config_classes adds DNS/DHCP configuration output procedures
    to the IPdb2 table classes.

    This file is part of Lloyd's Free Pascal Libraries (LFPL).

    LFPL is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation, either version 2.1 of the 
    License, or (at your option) any later version with the following 
    modification:

    As a special exception, the copyright holders of this library 
    give you permission to link this library with independent modules
    to produce an executable, regardless of the license terms of these
    independent modules, and to copy and distribute the resulting 
    executable under terms of your choice, provided that you also meet,
    for each linked independent module, the terms and conditions of 
    the license of that module. An independent module is a module which
    is not derived from or based on this library. If you modify this
    library, you may extend this exception to your version of the 
    library, but you are not obligated to do so. If you do not wish to
    do so, delete this exception statement from your version.

    LFPL is distributed in the hope that it will be useful,but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General 
    Public License for more details.

    You should have received a copy of the GNU Lesser General Public 
    License along with LFPL.  If not, see <http://www.gnu.org/licenses/>.


*************************************************************************** *}

unit ipdb2_dns_dhcp_config_classes;

interface

{$include lbp_standard_modes.inc}
//{$V-}    //Added by LP because it says so below
//{$R-}    //Range checking off
//{$S-}    //Stack checking off
//{$I-}    //I/O checking off
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

uses
   lbp_argv,
   lbp_types,     // lbp_exception
   lbp_testbed,
   lbp_xdg_basedir,
   lbp_generic_containers,
   ipdb2_home_config, // Set/save/retrieve db connection settings.
   lbp_ini_files,
   lbp_sql_db,   // SQLCriticalException
   ipdb2_tables,
   ipdb2_flags,
   lbp_ip_utils,  // MAC and IP coversion between words and strings
   sysutils;     // Exceptions, DirectoryExists, mkdir, etc


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
      public
         InDynRange:  boolean;
         DynStart:     string;
         DynEnd:       string;
         procedure DhcpdConfOut( var DhcpdConf: text);
   end; // tDynInfo class
   

// ************************************************************************
// * tNodeDictionary - A simple dictionary to hold Node information which 
// *                   is often looked up by Node ID such as DNS servers.
// ************************************************************************
type
   tNodeDictionarySub = specialize tgDictionary< word64, tSimpleNode>;
   tNodeDictionary = class( tNodeDictionarySub)
      public
         function FindNodeInfo( ID: Word64): tSimpleNode; virtual;
      end; // tNodeDictionary class


// *************************************************************************
// * tDdiFullNodeQuery - An IPdb2 FullNodeQuery that can output itself to
// *                      DNS and DHCP configuration files
// *************************************************************************
type
   tDdiFullNodeQuery = class( IPdb2_tables.FullNodeQuery)
      public
         procedure DhcpdConfOut( var DhcpdConf: text; DynInfo: tDynInfo);
         procedure DnsConfOut( var DnsConf: text);
      end; // tDdiFullNodeQuery class


// *************************************************************************
// * tDdiFullAliasQuery - An IPdb2 FullAliasQuery that can output itself to
// *                      DNS configuration files
// *************************************************************************
type
   tDdiFullAliasQuery = class( FullAliasQuery)
      public
         procedure DnsConfOut( var DnsConf: text);
      end; // tDdiFullAliasQuery class


// *************************************************************************
// * tDdiDomainsTable - An IPdb2 DomainsTable that can output itself to
// *                     DNS configuration files
// *************************************************************************
type
   tDdiDomainsTable = class( DomainsTable)
      public
         procedure DnsConfOut( var DnsConf: text);
      end; // tDdiDomainsTable class


// *************************************************************************
// * tDdiIpRangesTable - An IPdb2 IpRangesTable that can output itself to
// *                     DNS and DHCP configuration files
// *************************************************************************
type
   tDdiIpRangesTable = class( IpRangesTable)
      public
         procedure DhcpdConfOut( var DhcpdConf: text);
         procedure DnsConfOut( var DnsConf: text);
      end; // tDdiIpRangesTable class


// ************************************************************************
// * Global variables
// ************************************************************************
var
   WorkingFolder:       string;  // The name of the working folder
//   StaticFolder:        string;  // The name of the folder where static include data is stored.
   dhcpd_conf:          string;
   named_conf:          string;
   dns_folder:          string;
   dhcp_folder:         string;
   dhcp_max_lease_secs: string;
   dhcp_def_lease_secs: string;
   dhcp_def_domain:     string;
   {$warning ===== Move this to the implementation once all the code that references it has been moved to this unit! =====}
   NodeDict:            tNodeDictionary;
   FullNode:            tDdiFullNodeQuery;
   FullAlias:           tDdiFullAliasQuery;
   Domains:             tDdiDomainsTable;
   IPRanges:            tDdiIpRangesTable;
   NamedConf:           Text;
   DhcpdConf:           Text;


// *************************************************************************

implementation
// =========================================================================
// = tDynInfo class - Used to hold the state information about DHCP Dynamic
// = ranges which need output
// =========================================================================
// ************************************************************************
// * DhcpdConfOut( var DhcpdConf: text
// ************************************************************************

procedure tDynInfo.DhcpdConfOut( var DhcpdConf: text);
   begin
      InDynRange:= false;
      writeln( DhcpdConf, '   range ', DynStart, ' ', DynEnd, ';');
      writeln( DhcpdConf);
   end; // DhcpdConfOut()


// =========================================================================
// = tNodeDictionary - A simple dictionary to hold Node information which 
// =                   is often looked up by Node ID such as DNS servers.
// =========================================================================
// ************************************************************************
// * FindNodeInfo() - Returns the tSimpleNode associated with the passed ID
// ************************************************************************

function tNodeDictionary.FindNodeInfo( ID: Word64): tSimpleNode;
   var
      SimpleNode: tSimpleNode;
   begin
      result:= nil;
      if( ID = 0) then exit;

      // Try to get it from NodeDict
      if( Find( ID)) then begin
         result:= Value;
      end else begin

         // Try to look it up in FullNode and add it to NodeDict
         FullNode.NodeID.SetValue( ID);
         FullNode.Query( ' and NodeInfo.ID = ' + FullNode.NodeID.GetSqlValue);
         if( FullNode.Next) then begin
            SimpleNode:= tSimpleNode.Create();
            SimpleNode.FullName:= FullNode.FullName;
            SimpleNode.IPString:= FullNode.CurrentIP.GetValue;
            SimpleNode.IPWord32:= FullNode.CurrentIP.OrigValue;

            Add( FullNode.NodeID.OrigValue, SimpleNode);
            result:= SimpleNode;
         end; // If found in FullNode
      end; // else try FullNode lookup
   end; // FindNodeInfo()

// =========================================================================
// = tDdiFullNodeQuery class
// =========================================================================
// ************************************************************************
// *  DhcpdConfOut() - Output the record's DHCPD configuration 
// ************************************************************************

procedure tDdiFullNodeQuery.DhcpdConfOut( var DhcpdConf: text; DynInfo: tDynInfo);
    var
      IsDyn:      boolean;
   begin
      IsDyn:= Flags.GetBit( ipdb2_flags.IsDynamic);
      if( IsDyn) then begin
         DynInfo.DynEnd:= CurrentIP.GetValue;
         if( not DynInfo.InDynRange) then begin
            DynInfo.InDynRange:= true;
            DynInfo.DynStart:= DynInfo.DynEnd;
         end;
      end else begin
         // If a dynamic range was in progress, the output it.
         if( DynInfo.InDynRange) then DynInfo.DhcpdConfOut( DhcpdConf);

         // Output the Node's DHCP information
         writeln( DhcpdConf, '   host ', Name.GetValue, ' {');
         writeln( DhcpdConf, '      hardware ethernet ', 
                              MacWord64ToString( NIC.OrigValue, ':', 2), ';');
         writeln( DhcpdConf, '      fixed-address ', CurrentIP.GetValue, ';');
         writeln( DhcpdConf, '      option host-name "', Name.GetValue, '";');
         writeln( DhcpdConf, '      option domain-name "', DomainName.GetValue, '";');
         writeln( DhcpdConf, '   } # ', FullName);
         writeln( DhcpdConf);
      end;
   end; // DhcpdConfOut()


// ************************************************************************
// *  DnsConfOut() - Output the record's DNS configuration 
// ************************************************************************

procedure tDdiFullNodeQuery.DnsConfOut( var DnsConf: text);
   begin
   end; // DnsConfOut()

   

// =========================================================================
// = tDdiFullAliasQuery class
// =========================================================================
// ************************************************************************
// *  DnsConfOut() - Output the record's DNS configuration 
// ************************************************************************

procedure tDdiFullAliasQuery.DnsConfOut( var DnsConf: text);
   begin
   end; // DnsConfOut()



// =========================================================================
// = tDdiDomainsTable class
// =========================================================================
// ************************************************************************
// *  DnsConfOut() - Output the record's DNS configuration 
// ************************************************************************

procedure tDdiDomainsTable.DnsConfOut( var DnsConf: text);
   begin
   end; // DnsConfOut()


   
// =========================================================================
// = tDdiIpRangesTable class
// =========================================================================
// ************************************************************************
// *  DhcpdConfOut() - Output the record's DHCPD configuration 
// ************************************************************************

procedure tDdiIpRangesTable.DhcpdConfOut( var DhcpdConf: text);
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
      SimpleNode:= NodeDict.FindNodeInfo( IPRanges.ClientDNS1.OrigValue);
      if( SimpleNode = nil) then raise SQLdbException.Create( 'A Subnet doesn''t have DNS servers set!');
      DNS:= SimpleNode.IPString;
      SimpleNode:= NodeDict.FindNodeInfo( IPRanges.ClientDNS2.OrigValue);
      if( SimpleNode <> nil) then DNS:= DNS + ', ' + SimpleNode.IPString;
      SimpleNode:= NodeDict.FindNodeInfo( IPRanges.ClientDNS3.OrigValue);
      if( SimpleNode <> nil) then DNS:= DNS + ', ' + SimpleNode.IPString;
      DNS:= DNS + ';';
      
      // Output the shared/common network configuration.
      writeln( DhcpdConf, 'subnet ', IpRanges.StartIP.GetValue(), ' netmask ',
               IpRanges.NetMask.GetValue, ' {');
      writeln( DhcpdConf, '   default-lease-time ', dhcp_def_lease_secs, ';');
      writeln( DhcpdConf, '   max-lease-time ', dhcp_max_lease_secs, ';');
      writeln( DhcpdConf, '   option broadcast-address ', IpRanges.EndIp.GetValue, ';');
      writeln( DhcpdConf, '   option subnet-mask ', IpRanges.NetMask.GetValue, ';');
      writeln( DhcpdConf, '   option routers ', IpRanges.Gateway.GetValue, ';');
      writeln( DhcpdConf, '   option domain-name-servers ', DNS);
      writeln( DhcpdConf, '   option domain-name "', dhcp_def_domain, '";'); 
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
          FullNode.DhcpdConfOut( DhcpdConf, DynInfo);
      end;

      // If a dynamic range was in progress, the output it.
      if( DynInfo.InDynRange) then DynInfo.DhcpdConfOut( DhcpdConf);
      DynInfo.Destroy;

      writeln( DhcpdConf, '} # End of subnet ', IpRanges.StartIP.GetValue, 
               ' ', IpRanges.EndIP.GetValue);
   end; // DhcpdConfOut()


// ************************************************************************
// *  DnsConfOut() - Output the record's DNS configuration 
// ************************************************************************

procedure tDdiIpRangesTable.DnsConfOut( var DnsConf: text);
   begin
   end; // DnsConfOut()

   

// =========================================================================
// = Global functions
// =========================================================================

var
   ini_file_name: string;
   ini_file:      IniFileObj;
   ini_section:   string;


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


// *************************************************************************
// * ReadIni() - Set the ini_file_name, read the file and set the global
// *             variables.
// *************************************************************************

procedure ReadIni();
   var
      ini_folder:  string;
      F:           text;
   begin
      // Set the ini_file_name and create the containing folders as needed.
      ini_folder:= lbp_xdg_basedir.ConfigFolder + DirectorySeparator + 'lbp';
      CheckFolder( ini_folder);
      ini_folder:= ini_folder + DirectorySeparator + 'ipdb2-home';
      CheckFolder( ini_folder);
      ini_file_name:= ini_folder + DirectorySeparator + 'ipdb2-dns-dhcp-config.ini';

      // Create a new ini file with empty values if needed.
      if( not FileExists( ini_file_name)) then begin
         if( lbp_types.show_init) then begin
            writeln( '   ReadIni(): No configuration file found.  Creating a new one.');
         end;
         assign( F, ini_file_name);
         rewrite( F);
         writeln( F, '[main]');
         writeln( F, 'dhcpd-conf=dhcpd.conf');
         writeln( F, 'named-conf=named.conf.local');
         writeln( F, 'dns-folder=/etc/bind/');
         writeln( F, 'dhcp-folder=/etc/dhcp/');
         writeln( F, 'dhcp-max-lease-secs=900');
         writeln( F, 'dhcp-def-lease-secs=900');
         writeln( F, 'dhcp-def-domain=la-park.org');
         writeln( F, '[testbed]');
         writeln( F, 'dhcpd-conf=dhcpd.conf');
         writeln( F, 'named-conf=named.conf.local');
         writeln( F, 'dns-folder=/etc/bind/');
         writeln( F, 'dhcp-folder=/etc/dhcp/');
         writeln( F, 'dhcp-max-lease-secs=900');
         writeln( F, 'dhcp-def-lease-secs=900');
         writeln( F, 'dhcp-def-domain=la-park.org');
         close( F);
      end;

      // Now we can finally read the ini file
      if( lbp_testbed.Testbed) then ini_section:= 'testbed' else ini_section:= 'main';
      ini_file:=            iniFileObj.Open( ini_file_name, true);
      dhcpd_conf:=          ini_file.ReadVariable( ini_section, 'dhcpd-conf');
      named_conf:=          ini_file.ReadVariable( ini_section, 'named-conf');
      dns_folder:=          ini_file.ReadVariable( ini_section, 'dns-folder');
      dhcp_folder:=         ini_file.ReadVariable( ini_section, 'dhcp-folder');
      dhcp_max_lease_secs:= ini_file.ReadVariable( ini_section, 'dhcp-max-lease-secs');
      dhcp_def_lease_secs:= ini_file.ReadVariable( ini_section, 'dhcp-def-lease-secs');
      dhcp_def_domain:=     ini_file.ReadVariable( ini_section, 'dhcp-def-domain');
   end; // ReadIni()


// *************************************************************************
// * ParseArgV() - Parse the command line parameters and initialize variables
// *               which require command line variables.
// *************************************************************************

procedure ParseArgv();
   begin
      if( lbp_types.show_init) then writeln( 'ipdb2_dns_dhcp_config_classes.ParseArgv(): begin');
      
      ReadIni();

      ParseHelper( 'dhcpd-conf', dhcpd_conf);
      ParseHelper( 'named-conf', named_conf);
      ParseHelper( 'dns-folder', dns_folder);
      ParseHelper( 'dhcp-folder', dhcp_folder);
      ParseHelper( 'dhcp-max-lease-secs', dhcp_max_lease_secs);
      ParseHelper( 'dhcp-def-lease-secs', dhcp_def_lease_secs);
      ParseHelper( 'dhcp-def-domain', dhcp_def_domain);

      // Test for missing variables
      if( (Length( dhcpd_conf) = 0) or
          (Length( named_conf) = 0) or
          (Length( dns_folder) = 0) or
          (Length( dhcp_folder) = 0) or
          (Length( dhcp_max_lease_secs) = 0) or
          (Length( dhcp_def_lease_secs) = 0) or
          (Length( dhcp_def_domain) = 0)) then begin
         raise SQLdbCriticalException.Create( 'Some ipdb2-home SQL settings are empty!  Please try again with all parameters set.');
      end;

      if( ParamSet( 'ipdb2-dns-dhcp-config-save')) then begin
         ini_file.SetVariable( ini_section, 'dhcpd-conf', dhcpd_conf);
         ini_file.SetVariable( ini_section, 'named-conf', named_conf);
         ini_file.SetVariable( ini_section, 'dns-folder', dns_folder);
         ini_file.SetVariable( ini_section, 'dhcp-folder', dhcp_folder);
         ini_file.SetVariable( ini_section, 'dhcp-max-lease-secs', dhcp_max_lease_secs);
         ini_file.SetVariable( ini_section, 'dhcp-def-lease-secs', dhcp_def_lease_secs);
         ini_file.SetVariable( ini_section, 'dhcp-def-domain', dhcp_def_domain);
         ini_file.write();
      end; 
      ini_file.close();

      // Set our static and working folders
//      StaticFolder:=  lbp_xdg_basedir.CacheFolder;
//      StaticFolder:=  BuildFolder(  [ StaticFolder, 'lbp', 'ipdb2_dns_dhcp_config_out', 'static']);
      WorkingFolder:= lbp_xdg_basedir.CacheFolder;
      WorkingFolder:= BuildFolder(  [ WorkingFolder, 'lbp', 'ipdb2_dns_dhcp_config_out', 'working']);
      dhcpd_conf:= WorkingFolder + dhcpd_conf;
      named_conf:= WorkingFolder + named_conf;

      // Now that the command line and INI variables are read, we can create the 
      //   global tables
      NodeDict:=   tNodeDictionary.Create( tNodeDictionary.tCompareFunction( @CompareWord64s));
      FullNode:=   tDdiFullNodeQuery.Create();
      FullAlias:=  tDdiFullAliasQuery.Create();
      Domains:=    tDdiDomainsTable.Create();
      IPRanges:=   tDdiIPRangesTable.Create();

      // Opent the DHCPd configuration file and output the global portion
      Assign( DhcpdConf, dhcpd_conf);
      rewrite( DhcpdConf);
      writeln( DhcpdConf, 'ddns-update-style none;');
      writeln( DhcpdConf, 'authoritative;');
      writeln( DhcpdConf);

      // Open the Named configuration file and output the global portion
      Assign( NamedConf, named_conf);
      rewrite( NamedConf);
      writeln( NamedConf, '//');
      writeln( NamedConf, '// Do any local configuration here');
      writeln( NamedConf, '//');
      writeln( NamedConf);
      writeln( NamedConf, 'include "rndc.include";');
      writeln( NamedConf);
      writeln( NamedConf, 'logging {');
      writeln( NamedConf, '   channel queries_log {');
      writeln( NamedConf, '      syslog;');
      writeln( NamedConf, '      severity info;');
      writeln( NamedConf, '   };');
      writeln( NamedConf, '   category default { default_syslog; default_debug; };');
      writeln( NamedConf, '   category unmatched { null; };');
      writeln( NamedConf, '};');
      writeln( NamedConf);

      if( lbp_types.show_init) then writeln( 'ipdb2_dns_dhcp_config_classes.initialization:  end');
      if( lbp_types.show_init) then writeln( 'ipdb2_dns_dhcp_config_classes.ParseArgv(): end');
   end; // ParseArgV


// *************************************************************************
// * Initialization - Setup the command line parameters and global variables
// *************************************************************************

initialization
   begin
      if( lbp_types.show_init) then writeln( 'ipdb2_dns_dhcp_config_classes.initialization:  begin');
      // Add Usage messages
      AddUsage( '   ========== IP Database DNS/DHCP Config Output Parameters ==========');
      AddParam( ['named-conf'], true, '', 'The DNS configuration file name.');
      AddParam( ['dns-folder'], true, '', 'The DNS configuration file folder with trailing');
      AddUsage( '                                 slash.');
      AddParam( ['dhcpd-conf'], true, '', 'The DHCPD configuration file name.');
      AddParam( ['dhcp-folder'], true, '', 'The DHCP configuration file folder with trailing');
      AddUsage( '                                 slash.');
      AddParam( ['dhcp-max-lease-secs'], true, '', 'The maximum lease time offered to hosts via DHCP.');
      AddParam( ['dhcp-def-lease-secs'], true, '', 'The default lease time offered to hosts via DHCP.');
      AddParam( ['dhcp-def-domain'], true, '', 'The default domain name given to hosts via DHCP.');
      AddParam( ['ipdb2-dns-dhcp-config-save'], False, '', 'Save youor changes to the ipdb2-dns-dhcp-config');
      AddUsage( '                                 settings INI file.');
      AddUsage( '   --testbed                   Set/retrieve the testbed version of these');
      AddUsage( '                                 settings');
      AddUsage( '');
      AddPostParseProcedure( @ParseArgv);
   end; // initialization


// *************************************************************************
// * finalization
// *************************************************************************

finalization
   begin
      Close( NamedConf);
      Close( DhcpdConf);

      IPRanges.Destroy;
      Domains.Destroy;
      FullAlias.Destroy;
      FullNode.Destroy;

      NodeDict.RemoveAll( True);
      NodeDict.Destroy;
   end; // finalization


// *************************************************************************

end. // ipdb2_dns_dhcp_config_classes
