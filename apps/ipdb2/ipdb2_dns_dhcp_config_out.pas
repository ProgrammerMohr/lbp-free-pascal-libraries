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
   lbp_xdg_basedir,
   lbp_ip_utils,
   sysutils;


var
   FullNode:         FullNodeQuery;
   FullAlias:        FullAliasQuery;
   IPRanges:         IPRangesTable;
   Domains:          DomainsTable;
   WorkingFolder:    string;  // The name of the working folder
   StaticFolder:     string;  // The name of the folder where static include data is stored.
   DhcpdConfWorking: string = 'dhcpd.conf';
   NamedConfWorking: string = 'named.conf';
   ProdDnsFolder:    string = '/etc/bind/';
   ProdDhcpFolder:   string = '/etc/dhcp/';
   DhcpdConf:        text;
   NamedConf:        text;
   DhcpMaxLeaseSecs: string = '3600'; // 1 hour
   DhcpDefLeaseSecs: string = '3600'; // 1 hour


// ************************************************************************
// * ProcessSubnet() - Process the passed IPRanges record
// ************************************************************************




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
 
   IPRanges.Query( 'where NetMask >= ' + Slash[ 8])
   Finalize();
end. // ipdb2_dns_dhcp_config_out program
