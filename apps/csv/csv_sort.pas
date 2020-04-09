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


// ************************************************************************
// * Dictionary types
// ************************************************************************

type
   tStringSortDictionary = specialize tgDictionary< string, tCsvStringArray>;
   tInt64SortDictionary  = specialize tgDictionary< Int64, tCsvStringArray>;


// ************************************************************************
// * Global variables
// ************************************************************************

var
   FieldName:          string; // From the --header parameter
   FieldIndex:         integer;
   SkipNonPrintable:   boolean;
   IgnoreCase:         boolean;
   ReverseOrder:       boolean;
   DelimiterIn:        char;
   DelimiterOut:       char;
   Csv:                tCsv;
   SortByIpv4:         boolean;
   SortByInteger:      boolean;
   SortByDouble:       boolean;
   StringDict:         tStringSortDictionary;
   Int64Dict:          tInt64SortDictionary;



// ************************************************************************
// * SetGlobals() - Sets our global variables
// ************************************************************************

procedure SetGlobals();
   var
      Delimiter:    string;
   begin
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
   
      // Open input CSV
      Csv:= tCsv.Create( lbp_input_file.InputStream, False);
      Csv.ParseHeader();
   
      // Get the header field to be sorted.
      if( ParamSet( 'header')) then begin
         FieldName:= GetParam( 'header');
      end else begin
         Usage( true, 'The header field parameter is required!');        
      end;

      // Make sure the header field is valid.
      if( Csv.ColumnExists( FieldName)) then begin
         FieldIndex := Csv.IndexOf( FieldName);
      end else begin
         Usage( true, 'Your header field ''' + FieldName + ''' does not exist in the input CSV file!');
      end;

      // Set the boolean options
      SkipNonPrintable:= ParamSet( 'skip-non-printable');
      IgnoreCase:=       ParamSet( 'ignore-case');
      ReverseOrder:=     ParamSet( 'reverse-order');
      SortByIpv4:=       ParamSet( 'ipv4');
      SortByInteger:=    ParamSet( 'number');
      SortByDouble:=     ParamSet( 'double');

      // Apply the boolean options
      Csv.SkipNonPrintable:= SkipNonPrintable;

      // Initialize the dictionaries;
      StringDict:= tStringSortDictionary.Create( tStringSortDictionary.tCompareFunction(@CompareString), true);
      Int64Dict:=  tInt64SortDictionary.Create( tInt64SortDictionary.tCompareFunction(@CompareInt64), true);
   end; // SetGlobals()


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
      InsertParam( ['double', 'float'], false, '', 'The passed filed is an floating point number.');
      InsertParam( ['r', 'reverse-order'], false, '', 'Outputs in decending order.');
      InsertUsage();
      ParseParams();
   end; // InitArgvParser();


// ************************************************************************
// * CompareStrings() - compares two strings. Used by the string dictionary
// ************************************************************************


// ************************************************************************
// * CompareInt64() - Compare two Int64s.  Used by the Int64 dictionary
// ************************************************************************


// ************************************************************************
// * 
// ************************************************************************


// ************************************************************************
// * main()
// ************************************************************************

var
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
   SetGlobals();

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

   StringDict.RemoveAll( True);
   StringDict.Destroy();
   Int64Dict.RemoveAll( True);
   Int64Dict.Destroy();
   Csv.Destroy;
end.  // csv_sort program
