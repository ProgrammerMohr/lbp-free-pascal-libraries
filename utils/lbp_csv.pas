{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Extract fields from a CSV string.  Quote and unquote CSV fields.

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
{$WARNING This unit needs lots of work.  It is only partially implemented}
{$WARNING Perhaps we should look at Free Pascal's included libraries.}
unit lbp_csv;

// Classes to handle Comma Separated Value strings and files.

interface

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}

uses
   lbp_types;


// *************************************************************************

type
   CSVException = class( lbp_exception);


const
   cEOF= char(0);
   cLF=  char( 10);
   cCR=  char( 13);
   cTab = char( 9);
   cSpace = ' ';
   cComma = ',';
   cQuote1 = '''';
   cQuote2 = '"';
   FieldEnders = [ cEOF, cLF, cCR, cComma];
   Quoteable = [ cComma, cSpace, cQuote1, cQuote2];

// *************************************************************************

type
   tCSVLine = class
      protected
         MyLine:       string;
         MyCharPos:    integer;
         LineLength:   integer;
         MyDelimiter:  char;
      public
         constructor Create();
         constructor Create( iLine: string);
//         procedure   Restart(); // Make the next NextValue calll return the first value
         function    NextValue(): string;
         class function    Quote( S: string): string;
         class function    Dequote( qS: string): string;
      protected
         function    PeekNextChar(): char;
         function    GetNextChar():  char;
         procedure   SetLine( iLine: string);
      public
         property    Line: string read MyLine write SetLine;
         property    Delimiter: char read MyDelimiter write MyDelimiter;
      end; // CSVLine class


// *************************************************************************
// * tCSV - This comes from netserv/ipdbsync/ipdbsync_pipe_interface
// *        It needs modifed to support reading/writing files and direct
// *        conversion of strings.
// *************************************************************************

// type
//    tCSV = class
//       private
//          QuoteChar:    char;
//          InFile:       Text;
//          OutFile:      Text;
//          PreviousChar: char;
//          CurrentChar:  char;
//          CurrentField: string;
//          EndOfFile:    boolean;
//          EndOfRow:     boolean;
//          Buffer:       string;
//          BuffLength:   integer;
//          BuffPos:      integer;
//          MyRow:        ArrayOfString
//       public
//          constructor  Create();
//          destructor   Destroy(); override;
//       private
//          procedure    NextChar();
//          procedure    NextField();
//       public
//          function     Encode( SA: StringArray): string;
//          function     Decode( S: string): StringArray;
//
//          function     ParseRow( ): StringArray
//          procedure    NextRow();  // Read
//          procedure    DumpRow( R: array of string); // for debugging
//          function     ReadRow():   StringArray;
//          procedure    WriteRow( R: array of string);
//       end; // tCSV class


// *************************************************************************

// *************************************************************************


implementation

var
   QuoteCharacter: char = '"';

// =========================================================================
// = tCSVLine
// =========================================================================
// *************************************************************************
// * Create() - Constructor
// *************************************************************************

constructor tCSVLine.Create( iLine: string);
   begin
      Line:= iLine;
      Delimiter:= ',';
   end; // Create()

// -------------------------------------------------------------------------


constructor tCSVLine.Create();
   begin
      Line:= '';
      Delimiter:= ',';
   end; // Create()


// *************************************************************************
// * Restart() - Make the next NextValue calll return the first value
// *************************************************************************

// *************************************************************************
// * NextValue() - Return the next CSV value as a string
// *************************************************************************

function tCSVLine.NextValue(): string;
   var
      Temp:      char;
      FirstPos:  integer;
      LastPos:   integer;
      SkipComma: integer;
   begin
      // Return empty values if we are beyond the end of the line
      if( MyCharPos > LineLength) then begin
         result:= '';
         exit;
      end;

      // Get rid of leading spaces
      repeat
         FirstPos:= MyCharPos;
         Temp:= GetNextChar();
      until( Temp <> ' ');

      while( (MyCharPos <= LineLength) and (Temp <> Delimiter)) do begin
         Temp:= GetNextChar()
      end;

      if( Temp = Delimiter) then SkipComma:= 1 else SkipComma:= 0;
      result:= Copy( MyLine, FirstPos, MyCharPos - FirstPos - SkipComma);
   end; // NextValue()


// *************************************************************************
// * PeekNextChar() - Get the next character in Line without
// *                  incrementing the index.
// *************************************************************************

function tCSVLine.PeekNextChar(): char;
   begin
      if( MyCharPos > LineLength) then begin
         raise CSVException.create(
            'Attempt to PeekNextChar() beyond the end of Line!');
      end;
      result:= MyLine[ MyCharPos];
   end; // PeekNextChar()


// *************************************************************************
// * GetNextChar() - Get the next character in Line and
// *                 increment the index.
// *************************************************************************

function tCSVLine.GetNextChar(): char;
   begin
      if( MyCharPos > LineLength) then begin
         raise CSVException.create(
            'Attempt to GetNextChar() beyond the end of Line!');
      end;
      result:= MyLine[ MyCharPos];
      inc( MyCharPos);
   end; // GetNextChar()


// *************************************************************************
// * SetLine() - Set the line to be parsed.
// *************************************************************************

procedure tCSVLine.SetLine( iLine: string);
   begin
      MyLine:= iLine;
      LineLength:= length( iLine);
      MyCharPos:= 1;
   end; // SetLine()


// *************************************************************************
// * Quote() - Quotes the passed string using pascal quote syntax.
// *************************************************************************

class function tCSVLine.Quote( S: string): string;
   var
      qS: string;
      qi: integer;
      i:  integer;
      L:  integer;
      qL: integer;
      C:  char;
   begin
      L:= Length( S);
      qL:= L * 2 + 2;
      SetLength( qS, qL);
      qi:= 1;
      qS[ qi]:= QuoteCharacter;
      for i:= 1 to L do begin
         inc( qi);
         C:= S[ i];
         qS[ qi]:= C;
         if( C = QuoteCharacter) then begin
            inc( qi);
            qS[ qi]:= C;
         end;
      end;
      inc( qi);
      qS[ qi]:= QuoteCharacter;
      SetLength( qS, qi);
      result:= qS;
   end; // Quote()


// *************************************************************************
// * Dequote() - Returns the original string from a quoted version.
// *************************************************************************

var
   DQErrMsg: string = 'tCSVLine.Dequote():  The passed string was not  properly CSV quoted!';

class function tCSVLine.Dequote( qS: string): string;
   var
      S:  string;
      qi: integer;
      i:  integer;
      qL: integer;
      FirstQuote: boolean;
      C:  char;
   begin
      S:= '';
      qL:= Length( qS);
      SetLength( S, qL - 2);
      if( (qL = 0) or (qS[ 1] <> QuoteCharacter) or (qS[ qL] <> QuoteCharacter)) then begin
         raise CSVException.Create( DQErrMsg);
      end;

      dec( qL); // skip the last quote character
      i:= 0;
      FirstQuote:= false;

      for qi:= 2 to qL do begin
         C:= qS[ qi];
         if( FirstQuote) then begin
            if( C = QuoteCharacter) then begin
               inc( i);
               S[ i]:= C;
               FirstQuote:= false;
            end else begin
               raise CSVException.Create( DQErrMsg);
            end;
         end else begin
            if( C = QuoteCharacter) then begin
               FirstQuote:= true;
            end else begin
               inc( i);
               S[ i]:= C;
            end;
         end;
      end; // for

      SetLength( S, i);
      result:= S;
   end; // Dequote()


// *************************************************************************


end. // lbp_csv unit
