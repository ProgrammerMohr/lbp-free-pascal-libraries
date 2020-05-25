{* ***************************************************************************

Copyright (c) 2019 by Lloyd B. Park

Sorts a .csv file according to the values in one field

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


program csv_sort;

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
// * tCsvLine class - A class to hold the elements of a tCsvCellArrayraise 
// *   We use this because LBP generic contains don't work with arrays.
// ************************************************************************

type
   tCsvLine = class
      public
         Row:  tCsvCellArray;
      end;
      

// ************************************************************************
// * tCsvLineList class - A parent class to hold all CSV lines with the
// *    same value in the sort field.
// ************************************************************************

type
   tCsvLineList = specialize tgDoubleLinkedList< tCsvLine>;


// ************************************************************************
// * tCsvLineListByString class - The CSV Line will be sorted by a string
// *    field
// ************************************************************************

type
   tCsvLineListByString = class( tCsvLineList)
      public
         Key:    string;
         constructor Create( iLine: tCsvCellArray);
      end;


// ************************************************************************
// * tCsvLineListByInt64 class - The CSV Line will be sorted by an int64
// *    field
// ************************************************************************

type
   tCsvLineListByInt64 = class( tCsvLineList)
      public
         Key:    int64;
         constructor Create( iLine: tCsvCellArray);
      end;


// ************************************************************************
// * tCsvLineByIPv4 class - The CSV Line will be sorted by an IPv4
// *                          address field
// ************************************************************************

type
   tCsvLineListByIPv4 = class( tCsvLineList)
      public
         Key:    word32;
         constructor Create( iLine: tCsvCellArray);
      end;


// ************************************************************************
// * Global variables
// ************************************************************************

var
   FieldName:          string; // From the --header parameter
   FieldIndex:         integer;
   SkipNonPrintable:   boolean = false;
   IgnoreCase:         boolean = false;
   ReverseOrder:       boolean = false;
   DelimiterIn:        char;
   DelimiterOut:       char;
   Csv:                tCsv;
   SortByIpv4:         boolean = false;
   SortByInteger:      boolean = false;
   SortByDouble:       boolean = false;



// ========================================================================
// = tCsvLineListByString class
// ========================================================================
// ************************************************************************
// * Create() - Constructor
// ************************************************************************

constructor tCsvLineListByString.Create( iLine: tCsvCellArray);
   var
      L:  tCsvLine;
   begin
      inherited Create();
      L:= tCsvLine.Create();
      L.Row:= iLine;
      Queue:= L;
      if( IgnoreCase) then begin
         Key:= LowerCase( iLine[ FieldIndex]);
      end else begin
         Key:= iLine[ FieldIndex];
      end;
   end; // Create()



// ========================================================================
// = tCsvLineListByInt64 class
// ========================================================================
// ************************************************************************
// * Constructor()
// ************************************************************************

constructor tCsvLineListByInt64.Create( iLine: tCsvCellArray);
   var
      L:  tCsvLine;
   begin
      inherited Create();
      L:= tCsvLine.Create();
      L.Row:= iLine;
      Queue:= L;
      key:= StrToInt64( iLine[ FieldIndex]);
   end; // Create()



// ========================================================================
// = tCsvLineListByIPv4 class
// ========================================================================
// ************************************************************************
// * Constructor()
// ************************************************************************

constructor tCsvLineListByIPv4.Create( iLine: tCsvCellArray);
   var
      L:  tCsvLine;
   begin
      inherited Create();
      L:= tCsvLine.Create();
      L.Row:= iLine;
      Queue:= L;
      key:= StrToInt64( iLine[ FieldIndex]);
   end; // Create()



// ************************************************************************
// * SetGlobals() - Sets our global variables
// ************************************************************************

procedure SetGlobals();
   var
      Delimiter:    string;
      Exclusive:    integer = 0;
   begin
      // Set the boolean options
      SkipNonPrintable:= ParamSet( 'skip-non-printable');
      IgnoreCase:=       ParamSet( 'ignore-case');
      ReverseOrder:=     ParamSet( 'reverse-order');
      if( ParamSet( 'ipv4')) then begin
         SortByIpv4:= true;
         Inc( Exclusive);
      end;
      if( ParamSet( 'number')) then begin
         SortByInteger:= true;
         Inc( Exclusive);
      end;
      if( ParamSet( 'number')) then begin
         SortByInteger:= true;
         Inc( Exclusive);
      end;
      if( ParamSet( 'double')) then begin
         SortByDouble:= true;
         Inc( Exclusive);
      end;
      if( Exclusive > 1) then begin
         raise tCsvException.Create( 'You selected more than one field sort type!');        
      end;
      
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
   
      // Get the header field to be sorted.
      if( ParamSet( 'header')) then begin
         FieldName:= GetParam( 'header');
      end else begin
         Usage( true, 'The header field parameter is required!');        
      end;

      // Make sure the header field is valid.
      if( Csv.ColumnExists( FieldName)) then begin
         FieldIndex := Csv.IndexOf( FieldName);
      end else begin
         Usage( true, 'Your header field ''' + FieldName + ''' does not exist in the input CSV file!');
      end;

      // Apply the boolean options
      Csv.SkipNonPrintable:= SkipNonPrintable;
   end; // SetGlobals()


// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      InsertUsage( '');
      InsertUsage( 'csv_sort reads a CSV file and outputs it sorted by the specified header field.');
      InsertUsage( 'The sorting is done in memory, so very large files may fail to sort.');
      InsertUsage( '');
      InsertUsage( 'Usage:');
      InsertUsage( '   csv_sort [--header <header field name>] [-f <input file name>] [-o <output file name>]');
      InsertUsage( '');
      InsertUsage( '   ========== Program Options ==========');
      SetInputFileParam( true, true, false, true);
      SetOutputFileParam( false, true, false, true);
      InsertParam( ['h','header'], true, '', 'The comma separated list of column names'); 
      InsertParam( ['d', 'id','input-delimiter'], true, ',', 'The character which separates fields on a line.'); 
      InsertParam( ['od','output-delimiter'], true, ',', 'The character which separates fields on a line.'); 
      InsertParam( ['s', 'skip-non-printable'], false, '', 'Try to fix files with some unicode characters.');
      InsertParam( ['i', 'ignore-case'], false, '', 'Perform a case insensitive sort.');
      InsertParam( ['4', 'ipv4'], false, '', 'The passed field is an IPv4 address.');
      InsertParam( ['n', 'number'], false, '', 'The passed filed is an integer number.');
      InsertParam( ['double', 'float'], false, '', 'The passed filed is an floating point number.');
      InsertParam( ['r', 'reverse-order'], false, '', 'Outputs in decending order.');
      InsertUsage();
      ParseParams();
   end; // InitArgvParser();


// ************************************************************************
// * CompareByStrings() - Compare two Strings.  Used by tCsvTree
// ************************************************************************

function CompareString( CLL1: tCsvLineList; CLL2: tCsvLineList): int8;
   var
      K1: string;
      K2: string;
   begin
      K1:= tCsvLineListByString( CLL1).Key;
      K2:= tCsvLineListByString( CLL2).Key;
      if( K1 > K2) then begin
         result:= 1;
      end else if( K1 < K2) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareString()


// ************************************************************************
// * CompareInt64() - Compare two Int64s.  Used by tCsvTree
// ************************************************************************

function CompareInt64( CLL1: tCsvLineList; CLL2: tCsvLineList): int8;
   var
      K1: Int64;
      K2: Int64;
   begin
      K1:= tCsvLineListByInt64( CLL1).Key;
      K2:= tCsvLineListByInt64( CLL2).Key;
      if( K1 > K2) then begin
         result:= 1;
      end else if( K1 < K2) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareInt64()


// ************************************************************************
// * CompareWord32() - Compare two Word32s.  Used by tCsvTree
// ************************************************************************

function CompareWord32( CLL1: tCsvLineList; CLL2: tCsvLineList): int8;
   var
      K1: word32;
      K2: word32;
   begin
      K1:= tCsvLineListByIPv4( CLL1).Key;
      K2:= tCsvLineListByIpv4( CLL2).Key;
      if( K1 > K2) then begin
         result:= 1;
      end else if( K1 < K2) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareInt64()


// ************************************************************************
// * 
// ************************************************************************


// ************************************************************************
// * main()
// ************************************************************************

var
   Header:    tCsvCellArray;
   TempLine:  tCsvCellArray;
   NewLine:   tCsvCellArray;
   Delimiter: string;
   OD:        char; // The output delimiter
   S:         string;
   C:         char;
   L:         integer; // Header length
   i:         integer;
   iMax:      integer; 
begin
   InitArgvParser();
   SetGlobals();

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
   // Header:= Csv.ParseRow;
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
   //    TempLine:= Csv.ParseRow();
   //    SetLength( NewLine, L);
   //    C:= Csv.PeekChr();
   //    if( C <> EOFchr) then begin
   //       for i:= 0 to iMax do NewLine[ i]:= TempLine[ Csv.IndexOf( Header[ i])];
   //       writeln( OutputFile, NewLine.ToLine( OD));
   //    end;
   // until( C = EOFchr);

   Csv.Destroy;
end.  // csv_sort program
