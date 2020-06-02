{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

This is my workspace for building new CSV filters.  Its a little easier to
build them here in a small file rather than in the large lbp_csv_filter.pas
file.

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

unit csv_new_filter;

// This is a temporary location to hold new filters as they are being built
// and tested.

interface

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}

uses
   lbp_argv,
   lbp_types,
   lbp_generic_containers,
   lbp_csv_filter_aux,
   lbp_csv_filter,
   lbp_csv,
   sysutils;


// *************************************************************************
// * tCsvInt32SortFilter()
// *************************************************************************

type
   tCsvInt32SortFilter = class( tCsvFilter)
      protected type
         tRowTree = specialize tgAvlTree< tCsvInt32RowTuple>;
      protected
         FieldName:        string;
         FieldIndex:       integer;
         Reverse:          boolean; // output in reverse order
         RowTree:          tRowTree;
      public
         constructor Create( iField:           string; 
                             iReverse:         boolean = false);
         destructor  Destroy(); override;
         procedure   SetInputHeader( Header: tCsvCellArray); override;
         procedure   SetRow( Row: tCsvCellArray); override;
      end; // tCsvInt32SortFilter


// *************************************************************************

implementation

// ========================================================================
// = tCsvInt32SortFilter class
// ========================================================================
// *************************************************************************
// * CompareInt32RowTuple() - Global function to support sorting
// *************************************************************************

function CompareInt32RowTuple( T1, T2: tCsvInt32RowTuple): integer;
   begin
      if( T1.key > T2.key) then begin
         result:= 1;
      end else if( T1.key < T2.key) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareInt32RowTuple();


// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor tCsvInt32SortFilter.Create( iField:           string; 
                                         iReverse:         boolean = false);
   var
      Func: tRowTree.tCompareFunction;
   begin
      inherited Create();
      FieldName:=       iField;
      Reverse:=         iReverse;
      Func:=            tRowTree.tCompareFunction( @CompareInt32RowTuple);
      RowTree:=         tRowTree.Create( Func, true);
   end; // Create()


// *************************************************************************
// * Destroy() - destructor - Does the actual output
// *************************************************************************

destructor tCsvInt32SortFilter.Destroy();
   begin
      if( Reverse) then begin
        while RowTree.Previous() do begin
           NextFilter.SetRow( RowTree.Value.Row);
        end;
      end else begin
        while RowTree.Next() do begin
           NextFilter.SetRow( RowTree.Value.Row);
        end;
      end;

      RowTree.RemoveAll( true);
      RowTree.Destroy();
   end; // Destroy();


// *************************************************************************
// * SetInputHeader() - Find the Field Index and then pass the header to the
// *                    next filter.
// *************************************************************************

procedure tCsvInt32SortFilter.SetInputHeader( Header: tCsvCellArray);
   var
      i:     integer;
      iMax:  integer;
      Found: boolean;
   begin
      i:= 0;
      iMax:= Length( Header) - 1;
      Found:= false;
      while( (not Found) and (i <= iMax)) do begin
         if( Header[ i] = FieldName) then begin
             Found:= true;
             FieldIndex:= i;
         end;
         inc( i);
      end;

      if( not Found) then Usage( true, Format( HeaderUnknownField, [FieldName]));

      NextFilter.SetInputHeader( Header);
   end; // SetInputHeader();


// *************************************************************************
// * SetRow() - Add the row to the tree
// *************************************************************************

procedure tCsvInt32SortFilter.SetRow( Row: tCsvCellArray);
   var
      Field: string;
      RowTuple: tCsvInt32RowTuple;
   begin
      RowTuple:= tCsvInt32RowTuple.Create();
      Field:= Row[ FieldIndex];
      RowTuple.Key:= Field.ToInteger;
      RowTuple.Row:= Row;
      RowTree.Add( RowTuple);
   end; // SetRow();


// *************************************************************************

end.  // csv_new_filter unit
