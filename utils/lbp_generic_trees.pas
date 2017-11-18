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
   sysutils,      // Exceptions
   lbp_types,     // lbp_exception
   lbp_generic_lists;
//   lbp_vararray;  // Int64SortElement



// ************************************************************************

type
   lbp_container_exception = class( lbp_exception);

// ************************************************************************

type
   generic tgAvlTreeNode< T: tObject> = class( tObject)
      protected
         Parent:     tgAvlTreeNode;
         LeftChild:  tgAvlTreeNode;
         RightChild: tgAvlTreeNode;
         Balance:    integer;
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
            tAvlTreeNodeList = specialize tgDoubleLinkedList< tAvlTreeNode>;
            tCompareFunction = function( const Data1, Data2: T): Integer;
            tNodeToStringFunction = function( const Data: T): string;  
      private
         MyRoot:          tAvlTreeNode;
         DuplicateOK:     boolean;
         CurrentNode:     tAvlTreeNode;
         MyCount:         integer;
         MyName:          string;
         MyCompare:       tCompareFunction;
         MyNodeToString:  tNodeToStringFunction;
      public
         Constructor Create( iCompare:        tCompareFunction;
                             iAllowDuplicates: boolean = false);
         Destructor  Destroy(); override;
         procedure   RemoveAll( DestroyElements: boolean = false);
         procedure   Add( Data: T);
         function    First():     T;
         function    Last():      T;
         function    Previous():  T;
         function    Next():      T;
         procedure   DumpNodes();  // 
      protected
         function    IsEmpty():  boolean; virtual;
         procedure   RemoveSubtree( StRoot: tAvlTreeNode; DestroyElements: boolean);
         procedure   AddBalance( N: tAVLTreeNode; Balance: integer);
         procedure   RemoveBalance( N: tAVLTreeNode; Balance: integer);
         procedure   RotateLeft( N: tAVLTreeNode);
         procedure   RotateLeftRight( N: tAVLTreeNode);
         procedure   RotateRight( N: tAVLTreeNode);
         procedure   RotateRightLeft( N: tAVLTreeNode);

//         procedure   Rebalance( N: Node);
      public
         property    AllowDuplicates: boolean
                                read DuplicateOK write DuplicateOK;
         property    Empty: boolean read IsEmpty write RemoveAll;
         property    Count: integer read MyCount;
         property    Root:  tAvlTreeNode read MyRoot;
         property    Name:  string  read MyName write MyName;
         property    Compare: tCompareFunction read MyCompare write MyCompare;
         property    NodeToString:  tNodeToStringFunction read MyNodeToString write MyNodeToString;
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
     Balance:=    0;
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
      NodeToString:= nil;
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
      if( MyRoot <> nil) then RemoveSubtree( MyRoot, DestroyElements);
   end; // RemoveAll()


// ************************************************************************
// * Add() - Add an element to the tree
// ************************************************************************

procedure tgAvlTree.Add( Data: T);
   var
      Child:          tAvlTreeNode;
      Parent:         tAvlTreeNode;
      Added:          boolean = false;
      CompareResult:  integer;
   begin
      Child:= tAvlTreeNode.Create( Data);

      if( MyRoot = nil) then begin
         // Special case of an empty tree
         MyRoot:= Child;
      end else begin
         Parent:= MyRoot;
         while( Parent <> nil) do begin
            CompareResult:= Compare( Child.Data, Parent.Data);
            if( (CompareResult = 0) and (not DuplicateOK)) then begin 
               Child.Destroy;
               raise lbp_container_exception.create( 
               'Duplicate records violate the constraints of this AVL tree!');
            end else if( CompareResult > 0) then begin
               // Right path
               if( Parent.RightChild = nil) then begin
                  // Add as right child
                  Parent.RightChild:= Child;
                  Child.Parent:= Parent;
                  AddBalance( Parent, 1);
                  exit;
               end else begin
                  Parent:= Parent.RightChild;
               end;
            end else begin
               // Left path
               if( Parent.LeftChild = nil) then begin
                  // Add as left child
                  Parent.LeftChild:= Child;
                  Child.Parent:= Parent;
                  AddBalance( Parent, -1);
                  exit;
               end else begin
                  Parent:= Parent.LeftChild;
               end;
            end;
         end; // while
      end; // else non-empty tree
      inc( MyCount);
   end; // Add()


// ************************************************************************
// * First() - Return the first or smallest element in the tree
// ************************************************************************

function tgAvlTree.First(): T;
   begin
      // Check for empty tree
      if( MyRoot = nil) then begin
         result:= nil;
         CurrentNode:= nil;
      end else begin
         CurrentNode:= MyRoot;
         while( CurrentNode.LeftChild <> nil) do begin 
            CurrentNode:= CurrentNode.LeftChild;
         end;
         result:= CurrentNode.Data;
      end;
   end; // First()


// ************************************************************************
// * Last() - Return the last or largest element in the tree
// ************************************************************************

function tgAvlTree.Last(): T;
   begin
       // Check for empty tree
      if( MyRoot = nil) then begin
         result:= nil;
         CurrentNode:= nil;
      end else begin
         CurrentNode:= MyRoot;
         while( CurrentNode.RightChild <> nil) do begin 
            CurrentNode:= CurrentNode.RightChild;
         end;
         result:= CurrentNode.Data;
      end;
   end; // Last()


// ************************************************************************
// * Previous() - Return the previous element in the tree.
// ************************************************************************

function tgAvlTree.Previous(): T;
   var
      PreviousNode:  tAvlTreeNode;
   begin
      if( CurrentNode = nil) then begin
         result:= Last();
         exit;
      end;
      // Do I have a left child?
      if( CurrentNode.LeftChild <> nil) then begin
         // Start traversing the right subtree
         CurrentNode:= CurrentNode.LeftChild;
         // Find the rightmost child if any
         while( CurrentNode.RightChild <> nil) do begin
            CurrentNode:= CurrentNode.RightChild;
         end;

      end else repeat
         // Move toward the root
         PreviousNode:= CurrentNode;
         CurrentNode:= CurrentNode.Parent;
      until( (CurrentNode = nil) or (CurrentNode.RightChild = PreviousNode)); 

      if( CurrentNode = nil) then result:= nil else result:= CurrentNode.Data;
   end; // Previous()


// ************************************************************************
// * Next() - Return the next element in the tree
// ************************************************************************

function tgAvlTree.Next(): T;
   var
      PreviousNode:  tAvlTreeNode;
   begin
      if( CurrentNode = nil) then begin
         result:= First();
         exit;
      end;
      // Do I have a right child?
      if( CurrentNode.RightChild <> nil) then begin
         // Start traversing the right subtree
         CurrentNode:= CurrentNode.RightChild;
         // Find the leftmost child if any
         while( CurrentNode.LeftChild <> nil) do begin
            CurrentNode:= CurrentNode.LeftChild;
         end;

      end else repeat
         // Move toward the root
         PreviousNode:= CurrentNode;
         CurrentNode:= CurrentNode.Parent;
      until( (CurrentNode = nil) or (CurrentNode.LeftChild = PreviousNode)); 

      if( CurrentNode = nil) then result:= nil else result:= CurrentNode.Data;
   end; // Next()


// ************************************************************************
// * DumpNodes();
// ************************************************************************

procedure tgAvlTree.DumpNodes();
   var
     L:  tAvlTreeNodeList;
     N:  tAvlTreeNode;
   begin
      L:= tAvlTreeNodeList.Create();
      N:= Root;

      if( NodeToString = nil) then begin
         raise lbp_container_exception.Create( 'NodeToString() has not been defined for this tgAVlTreeNode!');
      end;
      try 
         while( N <> nil) do begin
            write( 'Parent      = ');
            if( N.Parent = nil) then writeln else writeln( NodeToString( N.Parent.Data));
            writeln( 'Value       = ', NodeToString( N.Data));
            write( 'Left Child  = ');
            if( N.LeftChild = nil) then begin
               writeln;
            end else begin
               writeln( NodeToString( N.LeftChild.Data));
               L.Queue:= N.LeftChild;
            end;
            write( 'Right Child = '); 
            if( N.RightChild = nil) then begin
               writeln;
            end else begin
               writeln( NodeToString( N.RightChild.Data));
               L.Queue:= N.RightChild;
            end;
            writeln( 'Balance    = ', N.Balance);
            writeln( '-------------------------');
            N:= L.Queue;
         end;
      except
         on Exception do;
      end;
      L.Destroy;
   end; // DumpNodes()


// ************************************************************************
// * IsEmpty() - Returns true if the tree is empty.
// ************************************************************************

function tgAvlTree.IsEmpty(): T;
   begin
      result:= (MyCount = 0);
   end; // First()


// ************************************************************************
// * RemoveSubtree() - Helper for RemoveAll
// ************************************************************************

procedure tgAvlTree.RemoveSubtree( StRoot: tAvlTreeNode; DestroyElements: boolean);
   begin
      if( StRoot.LeftChild <> nil) then begin
         RemoveSubtree( StRoot.LeftChild, DestroyElements);
      end;
      if( StRoot.RightChild <> nil) then begin 
         RemoveSubtree( StRoot.RightChild, DestroyElements);
      end;
      if( DestroyElements) then StRoot.Data.Destroy;
      StRoot.Destroy;
   end; // RemoveSubtree()


// ************************************************************************
// * AddBalance() - Rebalance the tree after an Add()
// ************************************************************************

procedure tgAvlTree.AddBalance( N: tAVLTreeNode; Balance: integer);
   var
      Parent: tAVLTreeNode;
   begin
      while( N <> nil) do begin
         Balance:= Balance + N.Balance;
         N.Balance:= Balance;
         if(Balance = 0) then begin
            exit;
         end else if( Balance = -2) then begin
            if( N.LeftChild.Balance= -1) then begin
               RotateRight( N);
            end else begin
               RotateLeftRight( N);
            end;
            exit;
         end else if( Balance = 2) then begin
            if( N.RightChild.Balance = 1) then begin
               RotateLeft( N);
            end else begin
               RotateRightLeft( N);
            end;
            exit;
         end;
         Parent:= N.Parent;
         if( Parent <> nil) then begin
            if( Parent.LeftChild = N) then Balance:= -1 else Balance:= 1;
         end;
         N:= Parent;
      end;
   end; // AddBalance()


// ************************************************************************
// * RemoveBalance() - Rebalance the tree after a Remove()
// ************************************************************************

procedure tgAvlTree.RemoveBalance( N: tAVLTreeNode; Balance: integer);
   begin
   end; // RemoveBalance()


// ************************************************************************
// * RotateLeft()
// ************************************************************************

procedure tgAvlTree.RotateLeft( N: tAVLTreeNode);
   begin
   end; // RotateLeft();


// ************************************************************************
// * RotateLeftRight()
// ************************************************************************

procedure tgAvlTree.RotateLeftRight( N: tAVLTreeNode);
   begin
   end; // RotateLeftRight();


// ************************************************************************
// * RotateRight()
// ************************************************************************

procedure tgAvlTree.RotateRight( N: tAVLTreeNode);
   begin
   end; // RotateRight();


// ************************************************************************
// * RotatRightLeft()
// ************************************************************************

procedure tgAvlTree.RotateRightLeft( N: tAVLTreeNode);
   begin
   end; // RotateRightLeft();






// ************************************************************************

end. // lbp_generic_lists unit
