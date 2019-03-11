{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

test lbp_parse_helper

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

program test_parse_helper;

{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   lbp_types,
   lbp_input_file,
   lbp_parse_helper;

// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      InsertUsage( 'test_parse_helper is a simple test for my lbp_parse_helper unit.');
      InsertUsage( '');

      SetInputFileParam( false, true, false);
      ParseParams;
   end;  // InitArgvParser()


// ************************************************************************
// *  TestStreamParser()
// ************************************************************************

procedure TestStreamParser();
   var
      P: tChrSource;
      C: char;
   begin
      P:= tChrSource.Create( InputStream, false);
      writeln();
      writeln( '------------ Test Stream Parser ------------');

      C:= P.GetChr();
      while( C <> EOFchr) do begin
         write( C);
         C:= P.GetChr();
      end;

      writeln();
      P.Destroy;
   end; // TestStreamParser();


// ************************************************************************
// *  TestStringParser()
// ************************************************************************

procedure TestStringParser();
   var
      S:  string;
      CS: tChrSource;
      C:  char;
   begin
      S:= 'This () tests parsing from a multi line string.' + System.LineEnding +
          'This is the second line.' + System.LineEnding + 
          'And this is the third line.' + System.LineEnding;

      P:= tChrSource.Create( S);
      writeln();
      writeln( '------------ Test String Parser ------------');

      C:= P.GetChr();
      while( C <> EOFchr) do begin
         inc( Count);
         if( Count = 6) then begin
            P.UngetChr( 'X');
            P.UngetChr( 'Y');
            P.UngetChr( 'Z');
         end;
         write( C);
         C:= P.GetChr();
      end;

      writeln();
      P.Destroy;
   end; // TestStreamParser();


// ************************************************************************
// *  TestFileParser()
// ************************************************************************

procedure TestFileParser();
   var
      P: tChrSource;
      C: char;
   begin
      P:= tChrSource.Create( InputFile);
      writeln();
      writeln( '------------ Test File Parser ------------');

      C:= P.GetChr();
      while( C <> EOFchr) do begin
         write( C);
         C:= P.GetChr();
      end;

      writeln();
      P.Destroy;
   end; // TestFileParser();


// ************************************************************************
// * main()
// ************************************************************************
var
   AllowedChrs: set of char;
begin
   InitArgvParser();
//   TestStreamParser();
   TestStringParser();
//   TestFileParser(); 
end. // test_parse_helper
