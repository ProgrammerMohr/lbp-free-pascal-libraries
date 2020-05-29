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
   classes,
   sysutils;


// ***************************************************************s**********

type
   tHeaderTree = specialize tgDictionary<string, integer>;
   tStringTree = specialize tgAvlTree< string>;


// ***************************************************************s**********

type
   tCsvFilter = class( tObject)
      protected
         NextFilter:    tCsvFilter;
         procedure Go(); virtual;
      public
         procedure SetInputHeader( Header: tCsvCellArray); virtual;
         procedure SetRow( Row: tCsvCellArray); virtual;
      end; // tCsvFilter
      

// *************************************************************************

type
   tCsvFilterQueueParent = specialize tgDoubleLinkedList< tCsvFilter>;
   tCsvFilterQueue = class( tCsvFilterQueueParent)
      public
         Destructor  Destroy(); override;
         procedure   Go(); virtual;
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
         destructor  Destroy(); override;
         procedure   SetInputDelimiter( iD: char);
         procedure   SetSkipNonPrintable( Skip: boolean);
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
         procedure   SetInputHeader( Header: tCsvCellArray); override;
         procedure   SetRow( Row: tCsvCellArray); override;
         procedure   SetOutputDelimiter( oD: char);
      end; // tCsvOutputFileFilter


// *************************************************************************
// * tCsvReorderFilter class - Specify a new header with fields in whatever
// *    order you desire.  New fields are added to rows with empty values.
// *    For complex situations where multiple different csv's with slightly
// *    different input headers are being combined, this filter will allow 
// *    multiple calls to SetInputHeader, but will only NewHeader to the 
// *    next filter once. 
// *************************************************************************

type
   tCsvReorderFilter = class( tCsvFilter)
      protected
         HeaderSent: boolean;
         NewHeader:  tCsvCellArray;
         AllowNew:   boolean; // Allow new blank columns
         IndexMap:   array of integer;
         NewLength:  integer;
      public
         Constructor Create( iNewHeader: tCsvCellArray; iAllowNew: boolean);
         constructor Create( iNewHeader: string; iAllowNew: boolean);
         procedure   SetInputHeader( Header: tCsvCellArray); override;
         procedure   SetRow( Row: tCsvCellArray); override;
      end; // tCsvReorderFilter


// *************************************************************************
// * tCsvUniqueFilter class - Only output's unique rows.  All unique rows
// * are stored in memory.  Be careful with large files!
// *************************************************************************

type
   tCsvUniqueFilter = class( tCsvFilter)
      protected
         UniqueTree: tStringTree;
      public
         constructor Create();
         destructor  Destroy(); override;
         procedure   SetRow( Row: tCsvCellArray); override;
      end; // tCsvUniqueFilter


// *************************************************************************
// * Global variables
// *************************************************************************

var
   HeaderZeroLengthError: string = 'The passed header can not be empty!';
   HeaderUnknownField: string = '''%s'' is not a field in the input header!';

// *************************************************************************

implementation

// *************************************************************************

// ========================================================================
// = tCsvFilter class
// ========================================================================
// *************************************************************************
// * SetInputHeader() - The default is just to pass the header through to
// *    the next filter.  If the child modified the header, it should 
// *    override this procedure and NOT call the inherited version.  It 
// *    should then pass the new/modified header to NextFilter
// *************************************************************************

procedure tCsvFilter.SetInputHeader( Header: tCsvCellArray);
   begin
      NextFilter.SetInputHeader( Header);
   end; // SetInputHeader


// *************************************************************************
// * SetRow() - The default is just to pass the row through to
// *    the next filter.  If the child modified the row, it should 
// *    override this procedure and NOT call the inherited version.  It 
// *    should then pass the new/modified row to NextFilter
// *************************************************************************

procedure tCsvFilter.SetRow( Row: tCsvCellArray);
   begin
      NextFilter.SetRow( Row);
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
// * Destroy() - Destructor
// *************************************************************************

destructor tCsvFilterQueue.Destroy();
   var
      Filter: tCsvFilter;
   begin
      while( not IsEmpty) do begin
         Filter:= Queue;
         Filter.Destroy();
      end;
      inherited Destroy();
   end; // Destroy()


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
//         writeln( 'tCsvFilterQueue.Go():  Filter class name = ', PrevFilter.ClassName);
      end;
      PrevFilter.NextFilter:= nil;  // The last filter has no nextfilter
      
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
// * Destroy() - destructor
// *************************************************************************

destructor tCsvInputFileFilter.Destroy();
   begin
      Csv.Destroy();
      inherited Destroy();
   end; // Destroy()


// *************************************************************************
// * Go() - Performs the actual CSV reading and sends the header and rows
// *        to the next filter
// *************************************************************************

procedure tCsvInputFileFilter.Go();
   var
      Temp:  tCsvCellArray;
      C:     char;
   begin
      Csv.ParseHeader();
      NextFilter.SetInputHeader( Csv.Header);
      repeat
         Temp:= Csv.ParseRow();
         if( Length( Temp) > 0) then NextFilter.SetRow( Temp);
         C:= Csv.PeekChr();
      until( C = EOFchr);
   end; // Go()


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

procedure tCsvOutputFileFilter.SetInputHeader( Header: tCsvCellArray);
   begin
      writeln( OutputFile, Header.ToCsv(OutputDelimiter));
   end; // SetInputHeader()


// *************************************************************************
// * SetRow() - Simply output the header
// *************************************************************************

procedure tCsvOutputFileFilter.SetRow( Row: tCsvCellArray);
   begin
     writeln( OutputFile, Row.ToCsv( OutputDelimiter));
   end; // SetRow()


// *************************************************************************
// * SetOutputDelimiter() - Sets the delimiter for use in the output CSV
// *************************************************************************

procedure tCsvOutputFileFilter.SetOutputDelimiter( oD: char);
   begin
      OutputDelimiter:= oD;
   end; // SetOuputDelimiter()



// ========================================================================
// = tCsvReorderFilter class
// ========================================================================
// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor tCsvReorderFilter.Create( iNewHeader: tCsvCellArray; 
                                      iAllowNew: boolean);
   begin
      inherited Create();
      NewHeader:=  iNewHeader;
      NewLength:=  Length( NewHeader);
      AllowNew:=   iAllowNew;
      HeaderSent:= false;
      if( NewLength = 0) then lbp_argv.Usage( true, HeaderZeroLengthError);
   end; // Create()

// -------------------------------------------------------------------------

constructor tCsvReorderFilter.Create( iNewHeader: string; iAllowNew: boolean);
   var
      Csv: tCsv;
   begin
      inherited Create();

      // convert iNewHeader to a tCsvCellArray
      Csv:= tCsv.Create( iNewHeader);
      Csv.Delimiter:= ',';
      Csv.SkipNonPrintable:= true;
      NewHeader:=  Csv.ParseRow();
      Csv.Destroy;
      NewLength:=  Length( NewHeader);
      AllowNew:=   iAllowNew;
      HeaderSent:= false;
      if( NewLength = 0) then lbp_argv.Usage( true, HeaderZeroLengthError);
   end; // Create()


// *************************************************************************
// * SetInputHeader() - Simply output the header
// *************************************************************************

procedure tCsvReorderFilter.SetInputHeader( Header: tCsvCellArray);
   var
      HeaderTree: tHeaderTree;
      Name:       string;
      i:          integer;
      iMax:       integer;
      ErrorMsg:   string;
   begin
      // Create and populate the temorary lookup tree
      HeaderTree:= tHeaderTree.Create( tHeaderTree.tCompareFunction( @CompareStrings));
      HeaderTree.AllowDuplicates:= false;
      iMax:= Length( Header) - 1;
      for i:= 0 to iMax do HeaderTree.Add( Header[ i], i);

      // Create and populate the IndexMap;
      iMax:= NewLength - 1;
      SetLength( IndexMap, NewLength);
      for i:= 0 to iMax do begin
         Name:= NewHeader[ i];
         // Is the new header field in the old headers?
         if( HeaderTree.Find( Name)) then begin
            IndexMap[ i]:= HeaderTree.Value();
         end else begin
            if( AllowNew) then begin
               IndexMap[ i]:= -1; 
            end else begin
               ErrorMsg:= sysutils.Format( HeaderUnknownField, [Name]);
               lbp_argv.Usage( true, ErrorMsg);
            end;
         end; // if/else New Header field was found in the on header 
      end; // for

      // Clean up the HeaderTree
      HeaderTree.RemoveAll();
      HeaderTree.Destroy();
 
      // Pass the new header to the next filter
      if( not HeaderSent) then begin
         NextFilter.SetInputHeader( NewHeader);
         HeaderSent:= true;
      end;
   end; // SetInputHeader()


// *************************************************************************
// * SetRow() - Simply output the header
// *************************************************************************

procedure tCsvReorderFilter.SetRow( Row: tCsvCellArray);
   var
      NewRow: tCsvCellArray;
      iMax:   integer;
      iOld:   integer;
      iNew:   integer;
   begin
      SetLength( NewRow, NewLength);
      // Trasfer fields from Row to NewRow;
      iMax:= NewLength - 1;
      for iNew:= 0 to iMax do begin
         iOld:= IndexMap[ iNew];
         if( iOld < 0) then NewRow[ iNew]:= '' else NewRow[ iNew]:= Row[ iOld];
      end;
      NextFilter.SetRow( NewRow);
   end; // SetRow()



// ========================================================================
// = tCsvUniqueFilter class
// ========================================================================
// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor tCsvUniqueFilter.Create();
   begin
      inherited Create();
      UniqueTree:= tStringTree.Create( tStringTree.tCompareFunction( @CompareStrings));
   end; // Create()


// *************************************************************************
// * Destroy() - destructor
// *************************************************************************

destructor tCsvUniqueFilter.Destroy();
   begin
      UniqueTree.RemoveAll;
      UniqueTree.Destroy;
      inherited Destroy;
   end; // Destroy()

// *************************************************************************
// * SetRow()
// *************************************************************************

procedure tCsvUniqueFilter.SetRow( Row: tCsvCellArray);
   var
      RowStr: string;
   begin
      RowStr:= Row.ToCsv( ',');

      // If we haven't seen this row before     
      if( not UniqueTree.Find( RowStr)) then begin
         UniqueTree.Add( RowStr);
         NextFilter.SetRow( Row);
      end;
   end;  // SetRow()



// *************************************************************************

end. // lbp_csv_filter unit
