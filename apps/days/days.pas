{* ***************************************************************************

    Copyright (c) 2017 by Lloyd B. Park

    days - Simply prints the next two weeks dates in 'day-of-week, month day'
           format for my Growly Notes daily to-do lists

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

program days;

{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   lbp_types,
   lbp_current_time,
   dateutils,
   sysutils;


// ************************************************************************

var
   NumberOfDays: integer = 8;
   DowStr:       array[ 1..7] of string = ( 'Sunday', 'Monday', 'Tuesday',
                    'Wednesday', 'Thursday', 'Friday', 'Saturday');
   MonthStr:     array[ 1..12] of string = ( 'January', 'February', 'March',
                    'April', 'May', 'June', 'July', 'August', 'September',
                    'October', 'November', 'December');
   
   

// ***********************************************************************
// * ParseArgv() - check the validity of the command line
// ***********************************************************************

procedure ParseArgv();
   var
      L:    integer;
      N:    string;
      Code: integer;
   begin
      L:= Length( UnnamedParams);
      if( L > 1) then begin
         writeln; writeln;
         writeln( 'You entered too many parameters!');
         writeln; writeln;
         Usage( true);
      end else if( L = 1) then begin
         CurrentTime.Str:= UnnamedParams[ 0] + ' 00:00:00';
      end;

      if ParamSet( 'number-of-days') then begin
         N:= GetParam( 'number-of-days');
         Val( N, NumberOfDays, Code);
         if( Code <> 0) then begin
            raise Exception.Create( 'An invalid number of days was entered!');
         end;
         if( NumberOfDays < 1) then begin
            raise Exception.Create( 'The number of days must be equal to or greater than 1!');
         end;   
      end; 
   end; // ParseArgv();

   
// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      InsertUsage( '');
      InsertUsage( 'Usage:  days [-n days] [start date in YYYY-MM-DD format]');
      InsertUsage( '');
      InsertUsage( 'Simply prints the next two weeks of dates in ''day-of-week, month, day''');
      InsertUsage( '   format for my Growly Notes daily to-do lists');
      InsertUsage( '');
      InsertUsage( 'Options:');
      InsertUsage( '   Start date is optional.  Today''s date is used if none is specified.');
      InsertUsage( '');
      InsertParam( ['n', 'number-of-days'], true, '', 'The number of days to print.  Defaults to 8');
      AddPostParseProcedure( @ParseArgv);
      ParseParams();
   end; // InitArgvParser()


// ************************************************************************
// * PrintDays() - Print the dates to stdout 
// ************************************************************************

procedure PrintDays();
   var
      i:     integer;
      DT:    tDateTime;
      DOW:   string;
      Month: string;
   begin
      DT:= CurrentTime.TimeOfDay;
      for i:= 1 to NumberOfDays do begin
         DOW:=   DowStr[ DayOfWeek( DT)];
         Month:= MonthStr[ MonthOf( DT)];
         Writeln( DOW, ', ', Month, DayOf( DT));
         DT:= IncDay( DT);
      end; // for
   end; // PrintDays()


// ************************************************************************
// * main()
// ************************************************************************

begin
   InitArgvParser;
   writeln;
   PrintDays;
   writeln;
end.  // days

