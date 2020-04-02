program csv_cat;

{$include lbp_standard_modes.inc}

uses
   lbp_argv,
   lbp_types,
   lbp_csv,
   lbp_parse_helper,
   lbp_generic_containers,
   lbp_output_file,
   sysutils; // FileExists()

var
   SkipNonPrintable:   boolean = false;
   DelimiterIn:        char;
   DelimiterOut:       char;
   FirstHeader:        tCsvStringArray = nil;

// ************************************************************************
// * SetGlobals() - Sets our global variables
// ************************************************************************

procedure SetGlobals();
   var
      Delimiter:    string;
   begin
      // Make sure we passed at least one file name.
      if( Length( UnnamedParams) < 1) then begin
         raise tCsvException.Create( 'You must supply at least one CSV file name');
      end;

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

      SkipNonPrintable:= ParamSet( 'skip-non-printable');
   end; // InitGlobals()



// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      InsertUsage( '');
      InsertUsage( 'csv_cat reads a list of CSV file names and combines them into one file.  The');
      InsertUsage( '      header line of each file must be the same.');
      InsertUsage( 'Usage:');
      InsertUsage( '   csv_cat <1st file name> <2nd file name> ...');
      InsertUsage( '');
      InsertUsage( '   ========== Program Options ==========');
      SetOutputFileParam( false, true, false, true);
      InsertParam( ['d', 'id','input-delimiter'], true, ',', 'The character which separates fields on a line.'); 
      InsertParam( ['od','output-delimiter'], true, ',', 'The character which separates fields on a line.'); 
      InsertParam( ['s', 'skip-non-printable'], false, '', 'Try to fix files with some unicode characters.');
      InsertUsage();
      ParseParams();
   end; // InitArgvParser();


// ************************************************************************
// * HeadersMatch() - returns true if the two passed headers have the 
// *                  same fields in the same order.
// ************************************************************************

function HeadersMatch( H1, H2: tCsvStringArray): boolean;
   var
      i:     integer;
      iMax:  integer;
   begin
      result:= true;
      iMax:= Length( H1) - 1;
      
      if( Length( H1) <> Length( H2)) then begin
         result:= false;
         exit;
      end;

      for i:= 0 to iMax do begin
         if( H1[ i] <> H2[ i]) then begin
            result:= false;
            exit;
         end;
      end; 
   end; // HeadersMatch()


// ************************************************************************
// * ProcessCsv() - Main loop to process the file
// ************************************************************************

procedure ProcessCsv( FileName: string);
   var
      Line:  tCsvStringArray;
      CsvIn:  tCsv;
   begin
      if( not FileExists( FileName)) then begin
         raise tCsvException.Create( 'The file ''%s'' does not exist!', [FileName]);
      end; 

      CsvIn:= tCsv.Create( FileName, true);
      CsvIn.SkipNonPrintable:= SkipNonPrintable;
      CsvIn.Delimiter:= DelimiterIn;

      // Check and output the first header
      CsvIn.ParseHeader;
      Line:= CsvIn.Header;
      if( FirstHeader = nil) then begin
         FirstHeader:= Line;
         writeln( OutputFile, Line.ToLine( DelimiterOut));
      end else begin
         if not HeadersMatch( FirstHeader, Line) then begin
            raise tCsvException.Create( 'The header line of file ''%s'' does not match the one from the first CSV file!', [FileName]);
         end;
      end;

      // Output the rest of the file
      Line:= CsvIn.ParseLine;
      while( CsvIn.PeekChr <> EOFchr) do begin
         writeln( OutputFile, Line.ToLine( DelimiterOut));
         Line:= CsvIn.ParseLine;
      end;

      CsvIn.Destroy();
   end; // ProcessCsv();


// ************************************************************************
// * main()
// ************************************************************************
var
   FileName: string;
begin
   InitArgvParser();
   SetGlobals();

   for FileName in UnnamedParams do begin
      ProcessCsv( FileName);
   end;
end.  // csv_cat program
