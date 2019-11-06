program csv_reorder;

{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   lbp_types,
   lbp_csv,
   lbp_parse_helper,
   lbp_generic_containers,
   lbp_input_file,
   lbp_output_file;


// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      InsertUsage( '');
      InsertUsage( 'csv_reorder reads a CSV file and outputs it out again with only');
      InsertUsage( '         the columns specified in the --order parameter and in');
      InsertUsage( '         the order they are specified');
      InsertUsage( '');
      InsertUsage( 'Usage:');
      InsertUsage( '   csv_header [--header] [-f <input file name>] [-o <output file name>]');
      InsertUsage( '');
      InsertUsage( '   ========== Program Options ==========');
      SetInputFileParam( true, true, false, true);
      SetOutputFileParam( false, true, false, true);
       InsertParam( ['header'], true, '', 'The comma separated list of column names'); 
      InsertUsage();
      ParseParams();
   end; // InitArgvParser();


// ************************************************************************
// * main()
// ************************************************************************

var
   Csv:       tCsv;
   Header:    tCsvStringArray;
   TempLine:  tCsvStringArray;
   NewLine:   tCsvStringArray;
   S:         string;
   C:         char;
   L:         integer; // Header length
   i:         integer;
   iMax:      integer; 
begin
   InitArgvParser();
   // Get the new header
   if( not ParamSet( 'header')) then Usage( true, 'The ''--header'' parametter must be specified!');
   Csv:= tCsv.Create( GetParam( 'header'));
   Header:= Csv.ParseLine;
   writeln( OutputFile, Header.ToLine);
   Csv.Destroy;
   L:= Length( Header);
   if( L < 1) then Usage( true, 'An empty string was passed in the ''--header'' parametter!');
   iMax:= L - 1;

   // Open input CSV
   Csv:= tCsv.Create( lbp_input_file.InputStream, False);
   Csv.Delimiter:= TabChr;

   // Test to make sure the user entered a valid header,  Output it if it is OK.
   Csv.ParseHeader();
   for S in Header do begin
      if( not Csv.ColumnExists( S)) then Usage( true, 'Your heade field ''' + S + ''' does not exist in the input CSV file!');
   end; // for
   writeln( OutputFile, Header.ToLine);

   // Process the input CSV
   repeat
      TempLine:= Csv.ParseLine();
      SetLength( NewLine, L);
      C:= Csv.PeekChr();
      if( C <> EOFchr) then begin
         for i:= 0 to iMax do NewLine[ i]:= TempLine[ Csv.IndexOf( Header[ i])];
         writeln( OutputFile, NewLine.ToLine);
      end;
   until( C = EOFchr);

   Csv.Destroy;
end.  // csv_reorder program
