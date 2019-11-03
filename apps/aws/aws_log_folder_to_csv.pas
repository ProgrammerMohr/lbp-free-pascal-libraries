program aws_cdn_log_folder_to_csv;

// ************************************************************************
// * This program reads the current folder containing gzipped log entries 
// * from AWS. There is one log entry per file.
// ************************************************************************

uses
   lbp_argv,
   lbp_types, // show_debug, etc
   lbp_output_file,
   lbp_csv,  // just for the output routines.
   lbp_parse_helper;


// ************************************************************************

var
   LogFolder: string = '/Users/lpark/Desktop/OLD CDN LOGS-20191016';

// ************************************************************************
// * CreateLogFileList() - Reads the log folder and returns a list of 
// *                       log file names in alphabetical order. 
// ************************************************************************

function CreateLogFile


// ************************************************************************
// * InitArgvParser() - Initialize the command line usage message and
// *                    parse the command line.
// ************************************************************************

procedure InitArgvParser();
   begin
      InsertUsage( '');
      InsertUsage( 'aws_cdn_log_folder_to_csv reads log entries from AWS in the current folder');
      InsertUsage( '         and outputs them in CSV format.  AWS sends one log entry per');
      InsertUsage( '         gzipped file.  The program was written specifically for AWS CDN');
      InsertUsage( '         logs but may be generic enough to work will all logs.');
      InsertUsage( '');
      InsertUsage( 'Usage:');
      InsertUsage( '   aws_cdn_log_folder_to_csv [-l <log folder> [-o <output file name>]');
      InsertUsage( '');
      InsertUsage( '   ========== Program Options ==========');
      SetOutputFileParam( false, true, false, true);
      InsertUsage();

      ParseParams();
   end; // InitArgvParser();


// ************************************************************************
// * main()
// ************************************************************************

begin
   // Initialize
   InitArgvParser();
end. // aws_cdn_log_folder_to_csv
