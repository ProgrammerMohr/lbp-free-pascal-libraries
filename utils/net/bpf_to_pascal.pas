program bpf_to_pascal;

{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   lbp_types,
   sysutils;  // Format()
   

   
   
// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      InsertUsage( '');
      InsertUsage( 'This program converts the packet filter code (BPF) from tcpdump into Pascal');
      InsertUsage( 'code which can be used with raw sockets to filter packets in the same way as');
      InsertUsage( 'tcpdump.  Pipe the results of tcpdump to the program.  For example:');
      InsertUsage;
      InsertUsage( '   tcpdump -i eth0 -n -e -dd ''dst port bootpc'' | bpf_to_pascal');
      InsertUsage;
      InsertUsage( 'The program will output the Pascal code.');
      InsertUsage( '');

      ParseParams();
   end; // InitArgvParser()


// ************************************************************************
// * main()
// ************************************************************************

var
   Count: integer;
   code:  integer;
   jt:    integer;
   jf:    integer;
   k:     word64;
   comma: string;

begin
   InitArgvParser;
   readln( Count);
   writeln( '   MyBPF: array[ 1..', Count, '] of fpsock_filter = (');

   comma:= ',';
   while not EOF do begin
      Dec( Count);
      if( Count = 0) then comma:='';
      readln( code, jt, jf, k);
      writeln( format( '      ( code:$%.2x;  jt:%.2d;  jf:%.2d;  k:$%.8x )%s', [code, jt, jf, k, comma]));
   end; // while
   writeln( '   ); // MyBPF');
end.  // bpf_to_pascal
