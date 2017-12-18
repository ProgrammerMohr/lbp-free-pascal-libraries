{* ***************************************************************************

    Copyright (c) 2017 by Lloyd B. Park

    test_trees - Test my generic trees

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

program test_trees;

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

uses
   lbp_generic_trees,
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
   tStringTree = specialize tgAvlTree< test_trees.tStringClass>;

var
   A: tStringClass;
   B: tStringClass;
   C: tStringClass;
   D: tStringClass;
   E: tStringClass;
   F: tStringClass;
   G: tStringClass;


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
      A:= tStringClass.Create( 'A');
      B:= tStringClass.Create( 'B');
      C:= tStringClass.Create( 'C');
      D:= tStringClass.Create( 'D');
      E:= tStringClass.Create( 'E');
      F:= tStringClass.Create( 'F');
      G:= tStringClass.Create( 'G');
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
   end; // DestroyStrings;


// ************************************************************************
// * FirstNextTest() - Test the First(), Next() functions
// ************************************************************************

procedure FirstNextTest();
   var
     T: tStringTree;
     S: tStringClass;
   begin
      CreateStrings;
      T:= tStringTree.Create( tStringTree.tCompareFunction( @CompareStrings));
      T.NodeToString:= tStringTree.tNodeToStringFunction( @NodeToString);

      T.Add( D);
      T.Add( B);
      T.Add( F);
      T.Add( A);
      T.Add( C);
      T.Add( E);
      T.Add( G);

      writeln( '------ Testing AVL Tree First() and Next() functions. ------');
      S:= T.First;
      while( S <> nil) do begin
         Writeln( '   ', S.Value);
         S:= T.Next;
      end; 
      writeln;

      writeln( '------ Testing AVL Tree Dump procedure. ------');
      T.Dump;
      writeln;

      T.Destroy;
      DestroyStrings;
   end; // FirstNextTest()


// ************************************************************************
// * LastPreviouTest() - Test the Last(), Previous() functions
// ************************************************************************

procedure LastPreviousTest();
   var
     T: tStringTree;
     S: tStringClass;
   begin
      CreateStrings;
      T:= tStringTree.Create( tStringTree.tCompareFunction( @CompareStrings));

     
      T.Add( D);
      T.Add( B);
      T.Add( F);
      T.Add( A);
      T.Add( C);
      T.Add( E);
      T.Add( G);

      writeln( '------ Testing AVL Tree Last() and Previous() functions. ------');
      S:= T.Last;
      while( S <> nil) do begin
         Writeln( '   ', S.Value);
         S:= T.Previous;
      end; 
      writeln;

      T.Destroy;
      DestroyStrings;
   end; // LastPreviousTest()


// ************************************************************************
// * main()
// ************************************************************************

begin
   FirstNextTest;
   LastPreviousTest;

   writeln( '------ Testing AVL Tree Dump() debugging function. ------')
end.  // test_trees

