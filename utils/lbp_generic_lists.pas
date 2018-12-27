{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

linked list and ring buffer/circular list which use generics

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
// Creates generic lists items.
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
   lbpListException = class( lbp_exception);

// ************************************************************************

type
   generic tgList< T> = class( tObject)
      private type
      // ---------------------------------------------------------------
         tEnumerator = class(tObject)
            private
               MyList: tgList;
            public
               constructor Create( List: tgList);
            private
               function GetCurrent(): T;
            public
               function MoveNext(): boolean;
               property Current: T read GetCurrent;
            end; // tEnumerator
      // ---------------------------------------------------------------
      public
         Name:          String;
      protected
         MySize:        integer;
         SizeM:         integer; // MySize - 1
         MyHead:        integer;
         MyTail:        integer;
         CurrentIndex:  integer;
         MyForward:     boolean;
         Items:         array of T;
      public
         constructor    Create( const iSize: integer; iName: string = '');
      protected
         function       IncIndex( I: integer): integer; virtual;
         function       DecIndex( I: integer): integer; virtual;
         procedure      AddHead( Item: T); virtual; // Add to the head of the list
         function       GetHead(): T; virtual;      // Return the head element.
         function       RemoveHead(): T; virtual;      // Return the head element and remove it from the list.
         procedure      AddTail( Item: T); virtual; // Add to the tail of the list
         function       GetTail(): T; virtual;      // Return the tail element
         function       RemoveTail(): T; virtual;      // Return the tail element and remove it from the list.
         function       GetByIndex( i: integer): T; virtual;
      public
         procedure      Empty(); virtual;
         procedure      StartIteration( Forward: boolean = true); virtual;
         function       Next():           boolean; virtual;
         function       IsEmpty():        boolean; virtual;
         function       IsFull():         boolean; virtual;
         function       IsFirst():        boolean; virtual; // True if CurrentNode is First
         function       IsLast():         boolean; virtual;
         function       GetCurrent():     T;       virtual; // Returns the data pointer at CurrentNode
         procedure      Replace( Item: T); virtual; 
         function       Length():         integer; virtual;
         function       GetEnumerator():  tEnumerator; virtual;
         function       Reverse():        tEnumerator; virtual;
         property       Head:             T read RemoveHead write AddHead;
         property       Tail:             T read RemoveTail write AddTail;
         property       Stack:            T read RemoveTail write AddTail;
         property       Push:             T write AddTail;
         property       Pop:              T read RemoveTail;
         property       Queue:            T read RemoveHead write AddTail;
         property       Enqueue:          T write AddTail;
         property       Dequeue:          T read RemoveHead;
         property       Value:            T read GetCurrent write Replace;
         property       Forward:    boolean read MyForward write MyForward;
         property       Peek[ i: integer]: T read GetByIndex;
   end; // generic tgList


// ************************************************************************

type
   generic tgDoubleLinkedList< T> = class( tObject)
         //public type tListNodePtr = ^tListNode;
      private type
         // ---------------------------------------------------------------
         tListNode = class( tObject)
            protected
               Item:    T;
               Prev:    tListNode;
               Next:    tListNode;
            public
               constructor  Create( MyItem: T = Default( T));
            end; // tgListNode class
         // ---------------------------------------------------------------
         tEnumerator = class(tObject)
            public
               MyList: tgDoubleLinkedList;
               constructor Create( List: tgDoubleLinkedList);
               function GetCurrent(): T;
               function MoveNext(): boolean;
               property Current: T read GetCurrent;
            end; // tEnumerator
         // ---------------------------------------------------------------
      public
         Name:          String;
      protected
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
         function       GetEnumerator():  tEnumerator;
         function       Reverse():        tEnumerator;
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
// = tgList generic class
// ========================================================================
// ************************************************************************
// * Constructors
// ************************************************************************

constructor tgList.Create( const iSize: integer; iName: string = '');
   begin
      inherited Create;
      MySize:= iSize + 2;
      SizeM:=  iSize + 1;
      Name:=   iName;
      SetLength( Items, MySize);
      MyHead:= 0;
      MyTail:= 1;
      MyForward:= true;
      CurrentIndex:= -1;
   end; // Create()


// ************************************************************************
// * IncIndex() - Increment the passed index and return the value
// ************************************************************************

function tgList.IncIndex( I: integer): integer;
   begin
      result:= (I + 1) mod MySize; 
   end; // IncIndex()


// ************************************************************************
// * DecIndex() - Decrement the passed index and return the value
// ************************************************************************

function tgList.DecIndex( I: integer): integer;
   begin
      result:= (I + SizeM) mod MySize; 
   end; // DecIndex();


// ************************************************************************
// * AddHead() - Add an item to the head of the list
// ************************************************************************

procedure tgList.AddHead( Item: T);
   begin
      if( IsFull) then begin
         raise lbpListException.Create( 'An attempt was made to add an item to a circular list which is full!');
      end;

      Items[ MyHead]:= Item;
      MyHead:= DecIndex( MyHead);
      CurrentIndex:= -1;
   end; // AddHead()


// ************************************************************************
// * GetHead() - Returns the Item at the Head
// ************************************************************************

function tgList.GetHead(): T;
   begin
      if( IsEmpty) then begin
         raise lbpListException.Create( 'An attempt was made to get an item from an empty list');
      end;
      CurrentIndex:= -1;
      result:= Items[ IncIndex( MyHead)];
   end; // GetHead()


// ************************************************************************
// * RemoveHead() - Removes and returns the Item at the Head
// ************************************************************************

function tgList.RemoveHead(): T;
   begin
      if( IsEmpty) then begin
         raise lbpListException.Create( 'An attempt was made to get an item from an empty list');
      end;
      MyHead:= IncIndex( MyHead);
      result:= Items[ MyHead];
      CurrentIndex:= -1;
   end; // RemoveHead()


// ************************************************************************
// * AddTail() - Add an item to the Tail of the list
// ************************************************************************

procedure tgList.AddTail( Item: T);
   begin
      if( IsFull) then begin
         raise lbpListException.Create( 'An attempt was made to add an item to a circular list which is full!');
      end;

      Items[ MyTail]:= Item;
      MyTail:= IncIndex( MyTail);
      CurrentIndex:= -1;
   end; // AddTail()


// ************************************************************************
// * GetTail() - Returns the Item at the Tail
// ************************************************************************

function tgList.GetTail(): T;
   begin
      if( IsEmpty) then begin
         raise lbpListException.Create( 'An attempt was made to get an item from an empty list');
      end;
      CurrentIndex:= -1;
      result:= Items[ DecIndex( MyTail)];
   end; // GetTail()


// ************************************************************************
// * RemoveTail() - Removes and returns the Item at the Tail
// ************************************************************************

function tgList.RemoveTail(): T;
   begin
      if( IsEmpty) then begin
         raise lbpListException.Create( 'An attempt was made to get an item from an empty list');
      end;
      MyTail:= DecIndex( MyTail);
      result:= Items[ MyTail];
      CurrentIndex:= -1;
   end; // RemoveTail()


// ************************************************************************
// * GetByIndex() - Return the i'th element.  The first element is #1
// ************************************************************************

function tgList.GetByIndex( i: integer): T;
   begin
      if( (i <= 0) or (i > Length)) then begin
         raise lbpListException.Create( 'tgList index out of bounds!');
      end;

      result:= Items[ (MyHead + i) mod MySize];
   end; // GetByIndex()


// ************************************************************************
// * RemoveAll() - Remove all elements from the list.  No destructors are
//                 called!
// ************************************************************************

procedure tgList.Empty;
   begin
      MyHead:= 0;
      MyTail:= 1;
      MyForward:= true;
      CurrentIndex:= -1;   
   end; // RemoveAll


// ************************************************************************
// * StartIteration() - Begin the iteration
// ************************************************************************

procedure tgList.StartIteration( Forward: boolean);
   begin
      MyForward:= Forward;  // Set the direction
      CurrentIndex:= -1;
   end; // StartIteration


// ************************************************************************
// * Next() - Returns true if the buffer is empty
// ************************************************************************

function tgList.Next(): boolean;
   begin
      // If Empty
      if( (MyTail = IncIndex( MyHead))) then begin
         result:= false;
      end else begin
         if( MyForward) then begin
            if( CurrentIndex < 0) then CurrentIndex:= MyHead;
            CurrentIndex:= IncIndex( CurrentIndex);
            if( CurrentIndex = MyTail) then CurrentIndex:= -1;  
         end else begin
            if( CurrentIndex < 0) then CurrentIndex:= MyTail;
            CurrentIndex:= DecIndex( CurrentIndex);
            if( CurrentIndex = MyHead) then CurrentIndex:= -1;  
         end; // else not MyForward
         result:= ( CurrentIndex >= 0);
      end; // else not MyForward
   end; // Next();


// ************************************************************************
// * IsEmpty() - Returns true if the buffer is empty
// ************************************************************************

function tgList.IsEmpty(): boolean;
   begin
      result:= (MyTail = IncIndex( MyHead));
   end; // IsEmpty()


// ************************************************************************
// * IsFull() - Returns true if the buffer is full
// ************************************************************************

function tgList.IsFull(): boolean;
   begin
      result:= (MyHead = IncIndex( MyTail));
   end; // IsFull()


// ************************************************************************
// * IsFirst()  - Returns true if the current item is also first
// ************************************************************************

function tgList.IsFirst(): boolean;
   begin
     result:= (CurrentIndex = IncIndex( MyHead));
   end; // IsFirst()


// ************************************************************************
// * IsLast()  - Returns true if the current item is also last
// ************************************************************************

function tgList.IsLast(): boolean;
   begin
     result:= (CurrentIndex = DecIndex( MyTail));
   end; // IsLast()


// ************************************************************************
// * GetCurrent() - Returns the current element
// ************************************************************************

function tgList.GetCurrent: T;
   begin
      result:= Items[ CurrentIndex];
   end; // GetCurrent;


// ************************************************************************
// * Replace() - Replaces the current element with a new value
// ************************************************************************

procedure tgList.Replace( Item: T);
   begin
      Items[ CurrentIndex]:= Item;   
   end; // Replace()


// ************************************************************************
// * Length() - Returns the number of elements in the list
// ************************************************************************

function tgList.Length(): integer;
   var
      Tl: integer;
   begin
      if( MyTail < MyHead) then Tl:= MyTail + MySize else Tl:= MyTail;
      result:= Tl - MyHead - 1;
   end; // Length()

// ************************************************************************
// * GetEnumerator()  - Returns the enumerator
// ************************************************************************

function tgList.GetEnumerator():  tEnumerator;
   begin
      result:= tEnumerator.Create( Self);
      CurrentIndex:= -1;
      MyForward:= true;
   end; // GetEnumerator()


// ************************************************************************
// * Reverse()  - Returns the enumerator
// ************************************************************************

function tgList.Reverse():  tEnumerator;
   begin
      result:= tEnumerator.Create( Self);
      CurrentIndex:= -1;
      MyForward:= false;
   end; // Reverse()


// ------------------------------------------------------------------------
// -  tEnumerator
// ------------------------------------------------------------------------
// ************************************************************************
// * Create() - constructor
// ************************************************************************

constructor tgList.tEnumerator.Create( List: tgList);
   begin
      inherited Create;
      List.CurrentIndex:= -1;
      MyList:= List;
   end; // Create()


// ************************************************************************
// * GetCurrent() - Return the current list element
// ************************************************************************

function tgList.tEnumerator.GetCurrent(): T;
   begin
      result:= MyList.Items[ MyList.CurrentIndex];
   end; // GetCurrent()


// ************************************************************************
// * MoveNext() - Move to the next element in the list
// ************************************************************************

function tgList.tEnumerator.MoveNext(): T;
   begin
      result:= MyList.Next;
   end; // MoveNext()



// ========================================================================
// = tgDoubleLinkedList.tListNode generic class
// ========================================================================
// ************************************************************************
// * Constructors
// ************************************************************************

constructor tgDoubleLinkedList.tListNode.Create( MyItem: T = Default( T));
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

function tgDoubleLinkedList.tEnumerator.GetCurrent(): T;
   begin
      result:= MyList.CurrentNode.Item;
   end; // GetCurrent()


// ************************************************************************
// * MoveNext() - Move to the next element in the list
// ************************************************************************

function tgDoubleLinkedList.tEnumerator.MoveNext(): T;
   begin
      result:= MyList.Next;
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
         raise lbpListException.Create(
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
         raise lbpListException.Create( 'Attempt to get an element from an empty list!');
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
         raise lbpListException.Create( 'Attempt to get an element from an empty list!');
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
         raise lbpListException.Create( 'Attempt to get an element from an empty list!');
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
         raise lbpListException.Create( 'Attempt to get an element from an empty list!');
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
         raise lbpListException.Create( 'Old Item not found in list')
      else begin
         // Find the node
         N:= FirstNode;
         while (N <> nil) and (N.Item <> OldItem) do
            N:= N.Next;
         if (N = nil) then
            raise lbpListException.Create( 'Old Item not found in list')
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
         raise lbpListException.Create( 'Item not found in list')
      else begin
         // Find the node
         N:= FirstNode;
         while (N <> nil) and (N.Item <> Item) do
            N:= N.Next;
         if (N = nil) then
            raise lbpListException.Create( 'Old Item not found in list');

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
         raise lbpListException.Create( 'The is no current item to remove from the list.');

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
         raise lbpListException.Create( 'The is no current item to remove from the list.')
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

end. // lbp_generic_lists unit
