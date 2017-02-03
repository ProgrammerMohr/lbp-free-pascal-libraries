program test_raw_socket;

{$include kent_standard_modes.inc}
{$LONGSTRINGS ON}    // Non-sized Strings are ANSI strings

uses
   kent_types,
   kent_log,
   kent_net_info,   // info about our interfaces
   kent_net_buffer,
   kent_net_fields;

var
   NetInfo:       tNetworkInfo;
   InterfaceInfo: tNetInterfaceInfo;
   Netdevice:     string;
   Buffer:        tUDPPacketBuffer;
   F:             tNetField;
begin
   Log( LOG_DEBUG, 'Program starting');

   // Look for an ethernet interface as the first parameter
   if( ParamCount > 0) then begin
      NetDevice:= ParamStr( 1);
   end else begin
      NetDevice:= 'eth0';
   end;
   InterfaceInfo:= GetNetInterfaceInfo( NetDevice);
   NetInfo:= tNetworkInfo( InterfaceInfo.IPList.GetFirst());
   if( NetInfo = nil) then begin
      raise KentException.Create( NetDevice + ' has no assigned IP!');
   end;

   Buffer:= tUDPPacketBuffer.Create();
   Buffer.RawMode:= true;

   Buffer.EthHdr.SrcMAC.DefaultStrValue:= InterfaceInfo.MACstr;
   Buffer.EthHdr.SrcMAC.Clear();
   Buffer.EthHdr.DstMAC.DefaultStrValue:= InterfaceInfo.BroadcastStr;
   Buffer.EthHdr.DstMAC.Clear();

//   Buffer.EthHdr.EthType.StrValue:= '0800';
   Buffer.IPHdr.SrcIP.DefaultValue:= NetInfo.IPAddr;
   Buffer.IPHdr.SrcIP.Clear();
   Buffer.IPHdr.DstIP.DefaultStrValue:= '255.255.255.255';
   Buffer.IPHdr.DstIP.Clear();
   Buffer.IPHdr.IPLength.Value:= 328;
   Buffer.UDPHdr.SrcPort.DefaultValue:= 68;
   Buffer.UDPHdr.SrcPort.Clear();
   Buffer.UDPHdr.DstPort.DefaultValue:= 67;
   Buffer.UDPHdr.DstPort.Clear();

   Buffer.AddBaseFields();

   Buffer.Encode();
   Buffer.LogFullPacket();

   Buffer.HexDump();

   F:= tNetField( Buffer.HeaderFields.GetFirst());
   while( F <> nil) do begin
      F.Clear();
      F:= tNetField( Buffer.HeaderFields.GetNext());
   end;

   Buffer.LogFullPacket();
   Writeln( '------------------------------------------');
   Buffer.Decode();
   Buffer.LogFullPacket();

   Buffer.Destroy();
   InterfaceInfo:= nil;
   NetInfo:= nil;

   Log( LOG_DEBUG, 'Program ending.');
end.  // test_raw_socket
