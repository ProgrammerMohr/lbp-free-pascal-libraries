unit lbp_dns_dhcp_host;

// A siple unit to hold a mimimal DNS/DHCP host record.

interface

{$include lbp_standard_modes.inc}

uses
   lbp_types,
   lbp_utils,
   lbp_ip_utils;


// *************************************************************************

type
   tdns_dhcp_host = class
      private
         MyIPAddr:   word32;
         MyMACAddr:  word64;
         function    GetIPStr(): string;
         procedure   SetIPStr( S: string);
         function    GetMACStr(): string;
         procedure   SetMACStr( S: string);
      public
         Name:     string;
         Domain:   string;
         Comment:  string;
         constructor Create();
         property  IP:    word32  read MyIPAddr  write MyIPAddr;
         property  MAC:   word64  read MyMACAddr write MyMACAddr;
         property  IPStr: string  read GetIPStr  write SetIPStr;
         property  MACStr: string read GetMACStr write SetMACStr;
      end; // tdns_dhcp_host


// *************************************************************************

implementation

// =========================================================================
// = tdns_dhcp_host - Stores mimimal informaton for a host record
// =========================================================================
// *************************************************************************
// * Create() - Constructor
// *************************************************************************

constructor tdns_dhcp_host.Create();
   begin
      IP:= 0;
      MAC:= 0;
      Name:= '';
      Domain:= Name;
      Comment:= Name;
   end; // Create()


// *************************************************************************
// * GetIPStr() - Returns the string representation of IP
// *************************************************************************

function tdns_dhcp_host.GetIPStr(): string;
   begin
      result:= IPWord32ToString( IP);
   end; // GetIPStr()


// *************************************************************************
// * SetIPStr() - Sets the IP from a string
// *************************************************************************

procedure tdns_dhcp_host.SetIPStr( S: string);
   begin
      IP:= IPStringToWord32( S);
   end; // SetIPStr()


// *************************************************************************
// * GetMACStr() - Returns the string representation of MAC
// *************************************************************************

function tdns_dhcp_host.GetMACStr(): string;
   begin
      result:= MACWord64ToString( MAC);
   end; // GetMACStr()


// *************************************************************************
// * SetMACStr() - Sets the MAC from a string
// *************************************************************************

procedure tdns_dhcp_host.SetMACStr( S: string);
   begin
      MAC:= MACStringToWord64( S);
   end; // SetMACStr()


// *************************************************************************

end. // lbp_dns_dhcp_host unit