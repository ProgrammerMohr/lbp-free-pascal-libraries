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
      generic tgList< T> = class( tObject)
//         private type
//            tListNode = specialize tgListNode< T>;
//            tListEnumerator = specialize tgDLListEnumerator< T>;
         public
            Name:          String;
         protected
            MySize:        integer;
            SizeM:         integer; // MySize - 1
            Head:          integer;
            Tail:          integer;
            CurrentIndex:  integer;
            ListLength:    integer;
            MyForward:     boolean;
            Items:         array of T;
         public
            constructor    Create( const iSize: integer; iName: string = '');
         protected
            function  IncIndex( I: integer): integer;
            function  DecIndex( I: integer): integer;

             procedure      AddHead( Item: T); virtual; // Add to the head of the list
             function       GetHead(): T; virtual;      // Return the head element.
             function       DelHead(): T; virtual;      // Return the head element and remove it from the list.
             procedure      AddTail( Item: T); virtual; // Add to the tail of the list
             function       GetTail(): T; virtual;      // Return the head element
             function       DelTail(): T; virtual;      // Return the head element and remove it from the list.
//             procedure      RemoveAll(); virtual;
//             procedure      StartIteration( Forward: boolean = true); virtual;
//             function       Next():           boolean; virtual;
//             procedure      RemoveAll( DestroyElements: boolean = false); virtual; // Remove all elements from the list.
             function       IsEmpty():        boolean; virtual;
             function       IsFull():         boolean; virtual;
//             function       IsFirst():        boolean; virtual; // True if CurrentNode is First
//             function       IsLast():         boolean; virtual;
//             function       GetCurrent():     T virtual; // Returns the data pointer at CurrentNode
//             function       GetEnumerator():  tListEnumerator;
//             function       Reverse():        tListEnumerator;
//             property       Head:             T read DelHead write AddHead;
//             property       Tail:             T read DelTail write AddTail;
//             property       Stack:            T read DelTail write AddTail;
//             property       Push:             T write AddTail;
//             property       Pop:              T read DelTail;
//             property       Queue:            T read DelHead write AddTail;
//             property       Enqueue:          T write AddTail;
//             property       Dequeue:          T read DelHead;
//             property       Value:            T read GetCurrent write Replace;
//             property       Length:           Int32 read ListLength;
      end; // generic tgList


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
      MySize:= iSize + 2;
      SizeM:=  iSize + 1;
      Name:=   iName;
      SetLength( Items, MySize);
      Head:= 0;
      Tail:= 1;
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
   var
      Temp: integer;
   begin
      if( IsFull) then begin
         raise lbpListException.Create( 'An attempt was made to add an item to a circular list which is full!');
      end;

      Items[ Head]:= Item;
      Head:= DecIndex( Head);
   end; // AddHead()


// ************************************************************************
// * GetHead() - Returns the Item at the Head
// ************************************************************************

function tgList.GetHead(): T
   begin
      if( IsEmpty) then begin
         raise lbpListException.Create( 'An attempt was made to get an item from an empty list');
      end;
      CurrentIndex:= IncIndex( Head);
      result:= Items[ CurrentIndex];
   end; // GetHead()


// ************************************************************************
// * DelHead() - Removes and returns the Item at the Head
// ************************************************************************

function tgList.DelHead(): T
   begin
      if( IsEmpty) then begin
         raise lbpListException.Create( 'An attempt was made to get an item from an empty list');
      end;
      CurrentIndex:= IncIndex( Head);
      result:= Items[ CurrentIndex];
   end; // DelHead()


// ************************************************************************
// * AddTail() - Add an item to the Tail of the list
// ************************************************************************

procedure tgList.AddTail( Item: T);
   var
      Temp: integer;
   begin
      if( IsFull) then begin
         raise lbpListException.Create( 'An attempt was made to add an item to a circular list which is full!');
      end;

      Items[ Tail]:= Item;
      Tail:= IncIndex( Tail);
   end; // AddTail()


// ************************************************************************
// * GetTail() - Returns the Item at the Tail
// ************************************************************************

function tgList.GetHead(): T
   begin
      if( IsEmpty) then begin
         raise lbpListException.Create( 'An attempt was made to get an item from an empty list');
      end;
      CurrentIndex:= DecIndex( Tail);
      result:= Items[ CurrentIndex];
   end; // GetHead()


// ************************************************************************
// * DelHead() - Removes and returns the Item at the Head
// ************************************************************************

function tgList.DelHead(): T
   begin
      if( IsEmpty) then begin
         raise lbpListException.Create( 'An attempt was made to get an item from an empty list');
      end;
      CurrentIndex:= IncIndex( Head);
      result:= Items[ CurrentIndex];
   end; // DelHead()


// ************************************************************************
// * IsEmpty() - Returns true if the buffer is empty
// ************************************************************************

function tgList.IsEmpty(): boolean;
   begin
      result:= (Tail = IncIndex( Head));
   end; // IsEmpty()

// ************************************************************************
// * IsFull() - Returns true if the buffer is full
// ************************************************************************

function tgList.IsFull(): boolean;
   begin
      result:= (Head = IncIndex( Tail));
   end; // IsFull()

// ************************************************************************

end. // lbp_generic_ring_buffer
