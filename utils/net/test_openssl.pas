program TestOpenSSL;

uses
   openssl;

var
   SHAResult: tSHAResult;
   MD5Result: tMD5Result;
begin

   SHA1( 'lpark', SHAResult);
   writeln( DigestToHex(SHAResult));
   SHA1( 'ameyp', SHAResult);
   writeln( DigestToHex(SHAResult));
   SHA1( 'lpark', SHAResult);
   writeln( DigestToHex(SHAResult));
   
   MD5( 'lpark', MD5Result);
   writeln( DigestToHex(MD5Result));
   MD5( 'ameyp', MD5Result);
   writeln( DigestToHex(MD5Result));
   MD5( 'lpark', MD5Result);
   writeln( DigestToHex(MD5Result));
end.