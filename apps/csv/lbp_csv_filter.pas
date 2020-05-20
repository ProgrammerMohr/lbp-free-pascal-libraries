{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Defines Filters to modify CSV files

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
unit lbp_csv_filter;

// Classes to handle Comma Separated Value strings and files.

interface

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}

uses
   lbp_argv,
   lbp_types,
   lbp_generic_containers,
   lbp_parse_helper,
   lbp_csv,
   classes;


// *************************************************************************

type
   tCsvFilter = class( tObject)
      protected
         NextFilter:    tCsvFilter;
         MyInputHeader: tCsvStringArray;
         procedure Go(); virtual;
      public
         procedure SetInputHeader( Header: tCsvStringArray); virtual;
         procedure SetRow( Row: tCsvStringArray); virtual;
      end; // tCsvFilter
      

// *************************************************************************

type
   tCsvFilterQueueParent = specialize tgDoubleLinkedList< tCsvFilter>;
   tCsvFilterQueue = class( tCsvFilterQueueParent)
      public
         procedure Go(); virtual;
      end; // tCsvFilterQueue
      

// *************************************************************************

type
   tCsvInputFileFilter = class( tCsvFilter)
      protected
         Csv: tCsv;
         procedure Go(); override;
      public
         constructor Create( iStream: tStream; iDestroyStream: boolean = true);
         constructor Create( iString: string; IsFileName: boolean = false);
         constructor Create( var iFile:   text);
         procedure SetInputDelimiter( iD: char);
         procedure SetSkipNonPrintable( Skip: boolean);
      end; // tCsvInputFileFilter


// *************************************************************************

type
   tCsvOutputFileFilter = class( tCsvFilter)
      protected
         CloseOnDestroy:  boolean;
         OutputFile:      Text;
         OutputDelimiter: char;
      public
         constructor Create( iFileName: string);
         constructor Create( var iFile:   text);
         destructor  Destroy(); override;
         procedure   SetInputHeader( Header: tCsvStringArray); override;
         procedure   SetRow( Row: tCsvStringArray); override;
         procedure   SetOutputDelimiter( oD: char);
      end; // tCsvOutputFileFilter


// *************************************************************************

implementation

// ========================================================================
// = tCsvFilter class
// ========================================================================
// *************************************************************************
// * SetInputHeader() - 
// *************************************************************************

procedure tCsvFilter.SetInputHeader( Header: tCsvStringArray);
   begin
      MyInputHeader:= Header;
   end; // SetInputHeader


// *************************************************************************
// * SetRow() - Children should override this as needed.  But they should
// *            never tCsvFilter's version should never be called with 
// *            via inherited SetRow().
// *************************************************************************

procedure tCsvFilter.SetRow( Row: tCsvStringArray);
   begin
      raise tCsvException.Create( 'tCsvFilter.SetRow() should never be called by child classes!  Do not use inherited SetRow()!')
   end; // SetRow()


// *************************************************************************
// * Go() - For the input filter only, Go reads the input and calls 
// *        the next filter's SetInputHeader() once and SetRow() for each row. 
// *************************************************************************

procedure tCsvFilter.Go();
   begin
      raise tCsvException.Create( 'tCsvFilter.Go() should only be implemented and called for the first class in the filter which starts to process going!  Do not use inherited Go()!')
   end; // Go()



// ========================================================================
// = tCsvFilterQueue class
// ========================================================================
// *************************************************************************
// * Go() - Start the filter.  As a side effect it cleans up all contained 
// *        tCsvFilters and empties itself.        
// *************************************************************************

procedure tCsvFilterQueue.Go();
   var
      PrevFilter:  tCsvFilter;
      Filter:      tCsvFilter;
   begin
      if( Self.Length < 2) then raise tCsvException.Create( 'tCsvFilterQueue.Go() - At least an input and output filter must be in the queue!');
      // Set each filter's NextFilter
      PrevFilter:= nil;
      for Filter in self do begin
         if( PrevFilter <> nil) then PrevFilter.NextFilter:= Filter;        
         PrevFilter:= Filter;
         writeln( 'tCsvFilterQueue.Go():  Filter class name = ', PrevFilter.ClassName);
      end;
      PrevFilter.NextFilter:= nil;  // The last filter has no nextfilter
      writeln( 'tCsvFilterQueue.Go():  Filter class name = ', PrevFilter.ClassName);
      writeln( PrevFilter.ClassName);
      
      // Process the rows
      Filter:= Queue;
      Filter.Go(); // Only the input filter should have a working go function

      // Clean up after ourselves
      Filter.Destroy;
      while( not IsEmpty()) do begin
         Filter:= Queue;
         Filter.Destroy;
      end; 
   end; // Go



// ========================================================================
// = tCsvInputFileFilter class
// ========================================================================
// *************************************************************************
// * Go() - Performs the actual CSV reading and sends the header and rows
// *        to the next filter
// *************************************************************************

procedure tCsvInputFileFilter.Go();
   var
      Temp:  tCsvStringArray;
      C:     char;
   begin
      NextFilter.SetInputHeader( Csv.Header);
      repeat
         Temp:= Csv.ParseLine();
         NextFilter.SetRow( Temp);
         C:= Csv.PeekChr();
      until( C = EOFchr);
   end; // Go()


// *************************************************************************
// * Create() - constructors
// *************************************************************************

constructor tCsvInputFileFilter.Create( iStream: tStream; iDestroyStream: boolean);
   begin
      inherited Create();
      Csv:= tCsv.Create( iStream, iDestroyStream);
   end; // Create()

// -------------------------------------------------------------------------

constructor tCsvInputFileFilter.Create( iString: string; IsFileName: boolean);
   begin
      inherited Create();
      Csv:= tCsv.Create( iString, IsFileName);
   end; // Create()


// -------------------------------------------------------------------------

constructor tCsvInputFileFilter.Create( var iFile: text);
   begin
      inherited Create();
      Csv:= tCsv.Create( iFile);
   end; // Create()


// *************************************************************************
// * SetInputDelimiter() - Sets the delimiter for use in the input CSV
// *************************************************************************

procedure tCsvInputFileFilter.SetInputDelimiter( iD: char);
   begin
      Csv.Delimiter:= iD;
   end; // SetInputDelimiter()


// *************************************************************************
// * SetInputDelimiter() - Sets the delimiter for use in the input CSV
// *************************************************************************

procedure tCsvInputFileFilter.SetSkipNonPrintable( Skip: boolean);
   begin
      Csv.SkipNonPrintable:= Skip;
   end; // SetSkipNonPrintable()



// ========================================================================
// = tCsvOutputFileFilter class
// ========================================================================
// *************************************************************************
// * Create() - constructors
// *************************************************************************

constructor tCsvOutputFileFilter.Create( iFileName: string);
   begin
      inherited Create();
      CloseOnDestroy:= true;
      OutputDelimiter:= lbp_csv.CsvDelimiter;
      Assign( OutputFile, iFileName);
      Rewrite( OutputFile);
   end; // Create()


// -------------------------------------------------------------------------

constructor tCsvOutputFileFilter.Create( var iFile: text);
   begin
      inherited Create();
      CloseOnDestroy:= false;
      OutputDelimiter:= lbp_csv.CsvDelimiter;
      OutputFile:= iFile;
   end; // Create()


// *************************************************************************
// * Destroy() - destructor
// *************************************************************************

destructor tCsvOutputFileFilter.Destroy();
   begin
      if( CloseOnDestroy) then Close( OutputFile);
      inherited Destroy();
   end; // Destroy


// *************************************************************************
// * SetInputHeader() - Simply output the header
// *************************************************************************

procedure tCsvOutputFileFilter.SetInputHeader( Header: tCsvStringArray);
   begin
      writeln( OutputFile, Header.ToLine);
   end; // SetInputHeader()


// *************************************************************************
// * SetRow() - Simply output the header
// *************************************************************************

procedure tCsvOutputFileFilter.SetRow( Row: tCsvStringArray);
   begin
      writeln( OutputFile, Row.ToLine);
   end; // SetRow()


// *************************************************************************
// * SetOutputDelimiter() - Sets the delimiter for use in the output CSV
// *************************************************************************

procedure tCsvOutputFileFilter.SetOutputDelimiter( oD: char);
   begin
      OutputDelimiter:= oD;
   end; // SetOuputDelimiter()



// *************************************************************************

end. // lbp_csv_filter unit
