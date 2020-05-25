{* ***************************************************************************

Copyright (c) 2019 by Lloyd B. Park

Outputs a .csv file's Header using new lines as separators between field names

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

program csv_heaser;

{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   lbp_parse_helper,
   lbp_csv,
   lbp_generic_containers,
   lbp_input_file,
   lbp_output_file;


// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      InsertUsage( '');
      InsertUsage( 'csv_header dumps the first line of a CSV file and outputs it one cell');
      InsertUsage( '         per line.  It will optionally sort the lines.');
      InsertUsage( '');
      InsertUsage( 'Usage:');
      InsertUsage( '   csv_header [-s|--sort] [-f <file name>] [-o <output file name>]');
      InsertUsage( '');
      InsertUsage( '   ========== Program Options ==========');
      SetInputFileParam( true, true, false, true);
      SetOutputFileParam( false, true, false, true);
      InsertParam( ['s','sort'], false, '', 'Sort the output.'); 
      InsertParam( ['d','delimiter'], true, ',', 'The character which separates fields on a line.'); 
      InsertUsage();
      ParseParams();
   end; // InitArgvParser();


// ************************************************************************
// * main()
// ************************************************************************

var
   Csv:        tCsv;
   Header:     tCsvCellArray;
   S:          string;
   Delimiter:  string;
begin
   InitArgvParser();

      // Set the delimiter
   if( ParamSet( 'delimiter')) then begin
      Delimiter:= GetParam( 'delimiter');
      if( Length( Delimiter) <> 1) then begin
         raise tCsvException.Create( 'The delimiter must be a singele character!');
      end;
      lbp_csv.CsvDelimiter:= Delimiter[ 1];
   end;

   Csv:= tCsv.Create( lbp_input_file.InputStream, False); 
   Csv.ParseHeader();
   if( ParamSet( 's')) then Header:= Csv.SortedHeader else Header:= Csv.Header;
   for S in Header do writeln( OutputFile, CsvQuote( S));

   Csv.Destroy;
end.  // csv_header program
