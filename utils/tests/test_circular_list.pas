program test_circular_list;

{$include lbp_standard_modes.inc}
//{$V-}    //Added by LP because it says so below
//{$R-}    //Range checking off
//{$S-}    //Stack checking off
//{$I-}    //I/O checking off
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

uses
   lbp_generic_ring_buffer,
   sysutils,       // Exceptions
   lbp_types;     // int32

// ************************************************************************

type 
   CharList = specialize tgList< char>;


// ************************************************************************
// * FillForward() - Fills L in the forward direction
// ************************************************************************

procedure FillForward( L: CharList; Debug: boolean = False);
   var
      C: char;
   begin
      writeln( 'FillForward()');
      C:= 'a';
      while( not L.IsFull) do begin
         if( Debug) then begin
            if( L.IsEmpty) then writeln( '   Empty') else writeln( '   Not empty');
            writeln( '   Adding ', C);
         end; // if Debug
         L.AddHead( C);
         inc( C);
         if( Debug) then begin
            if( L.IsEmpty) then writeln( '   Empty') else writeln( '   Not empty');
            if( L.IsFull)  then writeln( '   Full')  else writeln( '   Not full');
         end; // if Debug
      end;
   end; // FillForward()


// ************************************************************************
// * FillReverse() - Fills L in the reverse direction
// ************************************************************************

procedure FillReverse( L: CharList; Debug: boolean = False);
   var
      C: char;
   begin
      writeln( 'FillReverse()');
      C:= 'a';
      while( not L.IsFull) do begin
         if( Debug) then begin
            if( L.IsEmpty) then writeln( '   Empty') else writeln( '   Not empty');
            writeln( '   Adding ', C);
         end; // if Debug
         L.AddTail( C);
         inc( C);
         if( Debug) then begin
            if( L.IsEmpty) then writeln( '   Empty') else writeln( '   Not empty');
            if( L.IsFull)  then writeln( '   Full')  else writeln( '   Not full');
         end; // if Debug
      end;
   end; // FillReverse()


// ************************************************************************
// * EmptyForward() - Remove items from L one at a time.
// ************************************************************************

procedure EmptyForward( L: CharList; Debug: boolean = False);
   var
      C: char;
   begin
      writeln( 'EmptyForward()');
      while( not L.IsEmpty) do begin
         if( Debug) then begin
            if( L.IsFull)  then writeln( '   Full')  else writeln( '   Not full');
         end; // if Debug
         C:= L.RemoveTail;
         if( Debug) then begin
            writeln( '   Removed ', C);
            if( L.IsEmpty) then writeln( '   Empty') else writeln( '   Not empty');
         end; // if Debug
      end;
   end; // EmptyForward()


// ************************************************************************
// * EmptyReverse() - Remove items from L one at a time.
// ************************************************************************

procedure EmptyReverse( L: CharList; Debug: boolean = False);
   var
      C: char;
   begin
      writeln( 'EmptyReverse()');
      while( not L.IsEmpty) do begin
         if( Debug) then begin
            if( L.IsFull)  then writeln( '   Full')  else writeln( '   Not full');
         end; // if Debug
         C:= L.RemoveHead;
         if( Debug) then begin
            writeln( '   Removed ', C);
            if( L.IsEmpty) then writeln( '   Empty') else writeln( '   Not empty');
         end; // if Debug
      end;
   end; // EmptyReverse()


// ************************************************************************
// * main()
// ************************************************************************
var 
   L: CharList;
begin
   L:= CharList.Create( 4, 'Test Char List');

   FillForward( L, true);
   EmptyForward( L, true);
   FillForward( L, false);
   EmptyReverse( L, true);
   FillReverse( L, true);
   EmptyForward( L, true);
   FillReverse( L, false);
   EmptyReverse( L, true);


   L.Destroy();
end. // test_circular_list program
