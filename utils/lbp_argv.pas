{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

parse command line parameters

This file is part of Lloyd's Free Pascal Libraries (LFPL).

    LFPL is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as 
    published by the Free Software Foundation, either version 2.1 of the 
    License, or (at your option) any later version with the following 
    modification:

    As a special exception, the copyright holders of this library 
    give you permission to link this library with independent modules
    to produce an executable, regardless of the license terms of these
    independent modules, and to copy and distribute the resulting 
    executable under terms of your choice, provided that you also meet,
    for each linked independent module, the terms and conditions of 
    the license of that module. An independent module is a module which
    is not derived from or based on this library. If you modify this
    library, you may extend this exception to your version of the 
    library, but you are not obligated to do so. If you do not wish to
    do so, delete this exception statement from your version.

    LFPL is distributed in the hope that it will be useful,but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General 
    Public License for more details.

    You should have received a copy of the GNU Lesser General Public 
    License along with LFPL.  If not, see <http://www.gnu.org/licenses/>.

*************************************************************************** *}

// A unit to parse command line parameters
//
// Programs should use InsertUsage() and InsertParam() to populate the top
// portion of the Usage message.
//
// Units should use AddUsage() and AddParam() to populate the bottom portion
// of the usage message.
//
// Both programs and units may create a ParseArgV() procedure which calls
// GetParam() and ParamSet() to determin the validity of the passed parameters.
// If a parseArgV() procedure is defined, then AddPostParseProcedure( @ParseArgV)
// Should be called.
//
// The main program and only the main program should call ParseParams() after
// any InsertUsage(), InsertParam(), and AddPostParseProcedure( @ParseArgV) calls.
//
// The main program may optionally call CleanParams() to free the memory used by
// the lbp_argv unit.  For this reason ParseArgV() procedures should copy any
// parameter values which may be needed later to local variables.

unit lbp_argv;

interface

{$include lbp_standard_modes.inc}
{$LONGSTRINGS ON}

uses
   lbp_types,
   lbp_string_trees,
   lbp_lists,
   lbp_delayed_exceptions,
   sysutils;

// ************************************************************************

type
   tArgVParseProc = procedure();
   argv_exception = class( lbp_exception);


// ************************************************************************

var
   PVTree:            tStringTree;       // A tree of named ParamValues for easy lookup.
   UnnamedParams:     array of string;
   

// ************************************************************************
// * show_init should be tested in program's initialization and parse_argv()
// *           procedures.  If true they should writeln progress reports.
// *           show_init is read from command line parameters early so that 
// *           it can be used right away.
// * show_progress and show_debug should be used in a similar fashion in
// *           any unit or program.
// ************************************************************************

var
   // show_init:      defined in lbp_types
   show_init_text:    string  = 'show_init';
   // show_progress:  defined in lbp_types
   // show_debug:     defined in lbp_types

   
// ************************************************************************
// * ParamValue - A class to hold the value of a parameter
// ************************************************************************

type
   ParamValue = class
//      private
      public
         Str:           string; // the string value
         InUse:         boolean; // true or false
         ValueRequired: boolean;
      public
         constructor Create();
      end;



// ************************************************************************

procedure Usage( HaltProgram: boolean = false; Message: string = '');
procedure InsertUsage( S: string = '');
procedure AddUsage( S: string = '');
function  InsertParam( Names: array of string;
                       ValueRequired: boolean = false;
                       DefaultValue: string = '';
                       Usage: string = ''): ParamValue;
function  AddParam( Names: array of string;
                    ValueRequired: boolean = false;
                    DefaultValue: string = '';
                    Usage: string = ''): ParamValue;
procedure AddParamAlias( Alias: string; Name: string);
procedure AddPostParseProcedure( P: tArgVParseProc);
function  GetParam( Name: string): string;
function  ParamSet( Name: string): boolean;
procedure ParseHelper( Name: string; var Value: string);
procedure ParseHelper( Name: string; var Value: integer);
procedure ParseParams();
procedure CleanParams(); // Delete all the objects in this unit.
procedure DumpParams(); // For debugging

var
   // These variables are populated by ParamStr( 0);
   ProgramName:      string = '';
   ProgramFullName:  string = '';
   ProgramDirectory: string = '';
   ProgramExtension: string = '';
   Parsed:           boolean = false;   // set true if ParseParams() has been called.

   
// ************************************************************************

implementation

// ========================================================================
// = ParamNode Class
// ========================================================================

constructor ParamValue.Create();
   begin
      inherited Create();
      Str:=   '';
      InUse:= false;
   end; // Create();


// ========================================================================
// = Global variables and procedures;
// ========================================================================

var
   UsageList1: DoubleLinkedList;  // A list of usage messages (used by InsertXXX)
   UsageList2: DoubleLinkedList;  // A list of usage messages (used by AddXXX)
   PVList:     DoubleLinkedList;  // A list of ParamValues
   PostParse:  DoubleLinkedList;  // A list of post parse procedure to be run.
   Cleaned:    boolean = false;   // CleanParams() has been called.


// ************************************************************************
// * Usage() - Print the usage message and optionaly halt the program
// ************************************************************************

procedure Usage( HaltProgram: boolean = false; Message: string = '');
   var
      SP: StringPtr;
   begin
      while( not UsageList1.Empty()) do begin
         SP:= StringPtr( UsageList1.Dequeue);
         writeln( SP^);
         dispose( SP);
      end;
      while( not UsageList2.Empty()) do begin
         SP:= StringPtr( UsageList2.Dequeue);
         writeln( SP^);
         dispose( SP);
      end;
      if( length( Message) > 0) then begin
         writeln;
         writeln( Message);
         writeln;
      end;
      if( HaltProgram) then begin
         CleanParams;
         halt;
      end;
   end; // Usage()


// ************************************************************************
// * AddUsage() - Add a string to the usage message
// ************************************************************************

procedure AddUsage( S: string);
   var
      SP: StringPtr;
   begin
      new( SP);
      SP^:= S;
      UsageList2.Enqueue( SP);
   end; // AddUsage();


// ************************************************************************
// * InsertUsage() - Set the program name, description for the usage message
// ************************************************************************

procedure InsertUsage( S: string);
   var
      SP: StringPtr;
   begin
      new( SP);
      SP^:= S;
      UsageList1.Enqueue( SP);
   end; // InsertUsage();


// ************************************************************************
// * AddParamSub - A subroutine used by AddParam() and InsertParam()
// ************************************************************************

function AddParamSub( Insert: boolean;
                      Names: array of string;
                      ValueRequired: boolean;
                      DefaultValue: string;
                      Usage: string): ParamValue;
   var
      i:        integer;
      Max:      integer;
      Message:  string;
      PName:    string;
      PV:       ParamValue;
      Hyphens:  string;
   begin
      Max:= length( Names) - 1;
      PV:= ParamValue.Create();
      PVList.Enqueue( PV);
      PV.Str:= DefaultValue;
      PV.ValueRequired:= ValueRequired;
      for i:= 0 to Max do begin
         PName:= Names[ i];
         if( Length( PName) = 1) then begin
            Hyphens:= '-';
         end else begin
            Hyphens:= '--';
         end;

         PVTree.Add( PName, PV);
         result:= PV;

         if( i = 0) then begin
            Message:= '   ' + Hyphens + PName
         end else begin
            Message:= Message + ', ' + Hyphens + PName;
         end;
      end;

      if( Insert) then begin
         InsertUsage( format( '%:-30s %s', [Message, Usage]));
      end else begin
         AddUsage( format( '%:-30s %s', [Message, Usage]));
      end;
   end; // AddParamSub()


// ************************************************************************
// * AddParam - Add a parameter which will be looked for.
// ************************************************************************

function AddParam( Names: array of string;
                   ValueRequired: boolean = false;
                   DefaultValue: string = '';
                   Usage: string = ''): ParamValue;
   begin
      result:= AddParamSub( false, Names, ValueRequired, DefaultValue, Usage);
   end; // AddParam()


// ************************************************************************
// * InsertParam - Add a parameter which will be looked for.
// ************************************************************************

function InsertParam( Names: array of string;
                      ValueRequired: boolean = false;
                      DefaultValue: string = '';
                      Usage: string = ''): ParamValue;
   begin
      result:= AddParamSub( true, Names, ValueRequired, DefaultValue, Usage);
   end; // InsertParam()


// ************************************************************************
// * AddParamAlias() - Adds a new name an existing name.  For example:
//
// ************************************************************************

procedure AddParamAlias( Alias: string; Name: string);
   var
      PV:  ParamValue;
   begin
      PV:= ParamValue( PVTree.Find( Name).AuxData);
      if( PV = nil) then raise argv_exception.Create( Name + ' parameter is not available.');
      PVTree.Add( Alias, PV);
   end; // AddParamAlias()

   
// ************************************************************************
// * AddPostParseProcedure() - Addd the passed procedure to the list of
// *                           procedures to be called after ParseParams is
// *                           otherwise done.
// ************************************************************************

procedure AddPostParseProcedure( P: tArgVParseProc);
   begin
      PostParse.Enqueue( P);
   end; // AddPostParseProcedure();


// ************************************************************************
// * GetParam() - Returns the names parameter's value
// ************************************************************************

function GetParam( Name: string): string;
   var
      PV:   ParamValue;
   begin
      PV:= ParamValue( PVTree.Find( Name).AuxData);
      if( PV = nil) then raise argv_exception.Create( Name + ' parameter is not available.');
      result:= PV.Str;
   end; // GetParam()


// ************************************************************************
// * ParamSet() - Returns true if the parameter was set on the command line.
// ************************************************************************

function ParamSet( Name: string): boolean;
   var
      PV:   ParamValue;
   begin
      PV:= ParamValue( PVTree.Find( Name).AuxData);
      if( PV = nil) then raise argv_exception.Create( Name + ' parameter is not available.');
      result:= PV.InUse;
   end; // ParamSet()


// ************************************************************************
// * ParseHelper() - This should be called in other unit's ParseArgV
// *                 routines to set a Value if it has be changed on the
// *                 command line.
// ************************************************************************

procedure ParseHelper( Name: string; var Value: string);
   var
      PV:   ParamValue;
   begin
      PV:= ParamValue( PVTree.Find( Name).AuxData);
      if( PV = nil) then raise argv_exception.Create( Name + ' parameter is not available.');
      if( PV.InUse) then Value:= PV.Str;
   end; // ParseHelper


// ------------------------------------------------------------------------

procedure ParseHelper( Name: string; var Value: integer);
   var
      PV:    ParamValue;
      Temp:  integer;
      Code:  word;
   begin
      PV:= ParamValue( PVTree.Find( Name).AuxData);
      if( PV = nil) then raise argv_exception.Create( Name + ' parameter is not available.');
      if( PV.InUse) then begin
         Val( PV.Str, Temp, Code);
         if( Code > 0) then raise argv_exception.Create( Name + ' parameter value is not a valid integer!');
         Value:= Temp;
      end;
   end; // ParseHelper


// ************************************************************************
// * ParseParams() - Parse all the parameters
// ************************************************************************

procedure ParseParams();
   var
      P:          tArgVParseProc;
      iP:         integer;
      PV:         ParamValue;
      Name:       string;
      Value:      string;
      Node:       tStringObj;
      i:          integer;
   begin
      Parsed:= true;

      PV:= nil;
      for iP:= 1 to ParamCount do begin
         // Have we previously found a named parameter but not the value?
         if( PV = nil) then begin
            Name:= ParamStr( iP);
            // is this a named parameter?
            if( Name[ 1] = '-') then begin
               i:= 2;
               if( Name[ 2] = '-') then i:= 3;
               Name:= Copy( Name, i, Length( Name));
               i:= pos( '=', Name);
               if( i > 0) then begin
                  Value:= Copy( Name, i + 1, Length( Name));
                  Name:= Copy( Name, 1, i - 1);
               end;
               Node:= PVTree.Find( Name);
               if( Node = nil) then begin
                  Usage();
                  raise argv_exception.Create( 'Unrecognized parameter ' + Name + ' on the command line!');
               end;

               // We now know this is a valid named parameter
               PV:= ParamValue( Node.AuxData);

               // Name=Value pair?
               if( i > 0) then begin
                  if( PV.ValueRequired) then begin
                     PV.InUse:= true;
                     PV.Str:= Value;
                     PV:= nil;
                  end else begin
                     Value:= lowercase( Value);
                     if( (Value = '1') or (Value = 't') or (Value = 'true') or (Value = 'y') or (Value = 'yes')) then begin
                        PV.InUse:= true;
                     end else begin
                        PV.InUse:= false;
                     end; // true or false Value
                  end;
               end else begin

                  // else not a Name=Value pair
                  if( not PV.ValueRequired) then begin
                     PV.InUse:= true;
                     PV:= nil;
                  end;
               end; // if/else Name=Value pair
            end else begin
               // This is an unnamed parameter
               i:= Length( UnnamedParams);
               setlength( UnnamedParams, i + 1);
               UnnamedParams[ i]:= Name;
            end;
         end else begin
            // PV <> nil
            // This is the stand alone value of a named parameter
            PV.Str:= ParamStr( iP);
            PV.InUse:= true;
            PV:= nil;
         end; // else PV <> nil
      end; // for

      if( PV <> nil) then begin
         Usage();
         raise argv_exception.Create( 'Command line parameter ' + Name + ' requires a value and no value was specified!');
      end;

      // Handle post processing
      while( not PostParse.Empty) do begin
         P:= tArgVParseProc( PostParse.Dequeue);
         if( show_init) then begin
            P();
         end else begin
            try
               P();
            except
               on E: Exception do DelayException( E);
            end;
         end;
      end;

      // Handle errors which occured durring post processing
      RaiseDelayedExceptions( 'The following errors occured during program initialization:');
   end; // ParseParams();


// ************************************************************************
// * CleanParams() - Remove all the objects created by this unit.
// ************************************************************************

procedure CleanParams();
   var
      SP:  StringPtr;
      PV:  ParamValue;
   begin
      if Cleaned then exit;


      while( not UsageList1.Empty()) do begin
         SP:= StringPtr( UsageList1.Dequeue);
         dispose( SP);
      end;
      UsageList1.Destroy;

      while( not UsageList2.Empty()) do begin
         SP:= StringPtr( UsageList2.Dequeue);
         dispose( SP);
      end;
      UsageList2.Destroy;

      PVTree.RemoveAll( true);
      PVTree.Destroy;

      while( not PVList.Empty()) do begin
         PV:= ParamValue( PVList.Dequeue);
         PV.Destroy();
      end;
      PVList.Destroy();

      while( not PostParse.Empty) do PostParse.Dequeue();
      PostParse.Destroy();

      Cleaned:= true;
   end; // CleanParams();


// ************************************************************************
// * DumpParams()
// ************************************************************************

procedure DumpParams();
   var
      i:  integer;
      L:  integer;
      PV: ParamValue;
      S:  string;
      T:  tStringTree;
   begin
      writeln( '====================================================');
      writeln( 'Command line parameter dump');
      T:= tStringTree.Create( false);
      PVTree.Copy( T);
      S:= T.GetFirst();
      while( Length( S) > 0) do begin
         PV:= ParamValue( PVTree.Find( S).AuxData);
         if( PV.ValueRequired) then begin
            if( PV.InUse) then begin
               writeln( '   ', S, '=', PV.Str);
            end;
         end else begin
            if( PV.InUse) then begin
               writeln( '   ', S, '=true');
            end else begin
               writeln( '   ', S, '=false');
            end;
         end;
         S:= T.GetNext();
      end;
      T.RemoveAll( false);
      T.Destroy();

      L:= length( UnnamedParams) - 1;
      for i:= 0 to L do begin
         writeln( '   =', UnnamedParams[ i]);
      end;
      writeln( '====================================================');
   end; // DumpParams()


// *************************************************************************
// * ParseArgV() - Parse the command line parameters
// *************************************************************************

procedure ParseArgv();
   begin
      // if the user asked for help, print the usage message and exit.
      if ParamSet( '?') then begin
         Usage();
         CleanParams;
         halt;
      end;
      show_debug:=     ParamSet( 'show-debug');
      show_Progress:=  ParamSet( 'show-progress') or show_debug;
   end; // ParseArgV


// *************************************************************************
// * ParseProgramName() - Parse the 0th Argument
// *************************************************************************

procedure ParseProgramName();
   var
      i:      integer;
      s:      integer = 0; // Location of the rightmost directory separator in ProgramFullName
      d:      integer = 0; // Location of the rightmost dot in ProgramFullName
   begin
      // Get Program Name, directory, and extension.
      ProgramFullName:= ParamStr( 0);
      i:= Length( ProgramFullName);
      while( (s = 0) and (i >= 1)) do begin
         case ProgramFullName[ i] of
            DirectorySeparator: s:= i;
            '.':                d:= i;
         end; // case
         dec( i);
      end;
      if( S = 0) then begin
         GetDir( 0, ProgramDirectory);
      end else if( S = 1) then begin
         ProgramDirectory:= DirectorySeparator;
      end else begin
         ProgramDirectory:= Copy( ProgramFullName, 1, s - 1);
      end;
      ProgramName:= copy( ProgramFullName, s + 1, Length( ProgramFullName) - s);
      if( d > 0) then begin
         ProgramExtension:= Copy( ProgramFullName, d + 1, Length( ProgramFullName) - d);
         if( UpperCase( ProgramExtension) = 'EXE') then begin
            SetLength( ProgramName, Length( ProgramName) - 4);
         end;
      end;
   end; // ParseProgramName()


// ************************************************************************
// * Preset_show_init() - Set the show_init boolean if the --show-init
//                        command line parameter is present.
// ************************************************************************

procedure Preset_show_init();
   var
      iP:         integer;
      P:          string;
   begin
      for iP:= 1 to ParamCount do begin
         P:= ParamStr( iP);
         if( (P = '-show-init' ) or (P = '--show-init')) then show_init:= true;
      end;
   end; // Preset_show_init()
   

// ========================================================================
// = Initialization and Finalization
// ========================================================================


initialization
   begin
      Preset_show_init();
      if( show_init) then writeln( 'lbp_argv.initialization:  show_init enabled');
      ParseProgramName;
      UsageList1:= DoubleLinkedList.Create();
      UsageList2:= DoubleLinkedList.Create();
      PVList:=     DoubleLinkedList.Create();
      PVTree:=     tStringTree.Create( False);
      PostParse:=  DoubleLinkedList.Create();
      setlength( UnnamedParams, 0);
      AddUsage( '   ========== General Parameters ==========');
      AddParam( ['?','help'], false, '', 'Display this help message and exit');
      AddUsage( '');
      AddUsage( '   ========== Program Debuging Parameters ==========');
      AddParam( ['show-debug'], false, '',   'Display any available debug messages');
      AddParam( ['show-progress'], false, '', 'Similar to show-debug but less verbose');
      AddParam( ['show-init'], false, '', 'Display progress reports of initialization');
      AddUsage( '                                 and ParseArgv() procedures.');
      AddUsage();
      AddPostParseProcedure( @ParseArgv);
      if( show_init) then writeln( 'lbp_argv.initialization:  end');
   end; // initialization


// ************************************************************************

finalization
   begin
      if( show_init) then writeln( 'lbp_argv.finalization:  begin');
      CleanParams();
      if( not Parsed) then raise argv_exception.Create( 'The lbp_argv unit was included in the program, but ParseParams() was not called!');
      if( show_init) then writeln( 'lbp_argv.finalization:  end');
   end; // finalization;


// ************************************************************************
end. // lbp_argv unit
