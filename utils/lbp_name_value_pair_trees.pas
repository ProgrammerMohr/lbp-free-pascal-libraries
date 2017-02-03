{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

A binary tree of name/value string pairs

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

unit lbp_name_value_pair_trees;
// Creates a balanced binary tree of Name/Value string pairs.  The tree is
// sorted and searched by Name and Value is retrieved using the Value property. 

{$include lbp_standard_modes.inc}

interface

uses
   lbp_binary_Trees,
   lbp_types;

// *************************************************************************
// * tNVPNode - Name Value Pair node.
// *************************************************************************
type
   tNVPNode = class
      public
         MyName:  string;
         MyValue: string;
         constructor Create( Name: string; Value: string);
      end; // tNVPNode


// *************************************************************************
// * tNameValuePairTree - Basic tree with case sensitive searching.
// *************************************************************************
type
   tNameValuePairTree = class( tBalancedBinaryTree)
      protected
         NVP:        tNVPNode;
      public
         constructor  Create( iDuplicateOK: boolean);
         procedure    Add(  iName: string; iValue: string); overload;
         function     Find( iName: string): String; overload;
         function     GetFirst():  string; overload;
         function     GetLast():   string; overload;
         function     GetNext():   string; overload;
         function     GetPrevious(): string; overload;
         procedure    Remove( iName: string); overload;
         procedure    Dump; virtual; // Debug
      private
         function     GetValue(): string;
      public
         property     Value: string read GetValue;
      end; // tNameValuePairTree


// *************************************************************************

implementation

// =========================================================================
// = tNVPNode - Name Value Pair node.
// =========================================================================
// *************************************************************************
// * Create() - constructor
// *************************************************************************

constructor tNVPNode.Create( Name: string; Value: string);
   begin
      MyName:= Name;
      MyValue:= Value;
   end; // Create()


// =========================================================================
// = Global procedures
// =========================================================================
// *************************************************************************
// * CompareNames - global function used only by tNameValuePairTree
// *************************************************************************

function CompareNames(  P1: tNVPNode; P2: tNVPNode): int8;
   begin
      if( P1.MyName > P2.MyName) then begin
         result:= 1;
      end else if( P1.MyName < P2.MyName) then begin
         result:= -1;
      end else begin
         result:= 0;
      end;
   end; // CompareNames()


// =========================================================================
// = tNameValuePairTree
// =========================================================================
// *************************************************************************
// * Create() - Constructor
// *************************************************************************

constructor tNameValuePairTree.Create( iDuplicateOK: boolean);
   begin
      inherited Create( tCompareProcedure( @CompareNames), iDuplicateOK);
   end; //constructor


// *************************************************************************
// * Add() - Add a string to the tree
// *************************************************************************

procedure tNameValuePairTree.Add( iName: string; iValue: string);
   begin
      NVP:= tNVPNode.Create( iName, iValue);
      inherited Add( NVP);
   end; // Add()


// *************************************************************************
// * Find() - Find the string in the tree and return the Value associated
// *          with it.
// *************************************************************************

function tNameValuePairTree.Find( iName: string): string;
   var
      Temp: tNVPNode;
   begin
      Temp:= tNVPNode.Create( iName, '');
      NVP:= tNVPNode( inherited Find( Temp));
      if( NVP = nil) then result:= '' else result:= NVP.MyValue;
      Temp.Destroy;
      NVP:= nil;
   end; // Find()


// *************************************************************************
// * GetFirst() - Get the first Name in the tree
// *************************************************************************

function tNameValuePairTree.GetFirst(): string;
   begin
      NVP:= tNVPNode( inherited GetFirst());
      if( NVP = nil) then result:= '' else result:= NVP.MyName;
   end; // GetFirst()


// *************************************************************************
// * GetLast() - Get the Last string in the tree
// *************************************************************************

function tNameValuePairTree.GetLast():  string;
   begin
      NVP:= tNVPNode( inherited GetLast());
      if( NVP = nil) then result:= '' else result:= NVP.MyName;
   end; // GetLast()


// *************************************************************************
// * GetNext() - Get the Next string in the tree
// *************************************************************************

function tNameValuePairTree.GetNext():  string;
   begin
      NVP:= tNVPNode( inherited GetNext());
      if( NVP = nil) then result:= '' else result:= NVP.MyName;
   end; // GetNext()


// *************************************************************************
// * GetPrevious() - Get the previous string in the tree
// *************************************************************************

function tNameValuePairTree.GetPrevious(): string;
   begin
      NVP:= tNVPNode( inherited GetPrevious());
      if( NVP = nil) then result:= '' else result:= NVP.MyName;
   end; // GetPrevious()


// *************************************************************************
// * Remove - Remove the string from the tree
// *************************************************************************

procedure tNameValuePairTree.Remove( iName: string);
   begin
      NVP:= tNVPNode.Create( iName, '');
      inherited Remove( NVP, true);
      NVP.Destroy;
      NVP:= nil;
   end; // Remove()


// *************************************************************************
// * GetValue() - Returns the value of the current Name Value pair
// *************************************************************************

function tNameValuePairTree.GetValue(): string;
   begin
      if( NVP = nil) then result:= '' else result:= NVP.MyValue;
   end; // GetValue()


// *************************************************************************
// * Dump() - Display all the strings in the tree.
// *************************************************************************

procedure tNameValuePairTree.Dump();
   var
      TempName: string;
   begin
      TempName:= GetFirst();
      while( Length( TempName) > 0) do begin
         writeln( 'Debug:  tNameValuePairTree.Dump():  ', TempName, 
                  ' = ', Value);
         TempName:= GetNext();
      end;
   end; // Dump()



// *************************************************************************

end. // lbp_name_value_pair_trees unit
