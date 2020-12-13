{* ***************************************************************************

    Copyright (c) 2020 by Lloyd B. Park

    ipdb2_home_import_csv - This is a one-shot program to import a spreadsheet
    of IP address information into a database.  IPdb2 is an old project
    written in Java whe Java was fairly new.  It provides a GUI to manage
    IP addresses and output DNS/DHCP configuration files.  I'm now using it
    at home.

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

program ipdb2_home_import_csv;

{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   lbp_types,
   ipdb2_home_config,
   lbp_input_file;


// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      InsertUsage( '');
      InsertUsage( 'ipdb2_home_import_csv is a one-shot program to import IP address information');
      InsertUsage( '         from a CSV file into the IPdb2 database I am implementing at home for');
      InsertUsage( '         my work/home testbed.');
      InsertUsage();
      InsertUsage( 'You must pass the input file name through the -f parameter or pipe the file to');
      InsertUsage( '         this program.');
      InsertUsage( '');
      InsertUsage( 'Usage:');
      InsertUsage( '   ipdb2_home_import_csv [options]');
      InsertUsage( '');
      InsertUsage( '   ========== Program Options ==========');
      SetInputFileParam( true, true, false, true);
      InsertUsage();
      ParseParams();
   end;



// ************************************************************************
// * main()
// ************************************************************************

begin
   InitArgvParser();

   writeln( 'This is just a placeholder to test ipdb2_home_config for now.');
end. // ipdb2_home_import_csv program
