{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

AVL and Red Black trees which use generics

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

unit lbp_generic_trees;

interface

{$include lbp_standard_modes.inc}
//{$V-}    //Added by LP because it says so below
//{$R-}    //Range checking off
//{$S-}    //Stack checking off
//{$I-}    //I/O checking off
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

uses
   sysutils,       // Exceptions
   lbp_types;     // lbp_exception
//   lbp_vararray;  // Int64SortElement


// ************************************************************************

type
   generic tgAvlTreeNode< T: tObject> = class( tObject)
      protected
         Parent:     tgAvlTreeNode;
         LeftChild:  tgAvlTreeNode;
         RightChild: tgAvlTreeNode;
         Data:       T;
      public
         Constructor Create( MyData: T);
      end; // tgAvlTreeNode


// ************************************************************************

type
   generic tgAvlTree< T: tObject> = class( tObject)
      public
         type
            tAvlTreeNode = specialize tgAvlTreeNode< T>;
            tCompareFunction = function( const Data1, Data2: T): Integer;  
      private
         MyRoot:          tAvlTreeNode;
         DuplicateOK:     boolean;
         CurrentNode:     tAvlTreeNode;
         MyCount:         integer;
         MyName:          string;
         MyCompare:       tCompareFunction;
      public
         Constructor Create( iCompare:        tCompareFunction;
                             iAllowDuplicates: boolean);
         Destructor  Destroy(); override;
         procedure   RemoveAll( DestroyElements: boolean = false);
         procedure   Add( Data: T);
         function    First():     T;
         function    Last():      T;
         function    Previous():  T;
         function    Next():      T;
      protected
         function    IsEmpty():  boolean; virtual;
      public
         property    AllowDuplicates: boolean
                                read DuplicateOK write DuplicateOK;
         property    Empty: boolean read IsEmpty write RemoveAll;
         property    Count: integer read MyCount;
         property    Root:  tAvlTreeNode read MyRoot;
         property    Name:  string  read MyName write MyName;
         property    Compare: tCompareFunction read MyCompare write MyCompare;
      end; // tgAvlTree


// ************************************************************************

implementation

// ========================================================================
// = tgAvlTreeNode generic class
// ========================================================================
// ************************************************************************
// * Constructors
// ************************************************************************

constructor tgAvlTreeNode.Create( MyData: T);
  // Makes a new and empty List
  begin
     inherited Create;
     Parent:=     nil;
     LeftChild:=  nil;
     RightChild:= nil;
     Data:=       MyData;
  end; // Create()



// ========================================================================
// = tgAvlTree generic class
// ========================================================================
// ************************************************************************
// * Create() - Constructors
// ************************************************************************

constructor tgAvlTree.Create( iCompare:     tCompareFunction;
                                  iAllowDuplicates: boolean);
   begin
      inherited Create;
      MyRoot:= nil;
      Compare:= iCompare;
      DuplicateOK:= iAllowDuplicates;
      CurrentNode:= nil;
      MyName:= '';
      MyCount:= 0;
   end; // Create()


// ************************************************************************
// * Destroy() - Destructor
// ************************************************************************

Destructor tgAvlTree.Destroy();
   begin
      RemoveAll;
      inherited Destroy();
   end;


// ************************************************************************
// * RemoveAll() - Remove all the elements from the tree and optionally 
// *               Destroy() the elements.
// ************************************************************************

procedure tgAvlTree.RemoveAll( DestroyElements: boolean);
   begin
   end; // RemoveAll()


// ************************************************************************
// * Add() - Add an element to the tree
// ************************************************************************

procedure tgAvlTree.Add( Data: T);
   begin
   end; // Add()


// ************************************************************************
// * First() - Return the first or smallest element in the tree
// ************************************************************************

function tgAvlTree.First(): T;
   begin
      result:= MyRoot.Data;
   end; // First()


// ************************************************************************
// * Last() - Return the last or largest element in the tree
// ************************************************************************

function tgAvlTree.Last(): T;
   begin
      result:= MyRoot.Data;
   end; // Last()


// ************************************************************************
// * Previous() - Return the previous element in the tree.
// ************************************************************************

function tgAvlTree.Previous(): T;
   begin
      result:= MyRoot.Data;
   end; // Previous()


// ************************************************************************
// * Next() - Return the next element in the tree
// ************************************************************************

function tgAvlTree.Next(): T;
   begin
      result:= MyRoot.Data;
   end; // Next()


// ************************************************************************
// * IsEmpty() - Returns true if the tree is empty.
// ************************************************************************

function tgAvlTree.IsEmpty(): T;
   begin
      result:= (MyCount = 0);
   end; // First()



// ************************************************************************

end. // lbp_generic_lists unit
