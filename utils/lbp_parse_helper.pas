{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

lbp_parse_helper



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

unit lbp_parse_helper;

interface

{$include lbp_standard_modes.inc}
//{$V-}    //Added by LP because it says so below
//{$R-}    //Range checking off
//{$S-}    //Stack checking off
//{$I-}    //I/O checking off
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

// ************************************************************************

uses
   lbp_types,
   lbp_generic_containers,
   classes;

// ************************************************************************

type
   tCharList = specialize tgList< char>;
   tCharSet = set of char;
   ParseException = class( lbp_exception);
const
   ParserBufferSize = 4096;
   EOFchr = char( 26);
   CRchr  = char( 13);
   LFchr  = char( 10);
   TabChr = char( 9);
var
   AsciiChrs:   tCharSet  = [char( 0)..char( 127)];
   AnsiChrs:    tCharSet  = [char( 0)..char( 255)];
   AlphaChrs:   tCharSet  = ['a'..'z', 'A'..'Z'];
   NumChrs:     tCharSet  = ['0'..'9'];
   AlphaNumChrs: tCharSet = ['a'..'z', 'A'..'Z', '0'..'9'];
   WhiteChrs:   tCharSet  = [ ' ', TabChr, LFchr, CRchr];
   QuoteChrs:   tCharSet  = ['''', '"' ];
   SymbolChrs:  tCharSet  = [char( 33)..char( 47), char( 58)..char( 64),
                               char( 91)..char( 96), char( 123)..char( 126)];
   CtlChrs:     tCharSet  = [char(0)..char(31),char(127)];
   IntraLineWhiteChrs:  tCharSet = [ ' ', TabChr];
   InterLineWhiteChrs:  tCharSet = [ LFchr, CRchr];
   AsciiPrintableChrs:  tCharSet;
   AnsiPrintableChrs:   tCharSet;



// ************************************************************************
// * tChrSource class - Provides tools to get and unget characters from
// *                    some text source.
// ************************************************************************
type
   tChrSource = class( tObject)
      private
         ChrBuff:        array[ 0..(ParserBufferSize - 1)] of char;
         ChrBuffLen:     longint;
         ChrBuffPos:     longint;
         UngetQ:         tCharList;
         Stream:         tStream;
         DestroyStream:  boolean;
      protected
         // Element Parsing variables;
         S:              string;
         SSize:          longint;
         SLen:           longint;
      public
         constructor Create( iStream: tStream; iDestroyStream: boolean = true);
         constructor Create( iString: string; IsFileName: boolean = false);
         constructor Create( var iFile:   text);
         destructor  Destroy(); override;
      protected
         procedure   Init(); virtual;
         procedure   InitS();
         procedure   ParseAddChr( C: char);
      public
         function    PeekChr(): char;
         function    GetChr(): char;
         procedure   UngetChr( C: char);
         function    ParseElement( var AllowedChrs: tCharSet): string;
         property    Chr: char read GetChr write UngetChr;
      end; // tChrSource class


// ************************************************************************

implementation

// ========================================================================
// = tChrSource class
// ========================================================================
// *************************************************************************
// * Create() - Constructor
// *************************************************************************

constructor tChrSource.Create( iStream: tStream; iDestroyStream: boolean);
   begin
      inherited Create();
      Stream:= iStream;
      DestroyStream:= iDestroyStream;
      Init();  end; // Create()

// -------------------------------------------------------------------------

constructor tChrSource.Create( iString: string; IsFileName: boolean);
   begin
      inherited Create();
      if( IsFileName) then begin
         Stream:= tFileStream.Create( iString, fmOpenRead);
      end else begin
         Stream:= tStringStream.Create( iString);
      end;
      DestroyStream:= true;
      Init();
   end; // Create()


// -------------------------------------------------------------------------

constructor tChrSource.Create( var iFile: text);
   begin
      inherited Create();
      Stream:= tHandleStream.Create( TextRec( iFile).Handle);
      DestroyStream:= true;
      Init();
   end; // Create()


// *************************************************************************
// * Destroy() - Destructor
// *************************************************************************

destructor tChrSource.Destroy();
   begin
       if( DestroyStream) then Stream.Destroy();
       UngetQ.Destroy;
       inherited Destroy();
   end; // Destroy()


// *************************************************************************
// * Init() - internal function to initialize variables.  Called by Create()
// *************************************************************************

procedure tChrSource.Init();
   begin
      UngetQ:= tCharList.Create( 4, 'UngetQ');

      ChrBuffLen:= Stream.Read( ChrBuff, ParserBufferSize);
      ChrBuffPos:= 0;
   end; // Init()


// ************************************************************************
// * InitS() - Set S's initial length and size
// ************************************************************************

procedure tChrSource.InitS();
   begin
      SSize:= 16;
      SetLength( S, SSize);
      SLen:= 0;      
   end; // InitS()


// ************************************************************************
// * AddChr() - Add a character to S and resize as needed.
// ************************************************************************

procedure tChrSource.ParseAddChr( C: char);
   begin
      // If we used up all the space in S then double it's capacity.
      if( SLen = SSize) then begin
         SSize:= SSize SHL 1;
         SetLength( S, SSize);
      end;
      inc( SLen);
      S[ SLen]:= C; 
   end; // ParseAddChar()


// *************************************************************************
// * PeekChr() - Returns the next char in the stream
// *************************************************************************

function tChrSource.PeekChr(): char;
   begin
      result:= EOFchr;
      if( not UngetQ.IsEmpty()) then begin
         UngetQ.StartEnumeration();
         if( UngetQ.Next()) then begin
            result:= UngetQ.GetCurrent();
         end;
      end else begin
         if( ChrBuffPos = ChrBuffLen) then begin
            // Read another block into the buffer
            ChrBuffLen:= Stream.Read( ChrBuff, ParserBufferSize);
            ChrBuffPos:= 0;
         end;
         if( ChrBuffPos < ChrBuffLen) then begin
           result:= ChrBuff[ ChrBuffPos];
         end;
      end; 
   end; // PeekChr();


// *************************************************************************
// * GetChr() - Returns the next char in the stream
// *************************************************************************

function tChrSource.GetChr(): char;
   begin
      result:= EOFchr;
      if( not UngetQ.IsEmpty()) then begin
         result:= UngetQ.Queue;
      end else begin
         if( ChrBuffPos = ChrBuffLen) then begin
            // Read another block into the buffer
            ChrBuffLen:= Stream.Read( ChrBuff, ParserBufferSize);
            ChrBuffPos:= 0;
         end;
         if( ChrBuffPos < ChrBuffLen) then begin
           result:= ChrBuff[ ChrBuffPos];
           inc( ChrBuffPos);
         end;
      end; 
   end; // GetChr();


// *************************************************************************
// * UngetChr() - inserts the passed character into the stream
// *************************************************************************

procedure tChrSource.UngetChr( C: char);
   begin
      UngetQ.Queue:= C;
   end; // UngetChr()


// ************************************************************************
// * Parse()
// ************************************************************************

function tChrSource.ParseElement( var AllowedChrs: tCharSet): string;
   var
      C: char;
   begin
      InitS();

      C:= GetChr();
      while( C in AllowedChrs) do begin
         ParseAddChr( C);
         C:= GetChr();
      end;
      UngetChr( C);
      SetLength( S, SLen);
      result:= S;
   end; // ParseElement()



// *************************************************************************

begin
   AsciiPrintableChrs:= (AsciiChrs - CtlChrs) + WhiteChrs;
   AnsiPrintableChrs:= (AnsiChrs - CtlChrs) + WhiteChrs;
end.  // lbp_parse_helper unit