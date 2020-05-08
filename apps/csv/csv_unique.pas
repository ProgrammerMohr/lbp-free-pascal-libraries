{* ***************************************************************************

Copyright (c) 2019 by Lloyd B. Park

Outputs unqique rows in the table.  As a side effect the rows will be
sorted in alphabetical order.

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


program csv_unique;

{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   lbp_types,
   lbp_csv,
   lbp_parse_helper,
   lbp_generic_containers,
   lbp_input_file,
   lbp_output_file,
   sysutils; // Conversion functions



// ************************************************************************
// * tStringTree class 
// ************************************************************************

type
   tStringTree = specialize tgAvlTree< string>;


// ************************************************************************
// * Global variables
// ************************************************************************

var
   SkipNonPrintable:   boolean = false;
   DelimiterIn:        char;
   DelimiterOut:       char;
//   IgnoreCase:         boolean = false;
   Csv:                tCsv;
   UniqueTree:         tStringTree;


// ************************************************************************
// * SetGlobals() - Sets our global variables
// ************************************************************************

procedure SetGlobals();
   var
      Delimiter:    string;
   begin
      // Set the boolean options
      SkipNonPrintable:= ParamSet( 'skip-non-printable');
//      IgnoreCase:=       ParamSet( 'ignore-case');
      
      // Set the input delimiter
      if( ParamSet( 'id')) then begin
         Delimiter:= GetParam( 'id');
         if( Length( Delimiter) <> 1) then begin
            raise tCsvException.Create( 'The delimiter must be a singele character!');
         end;
         DelimiterIn:= Delimiter[ 1];
      end else begin
         DelimiterIn:= CsvDelimiter; // the default value in the lbp_csv unit.
      end;

      // Set the output delimiter
      if( ParamSet( 'od')) then begin
         Delimiter:= GetParam( 'od');
         if( Length( Delimiter) <> 1) then begin
            raise tCsvException.Create( 'The delimiter must be a singele character!');
         end;
         DelimiterOut:= Delimiter[ 1];
      end else begin
         DelimiterOut:= DelimiterIn;
      end;
   
      // Open input CSV
      Csv:= tCsv.Create( lbp_input_file.InputStream, False);
      Csv.ParseHeader();
   
      // Apply the boolean options
      Csv.SkipNonPrintable:= SkipNonPrintable;

      UniqueTree:= tStringTree.Create( tStringTree.tCompareFunction( @CompareStrings));
   end; // SetGlobals()


// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      InsertUsage( '');
      InsertUsage( 'csv_unique reads a CSV file and outputs the unique rows.  Use csv_reorder');
      InsertUsage( 'to get a list of unique items in a single field.  Use csv_count to quickly');
      InsertUsage( 'find out how many unique rows you found.');
      InsertUsage( '');
      InsertUsage( 'Usage:');
      InsertUsage( '   csv_sort [-f <input file name>] [-o <output file name>]');
      InsertUsage( '');
      InsertUsage( '   ========== Program Options ==========');
      SetInputFileParam( true, true, false, true);
      SetOutputFileParam( false, true, false, true);
      InsertParam( ['d', 'id','input-delimiter'], true, ',', 'The character which separates fields on a line.'); 
      InsertParam( ['od','output-delimiter'], true, ',', 'The character which separates fields on a line.'); 
      InsertParam( ['s', 'skip-non-printable'], false, '', 'Try to fix files with some unicode characters.');
      InsertUsage();
      ParseParams();
   end; // InitArgvParser();


// ************************************************************************
// * 
// ************************************************************************


// ************************************************************************
// * main()
// ************************************************************************

var
   Header:    tCsvStringArray;
   TempRow:   tCsvStringArray;
   TextRow:   string;
   NewLine:   tCsvStringArray;
   C:         char;
begin
   InitArgvParser();
   SetGlobals();

   Header:= Csv.Header;

   // Populate UniqueTree
   repeat
      TempRow:= Csv.ParseLine();
   
      // Does the row have fields?
      if( Length( TempRow) <> 0) then begin
         TextRow:= TempRow.ToLine( DelimiterOut);

         // Add it to the tree if necessary
         if( not UniqueTree.Find( TextRow)) then begin
            UniqueTree.Add( TextRow);
         end; // If not in the tree yet
      end; // If the row has fields

      C:= Csv.PeekChr();
   until( C = EOFchr); // while

   // Output 
   writeln( OutputFile, Header.ToLine( DelimiterOut));
   
   for TextRow in UniqueTree do begin
      writeln( OutputFile, TextRow);
   end;


   // // Set the input delimiter
   // if( ParamSet( 'id')) then begin
   //    Delimiter:= GetParam( 'id');
   //    if( Length( Delimiter) <> 1) then begin
   //       raise tCsvException.Create( 'The delimiter must be a singele character!');
   //    end;
   //    CsvDelimiter:= Delimiter[ 1];
   // end;

   // // Set the output delimiter
   // if( ParamSet( 'od')) then begin
   //    Delimiter:= GetParam( 'od');
   //    if( Length( Delimiter) <> 1) then begin
   //       raise tCsvException.Create( 'The delimiter must be a singele character!');
   //    end;
   //    OD:= Delimiter[ 1];
   // end else OD:= CsvDelimiter;
   
   // // Get the new header from the command line.
   // if( not ParamSet( 'header')) then Usage( true, 'The ''--header'' parametter must be specified!');
   // Csv:= tCsv.Create( GetParam( 'header'));
   // Csv.Delimiter:= ','; // The delimiter for the command line is always a ','
   // Csv.SkipNonPrintable:= ParamSet( 's');
   // Header:= Csv.ParseLine;
   // Csv.Destroy;
   // L:= Length( Header);
   // if( L < 1) then Usage( true, 'An empty string was passed in the ''--header'' parametter!');
   // iMax:= L - 1;

   // // Open input CSV
   // Csv:= tCsv.Create( lbp_input_file.InputStream, False);
   
   // // Test to make sure the user entered a valid header,  Output it if it is OK.
   // Csv.ParseHeader();
   // for S in Header do begin
   //    if( not Csv.ColumnExists( S)) then Usage( true, 'Your header field ''' + S + ''' does not exist in the input CSV file!');
   // end; // for

   // // Process the input CSV
   // writeln( OutputFile, Header.ToLine( OD));
   // repeat
   //    TempLine:= Csv.ParseLine();
   //    SetLength( NewLine, L);
   //    C:= Csv.PeekChr();
   //    if( C <> EOFchr) then begin
   //       for i:= 0 to iMax do NewLine[ i]:= TempLine[ Csv.IndexOf( Header[ i])];
   //       writeln( OutputFile, NewLine.ToLine( OD));
   //    end;
   // until( C = EOFchr);

   // Clean up
   Csv.Destroy;
   UniqueTree.RemoveAll;
   UniqueTree.Destroy;
end.  // csv_unique program
