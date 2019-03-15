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
   lbp_csv2,
   lbp_parse_helper;

// ************************************************************************


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
      S:      string;
      CS:     tChrSource;
      C:      char;
      Count:  integer = 0;
   begin
      S:= 'This () tests parsing from a multi line string.' + System.LineEnding +
          'This is the second line.' + System.LineEnding + 
          'And this is the third line.' + System.LineEnding;

      CS:= tChrSource.Create( S);
      writeln();
      writeln( '------------ Test String Parser ------------');

      C:= CS.GetChr();
      while( C <> EOFchr) do begin
         inc( Count);
         if( Count = 6) then begin
            CS.UngetChr( 'X');
            CS.UngetChr( 'Y');
            CS.UngetChr( 'Z');
         end;
         write( C);
         C:= CS.GetChr();
      end;

      writeln();
      CS.Destroy;
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
   end; // TestFileParser()

// ************************************************************************
// * ReadCsv();
// ************************************************************************

procedure ReadCsv();
   var
      FileName: string = '/Users/lpark/Desktop/Managed Accounts List of EC2 Instances 03-06-2019 09_52_14_2019-03-07-13-39-44.csv';
      CsvFile:  text;
      Csv:      tCsv;
      CA:       tCsvStringArray;
      i:        integer;
      iMax:     integer;
   begin
      assign( CsvFile, FileName);
      reset( CsvFile);
      Csv:= tCsv.Create( CsvFile);
      
      CA:= Csv.ParseLine;
      iMax:= Length( CA) - 1;
      for i:= 0 to iMax do writeln( i, ' - ', CA[ i]);

      Csv.Destroy();
      Close( CsvFile);
   end; // ReadCsv()


// ************************************************************************
// * ReadCsv2();
// ************************************************************************

procedure ReadCsv2();
   var
      FileName: string = '/Users/lpark/Desktop/Managed Accounts List of EC2 Instances 03-06-2019 09_52_14_2019-03-07-13-39-44.csv';
      CsvFile:  text;
      Csv:      tCsv;
      LA:       tCsvLineArray;
      i:        integer;
      iMax:     integer;
   begin
      assign( CsvFile, FileName);
      reset( CsvFile);
      Csv:= tCsv.Create( CsvFile);
      
      LA:= Csv.Parse;
      iMax:= Length( LA) - 1;
      for i:= 0 to iMax do writeln( i, ' - ', LA[ i][ 55]);

      Csv.Destroy();
      Close( CsvFile);
   end; // ReadCsv2()


// ************************************************************************
// * ReadCsv3();
// ************************************************************************

procedure ReadCsv3();
   var
      CsvStr:   string = ' 1st unquoted String ,  ' +
                         '''1st quoted string''  ,' +
                         '''2nd quoted string with two lines' + LFchr +
                         '    second line of the 2nd quoted string. '',' +
                         '2nd  unquoted string, The next 3 cells are empty,   ,,';
      Csv:      tCsv;
      CA:       tCsvStringArray;
      i:        integer;
      iMax:     integer;
   begin
      Csv:= tCsv.Create( CsvStr);
      
      CA:= Csv.ParseLine;
      writeln( Ord(Csv.PeekChr()));
      iMax:= Length( CA) - 1;
      for i:= 0 to iMax do writeln( i, ' - ', CA[ i]);
      
      Csv.Destroy();
   end; // ReadCsv2()


// ************************************************************************
// * main()
// ************************************************************************

begin
   InitArgvParser();
//   TestStreamParser();
//   TestStringParser();
//   TestFileParser(); 

   ReadCsv2();
end. // test_parse_helper
