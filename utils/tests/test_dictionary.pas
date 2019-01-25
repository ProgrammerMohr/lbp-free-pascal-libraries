{* ***************************************************************************

    Copyright (c) 2017 by Lloyd B. Park

    test_dictionary - Test my generic dictionary

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

program test_dictionary;

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

uses
   lbp_generic_dictionaries,
   lbp_types;


// ************************************************************************

type
   tStringClass = class( tObject)
   public
      Value: String;
      Constructor Create( MyValue: string);
   end; // tStringClass


constructor tStringClass.Create( MyValue: string);
   begin
      Value:= MyValue;
   end;


// ************************************************************************

type
   tStringDictionary = specialize tgDictionary< string, test_dictionary.tStringClass>;

var
   A: tStringClass;
   B: tStringClass;
   C: tStringClass;
   D: tStringClass;
   E: tStringClass;
   F: tStringClass;
   G: tStringClass;
   Search: tStringClass;

// *************************************************************************
// * CompareStrings - global function used only by tStringTree
// *************************************************************************

function CompareStrings(  S1: tStringClass; S2: tStringClass): integer;
   begin
      if( S1.Value > S2.Value) then begin
         result:= 1;
      end else if( S1.Value < S2.Value) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareStrings()


// *************************************************************************
// * NodeToString - global function used only by tStringTree
// *************************************************************************

function NodeToString( Data1: tStringClass): string;
   begin
      result:= Data1.Value
   end; // NodeToString;


// ************************************************************************
// * CreateStrings()
// ************************************************************************

procedure CreateStrings();
   begin
      A:= tStringClass.Create( 'aa');
      B:= tStringClass.Create( 'bb');
      C:= tStringClass.Create( 'cc');
      D:= tStringClass.Create( 'dd');
      E:= tStringClass.Create( 'ee');
      F:= tStringClass.Create( 'ff');
      G:= tStringClass.Create( 'gg');
      Search:= tStringClass.Create( 'ff');
   end; // CreateStrings()


// ************************************************************************
// * DestroyStrings()
// ************************************************************************

procedure DestroyStrings();
   begin
      A.Destroy;
      B.Destroy;
      C.Destroy;
      D.Destroy;
      E.Destroy;
      F.Destroy;
      G.Destroy;
      Search.Destroy;
   end; // DestroyStrings;


// ************************************************************************
// * FirstNextTest() - Test the First(), Next() functions
// ************************************************************************

procedure FirstNextTest();
   var
     Dict: tStringDictionary;
     S: tStringClass;
   begin
      CreateStrings;
      Dict:= tStringDictionary.Create( tStringDictionary.tCompareFunction( @CompareStrings));
      Dict.NodeToString:= tStringDictionary.tNodeToStringFunction( @NodeToString);
      writeln( 'FirstNextTest(): 1');

      Dict.Add( 'A', A);
      Dict.Add( 'B', B);
      Dict.Add( 'F', F);
      Dict.Add( 'G', G);
      Dict.Add( 'D', D);
      Dict.Add( 'E', E);
      Dict.Add( 'C', C);

      writeln( 'FirstNextTest(): 2');
      writeln( '------ Testing AVL Tree Find() function. ------');
      if( Dict.Find( 'F')) then writeln( '   Found: ', Dict.Value.Value);
      writeln( 'FirstNextTest(): 3');


      writeln( '------ Testing AVL Tree First() and Next() functions. ------');
      Dict.StartEnumeration();
      while( Dict.Next) do begin
         Writeln( '   ', Dict.Key);
      end; 
      writeln;

      writeln( '------ Testing AVL Tree for .. in functionality. ------');
      for S in Dict do Writeln( '   ', S.Value);
      writeln;

      writeln( '------ Testing AVL Tree Dump procedure. ------');
      Dict.Dump;
      writeln;

      Dict.Destroy;
      DestroyStrings;
   end; // FirstNextTest()


// ************************************************************************
// * LastPreviouTest() - Test the Last(), Previous() functions
// ************************************************************************

// procedure LastPreviousTest();
//    var
//      T: tStringTree;
//      S: tStringClass;
//    begin
//       CreateStrings;
//       T:= tStringTree.Create( tStringTree.tCompareFunction( @CompareStrings));
//       T.NodeToString:= tStringTree.tNodeToStringFunction( @NodeToString);

     
//       T.Add( D);
//       T.Add( B);
//       T.Add( F);
//       T.Add( A);
//       T.Add( C);
//       T.Add( E);
//       T.Add( G);

//       writeln( '------ Testing AVL Tree Last() and Previous() functions. ------');
//       T.StartEnumeration;
//       while( T.Previous) do begin
//          Writeln( '   ', T.Value.Value);
//       end; 
//       writeln;

//       writeln( '------ Testing AVL Tree for .. in functionality. ------');
//       for S in T.Reverse do Writeln( '   ', S.Value);
//       writeln;

//       writeln( '------ Testing AVL Tree Dump procedure. ------');
//       T.Dump;
//       writeln;


// //      T.RemoveAll( true);
//       T.Destroy;
//       DestroyStrings;
//    end; // LastPreviousTest()


// ************************************************************************
// * main()
// ************************************************************************

begin
   FirstNextTest;
//   LastPreviousTest;

   writeln( '------ Testing AVL Tree Dump() debugging function. ------')
end.  // test_dictionary
