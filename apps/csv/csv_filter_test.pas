program csv_filter_test;

uses
   lbp_argv,
   lbp_types,
   lbp_csv_io_filters;



begin
   ParseParams();
   CsvFilterQueue.Queue:= CsvInputFilter;
   CsvFilterQueue.Queue:= CsvOutputFilter;
   CsvFilterQueue.Go();

end. // csv_filter_test
