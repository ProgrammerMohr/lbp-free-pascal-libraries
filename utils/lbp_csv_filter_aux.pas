{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

Defines internal types used by the lbp_csv_filter unit.  It may also help those
building their own custom filters outside lbp_csv_filter_unit.

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
unit lbp_csv_filter_aux;

// Classes to handle Comma Separated Value strings and files.

interface

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}

uses
   lbp_argv,
   lbp_types,
   lbp_generic_containers,
   lbp_csv,
   sysutils;


// ************************************************************************
// * tgCsvRowTuple - My tgDictionary class
// ************************************************************************

type
   generic tgCsvRowTuple< K> = class( tObject)
      public
         Key: K;
         Row: tCsvCellArray;
      end; // tgCsvRowTuple

   tCsvStringRowTubple = specialize tgCsvRowTuple< string>;
   tCsvWord64RowwTuple = specialize tgCsvRowTuple< word64>;
   tCsvWord32RowwTuple = specialize tgCsvRowTuple< word32>;
   tCsvInt64RowwTuple  = specialize tgCsvRowTuple< int64>;
   tCsvInt32RowwTuple  = specialize tgCsvRowTuple< int32>;


// ************************************************************************

type
   tHeaderDict         = specialize tgDictionary<string, integer>;
   tStringTree         = specialize tgAvlTree< string>;
   tIntegerArray       = array of integer;
   tCsvStringRowTuple  = specialize tgCsvRowTuple<  string>;
   tCsvWord32RowTuple  = specialize tgCsvRowTuple<  word32>;
   tCsvWord64RowTuple  = specialize tgCsvRowTuple<  word64>;
   tCsvInt32RowTuple   = specialize tgCsvRowTuple<  int32>;
   tCsvInt64RowTuple   = specialize tgCsvRowTuple<  int64>;

   tStringRowDict  = specialize tgDictionary<string,  tCsvStringRowTuple>;
   tWord64RowDict  = specialize tgDictionary<word64,  tCsvWord64RowTuple>;
   tWord32RowDict  = specialize tgDictionary<word32,  tCsvWord32RowTuple>;
   tInt64RowDict   = specialize tgDictionary<int64,   tCsvInt64RowTuple>;
   tInt32RowDict   = specialize tgDictionary<int32,   tCsvInt32RowTuple>;


// *************************************************************************
// * Global variables
// *************************************************************************

var
   HeaderZeroLengthError: string = 'The passed header can not be empty!';
   HeaderUnknownField: string = '''%s'' is not a field in the input header!';


// *************************************************************************

implementation

// *************************************************************************

end. // lbp_csv_filter_aux unit
