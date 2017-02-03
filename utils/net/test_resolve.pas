program test_resolv;

{$include lbp_standard_modes.inc}

uses
   sockets, // StrToHostAddr()
   resolve;


var
   HR:  THostResolver;
   IA:  tHostAddr;

   
   
// ************************************************************************
// * main()
// ************************************************************************

begin
   HR:= tHostResolver.Create( nil);
   HR.NameLookup( 'gear.net.kent.edu');
   writeln( HR.AddressAsString);
   HR.ClearData;

   IA:= StrToHostAddr( '131.123.252.42');
   if( HR.AddressLookup( IA)) then begin
      writeln( HR.ResolvedName);
   end else begin
      writeln( 'Address lookup failed!');
   end;
   HR.ClearData;

   HR.Destroy();
end.
