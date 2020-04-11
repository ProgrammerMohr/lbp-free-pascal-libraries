{* ***************************************************************************

Copyright (c) 2019 by Lloyd B. Park

Filter the lines in a .csv file using regular expressions.

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

program csv_grep;

{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   lbp_types,
   lbp_csv,
   lbp_parse_helper,
   lbp_generic_containers,
   lbp_input_file,
   lbp_output_file,
   regexpr;  // Regular expressions

type
   tIntegerList = specialize tgDoubleLinkedList< integer>;

var
   SkipNonPrintable:   boolean = false;
   InvertMatch:        boolean = false;
   IgnoreCase:         boolean = false;
   GrepIndexes:        tIntegerList;
   Csv:                tCsv;
   DelimiterOut:       char;
   RegularExpression:  tRegExpr;


// ************************************************************************
// * SetGlobals() - Sets our global variables
// ************************************************************************

procedure SetGlobals();
   var
      L:            integer = 0;  // used for Length
      Field:        string;
      GrepFields:   tCsvStringArray;
      Delimiter:    string;
      DelimiterIn:  char;
   begin
      // Get the regular expression
      if( Length( UnnamedParams) <> 1) then begin
         raise tCsvException.Create( 'You must enter one and only one regular expression on the command line!');
      end;
      RegularExpression:= tRegExpr.Create( UnnamedParams[ 0]);
      
      GrepIndexes:= tIntegerList.Create();

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
   
      // Get the new header from the command line.
      if( ParamSet( 'header')) then begin
         Csv:= tCsv.Create( GetParam( 'header'));
         Csv.Delimiter:= ','; // The delimiter for the command line is always a ','
         Csv.SkipNonPrintable:= ParamSet( 's');
         GrepFields:= Csv.ParseLine;
         Csv.Destroy;
         L:= Length( GrepFields);
      end;

      // Open input CSV
      Csv:= tCsv.Create( lbp_input_file.InputStream, False);
   
      // If we don't yet have GrepHeaders, default to searchin all headers
      Csv.ParseHeader();
      if( L = 0) then begin
         GrepFields:= Csv.Header();
      end;

      // Make sure all the header fields are valid and add their indexes to GrepIndexes
      for Field in GrepFields do begin
         if( Csv.ColumnExists( Field)) then begin
            GrepIndexes.Queue := Csv.IndexOf( Field);
         end else begin
            Usage( true, 'Your header field ''' + Field + ''' does not exist in the input CSV file!');
         end;
      end; // for

      // Set the boolean options
      SkipNonPrintable:= ParamSet( 'skip-non-printable');
      InvertMatch:=      ParamSet( 'invert-match');
      IgnoreCase:=       ParamSet( 'ignore-case');

      // Apply the boolean options
      Csv.SkipNonPrintable:= SkipNonPrintable;
      RegularExpression.ModifierI:= IgnoreCase;
      RegularExpression.ModifierM:= true; // start and end line works for each line in a multi-line field
   end; // InitGlobals()


// ************************************************************************
// * DumpGlobals() - Dump the global variables for troubleshooting
// ************************************************************************

Procedure DumpGlobals();
   var
      i:        integer;
      VarName:  string = 'GrepIndexes:        ';
   begin
      writeln( 'SkipNonPrintable:   ', SkipNonPrintable); 
      writeln( 'InvertMatch:        ', InvertMatch);
      writeln( 'IgnoreCase:         ', IgnoreCase);
      for i in GrepIndexes do begin
         writeln( VarName, i);
         VarName:= '                    ';
      end;
      writeln( 'DelimiterOut:       ', DelimiterOut);  
   end; // DumpFields()


// ************************************************************************
// * Clean up global variables;
// ************************************************************************

procedure CleanGlobals();
   begin
      Csv.Destroy();
      GrepIndexes.Destroy();
      RegularExpression.Destroy();
   end; // CleanGlobals();


// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      InsertUsage( '');
      InsertUsage( 'csv_grep reads a CSV file and performs a grep on each field specified by the');
      InsertUsage( '      --headers parameter.  If the grep matches on any field the row is output');
      InsertUsage( '      If no fields are specified all fields are searched.');
      InsertUsage( '');
      InsertUsage( 'Usage:');
      InsertUsage( '   csv_grep [--header <header1,header2,...>] [-f <input file name>] [-o <output file name>] <regular expression>');
      InsertUsage( '');
      InsertUsage( '   ========== Program Options ==========');
      SetInputFileParam( true, true, false, true);
      SetOutputFileParam( false, true, false, true);
      InsertParam( ['h','header'], true, '', 'The comma separated list of column names'); 
      InsertParam( ['d', 'id','input-delimiter'], true, ',', 'The character which separates fields on a line.'); 
      InsertParam( ['od','output-delimiter'], true, ',', 'The character which separates fields on a line.'); 
      InsertParam( ['s', 'skip-non-printable'], false, '', 'Try to fix files with some unicode characters.');
      InsertParam( ['i', 'ignore-case'], false, '', 'Perform a case insensitive search.');
      InsertParam( ['v', 'invert-match'], false, '', 'Output rows that do not match the pattern.');
      InsertUsage();
      ParseParams();
   end; // InitArgvParser();


// ************************************************************************
// * ProcessCsv() - Main loop to process the file
// ************************************************************************

procedure ProcessCsv();
   var
      Line:  tCsvStringArray;
      c:     char;
      Found: boolean;
      i:     integer;
   begin
      // Output the header
      writeln( OutputFile, Csv.Header.ToLine( DelimiterOut));
      repeat
         Line:= Csv.ParseLine();
         c:= Csv.PeekChr();
         Found:= false;
         if( c <> EOFchr) then begin
            // Test each field for a match
            for i in GrepIndexes do begin
               if( RegularExpression.Exec( Line[ i])) then Found:= true;
            end;  
            // Output the line if a match was found (or not found and InvertMatch)
            if( Found xor InvertMatch) then begin
               writeln( OutputFile, Line.ToLine( DelimiterOut));
            end;
         end;
      until( C = EOFchr);
   end; // ProcessCsv();


// ************************************************************************
// * main()
// ************************************************************************

begin
   InitArgvParser();
   SetGlobals();

   ProcessCsv();

   CleanGlobals();
end.  // csv_grep program
