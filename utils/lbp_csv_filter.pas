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
   lbp_csv_filter_aux,
   lbp_parse_helper,
   lbp_csv,
   regexpr,  // Regular expressions
   classes,
   sysutils;


// *************************************************************************

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
         IndexMap:   tIntegerArray;
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
// * tCsvRenameFilter class - Rename the passed iInputFields to iOutputFields.
// *    Row data in unchanged. 
// *************************************************************************

type
   tCsvRenameFilter = class( tCsvFilter)
      protected
         InputFields:   tCsvCellArray;
         OutputFields:  tCsvCellArray;
         HeaderSent:    boolean;
      public
         Constructor Create( iInputFields, iOutputFields: tCsvCellArray);
         constructor Create( iInputFields, iOutputFields: string);
         procedure   SetInputHeader( Header: tCsvCellArray); override;
      end; // tCsvRenameFilter


// *************************************************************************
// tCsvGrepFilter class - Use regular expressions to seach through fields
// *************************************************************************

type
   tCsvGrepFilter = class( tCsvFilter)
      protected
         GrepFields:   tCsvCellArray;
         GrepIndexes:  tIntegerArray;
         RegExpr:      tRegExpr;
         InvertMatch:  boolean;
      public
         Constructor Create( iGrepFields:  tCsvCellArray;
                             iRegExpr:     string;
                             iInvertMatch: boolean = false;
                             iIgnoreCase:  boolean = false);
         Constructor Create( iGrepFields:  string;
                             iRegExpr:     string;
                             iInvertMatch: boolean = false;
                             iIgnoreCase:  boolean = false);
         Destructor  Destroy(); override;
         procedure   SetInputHeader( Header: tCsvCellArray); override;
         procedure   SetRow( Row: tCsvCellArray); override;
      end; // tCsvGrepFilter


// *************************************************************************

implementation

// ========================================================================
// * Global procedures
// ========================================================================
// *************************************************************************
// * StringToCsvCellArray() - Converts the passed string to a tCsvCellArray
// *************************************************************************

function StringToCsvCellArray( S: string): tCsvCellArray;
   var
      Csv: tCsv;
   begin
      // convert iNewHeader to a tCsvCellArray
      Csv:= tCsv.Create( S);
      Csv.Delimiter:= ',';
      Csv.SkipNonPrintable:= true;
      result:=  Csv.ParseRow();
      Csv.Destroy;
   end; // StringToCsvCellArray()



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

      // This is a fix for the case of StdOut.  For some reason even though
      // The file handle is correct, if we use iFile it will print to stdout, 
      // but doesn't work with pipes.  This method fixes it.
      if( TextRec( iFile).Handle = 1) then begin
         OutputFile:= System.Output;
      end else begin
         OutputFile:= iFile;
      end;
//      OutputFile:= iFile;
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
      writeln( Output, Header.ToCsv(OutputDelimiter));
   end; // SetInputHeader()


// *************************************************************************
// * SetRow() - Simply output the header
// *************************************************************************

procedure tCsvOutputFileFilter.SetRow( Row: tCsvCellArray);
   begin
     writeln( Output, Row.ToCsv( OutputDelimiter));
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
   begin
      inherited Create();
      NewHeader:=  StringToCsvCellArray( iNewHeader);
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
      HeaderDict: tHeaderDict;
      Name:       string;
      i:          integer;
      iMax:       integer;
      ErrorMsg:   string;
   begin
      // Create and populate the temorary lookup tree
      HeaderDict:= tHeaderDict.Create( tHeaderDict.tCompareFunction( @CompareStrings));
      HeaderDict.AllowDuplicates:= false;
      iMax:= Length( Header) - 1;
      for i:= 0 to iMax do HeaderDict.Add( Header[ i], i);

      // Create and populate the IndexMap;
      iMax:= NewLength - 1;
      SetLength( IndexMap, NewLength);
      for i:= 0 to iMax do begin
         Name:= NewHeader[ i];
         // Is the new header field in the old headers?
         if( HeaderDict.Find( Name)) then begin
            IndexMap[ i]:= HeaderDict.Value();
         end else begin
            if( AllowNew) then begin
               IndexMap[ i]:= -1; 
            end else begin
               ErrorMsg:= sysutils.Format( HeaderUnknownField, [Name]);
               lbp_argv.Usage( true, ErrorMsg);
            end;
         end; // if/else New Header field was found in the on header 
      end; // for

      // Clean up the HeaderDict
      HeaderDict.RemoveAll();
      HeaderDict.Destroy();
 
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



// ========================================================================
// = tCsvRenameFilter class
// ========================================================================
var
   RenameLengthMismatchError: string =
   'The number of input and output fields must be the same!';
// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor tCsvRenameFilter.Create( iInputFields, iOutputFields: tCsvCellArray); 
   begin
      inherited Create();
      InputFields:=  iInputFields;
      OutputFields:= iOutputFields;
      if( Length( InputFields) <> Length( OutputFields)) then begin
         lbp_argv.Usage( true, RenameLengthMismatchError);
      end;
      HeaderSent:= false;
   end; // Create()

// -------------------------------------------------------------------------

constructor tCsvRenameFilter.Create( iInputFields, iOutputFields: string);
   begin
      inherited Create();
      InputFields:=  StringToCsvCellArray( iInputFields);
      OutputFields:= StringToCsvCellArray( iOutputFields);      
      if( Length( InputFields) <> Length( OutputFields)) then begin
         lbp_argv.Usage( true, RenameLengthMismatchError);
      end;
      HeaderSent:= false;
   end; // Create()


// *************************************************************************
// * SetInputHeader() - Simply output the header
// *************************************************************************

procedure tCsvRenameFilter.SetInputHeader( Header: tCsvCellArray);
   var
      i:     integer;
      HI:    integer; // Header index
      HIMax: integer;
      FI:    integer; // Field index
      FIMax: integer;
      Found: boolean;
   begin
      HIMax:= Length( Header) - 1;
      FIMax:= length( InputFields) - 1;

      // For each Input field;
      for FI:= 0 to FIMax do begin
         // Find the Header Index
         HI:= 0;
         i:= 0;
         Found:= false;
         while( (not Found) and (i <= HIMax)) do begin
            if( Header[ i] = InputFields[ FI]) then begin
               Found:= true;
               HI:= i;
            end; // if
            inc( i);
         end; // While searching for the matching header field
         if( not Found) then lbp_argv.Usage( true, HeaderUnknownField);
         
         Header[ HI]:= OutputFields[ FI];
      end; // For each InputField

      // Pass the new header to the next filter
      if( not HeaderSent) then begin
         NextFilter.SetInputHeader( Header);
         HeaderSent:= true;
      end;
   end; // SetInputHeader()



// ========================================================================
// = tCsvGrepFilter class
// ========================================================================
// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor tCsvGrepFilter.Create( iGrepFields:  tCsvCellArray; 
                                   iRegExpr:     string;
                                   iInvertMatch: boolean = false;
                                   iIgnoreCase:  boolean = false);
   begin
      inherited Create();
      GrepFields:=        iGrepFields;
      InvertMatch:=       iInvertMatch;
      RegExpr:=           tRegExpr.Create( iRegExpr);
      RegExpr.ModifierI:= iIgnoreCase;
      RegExpr.ModifierM:= true; // start and end line works for each line in a multi-line field
   end; // Create()

// -------------------------------------------------------------------------

constructor tCsvGrepFilter.Create( iGrepFields:  string; 
                                   iRegExpr:     string;
                                   iInvertMatch: boolean = false;
                                   iIgnoreCase:  boolean = false);
   begin
      inherited Create();
      GrepFields:=        StringToCsvCellArray( iGrepFields);
      InvertMatch:=       iInvertMatch;
      RegExpr:=           tRegExpr.Create( iRegExpr);
      RegExpr.ModifierI:= iIgnoreCase;
      RegExpr.ModifierM:= true; // start and end line works for each line in a multi-line field
   end; // Create()


// *************************************************************************
// * Destroy() - destructor
// *************************************************************************

destructor tCsvGrepFilter.Destroy();
   begin
      RegExpr.Destroy();
      inherited Destroy;
   end; // Destroy()


// *************************************************************************
// * SetInputHeader()
// *************************************************************************

procedure tCsvGrepFilter.SetInputHeader( Header: tCsvCellArray);
   var 
      HL:       integer; // Header Length
      GFL:      integer; // Grep fields Length;
      HI:       integer; // Header index
      GFI:      integer; // Grep fields index;
      Found:    boolean;
      ErrorMsg: string;
   begin
      // If an empty GrepFields was passed to Create(), then we use all the fields
      HL:=  Length( Header);
      GFL:= Length( GrepFields);
      if( GFL = 0) then begin
         GFL:= HL;
         GrepFields:= Header;
      end;
      SetLength( GrepIndexes, GFL);
      
      // For each Grep Field
      GFI:= 0;
      while( GFI < GFL) do begin
         HI:= 0;
         Found:= false;
  
         // for each Header
         while( (not found) and (HI < HL)) do begin
            if( Header[ HI] = GrepFields[ GFI]) then begin
               Found:= true;
               GrepIndexes[ GFI]:= HI;
            end;
            inc( HI);
         end; // while Header
  
         if( Found) then begin
            
         end else begin
            ErrorMsg:= Format( HeaderUnknownField, [GrepFields[ GFI]]);
            lbp_argv.Usage( true, ErrorMsg);
         end;

         inc( GFI);  
      end; // while GrepFields

      NextFilter.SetInputHeader( Header);
   end; // SetInputHeader


// *************************************************************************
// * SetRow() - Only pass rows that match the regexpr pattern
// *************************************************************************

procedure tCsvGrepFilter.SetRow( Row: tCsvCellArray);
   var
      Found: boolean = false;
      i:     integer;
   begin
      for i in GrepIndexes do begin
         if( RegExpr.Exec( Row[ i])) then Found:= true;
      end;

      if( Found xor InvertMatch) then NextFilter.SetRow( Row);
   end; // SetRow()



// *************************************************************************

end. // lbp_csv_filter unit
