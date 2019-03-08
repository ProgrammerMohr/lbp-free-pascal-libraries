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
   tCharSet = array of char;
   ParseException = class( lbp_exception);
const
   ParserBufferSize = 4096;
   EOFchr = char( 26);
   CRchr  = char( 13);
   LFchr  = char( 10);
   TabChr = char( 9);
var
   AsciChrs:    set of char = [char( 0)..char( 127)];
   AnsiChrs:    set of char = [char( 0)..char( 255)];
   AlphaChrs:   set of char = ['a'..'z', 'A'..'Z'];
   NumChrs:     set of char = ['0'..'9'];
   WhiteChrs:   set of char = [ ' ', TabChr, LFchr, CRchr];
   QuoteChrs:   set of char = ['''', '"' ];
   SymbolChrs:  set of char = [char( 33)..char( 47), char( 58)..char( 64),
                               char( 91)..char( 96), char( 123)..char( 126)];
   CtlChrs:     set of char = [char(0)..char(32),char(127)];


// ************************************************************************
// * tChrSource class - Provides tools to get and unget characters from
// *                    some text source.
// ************************************************************************
type
   tChrSource = class( tObject)
      private
         GetQ:           tCharList;
         UngetQ:         tCharList;
         ChrBuff:        array[ 0..(ParserBufferSize - 1)] of char;
         ChrBuffLen:     longint;
         ChrBuffPos:     longint;
         Stream:         tStream;
         DestroyStream:  boolean;
      public
         constructor Create( iStream: tStream; iDestroyStream: boolean = true);
         constructor Create( iString: string);
         constructor Create( var iFile:   text);
         destructor  Destroy(); override;
      private
         procedure Init();
      public
         function  GetChr(): char;
         procedure UngetChr( C: char);
         property  Chr: char read GetChr write UngetChr;
      end; // tChrSource class


// ************************************************************************
// * tParseElement()
// ************************************************************************

type
   tParseElement = interface
      function  Parse( CS: tChrSource): string;
   end; // tParseElement interface


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
      Init();
   end; // Create()

// -------------------------------------------------------------------------

constructor tChrSource.Create( iString: string );
   begin
      inherited Create();
      Stream:= tStringStream.Create( iString);
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
       GetQ.Destroy;
       UngetQ.Destroy;
       inherited Destroy();
   end; // Destroy()


// *************************************************************************
// * Init() - internal function to initialize variables.  Called by Create()
// *************************************************************************

procedure tChrSource.Init();
   begin
      GetQ:= tCharList.Create( 4, 'GetQ');
      UngetQ:= tCharList.Create( 4, 'UngetQ');

      ChrBuffLen:= Stream.Read( ChrBuff, ParserBufferSize);
      ChrBuffPos:= 0;
      while( (ChrBuffPos < ChrBuffLen) and not GetQ.IsFull) do begin
         GetQ.Queue:= ChrBuff[ ChrBuffPos];
         inc( ChrBuffPos);
      end;
   end; // Init()


// *************************************************************************
// * GetChr() - Returns the next char in the stream
// *************************************************************************

function tChrSource.GetChr(): char;
   begin
      result:= EOFchr;
      if( not UngetQ.IsEmpty()) then begin
         result:= UngetQ.Queue;
      end else begin
         if( not GetQ.IsEmpty()) then begin
            result:= GetQ.Queue;
         end;

         // Refill the queue from the buffer
         while( (ChrBuffPos < ChrBuffLen) and not GetQ.IsFull) do begin
            GetQ.Queue:= ChrBuff[ ChrBuffPos];
            inc( ChrBuffPos);
            if( ChrBuffPos = ChrBufFLen) then begin
               ChrBuffLen:= Stream.Read( ChrBuff, ParserBufferSize);
               ChrBuffPos:= 0;
            end;
         end;
      end; 
   end;


// *************************************************************************
// * UngetChr() - inserts the passed character into the stream
// *************************************************************************

procedure tChrSource.UngetChr( C: char);
   begin
      UngetQ.Queue:= C;
   end; // UngetChr()


// *************************************************************************

end.  // lbp_parse_helper unit
