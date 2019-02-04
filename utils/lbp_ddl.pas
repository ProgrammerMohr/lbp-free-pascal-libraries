{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park


This is a temporary location for the definition of the tgListDictionary class.
It combines the tgDoubleLinkedList and the tgDictionary classes.  It will be
moved to lbp_generic_containers when it is finished and tested.


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

unit lbp_ddl;

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
   lbp_utils,     // padleft() - only used for debug code.
   lbp_generic_containers;


// ************************************************************************
// * tgDoubleLinkiedList
// ************************************************************************

type
   generic tgDoubleLinkedList< K, V> = class( tObject);
         //public type tNodePtr = ^tNode;
      protected type
         // ---------------------------------------------------------------
         tNode = class( tObject)
            protected
               Parent:      tNode;
               LeftChild:   tNode;
               RightChild:  tNode;
               PrevNode:    tNode;
               NextNode:    tNode;
               Balance:     integer;
               Key:         K;
               Value:       V;
            public
               constructor  Create( iKey: K; iValue: V);
            end; // tgListNode class
         // ---------------------------------------------------------------
         tEnumerator = class(tObject)
            public
               MyList: tgDoubleLinkedList;
               constructor Create( List: tgDoubleLinkedList);
               function GetCurrent(): V;
               function MoveNext(): boolean;
               property Current: V read GetCurrent;
            end; // tEnumerator
         // ---------------------------------------------------------------
      public
         Name:          String;
      protected
         FirstNode:     tNode;
         LastNode:      tNode;
         CurrentNode:   tNode;
         ListLength:    Int32;
         MyForward:     boolean;
      public
         constructor    Create( const iName: string = '');
         destructor     Destroy; override;
         procedure      AddHead( Item: V); virtual; // Add to the head of the list
         function       GetHead(): V; virtual;      // Return the head element.
         function       DelHead(): V; virtual;      // Return the head element and remove it from the list.
         procedure      AddTail( Item: V); virtual; // Add to the tail of the list
         function       GetTail(): V; virtual;      // Return the head element
         function       DelTail(): V; virtual;      // Return the head element and remove it from the list.
         procedure      InsertBeforeCurrent( Item: V); virtual;
         procedure      InsertAfterCurrent( Item: V); virtual;
         procedure      Replace( OldItem, NewItem: V); virtual;
         procedure      Replace( NewItem: V); virtual;
         procedure      Remove( Item: V); virtual;
         procedure      Remove(); virtual;
         procedure      StartEnumeration( Forward: boolean = true); virtual;
         function       Next():           boolean; virtual;
         procedure      RemoveAll( DestroyElements: boolean = false); virtual; // Remove all elements from the list.
         function       IsEmpty():        boolean; virtual;
         function       IsFirst():        boolean; virtual; // True if CurrentNode is First
         function       IsLast():         boolean; virtual;
         function       GetCurrent():     T virtual; // Returns the data pointer at CurrentNode
         function       GetEnumerator():  tEnumerator;
         function       Reverse():        tEnumerator;
      private
         procedure      DestroyValue( Args: array of const);
      public
         property       Head:             T read DelHead write AddHead;
         property       Tail:             T read DelTail write AddTail;
         property       Stack:            T read DelTail write AddTail;
         property       Push:             T write AddTail;
         property       Pop:              T read DelTail;
         property       Queue:            T read DelHead write AddTail;
         property       Enqueue:          T write AddTail;
         property       Dequeue:          T read DelHead;
         property       Value:            T read GetCurrent write Replace;
         property       Length:           Int32 read ListLength;
   end; // generic tgDoubleLinkedList


// ************************************************************************

implementation



// ========================================================================
// = tgDoubleLinkedList.tNode generic class
// ========================================================================
// ************************************************************************
// * Constructors
// ************************************************************************

constructor tgDoubleLinkedList.tNode.Create( MyItem: V = Default( T));
  // Makes a new and empty List
  begin
     Item:= MyItem;
     Prev:= nil;
     Next:= nil;
  end; // Create()


// ========================================================================
// = tgDoubleLinkedList.tEnumerator generic class
// ========================================================================
// ************************************************************************
// * Create() - constructor
// ************************************************************************

constructor tgDoubleLinkedList.tEnumerator.Create( List: tgDoubleLinkedList);
   begin
      MyList:= List;
   end; // Create()


// ************************************************************************
// * GetCurrent() - Return the current list element
// ************************************************************************

function tgDoubleLinkedList.tEnumerator.GetCurrent(): V;
   begin
      result:= MyList.CurrentNode.Item;
   end; // GetCurrent()


// ************************************************************************
// * MoveNext() - Move to the next element in the list
// ************************************************************************

function tgDoubleLinkedList.tEnumerator.MoveNext(): V;
   begin
      result:= MyList.NextNode;
   end; // MoveNext()



// ========================================================================
// = tgDoubleLinkedList generic class
// ========================================================================
// ************************************************************************
// * Constructors
// ************************************************************************

constructor tgDoubleLinkedList.Create( const iName: String);
  // Makes a new and empty List
  begin
     FirstNode:=    Nil;
     LastNode:=     Nil;
     CurrentNode:=  Nil;
     Name:=         iName;
     ListLength:=   0;
     MyForward:=    true;
  end; // Create()


// ************************************************************************
// * Destructor
// ************************************************************************

destructor tgDoubleLinkedList.Destroy;

   begin
      if( FirstNode <> nil) then begin
         raise lbpContainerException.Create(
            'List ' + Name + ' is not empty and can not be destroyed!');
      end;
      inherited Destroy;
   end; // Destroy();


// ************************************************************************
// * AddHead()  - Adds an Object to the front of the list
// ************************************************************************

procedure tgDoubleLinkedList.AddHead( Item: V);
   var
      N: tNode;
   begin
      N:= tNode.Create( Item);
      if( FirstNode = nil) then begin
         LastNode:= N;
      end else begin
         FirstNode.PrevNode:= N;
         N.NextNode:= FirstNode;
      end;
     FirstNode:= N;
     CurrentNode:= nil;
     ListLength += 1;
   end; // AddHead()


// ************************************************************************
// * GetHead()  - Returns the first element of the list
// ************************************************************************

function tgDoubleLinkedList.GetHead(): V;
   begin
      if( FirstNode = nil) then begin
         raise lbpContainerException.Create( 'Attempt to get an element from an empty list!');
      end else begin
         result:= FirstNode.Item;
      end;
   end;  // GetHead()


// ************************************************************************
// * DelHead()  - Returns the first element and removes it from the list
// ************************************************************************

function tgDoubleLinkedList.DelHead(): V;
   var
      N: tNode;
   begin
      if( LastNode = nil) then begin
         raise lbpContainerException.Create( 'Attempt to get an element from an empty list!');
      end else begin
         N:= FirstNode;
         // Adjust Pointers
         // If only one element in list
         if FirstNode = LastNode then begin
            LastNode:= nil;
            FirstNode:= nil;
         end
         else begin
            FirstNode.NextNode.PrevNode:= nil;
            FirstNode:= FirstNode.NextNode;
         end;
         result:= N.Item;
         N.Destroy;
         ListLength -= 1;
      end; // if Empty
      CurrentNode:= nil;
   end;  // DelHead()


// ************************************************************************
// * AddTail() - Adds the object to the end of the list.
// *             Pushes an object on the stack.
// ************************************************************************

procedure tgDoubleLinkedList.AddTail( Item: V);
   var
      N: tNode;
   begin
      N:= tNode.Create( Item);
      if( LastNode = nil) then begin
         FirstNode:= N;
      end else begin
         LastNode.NextNode:= N;
         N.PrevNode:= LastNode;
      end;
     LastNode:= N;
     CurrentNode:= nil;
     ListLength += 1;
   end; // AddTail()


// ************************************************************************
// * GetTail()  - Returns the last element in the list and removes it from
// *              the list.
// ************************************************************************

function tgDoubleLinkedList.GetTail: V;
   begin
      if( LastNode = nil) then begin
         raise lbpContainerException.Create( 'Attempt to get an element from an empty list!');
      end else begin
         result:= LastNode.Item;
      end; // if Empty
   end;  // GetTail()


// ************************************************************************
// * DelTail()  - Returns the last element in the list and removes it from
// *              the list.
// ************************************************************************

function tgDoubleLinkedList.DelTail: T;
   var
      N: VNode;
   begin
      if( LastNode = nil) then begin
         raise lbpContainerException.Create( 'Attempt to get an element from an empty list!');
      end else begin
         N:= LastNode;
         // Adjust Pointers
         // If only one element in list
         if FirstNode = LastNode then begin
            LastNode:= Nil;
            FirstNode:=Nil;
         end else begin
            LastNode.PrevNode.NextNode:= Nil;
            LastNode:= LastNode.PrevNode;
         end;
         result:= N.Item;

         N.Destroy;
         ListLength -= 1;
      end; // if Empty
      CurrentNode:= nil;
   end;  // DelTail()


// ************************************************************************
// * InsertBeforeCurrent()  - Places an object in the list in front
// *                          of the current object.
// ************************************************************************

procedure tgDoubleLinkedList.InsertBeforeCurrent( Item: V);
   var
      N:  tNode;
   begin
      if( (CurrentNode = nil) or (CurrentNode = FirstNode)) then begin
         AddHead( Item);
      end else begin // There is a node in front of the current node
         N:= tNode.Create( Item);
         // Insert N in between the node in front of current and current
         N.NextNode:= CurrentNode;
         N.PrevNode:= CurrentNode.PrevNode;
         N.PrevNode.NextNode:= N;
         N.NextNode.PrevNode:= N;
         CurrentNode:= nil;
         ListLength += 1;
      end;
   end; // InsertBeforeCurrent()


// ************************************************************************
// * InsertAfterCurrent()  - Places an object in the list behind
// *                         the current object.
// ************************************************************************

procedure tgDoubleLinkedList.InsertAfterCurrent( Item: V);
   var
      N:  tNode;
   begin
      if( (CurrentNode = nil) or (CurrentNode = LastNode)) then begin
         AddTail( Item);  // Add to tail
      end else begin // There is a node after the current node
         N:= tNode.Create( Item);
         // Insert N in between the node after the current and current
         N.NextNode:= CurrentNode.NextNode;
         N.PrevNode:= CurrentNode;
         N.PrevNode.NextNode:= N;
         N.NextNode.PrevNode:= N;
         CurrentNode:= nil;
         ListLength += 1;
      end;
   end; // InsertAfterCurrent()


// ************************************************************************
// * Replace()  - Replaces the first occurance of OldObj with NewObj.
// ************************************************************************

procedure tgDoubleLinkedList.Replace( OldItem, NewItem: V);
   var
      N: tNode;
   begin
      if( FirstNode = nil) then
         raise lbpContainerException.Create( 'Old Item not found in list')
      else begin
         // Find the node
         N:= FirstNode;
         while (N <> nil) and (N.Item <> OldItem) do
            N:= N.NextNode;
         if (N = nil) then
            raise lbpContainerException.Create( 'Old Item not found in list')
         else
            N.Item:= NewItem;
         CurrentNode:= nil;
      end;
   end; // DoubleLinkedList.Replace


// ------------------------------------------------------------------------

procedure tgDoubleLinkedList.Replace( NewItem: V);
   begin
      if( CurrentNode <> nil) then begin
         CurrentNode.Item:= NewItem;
      end;
   end; // Replace()


// ************************************************************************
// * Remove()  - Removes the first occurance of Obj in the list.
// ************************************************************************

procedure tgDoubleLinkedList.Remove( Item: T);
   var
      N: VNode;
   begin
      if( FirstNode = nil) then
         raise lbpContainerException.Create( 'Item not found in list')
      else begin
         // Find the node
         N:= FirstNode;
         while (N <> nil) and (N.Item <> Item) do
            N:= N.NextNode;
         if (N = nil) then
            raise lbpContainerException.Create( 'Old Item not found in list');

         // Adjust Pointers
         if N.NextNode = nil then LastNode:= N.PrevNode
         else N.NextNode.PrevNode:= N.PrevNode;
         if N.PrevNode = nil then FirstNode:= N.NextNode
         else N.PrevNode.NextNode:= N.NextNode;
         N.Destroy;
         ListLength -= 1;
      end; // else not Empty
      CurrentNode:= nil;
   end;  // Remove ()


// ------------------------------------------------------------------------

procedure tgDoubleLinkedList.Remove();
   begin
      if (CurrentNode = nil) then exit;
         raise lbpContainerException.Create( 'The is no current item to remove from the list.');

      // Adjust Pointers
      if CurrentNode.NextNode = Nil then LastNode:= CurrentNode.PrevNode
      else CurrentNode.NextNode.PrevNode:= CurrentNode.PrevNode;
      if CurrentNode.PrevNode = Nil then FirstNode:= CurrentNode.NextNode
      else CurrentNode.PrevNode.NextNode:= CurrentNode.NextNode;
      CurrentNode.Destroy;
      ListLength -= 1;
      CurrentNode:= nil;
   end;  // Remove()


// ************************************************************************
// * RemoveAll()  - Removes all elements from the list.  If DestroyElements
// *                is true, each element's destructor will be called.
// ************************************************************************

procedure tgDoubleLinkedList.RemoveAll( DestroyElements: boolean);
   var
      Item: V;
   begin
      StartEnumeration;
      while( FirstNode <> nil) do begin
         Item:= Dequeue;
         if( DestroyElements) then DestroyValue( [Item]);
      end;
   end; // RemoveAll()


// ************************************************************************
// * StartEnumeration() - Begin the iteration
// ************************************************************************

procedure tgDoubleLinkedList.StartEnumeration( Forward: boolean);
   begin
      MyForward:= Forward;  // Set the direction
      CurrentNode:= nil;
   end; // StartEnumeration

// ************************************************************************
// * Next() -
// ************************************************************************

function tgDoubleLinkedList.NextNode(): boolean;
   begin
      if( CurrentNode = nil) then begin
         if( MyForward) then CurrentNode:= FirstNode else CurrentNode:= LastNode;
      end else begin
         if( MyForward) then CurrentNode:= CurrentNode.NextNode else CurrentNode:= CurrentNode.PrevNode;
      end;
      result:= (CurrentNode <> nil);
   end; // Next()


// ************************************************************************
// * IsEmpty()  - Returns true if the list is empty
// ************************************************************************

function tgDoubleLinkedList.IsEmpty(): boolean;
   // Tests to see if the list is empty
   begin
     result:= (FirstNode = nil);
   end; // IsEmpty()


// ************************************************************************
// * IsFirst()  - Returns true if the current item is also first
// ************************************************************************

function tgDoubleLinkedList.IsFirst(): boolean;
   begin
     result:= (FirstNode <> nil) and (CurrentNode = FirstNode);
   end; // IsFirst()


// ************************************************************************
// * IsLast()  - Returns true if the current item is also last
// ************************************************************************

function tgDoubleLinkedList.IsLast(): boolean;
   begin
     result:= (LastNode <> nil) and (CurrentNode = LastNode);
   end; // IsLast()


// ************************************************************************
// * GetCurrent()  - Returns the current item in the list.
// *                 Does not remove it from the list.
// ************************************************************************

function tgDoubleLinkedList.GetCurrent(): V;
   begin
      if CurrentNode = nil then
         raise lbpContainerException.Create( 'The is no current item to remove from the list.')
      else
         result:= CurrentNode.Item;
   End; // GetCurrent()


// ************************************************************************
// * GetEnumerator()  - Returns the enumerator
// ************************************************************************

function tgDoubleLinkedList.GetEnumerator():  tEnumerator;
   begin
      result:= tEnumerator.Create( Self);
      CurrentNode:= nil;
      MyForward:= true;
   end; // GetEnumerator()


// ************************************************************************
// * Reverse()  - Returns the enumerator
// ************************************************************************

function tgDoubleLinkedList.Reverse():  tEnumerator;
   begin
      result:= tEnumerator.Create( Self);
      CurrentNode:= nil;
      MyForward:= false;
   end; // Reverse()


// ************************************************************************
// * DestroyValue() - If the passed value is a class, call its destructor
// *                  This should only be used internally and will always
// *                  be passed a single value.
// ************************************************************************

procedure tgDoubleLinkedList.DestroyValue( Args: array of const);
   begin
      if( Args[ 0].vtype = vtClass) then tObject( Args[ 0].vClass).Destroy();
   end; // DestroyValue;



// ************************************************************************

end. // lbp_generic_containers unit
