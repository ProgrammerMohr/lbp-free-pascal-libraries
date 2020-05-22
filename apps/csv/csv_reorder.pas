{* ***************************************************************************

Copyright (c) 2019 by Lloyd B. Park

Outputs only the passed list of header fields of the input CSV file in the
same order as the passed header.

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

program csv_reorder;

{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   lbp_types,
   lbp_csv,
   lbp_csv_io_filters;


// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      InsertUsage( '');
      InsertUsage( 'csv_reorder reads a CSV file and outputs it out again with only the columns');
      InsertUsage( '         specified in the --order parameter and in the order they are');
      InsertUsage( '         specified.  New empty columns can also be created);
      InsertUsage( '');
      InsertUsage( 'Usage:');
      InsertUsage( '   csv_reorder [--header] [-f <input file name>] [-o <output file name>]');
      InsertUsage( '');
      InsertUsage( '   ========== Program Options ==========');
      InsertParam( ['h','header'], true, '', 'The comma separated list of column names'); 
      InsertUsage();

      ParseParams();  // parse the command line
   end; // InitArgvParser();


// ************************************************************************
// * GetNewHeader() - Get the new header fro the command line and convert 
// *                  it to a tCsvStringArray
// ************************************************************************

function GetNewHeader():s tCsvStringArray;
   var
      Csv:  tCsv;
   begin
      Csv:= tCsv.Create( GetParam( 'header'));
      Csv.Delimiter:= ','; // The delimiter for the command line is always a ','
      Csv.SkipNonPrintable:= ParamSet( 's');
      result:= Csv.ParseLine;
      Csv.Destroy;
      L:= Length( result);
      if( Lenght( result) = 0) then begin
         Usage( true, 'An empty string was passed in the ''--header'' parametter!');
      end;     
   end; // ConvertNewHeader()


// ************************************************************************
// * main()
// ************************************************************************

var
   Csv:       tCsv;
   Header:    tCsvStringArray;
   TempLine:  tCsvStringArray;
   NewLine:   tCsvStringArray;
   Delimiter: string;
   OD:        char; // The output delimiter
   S:         string;
   C:         char;
   L:         integer; // Header length
   i:         integer;
   iMax:      integer; 
begin
   InitArgvParser();

   // Set the input delimiter
   if( ParamSet( 'id')) then begin
      Delimiter:= GetParam( 'id');
      if( Length( Delimiter) <> 1) then begin
         raise tCsvException.Create( 'The delimiter must be a singele character!');
      end;
      CsvDelimiter:= Delimiter[ 1];
   end;

   // Set the output delimiter
   if( ParamSet( 'od')) then begin
      Delimiter:= GetParam( 'od');
      if( Length( Delimiter) <> 1) then begin
         raise tCsvException.Create( 'The delimiter must be a singele character!');
      end;
      OD:= Delimiter[ 1];
   end else OD:= CsvDelimiter;
   
   // Get the new header from the command line.
   if( not ParamSet( 'header')) then Usage( true, 'The ''--header'' parametter must be specified!');
   Csv:= tCsv.Create( GetParam( 'header'));
   Csv.Delimiter:= ','; // The delimiter for the command line is always a ','
   Csv.SkipNonPrintable:= ParamSet( 's');
   Header:= Csv.ParseLine;
   Csv.Destroy;
   L:= Length( Header);
   if( L < 1) then Usage( true, 'An empty string was passed in the ''--header'' parametter!');
   iMax:= L - 1;

   // Open input CSV
   Csv:= tCsv.Create( lbp_input_file.InputStream, False);
   
   // Test to make sure the user entered a valid header,  Output it if it is OK.
   Csv.ParseHeader();
   for S in Header do begin
      if( not Csv.ColumnExists( S)) then Usage( true, 'Your header field ''' + S + ''' does not exist in the input CSV file!');
   end; // for

   // Process the input CSV
   writeln( OutputFile, Header.ToLine( OD));
   repeat
      TempLine:= Csv.ParseLine();
      SetLength( NewLine, L);
      C:= Csv.PeekChr();
      if( C <> EOFchr) then begin
         for i:= 0 to iMax do NewLine[ i]:= TempLine[ Csv.IndexOf( Header[ i])];
         writeln( OutputFile, NewLine.ToLine( OD));
      end;
   until( C = EOFchr);

   Csv.Destroy;
end.  // csv_reorder program
