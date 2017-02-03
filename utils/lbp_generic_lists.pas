{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

linked list classes which use generics

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

unit lbp_generic_Lists;
// Creates generic lists of pointers to items.
//
// Push and Enqueue do the same thing, add to the end of the list.
//    AddToFront does the oposite.
// Pop removes from the end of the list
// Dequeue removes from the beginning of the list.

interface

{$include lbp_standard_modes.inc}
//{$V-}    //Added by LP because it says so below
//{$R-}    //Range checking off
//{$S-}    //Stack checking off
//{$I-}    //I/O checking off
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

uses
   sysutils,       // Exceptions
   lbp_types,     // int32
   lbp_vararray;  // Int64SortElement


// ************************************************************************

   type
      generic tgListNode< T> = class( tObject)
         protected
            Item:    T;
            Prev:    tgListNode;
            Next:    tgListNode;
         public
            constructor  Create( MyItem: T = Default( T));
         end; // tgListNode class


// ************************************************************************

type
   generic tgDLListEnumerator<T> = class(tObject)
      public
         MyList: tObject;
         constructor Create( List: tObject);
         function GetCurrent(): T;
         function MoveNext(): boolean;
         property Current: T read GetCurrent;
      end; // tgDLListEnumerator


// ************************************************************************

   type
      DoubleLinkedListException = class( lbp_exception);
      generic tgDoubleLinkedList< T> = class( tObject)
            //public type tListNodePtr = ^tListNode;
         private type
            tListNode = specialize tgListNode< T>;
            tListEnumerator = specialize tgDLListEnumerator< T>;
         public
            Name:          String;
         public
            FirstNode:     tListNode;
            LastNode:      tListNode;
            CurrentNode:   tListNode;
            ListLength:    Int32;
            MyForward:     boolean;
         public
            constructor    Create( const iName: string = '');
            destructor     Destroy; override;
            procedure      AddHead( Item: T); virtual; // Add to the head of the list
            function       GetHead(): T; virtual;      // Return the head element.
            function       DelHead(): T; virtual;      // Return the head element and remove it from the list.
            procedure      AddTail( Item: T); virtual; // Add to the tail of the list
            function       GetTail(): T; virtual;      // Return the head element
            function       DelTail(): T; virtual;      // Return the head element and remove it from the list.
            procedure      InsertBeforeCurrent( Item: T); virtual;
            procedure      InsertAfterCurrent( Item: T); virtual;
            procedure      Replace( OldItem, NewItem: T); virtual;
            procedure      Replace( NewItem: T); virtual;
            procedure      Remove( Item: T); virtual;
            procedure      Remove(); virtual;
            procedure      RemoveAll(); virtual;
            procedure      StartIteration( Forward: boolean = true); virtual;
            function       Next():           boolean; virtual;
//            procedure      RemoveAll( DestroyElements: boolean = false); virtual; // Remove all elements from the list.
            function       IsEmpty():        boolean; virtual;
            function       IsFirst():        boolean; virtual; // True if CurrentNode is First
            function       IsLast():         boolean; virtual;
            function       GetCurrent():     T virtual; // Returns the data pointer at CurrentNode
            function       GetEnumerator():  tListEnumerator;
            function       Reverse():        tListEnumerator;
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


/// ========================================================================
// = tgListNode generic class
// ========================================================================
// ************************************************************************
// * Constructors
// ************************************************************************

constructor tgListNode.Create( MyItem: T = Default( T));
  // Makes a new and empty List
  begin
     Item:= MyItem;
     Prev:= nil;
     Next:= nil;
  end; // Create()


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
         raise DoubleLinkedListException.Create(
            'List ' + Name + ' is not empty and can not be destroyed!');
      end;
      inherited Destroy;
   end; // Destroy();


// ************************************************************************
// * AddHead()  - Adds an Object to the front of the list
// ************************************************************************

procedure tgDoubleLinkedList.AddHead( Item: T);
   var
      N: tListNode;
   begin
      N:= tListNode.Create( Item);
      if( FirstNode = nil) then begin
         LastNode:= N;
      end else begin
         FirstNode.Prev:= N;
         N.Next:= FirstNode;
      end;
     FirstNode:= N;
     CurrentNode:= nil;
     ListLength += 1;
   end; // AddHead()


// ************************************************************************
// * GetHead()  - Returns the first element of the list
// ************************************************************************

function tgDoubleLinkedList.GetHead(): T;
   begin
      if( FirstNode = nil) then begin
         raise DoubleLinkedListException.Create( 'Attempt to get an element from an empty list!');
      end else begin
         result:= FirstNode.Item;
      end;
   end;  // GetHead()


// ************************************************************************
// * DelHead()  - Returns the first element and removes it from the list
// ************************************************************************

function tgDoubleLinkedList.DelHead(): T;
   var
      N: tListNode;
   begin
      if( LastNode = nil) then begin
         raise DoubleLinkedListException.Create( 'Attempt to get an element from an empty list!');
      end else begin
         N:= FirstNode;
         // Adjust Pointers
         // If only one element in list
         if FirstNode = LastNode then begin
            LastNode:= nil;
            FirstNode:= nil;
         end
         else begin
            FirstNode.Next.Prev:= nil;
            FirstNode:= FirstNode.Next;
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

procedure tgDoubleLinkedList.AddTail( Item: T);
   var
      N: tListNode;
   begin
      N:= tListNode.Create( Item);
      if( LastNode = nil) then begin
         FirstNode:= N;
      end else begin
         LastNode.Next:= N;
         N.Prev:= LastNode;
      end;
     LastNode:= N;
     CurrentNode:= nil;
     ListLength += 1;
   end; // AddTail()


// ************************************************************************
// * GetTail()  - Returns the last element in the list and removes it from
// *              the list.
// ************************************************************************

function tgDoubleLinkedList.GetTail: T;
   begin
      if( LastNode = nil) then begin
         raise DoubleLinkedListException.Create( 'Attempt to get an element from an empty list!');
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
      N: tListNode;
   begin
      if( LastNode = nil) then begin
         raise DoubleLinkedListException.Create( 'Attempt to get an element from an empty list!');
      end else begin
         N:= LastNode;
         // Adjust Pointers
         // If only one element in list
         if FirstNode = LastNode then begin
            LastNode:= Nil;
            FirstNode:=Nil;
         end else begin
            LastNode.Prev.Next:= Nil;
            LastNode:= LastNode.Prev;
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

procedure tgDoubleLinkedList.InsertBeforeCurrent( Item: T);
   var
      N:  tListNode;
   begin
      if( (CurrentNode = nil) or (CurrentNode = FirstNode)) then begin
         AddHead( Item);
      end else begin // There is a node in front of the current node
         N:= tListNode.Create( Item);
         // Insert N in between the node in front of current and current
         N.Next:= CurrentNode;
         N.Prev:= CurrentNode.Prev;
         N.Prev.Next:= N;
         N.Next.Prev:= N;
         CurrentNode:= nil;
         ListLength += 1;
      end;
   end; // InsertBeforeCurrent()


// ************************************************************************
// * InsertAfterCurrent()  - Places an object in the list behind
// *                         the current object.
// ************************************************************************

procedure tgDoubleLinkedList.InsertAfterCurrent( Item: T);
   var
      N:  tListNode;
   begin
      if( (CurrentNode = nil) or (CurrentNode = LastNode)) then begin
         AddTail( Item);  // Add to tail
      end else begin // There is a node after the current node
         N:= tListNode.Create( Item);
         // Insert N in between the node after the current and current
         N.Next:= CurrentNode.Next;
         N.Prev:= CurrentNode;
         N.Prev.Next:= N;
         N.Next.Prev:= N;
         CurrentNode:= nil;
         ListLength += 1;
      end;
   end; // InsertAfterCurrent()


// ************************************************************************
// * Replace()  - Replaces the first occurance of OldObj with NewObj.
// ************************************************************************

procedure tgDoubleLinkedList.Replace( OldItem, NewItem: T);
   var
      N: tListNode;
   begin
      if( FirstNode = nil) then
         raise DoubleLinkedListException.Create( 'Old Item not found in list')
      else begin
         // Find the node
         N:= FirstNode;
         while (N <> nil) and (N.Item <> OldItem) do
            N:= N.Next;
         if (N = nil) then
            raise DoubleLinkedListException.Create( 'Old Item not found in list')
         else
            N.Item:= NewItem;
         CurrentNode:= nil;
      end;
   end; // DoubleLinkedList.Replace


// ------------------------------------------------------------------------

procedure tgDoubleLinkedList.Replace( NewItem: T);
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
      N: tListNode;
   begin
      if( FirstNode = nil) then
         raise DoubleLinkedListException.Create( 'Item not found in list')
      else begin
         // Find the node
         N:= FirstNode;
         while (N <> nil) and (N.Item <> Item) do
            N:= N.Next;
         if (N = nil) then
            raise DoubleLinkedListException.Create( 'Old Item not found in list');

         // Adjust Pointers
         if N.Next = nil then LastNode:= N.Prev
         else N.Next.Prev:= N.Prev;
         if N.Prev = nil then FirstNode:= N.Next
         else N.Prev.Next:= N.Next;
         N.Destroy;
         ListLength -= 1;
      end; // else not Empty
      CurrentNode:= nil;
   end;  // Remove ()


// ------------------------------------------------------------------------

procedure tgDoubleLinkedList.Remove();
   begin
      if (CurrentNode = nil) then exit;
         raise DoubleLinkedListException.Create( 'The is no current item to remove from the list.');

      // Adjust Pointers
      if CurrentNode.Next = Nil then LastNode:= CurrentNode.Prev
      else CurrentNode.Next.Prev:= CurrentNode.Prev;
      if CurrentNode.Prev = Nil then FirstNode:= CurrentNode.Next
      else CurrentNode.Prev.Next:= CurrentNode.Next;
      CurrentNode.Destroy;
      ListLength -= 1;
      CurrentNode:= nil;
   end;  // Remove()


// ************************************************************************
// * RemoveAll()  - Removes all elements from the list.  It is up to the
// *                user to make sure each element is properly discarded.
// *                If DestroyElements is true, it is assumed each element
// *                is an instance of some class.
// ************************************************************************

procedure tgDoubleLinkedList.RemoveAll();
   begin
      StartIteration;
      while( FirstNode <> nil) do begin
         Dequeue;
      end;
   end; // RemoveAll()


// ************************************************************************
// * StartIteration() - Begin the iteration
// ************************************************************************

procedure tgDoubleLinkedList.StartIteration( Forward: boolean);
   begin
      MyForward:= Forward;  // Set the direction
      CurrentNode:= nil;
   end; // StartIteration

// ************************************************************************
// * Next() -
// ************************************************************************

function tgDoubleLinkedList.Next(): boolean;
   begin
      if( CurrentNode = nil) then begin
         if( MyForward) then CurrentNode:= FirstNode else CurrentNode:= LastNode;
      end else begin
         if( MyForward) then CurrentNode:= CurrentNode.Next else CurrentNode:= CurrentNode.Prev;
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

function tgDoubleLinkedList.GetCurrent(): T;
   begin
      if CurrentNode = nil then
         raise DoubleLinkedListException.Create( 'The is no current item to remove from the list.')
      else
         result:= CurrentNode.Item;
   End; // GetCurrent()


// ************************************************************************
// * GetEnumerator()  - Returns the enumerator
// ************************************************************************

function tgDoubleLinkedList.GetEnumerator():  tListEnumerator;
   begin
      result:= tListEnumerator.Create( Self);
      CurrentNode:= nil;
      MyForward:= true;
   end; // GetEnumerator()


// ************************************************************************
// * Reverse()  - Returns the enumerator
// ************************************************************************

function tgDoubleLinkedList.Reverse():  tListEnumerator;
   begin
      result:= tListEnumerator.Create( Self);
      CurrentNode:= nil;
      MyForward:= false;
   end; // Reverse()



// ========================================================================
// = tgDLListEnumerator generic class
// ========================================================================
// ************************************************************************
// * Create() - constructor
// ************************************************************************

constructor tgDLListEnumerator.Create( List: tObject);
   begin
      MyList:= List;
   end; // Create()


// ************************************************************************
// * GetCurrent() - Return the current list element
// ************************************************************************

function tgDLListEnumerator.GetCurrent(): T;
   begin
      result:= tgDoubleLinkedList( MyList).CurrentNode.Item;
   end; // GetCurrent()


// ************************************************************************
// * MoveNext() - Move to the next element in the list
// ************************************************************************

function tgDLListEnumerator.MoveNext(): T;
   begin
      result:= tgDoubleLinkedList( MyList).Next;
   end; // MoveNext()


// ************************************************************************

end. // lbp_generic_lists unit
