program aws_cdn_log_sto_csv;

// ************************************************************************
// * This program reads the current folder containing gzipped log entries 
// * from AWS. There is one log entry per file.
// ************************************************************************

uses
   lbp_argv,
   lbp_types, // show_debug, etc
   lbp_input_file,
   lbp_output_file,
   lbp_aws_log,
   lbp_csv,  // just for the output routines.
   lbp_parse_helper;


// ************************************************************************

// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      InsertUsage( '');
      InsertUsage( 'aws_cdn_log_folder_to_csv reads log entries from AWS and outputs them in');
      InsertUsage( '         CSV format.  AWS gzips their individual log files.  The file(s)');
      InsertUsage( '         must be un-gzipped before you can use them.  While you can');
      InsertUsage( '         specifiy a single file as input to this program, you will most');
      InsertUsage( '         likely want to use the zcat program to un-gzip and output a');
      InsertUsage( '         whole folder of gzipped logs and then pipe that to this program.');
      InsertUsage( '');
      InsertUsage( 'Usage:');
      InsertUsage( '   aws_log_folder_to_csv [-f <input file name>] [-o <output file name>]');
      InsertUsage( '');
      InsertUsage( '   ========== Program Options ==========');
      SetInputFileParam( true, true, false, true);
      SetOutputFileParam( false, true, false, true);
      InsertUsage();

      ParseParams();
   end; // InitArgvParser();


// ************************************************************************
// * main()
// ************************************************************************

var
   Aws:      tAwsLog;
   Header:   tAwsLogStringArray;
   S:        string;
begin
   InitArgvParser();
   Aws:= tAwsLog.Create( lbp_input_file.InputStream, False);
   
   AWS.Destroy;
end. // aws_log_to_csv
