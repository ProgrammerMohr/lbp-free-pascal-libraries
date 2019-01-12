{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park
Copyright (c) 2008 by Mattias Gaertner

AVL (Average Level) tree which uses generics
The AVL Tree is my attempt to make a generic version of Mattias Gaertner's
tAVLTree in the AVL_Tree unit included with Free Pascal.  Since I had written
my own AVL tree very shortly before Mattias' was released, I combined features
of both into this one. 


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
   lbp_types,     // lbp_excpetion
   lbp_utils,     // PadLeft() - Only used to print debug information
   lbp_generic_lists,
   typinfo;
//   lbp_vararray;  // Int64SortElement

// *******************************************************
// tObject.ToString() - returns class name by default    *
// *******************************************************

 

// ************************************************************************

type
   lbp_container_exception = class( lbp_exception);

// ************************************************************************
// * tgAvlTreeNode - Support class.
// ************************************************************************

type
   generic tgAvlTreeNode< T> = class( tObject)
      protected
         Parent:      tgAvlTreeNode;
         LeftChild:   tgAvlTreeNode;
         RightChild:  tgAvlTreeNode;
         Balance:     integer;
         Data:         T;
      public
         constructor  Create( iData: T);
         procedure Clear;
         function TreeDepth(): integer; // longest WAY down. e.g. only one node => 0 !
      end; // tgAvlTreeNode


// ************************************************************************
// * tgBaseAvlTreeNodeManager - Support class to control memory management 
// * (Add this when the rest of the unit is working)
// ************************************************************************

// type
//    tgBaseAvlTreeNodeManager< N> = class
//       public
//          procedure DisposeNode(ANode: TAVLTreeNode); virtual; abstract;
//          function NewNode: TAVLTreeNode; virtual; abstract;
//    end; // tgBaseAVLTreeNodeManager


// ************************************************************************
// * tgAvlTree
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
         procedure   Dump( N:       tAvlTreeNode = nil; 
                           Prefix:  string = '');  // Debug code 
      protected
         function    IsEmpty():  boolean; virtual;
         procedure   RemoveSubtree( StRoot: tAvlTreeNode; DestroyElements: boolean);
         function    FindInsertPosition( Data: T): tAvlTreeNode;
         procedure   RebalanceAfterAdd( N: tAVLTreeNode);
         procedure   RemoveBalance( N: tAVLTreeNode; Balance: integer);
         procedure   RotateLeft( N: tAVLTreeNode);
         procedure   RotateLeftRight( N: tAVLTreeNode);
         procedure   RotateRight( N: tAVLTreeNode);
         procedure   RotateRightLeft( N: tAVLTreeNode);

// //         procedure   Rebalance( N: Node);
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
// * Create() - constructor
// ************************************************************************
constructor tgAvlTreeNode.Create( iData: T);
   begin
      Parent:= nil;
      LeftChild:= nil;
      RightChild:= nil;
      Balance:= 0;
      Data:= iData;
   end;

// ************************************************************************
// * Clear() - Zero out the fields 
// ************************************************************************

procedure tgAvlTreeNode.Clear();
   begin
      Parent:= nil;
      LeftChild:= nil;
      RightChild:= nil;
      Balance:= 0;
      Data:= Default( T);
   end;

// ************************************************************************
// * TreeDepth() - Returns the depth of this node.
// ************************************************************************

function tgAvlTreeNode.TreeDepth(): integer;
// longest WAY down. e.g. only one node => 0 !
var 
   LeftDepth:  integer;
   RightDepth: integer;
begin
  if LeftChild<>nil then begin
    LeftDepth:=LeftChild.TreeDepth+1
  end else begin
    LeftDepth:=0;
  end;

  if RightChild<>nil then begin
    RightDepth:=RightChild.TreeDepth+1
  end else begin
    RightDepth:=0;
  end;
  
  if LeftDepth>RightDepth then
    Result:=LeftDepth
  else
    Result:=RightDepth;
end; // TreeDepth



// ========================================================================
// = tgAvlTree generic class
// ========================================================================
// ************************************************************************
// * Create() - Constructors
// ************************************************************************

constructor tgAvlTree.Create( iCompare:     tCompareFunction;
                                  iAllowDuplicates: boolean = false);
   begin
      inherited Create;
      MyRoot:= nil;
      MyCompare:= iCompare;
      MyNodeToString:= nil;
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
// * FindInsertPosition() - Find the node to which this new data will be 
// *                        a child.
// ************************************************************************

function tgAvlTree.FindInsertPosition( Data: T): tAvlTreeNode;
   var 
      Comp: integer;
   begin
      Result:= MyRoot;
      while( Result <> nil) do begin
         Comp:= MyCompare( Data, Result.Data);
         if Comp<0 then begin
            if Result.LeftChild <> nil then Result:=Result.LeftChild
            else exit;
         end else begin
            if Result.RightChild <> nil then Result:=Result.RightChild
            else exit;
         end;
      end; // while
   end; //FindInsertPosition()


// ************************************************************************
// * Add() - Add an element to the tree
// ************************************************************************

procedure tgAvlTree.Add( Data: T);
   var 
      InsertPos:   tAvlTreeNode;
      Comp:        integer;
      NewNode:     tAvlTreeNode;
   begin
      NewNode:= tAvlTreeNode.create( Data);
      inc( MyCount);
      if MyRoot <> nil then begin
         InsertPos:= FindInsertPosition( Data);
         Comp:= MyCompare( Data, InsertPos.Data);
         NewNode.Parent:= InsertPos;
         if( Comp < 0) then begin
            // insert to the left
            InsertPos.LeftChild:= NewNode;
         end else begin
            // Check for unallowed duplicate
            if( (Comp = 0) and DuplicateOK) then begin
              NewNode.Destroy(); // Clean up
              raise lbp_container_exception.Create( 'Duplicate key values are not allowed in this AVL Tree!');
            end;
            // insert to the right
            InsertPos.RightChild:= NewNode;
         end;
         RebalanceAfterAdd( NewNode);
      end else begin
         MyRoot:=NewNode;
      end;
   end; // TgAvlTree.Add()


// procedure tgAvlTree.Add( Data: T);
//    var
//       Child:          tAvlTreeNode;
//       Parent:         tAvlTreeNode;
//       CompareResult:  integer;
//    begin
//       Child:= tAvlTreeNode.Create( Data);

//       if( MyRoot = nil) then begin
//          // Special case of an empty tree
//          MyRoot:= Child;
//       end else begin
//          Parent:= MyRoot;
//          while( Parent <> nil) do begin
//             CompareResult:= MyCompare( Child.Data, Parent.Data);
//             if( (CompareResult = 0) and (not DuplicateOK)) then begin 
//                Child.Destroy;
//                raise lbp_container_exception.create( 
//                'Duplicate records violate the constraints of this AVL tree!');
//             end else if( CompareResult > 0) then begin
//                // Right path
//                if( Parent.RightChild = nil) then begin
//                   // Add as right child
//                   Parent.RightChild:= Child;
//                   Child.Parent:= Parent;
//                   RebalanceAdd( Parent, 1);
//                   exit;
//                end else begin
//                   Parent:= Parent.RightChild;
//                end;
//             end else begin
//                // Left path
//                if( Parent.LeftChild = nil) then begin
//                   // Add as left child
//                   Parent.LeftChild:= Child;
//                   Child.Parent:= Parent;
//                   RebalanceAdd( Parent, -1);
//                   exit;
//                end else begin
//                   Parent:= Parent.LeftChild;
//                end;
//             end;
//          end; // while
//       end; // else non-empty tree
//       inc( MyCount);
//    end; // Add()


// ************************************************************************
// * First() - Return the first or smallest element in the tree
// ************************************************************************

// function tgAvlTree.First(): T;
//    begin
//       // Check for empty tree
//       if( MyRoot = nil) then begin
//          result:= nil;
//          CurrentNode:= nil;
//       end else begin
//          CurrentNode:= MyRoot;
//          while( CurrentNode.LeftChild <> nil) do begin 
//             CurrentNode:= CurrentNode.LeftChild;
//          end;
//          result:= CurrentNode.Data;
//       end;
//    end; // First()


// ************************************************************************
// * Last() - Return the last or largest element in the tree
// ************************************************************************

// function tgAvlTree.Last(): T;
//    begin
//        // Check for empty tree
//       if( MyRoot = nil) then begin
//          result:= nil;
//          CurrentNode:= nil;
//       end else begin
//          CurrentNode:= MyRoot;
//          while( CurrentNode.RightChild <> nil) do begin 
//             CurrentNode:= CurrentNode.RightChild;
//          end;
//          result:= CurrentNode.Data;
//       end;
//    end; // Last()


// ************************************************************************
// * Previous() - Return the previous element in the tree.
// ************************************************************************

// function tgAvlTree.Previous(): T;
//    var
//       PreviousNode:  tAvlTreeNode;
//    begin
//       if( CurrentNode = nil) then begin
//          result:= Last();
//          exit;
//       end;
//       // Do I have a left child?
//       if( CurrentNode.LeftChild <> nil) then begin
//          // Start traversing the right subtree
//          CurrentNode:= CurrentNode.LeftChild;
//          // Find the rightmost child if any
//          while( CurrentNode.RightChild <> nil) do begin
//             CurrentNode:= CurrentNode.RightChild;
//          end;

//       end else repeat
//          // Move toward the root
//          PreviousNode:= CurrentNode;
//          CurrentNode:= CurrentNode.Parent;
//       until( (CurrentNode = nil) or (CurrentNode.RightChild = PreviousNode)); 

//       if( CurrentNode = nil) then result:= nil else result:= CurrentNode.Data;
//    end; // Previous()


// ************************************************************************
// * Next() - Return the next element in the tree
// ************************************************************************

// function tgAvlTree.Next(): T;
//    var
//       PreviousNode:  tAvlTreeNode;
//    begin
//       if( CurrentNode = nil) then begin
//          result:= First();
//          exit;
//       end;
//       // Do I have a right child?
//       if( CurrentNode.RightChild <> nil) then begin
//          // Start traversing the right subtree
//          CurrentNode:= CurrentNode.RightChild;
//          // Find the leftmost child if any
//          while( CurrentNode.LeftChild <> nil) do begin
//             CurrentNode:= CurrentNode.LeftChild;
//          end;

//       end else repeat
//          // Move toward the root
//          PreviousNode:= CurrentNode;
//          CurrentNode:= CurrentNode.Parent;
//       until( (CurrentNode = nil) or (CurrentNode.LeftChild = PreviousNode)); 

//       if( CurrentNode = nil) then result:= nil else result:= CurrentNode.Data;
//    end; // Next()


// ************************************************************************
// * DumpNOdes
// ************************************************************************

//  d - b - a
//  |    \- c
//   \- f - e
//       \- g

procedure tgAvlTree.Dump( N:       tAvlTreeNode = nil;
                          Prefix:  string       = ''); 
   var
      Temp: string;
   begin
      if( MyNodeToString = nil) then 
         writeln( 'The tree can not be dumped because ''NodeToString'' has not be set!');

      // Take care of the start condition and the empty cases
      if( N = nil) then begin
         if( MyRoot = nil) then exit;
         N:= MyRoot;
      end;

      // Convert the data to something printable
      Temp:= MyNodeToString( N.Data);
      if( Length( Temp) > 4) then SetLength( Temp, 4);
      PadLeft( Temp, 4);

      // Print N's data
      write( Temp);

      // Process the Left Branch
      if( N.LeftChild = nil) then begin
         writeln;
      end else begin
         write( ' -> ');
         Dump( N.LeftChild, Prefix + '   |    ');
      end;

      // Process the Right Branch
      if( N.RightChild <> nil) then begin
         write( Prefix, '    \-> ');
         Dump( N.RightChild, Prefix + '        ');
      end;
   end; // Dump


// procedure tgAvlTree.DumpNodes();
//    var
//      L:  tAvlTreeNodeList;
//      N:  tAvlTreeNode;
//    begin
//       L:= tAvlTreeNodeList.Create();
//       N:= Root;
// 
//       if( NodeToString = nil) then begin
//          raise lbp_container_exception.Create( 'NodeToString() has not been defined for this tgAVlTreeNode!');
//       end;
//       try 
//          while( N <> nil) do begin
//             write( 'Parent      = ');
//             if( N.Parent = nil) then writeln else writeln( NodeToString( N.Parent.Data));
//             writeln( 'Value       = ', NodeToString( N.Data));
//             write( 'Left Child  = ');
//             if( N.LeftChild = nil) then begin
//                writeln;
//             end else begin
//                writeln( NodeToString( N.LeftChild.Data));
//                L.Queue:= N.LeftChild;
//             end;
//             write( 'Right Child = '); 
//             if( N.RightChild = nil) then begin
//                writeln;
//             end else begin
//                writeln( NodeToString( N.RightChild.Data));
//                L.Queue:= N.RightChild;
//             end;
//             writeln( 'Balance    = ', N.Balance);
//             writeln( '-------------------------');
//             N:= L.Queue;
//          end;
//       except
//          on Exception do;
//       end;
//       L.Destroy;
//    end; // DumpNodes()


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
      if( (pTypeInfo( TypeInfo( T))^.Kind = tkClass) and DestroyElements) then begin
         StRoot.Data.Destroy;
      end;
      StRoot.Destroy;
   end; // RemoveSubtree()


// ************************************************************************
// * RebalanceAfterAdd() - Rebalance the tree after an Add()
// ************************************************************************

procedure tgAvlTree.RebalanceAfterAdd( N: tAVLTreeNode);
   var 
      OldParent:       tAvlTreeNode;
      OldParentParent: tAvlTreeNode;
      OldRight:        tAvlTreeNode;
      OldRightLeft:    tAvlTreeNode;
      OldRightRight:   tAvlTreeNode;
      OldLeft:         tAvlTreeNode;
      OldLeftLeft:     tAvlTreeNode;
      OldLeftRight:    tAvlTreeNode;
   begin
      OldParent:= N.Parent;
      if( OldParent = nil) then exit;
      if( OldParent.LeftChild = N) then begin
         // Node is left son
         dec(OldParent.Balance);
         if (OldParent.Balance=0) then exit;
         if (OldParent.Balance=-1) then begin
            RebalanceAfterAdd( OldParent);
            exit;
         end;
         // OldParent.Balance=-2
         if( N.Balance=-1) then begin
            // rotate
            OldRight:=N.RightChild;
            OldParentParent:=OldParent.Parent;
            if (OldParentParent<>nil) then begin
               // OldParent has GrandParent. GrandParent gets new child
               if (OldParentParent.LeftChild=OldParent) then
                  OldParentParent.LeftChild:=N
               else
                  OldParentParent.RightChild:=N;
            end else begin
               // OldParent was root node. New root node
               MyRoot:=N;
            end;
            N.Parent:=OldParentParent;
            N.RightChild:=OldParent;
            OldParent.Parent:=N;
            OldParent.LeftChild:=OldRight;
            if (OldRight<>nil) then
               OldRight.Parent:=OldParent;
            N.Balance:=0;
            OldParent.Balance:=0;
         end else begin
            // Node.Balance = +1
            // double rotate
            OldParentParent:=OldParent.Parent;
            OldRight:=N.RightChild;
            OldRightLeft:=OldRight.LeftChild;
            OldRightRight:=OldRight.RightChild;
            if (OldParentParent<>nil) then begin
               // OldParent has GrandParent. GrandParent gets new child
               if (OldParentParent.LeftChild=OldParent) then
                  OldParentParent.LeftChild:=OldRight
               else
                  OldParentParent.RightChild:=OldRight;
            end else begin
               // OldParent was root node. new root node
               MyRoot:=OldRight;
            end;
            OldRight.Parent:=OldParentParent;
            OldRight.LeftChild:=N;
            OldRight.RightChild:=OldParent;
            N.Parent:=OldRight;
            N.RightChild:=OldRightLeft;
            OldParent.Parent:=OldRight;
            OldParent.LeftChild:=OldRightRight;
            if (OldRightLeft<>nil) then
               OldRightLeft.Parent:=N;
            if (OldRightRight<>nil) then
               OldRightRight.Parent:=OldParent;
            if (OldRight.Balance<=0) then
               N.Balance:=0
            else
               N.Balance:=-1;
            if (OldRight.Balance=-1) then
               OldParent.Balance:=1
            else
               OldParent.Balance:=0;
            OldRight.Balance:=0;
         end;
      end else begin
         // Node is right son
         Inc(OldParent.Balance);
         if (OldParent.Balance=0) then exit;
         if (OldParent.Balance=+1) then begin
            RebalanceAfterAdd( OldParent);
            exit;
         end;
         // OldParent.Balance = +2
         if(N.Balance=+1) then begin
            // rotate
            OldLeft:=N.LeftChild;
            OldParentParent:=OldParent.Parent;
            if (OldParentParent<>nil) then begin
               // Parent has GrandParent . GrandParent gets new child
               if(OldParentParent.LeftChild=OldParent) then
                  OldParentParent.LeftChild:=N
               else
                  OldParentParent.RightChild:=N;
            end else begin
               // OldParent was root node . new root node
               MyRoot:=N;
            end;
            N.Parent:=OldParentParent;
            N.LeftChild:=OldParent;
            OldParent.Parent:=N;
            OldParent.RightChild:=OldLeft;
            if (OldLeft<>nil) then
               OldLeft.Parent:=OldParent;
            N.Balance:=0;
            OldParent.Balance:=0;
         end else begin
            // Node.Balance = -1
            // double rotate
            OldLeft:=N.LeftChild;
            OldParentParent:=OldParent.Parent;
            OldLeftLeft:=OldLeft.LeftChild;
            OldLeftRight:=OldLeft.RightChild;
            if (OldParentParent<>nil) then begin
               // OldParent has GrandParent . GrandParent gets new child
               if (OldParentParent.LeftChild=OldParent) then
                  OldParentParent.LeftChild:=OldLeft
               else
                  OldParentParent.RightChild:=OldLeft;
            end else begin
               // OldParent was root node . new root node
               MyRoot:=OldLeft;
            end;
            OldLeft.Parent:=OldParentParent;
            OldLeft.LeftChild:=OldParent;
            OldLeft.RightChild:=N;
            N.Parent:=OldLeft;
            N.LeftChild:=OldLeftRight;
            OldParent.Parent:=OldLeft;
            OldParent.RightChild:=OldLeftLeft;
            if (OldLeftLeft<>nil) then
               OldLeftLeft.Parent:=OldParent;
            if (OldLeftRight<>nil) then
               OldLeftRight.Parent:=N;
            if (OldLeft.Balance>=0) then
               N.Balance:=0
            else
               N.Balance:=+1;
            if (OldLeft.Balance=+1) then
               OldParent.Balance:=-1
            else
               OldParent.Balance:=0;
            OldLeft.Balance:=0;
         end;
      end;
   end; // RebalanceAfterAdd()


// ************************************************************************
// * RemoveBalance() - Rebalance the tree after a Remove()
// ************************************************************************

// procedure tgAvlTree.RemoveBalance( N: tAVLTreeNode; Balance: integer);
//    begin
//    end; // RemoveBalance()


// ************************************************************************
// * RotateLeft()
// ************************************************************************

// procedure tgAvlTree.RotateLeft( N: tAVLTreeNode);
//    begin
//    end; // RotateLeft();


// ************************************************************************
// * RotateLeftRight()
// ************************************************************************

// procedure tgAvlTree.RotateLeftRight( N: tAVLTreeNode);
//    begin
//    end; // RotateLeftRight();


// ************************************************************************
// * RotateRight()
// ************************************************************************

procedure tgAvlTree.RotateRight( N: tAVLTreeNode);
   begin
   end; // RotateRight();


// ************************************************************************
// * RotatRightLeft()
// ************************************************************************

// procedure tgAvlTree.RotateRightLeft( N: tAVLTreeNode);
//    begin
//    end; // RotateRightLeft();


// ************************************************************************

end. // lbp_generic_lists unit
