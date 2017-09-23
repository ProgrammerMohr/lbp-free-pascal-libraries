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

type
   tAvlTreeNode = specialize tgAvlTreeNode< tStringClass>; 


constructor tStringClass.Create( MyValue: string);
   begin
      Value:= MyValue;
   end;




// ************************************************************************
// * main()
// ************************************************************************

var
   A: tStringClass;
   B: tStringClass;
   C: tStringClass;
   AvlTreeNode: tAvlTreeNode;

begin
   A:= tStringClass.Create( 'A');
   B:= tStringClass.Create( 'B');
   C:= tStringClass.Create( 'C');
   
   AvlTreeNode:= tAvlTreeNode.Create( A);
   AvlTreeNode.Destroy;

   A.Destroy;
   B.Destroy;
   C.Destroy;
end.  // test_trees

