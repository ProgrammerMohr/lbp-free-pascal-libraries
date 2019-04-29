program csv_heaser;

{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   lbp_csv,
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
      InsertUsage( 'csv_header dumps the first line of a CSV file and outputs it one cell');
      InsertUsage( '         per line.  It will optionally sort the lines.');
      InsertUsage( '');
      InsertUsage( 'Usage:');
      InsertUsage( '   csv_header [-s|--sort] [-f <file name>] [-o <output file name>]');
      InsertUsage( '');
      InsertUsage( '   ========== Program Options ==========');
      SetInputFileParam( true, true, false, true);
      SetOutputFileParam( false, true, false, true);
      InsertParam( ['s','sort'], false, '', 'Sort the output.'); 
      InsertUsage();
      ParseParams();
   end; // InitArgvParser();


// ************************************************************************
// * main()
// ************************************************************************

var
   Csv:      tCsv;
   Header:   tCsvStringArray;
   S:        string;
begin
   InitArgvParser();
   Csv:= tCsv.Create( lbp_input_file.InputStream, False);
   
   Csv.ParseHeader();
   if( ParamSet( 's')) then Header:= Csv.SortedHeader else Header:= Csv.Header;
   for S in Header do writeln( OutputFile, S);

   Csv.Destroy;
end.  // csv_header program
