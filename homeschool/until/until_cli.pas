{* ***************************************************************************

    Copyright (c) 2020 by Lloyd B. Park

    until_cli is a simple program to print out the Days, hours, minutes, and 
    seconds until some event's date and time.

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

program until_cli;

{$include lbp_standard_modes.inc}

uses
   lbp_current_time,
   dateutils;

var
   EventTime: tlbpTimeClass;
   Days:         int64;
   Hours:        int64;
   Minutes:      int64;
   Seconds:      Int64;
   SecondsInDay: int64 = (24 * 60 * 60);

// ************************************************************************
// * main()
// ************************************************************************


// ************************************************************************

begin
   EventTime:= tlbpTimeClass.Create( ParamStr( 1));
   Seconds:= SecondsBetween( EventTime.TimeOfDay, CurrentTime.TimeOfDay);
   Days:= Seconds div SecondsInDay;
   Seconds:= Seconds mod SecondsInDay;
   Hours:=   Seconds div 3600;
   Seconds:= Seconds mod 3600;
   Minutes:= Seconds div 60;
   Seconds:= Seconds mod 60;

   writeln;
   writeln( Days, ' ', Hours, ':', Minutes, ':', Seconds);
   writeln;

   EventTime.Destroy;
end. // until_cli
