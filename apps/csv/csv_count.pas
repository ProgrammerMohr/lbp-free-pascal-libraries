program csv_count;

{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   lbp_types,
   lbp_csv,
   lbp_parse_helper,
   lbp_generic_containers,
   lbp_input_file;

var
   Csv:                tCsv;


// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      InsertUsage( '');
      InsertUsage( 'csv_count reads a CSV file and returns the number of rows found excluding the');
      InsertUsage( '      header.');
      InsertUsage( '');
      InsertUsage( 'Usage:');
      InsertUsage( '   csv_grep [-f <input file name>] [-d <delimiter character>');
      InsertUsage( '');
      InsertUsage( '   ========== Program Options ==========');
      SetInputFileParam( true, true, false, true);
      InsertParam( ['d', 'id','input-delimiter'], true, ',', 'The character which separates fields on a line.'); 
      InsertUsage();
      ParseParams();
   end; // InitArgvParser();


// ************************************************************************
// * main()
// ************************************************************************

var
   Line: tCsvStringArray;
   Rows: integer = 0;
   c:    char;
begin
   InitArgvParser();

   // Open input CSV
   Csv:= tCsv.Create( lbp_input_file.InputStream, False);

   // Skip the header
   Csv.ParseHeader();
 
   // Process the input CSV
   repeat
      Line:= Csv.ParseLine();
      C:= Csv.PeekChr();
      if( (C <> EOFchr) and (Length( Line) > 0)) then inc( Rows);
   until( C = EOFchr);

   writeln( Rows);
   Csv.Destroy;

end.  // csv_count program
