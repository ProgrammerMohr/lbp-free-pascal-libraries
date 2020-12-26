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
   // ipdb2_home_config,
   ipdb2_tables,
   ipdb2_flags,
   ipdb2_dns_dhcp_config_classes,
   // lbp_xdg_basedir,
   lbp_ip_utils,
   lbp_generic_containers,
   sysutils;

// ************************************************************************
// * Global Variable
// ************************************************************************
var
   Zone:             text;


/// ************************************************************************
// * ProcessDNSPtr() Output the current FullNode record to the Zone file.
// ************************************************************************

procedure ProcessDNSPtr();
   begin
   end; // ProcessDNSPtr()


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
         if( IPRanges.Flags.GetBit( OutputDhcp)) then IpRanges.DhcpdConfOut( DhcpdConf);
      end; // For each range
   end; // ProcessSubnets()


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
// * main()
// ************************************************************************

begin
   InitArgvParser();

   IpRanges.OutputConfigs( DhcpdConf, NamedConf);
 
end. // ipdb2_dns_dhcp_config_out program
