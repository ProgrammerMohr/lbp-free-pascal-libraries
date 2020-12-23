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
   ipdb2_home_config, // Set/save/retrieve db connection settings.
   lbp_ini_files,
   lbp_sql_db,   // SQLCriticalException
   ipdb2_tables, // 
   sysutils;     // Exceptions, DirectoryExists, mkdir, etc



// ************************************************************************
// * Global variables
// ************************************************************************

var
   dhcpd_conf:          string;
   named_conf:          string;
   dns_folder:          string;
   dhcp_folder:         string;
   dhcp_max_lease_secs: string;
   dhcp_def_lease_secs: string;
   dhcp_def_domain:     string;


// *************************************************************************

implementation

// -------------------------------------------------------------------------
// - Global functions
// -------------------------------------------------------------------------

var
   ini_file_name: string;
   ini_file:      IniFileObj;
   ini_section:   string;


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
// * ParseArgV() - Parse the command line parameters
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

      if( lbp_types.show_init) then writeln( 'ipdb2_dns_dhcp_config_classes.ParseArgv(): end');
   end; // ParseArgV


// *************************************************************************
// * Initialization - Set default connection info
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
      if( lbp_types.show_init) then writeln( 'ipdb2_dns_dhcp_config_classes.initialization:  end');
   end; // initialization


// *************************************************************************

end. // ipdb2_dns_dhcp_config_classes
