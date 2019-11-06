{* ***************************************************************************

Copyright (c) 2019 by Lloyd B. Park

Extract fields from a AwsLog string.  Quote and unquote AwsLog fields.

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
unit lbp_aws_log;

// Class to handle what I hope is a standard log format for AWS.  I built it
// to work with some CDN logs I had to report on.

interface

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}

uses
   lbp_types,
   lbp_generic_containers,
   lbp_parse_helper;

// *************************************************************************


type
   tAwsLogException   =  class( lbp_exception);
   tAwsLogStringArray =  array of string;
   tAwsLogLineArray   =  array of tAwsLogStringArray;
   tAwsLogStringArrayHelper = type helper for tAwsLogStringArray
      function ToLine(): string;
   end;

const
   USchr  = char( 31);  // Unit Separator - Send after each valid field
   RSchr  = char( 30);  // Record Separator - Send after each valid record
var
   EndOfCellChrs:    tCharSet = [ EOFchr, LFchr, CRchr, TabChr];
   EndOfHCellChrs:   tCharSet = [ EOFchr, LFchr, CRchr, ' '];
   EndOfRowChrs:     tCharSet = [ EOFchr, LFchr, CRchr];
   QuoteableChrs:    tCharSet;
   UnquotedCellChrs: tCharSet;

function AwsLogQuote( S: string): string; // Quote the string in a AwsLog compatible way

// *************************************************************************



// *************************************************************************

type
   tAwsLog = class( tChrSource)
      private type
         tIndexDict = specialize tgDictionary<string, integer>;
         tRevIndexDict = specialize tgDictionary<integer, string>;
      private
         IndexDict:   tIndexDict;
         MyVersion:   string;
         MyDelimiter: char;
         EOCchrs:     tCharSet;
      protected
         procedure  Init(); override;
         function   ParseQuotedStr(): string;
         function   ParseHeader(): integer; virtual;// returns the number of cells in the header
      public
         destructor Destroy(); override;
         function   ColumnExists( Name: string): boolean; virtual;
         function   IndexOf( Name: string): integer; virtual;
         function   Header():  tAwsLogStringArray; virtual;
         function   SortedHeader(): tAwsLogStringArray; virtual;
         function   ParseCell(): string; virtual;
         function   ParseLine(): tAwsLogStringArray; virtual;
         function   Parse(): tAwsLogLineArray; virtual;
         procedure  DumpIndex(); virtual;
      end; // tAwsLog class


// *************************************************************************

implementation

// =========================================================================
// = tAwsLog
// =========================================================================
// *************************************************************************
// * Init() - Initialize the class
// *************************************************************************

procedure tAwsLog.Init();
   begin
      Inherited Init();
      EOCchrs:= EndOfHCellChrs;
      ParseHeader();
      IndexDict:= tIndexDict.Create( tIndexDict.tCompareFunction( @CompareStrings), false);
   end; // Init()


// *************************************************************************
// * Destroy() - Destructor
// *************************************************************************

destructor tAwsLog.Destroy();
   begin
      IndexDict.Destroy;
      inherited Destroy;
   end; // Destroy()


// *************************************************************************
// * ParseHeader() - Read the header so we can lookup column numbers by name
// *************************************************************************

{$Warning Function needs reviewed.}
function tAwsLog.ParseHeader(): integer;
   var
      MyHeader:  tAwsLogStringArray;
      i:         integer;
      iMax:      integer;
   // ----------------------------------------------------------------------
   procedure MovePastBeginStr( BeginStr: string);
   var
      C: char;
      L: integer;
   begin
      iMax:= Length( BeginStr);
      for i:= 1 to iMax do begin
         C:= GetChr;
         if( C <> BeginStr[ i]) do begin
            raise tAwsLogException.Create( 'The AWS Log file is missing the %S line!', [BeginStr]);
         end;
      end; // for
   end; // MovePastBeginStr()
   // ----------------------------------------------------------------------
   begin
      MovePastBeginStr( '#Version');
      MyVersion:= ParseCell;
      MyHeader:= ParseLine();
      result:= Length( MyHeader);
      iMax:= result - 1;
      for i:= 0 to iMax do IndexDict.Add( MyHeader[ i], i);
   end; // ParseHeader()


// *************************************************************************
// * ColumnExists() - Returns true if the passed Name is a Column.
// *************************************************************************

{$Warning Function needs reviewed.}
function tAwsLog.ColumnExists( Name: string): boolean;
   begin
      result:= IndexDict.Find( Name);
   end; // ColumnExists()


// *************************************************************************
// * IndexOf() - Returns the column number of the passed header string
// *************************************************************************

{$Warning Function needs reviewed.}
function tAwsLog.IndexOf( Name: string): integer;
   begin
      result:= IndexDict.Items[ Name];
   end; // IndexOf()


// *************************************************************************
// * Header() - Returns an array of header names in the order they appear 
// *            in the AwsLog.  Returns an empty array if the Header hasn't
// *            been parsed.
// *************************************************************************

{$Warning Function needs reviewed.}
function tAwsLog.Header():  tAwsLogStringArray;
   begin
      SetLength( result, IndexDict.Count);
      IndexDict.StartEnumeration;
      while( IndexDict.Next) do result[ IndexDict.Value]:= IndexDict.Key; 
   end; // Header()


// *************************************************************************
// * SortedHeader() - Returns an array of header names sorted alphabetically.
// *                  Returns an empty array if the Header hasn't been
// *                  parsed.
// *************************************************************************

{$Warning Function needs reviewed.}
function tAwsLog.SortedHeader(): tAwsLogStringArray;
   var
      i: integer= 0;
   begin
      SetLength( result, IndexDict.Count);
      IndexDict.StartEnumeration;
      while( IndexDict.Next) do begin
         result[ i]:= IndexDict.Key;
         inc( i);
      end; 
   end; // SortedHeader()


// *************************************************************************
// * ParseQuotedStr() - Returns a quoted cell.  Assumes the first character
// *                    in the character source is the leading quote.
// *************************************************************************

{$Warning Function needs reviewed.}
function tAwsLog.ParseQuotedStr(): string;
   var
      Quote:    char;
      C:        char;
   begin
      result:= ''; // Set default value
      InitS();
      Quote:= Chr;
      
      C:= Chr;
      While( C in AnsiPrintableChrs) do begin
         if( C = Quote) then begin
            if( PeekChr() = Quote) then begin
               // Two quotes in a row
               C:= Chr; 
            end else begin
               SetLength( MyS, MySLen);
               result:= MyS;
               // Strip trailing spaces
               ParseElement( IntraLineWhiteChrs);
               exit;
            end;
         end; // if C = Quote
         ParseAddChr( C);
         C:= Chr;
      end;
      // If we reached here its because there wasn't an end quote character!
      raise lbp_exception.Create( 
         'Invalid character in a quoted string:  Ord($d)  There was most likely a missing end quote.',[C]);
   end; // ParseQuotedStr()


// *************************************************************************
// * ParseCell() - Returns a cell.  It leaves the EndOfCell character in the 
// *               buffer.
// *************************************************************************

{$Warning Function needs reviewed.}
function tAwsLog.ParseCell(): string;
   var
      C:        char;
      i:        integer;
   begin
      result:= ''; // Set default value
      InitS();

      // Discard leading white space
      ParseElement( IntraLineWhiteChrs);

      // Handle quoted cells
      C:= PeekChr();
      if( C in QuoteChrs) then begin
         result:= ParseQuotedStr();
         // Discard trailing spaces;
         ParseElement( IntraLineWhiteChrs);
      // Handle unquoted cells
      end else begin
         result:= ParseElement( UnquotedCellChrs);
         // Strip trailing spaces
         i:= Length( result);
         while( (i > 0) and (Result[ i] in IntraLineWhitechrs)) do dec( i);
         SetLength( result, i);
      end;

      C:= PeekChr();
      if( not (C in EOCchrs)) then begin
         raise tAwsLogException.Create( 'Cell ''' + result + 
                  ''' was not followed by a valid end of cell character');
      end;
      // if( C in InterLineWhiteChrs) then UngetChr( ',');
   end; // ParseCell()


// *************************************************************************
// * ParseLine() - Returns an array of strings.  The returned array is 
// *               invalid if an EOF is the next character in the tChrSource.
// *************************************************************************

{$Warning Function needs reviewed.}
function tAwsLog.ParseLine(): tAwsLogStringArray;
   var
      TempCell:  string;
      C:         char;
      Sa:        tAwsLogStringArray;
      SaSize:    longint = 16;
      SaLen:     longint = 0;
      LastCell:  boolean = false;
   begin
      SetLength( Sa, SaSize);

      // Strip off any white space including empty lines.  This insures the next 
      // character starts a valid cell.
      while( PeekChr() in WhiteChrs) do GetChr();

      // We only can add to cells if we are not at the end of the file
      if( PeekChr <> EOFchr) then begin
         repeat
            TempCell:= ParseCell();

            // Add TempCell to Sa - resize as needed
            if( SaLen = SaSize) then begin
               SaSize:= SaSize SHL 1;
               SetLength( Sa, SaSize);
            end;
            Sa[ SaLen]:= TempCell; 
            inc( SaLen);

            C:= PeekChr;
            LastCell:= C <> ',';
            if( not LastCell) then C:= GetChr;
         until( LastCell);  // so this only matches, CR, LF, and EOF
         
         // If the 'line' ended with an EOF and no CR or LF then we need to fake
         // it since we are returning a valid array of cells.
         if( PeekChr = EOFchr) then UngetChr( LFchr);
      end;

      SetLength( Sa, SaLen);
      result:= Sa;
   end; // ParseLine()


// *************************************************************************
// * Parse() - Returns an array of tAwsLogLines
// *************************************************************************

{$Warning Function needs reviewed.}
function tAwsLog.Parse(): tAwsLogLineArray;
   var
      TempLine:  tAwsLogStringArray;
      C:         char;
      La:        tAwsLogLineArray;
      LaSize:    longint;
      LaLen:     longint;
   begin
      LaSize:= 32;
      SetLength( La, LaSize);
      LaLen:= 0;      

      // Keep going until we reach the end of file character
      repeat
         TempLine:= ParseLine();
         C:= PeekChr();
         if( C <> EOFchr) then begin
            // Add TempLine to La - resize as needed
            if( LaLen = LaSize) then begin
               LaSize:= LaSize SHL 1;
               SetLength( La, LaSize);
            end;
            La[ LaLen]:= TempLine; 
            inc( LaLen);
         end;
      until( C = EOFchr);
      
      SetLength( La, LaLen);
      result:= La;
   end; // Parse()


// *************************************************************************
// * DumpIndex() - Writes the Column index one per line.
// *************************************************************************

{$Warning Function needs reviewed.}
procedure tAwsLog.DumpIndex();
   var
      RevIndexDict: tRevIndexDict;
      i: integer;
      V: string;
   begin
      RevIndexDict:= tRevIndexDict.Create( tRevIndexDict.tCompareFunction( @CompareIntegers));

      // Copy the existing dictionary to the new reverse lookup one.
      IndexDict.StartEnumeration;
      while( IndexDict.Next) do begin
         i:= IndexDict.Value;
         V:= IndexDict.Key;
         RevIndexDict.Add( i, V);
      end;

      RevIndexDict.StartEnumeration;
      while( RevIndexDict.Next) do begin
         V:= RevIndexDict.Value;
         i:= RevIndexDict.Key;
         writeln( i:4, ' - ', V);
      end;

      RevIndexDict.Destroy();
   end; // DumpIndex()

{$Warning End of code to be reviewed}

// =========================================================================
// = tAwsLogStringArrayHelper
// =========================================================================
// *************************************************************************
// * ToLine() - Convert the array into a line of AwsLog text
// *************************************************************************

{$Warning Function needs reviewed.}
function tAwsLogStringArrayHelper.ToLine(): string;
   var
      S:      string;
      Temp:   string;
      First:  boolean;
   begin
      result:= '';
      First:= true;
      for S in self do begin
         Temp:= AwsLogQuote( S);
         if( First) then begin
            First:= false;
            result:= temp;
         end else begin 
            result:= result + ',' + temp;
         end;
      end; // for
   end; // ToLine()



// =========================================================================
// = Global functions
// =========================================================================
// *************************************************************************
// * AwsLogQuote() = Return the passed string 
// *************************************************************************

{$Warning Function needs reviewed.}
function AwsLogQuote( S: string): string;
   var
      C:       char;
      QuoteIt: boolean = false;
   begin
      result:= '';
      for C in S do begin
         if( C in QuoteableChrs) then QuoteIt:= true;
         if( C = '"') then result:= result + '"';
         result:= result + C;
      end;
      if( QuoteIt) then result:= '"' + result + '"';
   end; // AwsLogQuote()


// *************************************************************************
// * Initialization
// *************************************************************************

begin
   UnquotedCellChrs:= AnsiPrintableChrs - EndOfCellChrs;
   QuoteableChrs:= [ TabChr];
end. // lbp_AwsLog unit
