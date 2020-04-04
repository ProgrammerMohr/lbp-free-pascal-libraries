program csv_sort;

{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   lbp_types,
   lbp_csv,
   lbp_parse_helper,
   lbp_generic_containers,
   lbp_input_file,
   lbp_output_file;


var
   SkipNonPrintable:   boolean;
   IgnoreCase:         boolean;
   ReverseOrder:       boolean;
   DelimiterOut:       char;
   Csv:                tCsv;
   SortByIpv4:         boolean;
   SortByInteger:      boolean;
   SortByDouble:       boolean;   


// ************************************************************************
// * SetGlobals() - Sets our global variables
// ************************************************************************

procedure SetGlobals();
   var
      L:            integer = 0;  // used for Length
      Field:        string;
      GrepFields:   tCsvStringArray;
      Delimiter:    string;
      DelimiterIn:  char;
   begin
      // Get the regular expression
      if( Length( UnnamedParams) <> 1) then begin
         raise tCsvException.Create( 'You must enter one and only one regular expression on the command line!');
      end;
      RegularExpression:= tRegExpr.Create( UnnamedParams[ 0]);
      
      GrepIndexes:= tIntegerList.Create();

      // Set the input delimiter
      if( ParamSet( 'id')) then begin
         Delimiter:= GetParam( 'id');
         if( Length( Delimiter) <> 1) then begin
            raise tCsvException.Create( 'The delimiter must be a singele character!');
         end;
         DelimiterIn:= Delimiter[ 1];
      end else begin
         DelimiterIn:= CsvDelimiter; // the default value in the lbp_csv unit.
      end;

      // Set the output delimiter
      if( ParamSet( 'od')) then begin
         Delimiter:= GetParam( 'od');
         if( Length( Delimiter) <> 1) then begin
            raise tCsvException.Create( 'The delimiter must be a singele character!');
         end;
         DelimiterOut:= Delimiter[ 1];
      end else begin
         DelimiterOut:= DelimiterIn;
      end;
   
      // Get the new header from the command line.
      if( ParamSet( 'header')) then begin
         Csv:= tCsv.Create( GetParam( 'header'));
         Csv.Delimiter:= ','; // The delimiter for the command line is always a ','
         Csv.SkipNonPrintable:= ParamSet( 's');
         GrepFields:= Csv.ParseLine;
         Csv.Destroy;
         L:= Length( GrepFields);
      end;

      // Open input CSV
      Csv:= tCsv.Create( lbp_input_file.InputStream, False);
   
      // If we don't yet have GrepHeaders, default to searchin all headers
      Csv.ParseHeader();
      if( L = 0) then begin
         GrepFields:= Csv.Header();
      end;

      // Make sure all the header fields are valid and add their indexes to GrepIndexes
      for Field in GrepFields do begin
         if( Csv.ColumnExists( Field)) then begin
            GrepIndexes.Queue := Csv.IndexOf( Field);
         end else begin
            Usage( true, 'Your header field ''' + Field + ''' does not exist in the input CSV file!');
         end;
      end; // for

      // Set the boolean options
      SkipNonPrintable:= ParamSet( 'skip-non-printable');
      IgnoreCase:=       ParamSet( 'ignore-case');
      ReverseOrder:=     ParamSet( '');
      SortByIpv4:=       ParamSet( '');
      SortByInteger:=    ParamSet( '');
      :=      ParamSet( '');

      // Apply the boolean options
      Csv.SkipNonPrintable:= SkipNonPrintable;
      RegularExpression.ModifierI:= IgnoreCase;
      RegularExpression.ModifierM:= true; // start and end line works for each line in a multi-line field
   end; // InitGlobals()


// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      InsertUsage( '');
      InsertUsage( 'csv_sort reads a CSV file and outputs it sorted by the specified header field.');
      InsertUsage( 'The sorting is done in memory, so very large files may fail to sort.');
      InsertUsage( '');
      InsertUsage( 'Usage:');
      InsertUsage( '   csv_sort [--header <header field name>] [-f <input file name>] [-o <output file name>]');
      InsertUsage( '');
      InsertUsage( '   ========== Program Options ==========');
      SetInputFileParam( true, true, false, true);
      SetOutputFileParam( false, true, false, true);
      InsertParam( ['h','header'], true, '', 'The comma separated list of column names'); 
      InsertParam( ['d', 'id','input-delimiter'], true, ',', 'The character which separates fields on a line.'); 
      InsertParam( ['od','output-delimiter'], true, ',', 'The character which separates fields on a line.'); 
      InsertParam( ['s', 'skip-non-printable'], false, '', 'Try to fix files with some unicode characters.');
      InsertParam( ['i', 'ignore-case'], false, '', 'Perform a case insensitive sort.');
      InsertParam( ['4', 'ipv4'], false, '', 'The passed field is an IPv4 address.');
      InsertParam( ['n', 'number'], false, '', 'The passed filed is an integer number.');
      InsertParam( ['d', 'double', 'float'], false, '', 'The passed filed is an floating point number.');
      InsertParam( ['r', 'reverse-order'], false, '', 'Outputs in decending order.');
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
   Delimiter: string;
   OD:        char; // The output delimiter
   S:         string;
   C:         char;
   L:         integer; // Header length
   i:         integer;
   iMax:      integer; 
begin
   InitArgvParser();

   // // Set the input delimiter
   // if( ParamSet( 'id')) then begin
   //    Delimiter:= GetParam( 'id');
   //    if( Length( Delimiter) <> 1) then begin
   //       raise tCsvException.Create( 'The delimiter must be a singele character!');
   //    end;
   //    CsvDelimiter:= Delimiter[ 1];
   // end;

   // // Set the output delimiter
   // if( ParamSet( 'od')) then begin
   //    Delimiter:= GetParam( 'od');
   //    if( Length( Delimiter) <> 1) then begin
   //       raise tCsvException.Create( 'The delimiter must be a singele character!');
   //    end;
   //    OD:= Delimiter[ 1];
   // end else OD:= CsvDelimiter;
   
   // // Get the new header from the command line.
   // if( not ParamSet( 'header')) then Usage( true, 'The ''--header'' parametter must be specified!');
   // Csv:= tCsv.Create( GetParam( 'header'));
   // Csv.Delimiter:= ','; // The delimiter for the command line is always a ','
   // Csv.SkipNonPrintable:= ParamSet( 's');
   // Header:= Csv.ParseLine;
   // Csv.Destroy;
   // L:= Length( Header);
   // if( L < 1) then Usage( true, 'An empty string was passed in the ''--header'' parametter!');
   // iMax:= L - 1;

   // // Open input CSV
   // Csv:= tCsv.Create( lbp_input_file.InputStream, False);
   
   // // Test to make sure the user entered a valid header,  Output it if it is OK.
   // Csv.ParseHeader();
   // for S in Header do begin
   //    if( not Csv.ColumnExists( S)) then Usage( true, 'Your header field ''' + S + ''' does not exist in the input CSV file!');
   // end; // for

   // // Process the input CSV
   // writeln( OutputFile, Header.ToLine( OD));
   // repeat
   //    TempLine:= Csv.ParseLine();
   //    SetLength( NewLine, L);
   //    C:= Csv.PeekChr();
   //    if( C <> EOFchr) then begin
   //       for i:= 0 to iMax do NewLine[ i]:= TempLine[ Csv.IndexOf( Header[ i])];
   //       writeln( OutputFile, NewLine.ToLine( OD));
   //    end;
   // until( C = EOFchr);

   // Csv.Destroy;
end.  // csv_sort program
