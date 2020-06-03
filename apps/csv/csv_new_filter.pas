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
   lbp_parse_helper, // CurrencyChrs
   lbp_csv_filter_aux,
   lbp_csv_filter,
   lbp_csv,
   lbp_ip_utils,
   sysutils;


// *************************************************************************
// * tCsvIpv4SortFilter()
// *************************************************************************

type
   tCsvIpv4SortFilter = class( tCsvWord32SortFilter)
      private
         IgnoreFailures: boolean;
      public
         constructor Create( iField:           string; 
                             iReverse:         boolean = false;
                             iIgnoreFailures:  boolean = false);
         procedure   SetRow( Row: tCsvCellArray); override;
      end; // tCsvIpv4SortFilter


// *************************************************************************

implementation

// ========================================================================
// = tCsvIpv4SortFilter class
// ========================================================================
// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor tCsvIpv4SortFilter.Create( iField:           string; 
                                       iReverse:         boolean = false;
                                       iIgnoreFailures:  boolean = false);
   begin
      inherited Create( iField, iReverse);
      IgnoreFailures:= iIgnoreFailures;
   end; // Create() 


// *************************************************************************
// * SetRow() - Add the row to the tree
// *************************************************************************

procedure tCsvIpv4SortFilter.SetRow( Row: tCsvCellArray);
   var
      Field:    string;
      RowTuple: tCsvWord32RowTuple;
      Temp:     word32;
   begin
      RowTuple:= tCsvWord32RowTuple.Create();
      Field:= Row[ FieldIndex];
      try
         Temp:= IPStringToWord32( Field);
      except
        on E: Exception do
        begin
           Temp:= 0;
           if( not IgnoreFailures) then raise E;
        end;
      end;
      RowTuple.Key:= Temp;
      RowTuple.Row:= Row;
      RowTree.Add( RowTuple);
   end; // SetRow();


// *************************************************************************

end.  // csv_new_filter unit
