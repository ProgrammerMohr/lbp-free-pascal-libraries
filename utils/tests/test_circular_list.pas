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
// * main()
// ************************************************************************
var 
   L: CharList;
   C: Char;
begin
   L:= CharList.Create( 4, 'Test Char List');

   for C:= 'a' to 'e' do begin
      if( L.IsEmpty) then writeln( 'Empty') else writeln( 'Not empty');
      writeln( 'Adding ', C);
      L.AddHead( C);
      if( L.IsEmpty) then writeln( 'Empty') else writeln( 'Not empty');
      if( L.IsFull)  then writeln( 'Full')  else writeln( 'Not full');
   end;

   L.Destroy();
end. // test_circular_list program
