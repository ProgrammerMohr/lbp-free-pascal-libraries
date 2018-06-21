{* ***************************************************************************

Copyright (c) 2018 by Lloyd B. Park

Queues and Stacks using a ring buffer

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

unit lbp_generic_ring_buffer;
// Creates queues and stacks of items using a circular buffer.
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
   lbp_types;     // int32


// ************************************************************************

type
   lbpListException = class( lbp_exception);

// ************************************************************************

type
      generic tgList< T> = class( tObject)
         private type
         // ---------------------------------------------------------------
            tgListEnumerator = class(tObject)
               private
                  MyList: tgList;
               public
                  constructor Create( List: tgList);
               private
                  function GetCurrent(): T;
               public
                  function MoveNext(): boolean;
                  property Current: T read GetCurrent;
               end; // tgLListEnumerator
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
            function  IncIndex( I: integer): integer;
            function  DecIndex( I: integer): integer;
         public
            procedure      AddHead( Item: T); virtual; // Add to the head of the list
            function       GetHead(): T; virtual;      // Return the head element.
            function       RemoveHead(): T; virtual;      // Return the head element and remove it from the list.
            procedure      AddTail( Item: T); virtual; // Add to the tail of the list
            function       GetTail(): T; virtual;      // Return the head element
            function       RemoveTail(): T; virtual;      // Return the head element and remove it from the list.
            
            procedure      Empty(); virtual;
            procedure      StartIteration( Forward: boolean = true); virtual;
            function       Next():           boolean; virtual;
            function       IsEmpty():        boolean; virtual;
            function       IsFull():         boolean; virtual;
            function       IsFirst():        boolean; virtual; // True if CurrentNode is First
            function       IsLast():         boolean; virtual;
            function       GetCurrent():     T;       virtual; // Returns the data pointer at CurrentNode
            procedure      Replace( Item: T); virtual; 
//            function       Length():         integer; virtual;
            function       GetEnumerator():  tgListEnumerator;
            function       Reverse():        tgListEnumerator;
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
      end; // generic tgList


// ************************************************************************



// ************************************************************************

implementation


/// ========================================================================
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
// * GetEnumerator()  - Returns the enumerator
// ************************************************************************

function tgList.GetEnumerator():  tgListEnumerator;
   begin
      result:= tgListEnumerator.Create( Self);
      CurrentIndex:= -1;
      MyForward:= true;
   end; // GetEnumerator()


// ************************************************************************
// * Reverse()  - Returns the enumerator
// ************************************************************************

function tgList.Reverse():  tgListEnumerator;
   begin
      result:= tgListEnumerator.Create( Self);
      CurrentIndex:= -1;
      MyForward:= false;
   end; // Reverse()


// ------------------------------------------------------------------------
// -  tgListEnumerator
// ------------------------------------------------------------------------
// ************************************************************************
// * Create() - constructor
// ************************************************************************

constructor tgList.tgListEnumerator.Create( List: tgList);
   begin
      inherited Create;
      List.CurrentIndex:= -1;
      MyList:= List;
   end; // Create()


// ************************************************************************
// * GetCurrent() - Return the current list element
// ************************************************************************

function tgList.tgListEnumerator.GetCurrent(): T;
   begin
      result:= MyList.Items[ MyList.CurrentIndex];
   end; // GetCurrent()


// ************************************************************************
// * MoveNext() - Move to the next element in the list
// ************************************************************************

function tgList.tgListEnumerator.MoveNext(): T;
   begin
      result:= MyList.Next;
   end; // MoveNext()


// ************************************************************************

end. // lbp_generic_ring_buffer
