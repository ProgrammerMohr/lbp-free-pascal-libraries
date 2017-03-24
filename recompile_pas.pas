{* ***************************************************************************

Copyright (c) 2017 by Lloyd B. Park

a class to handle some UNIX file information.

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

program recompile_pas;

{$include lbp_standard_modes.inc}

uses
   sysutils,  // functions to traverse a file directory
   classes;   // tFPList

// =======================================================================
// = tCode class - Holds a file name and its properties
// =======================================================================

type
   tCode = class
      private
         FIsOpen:    boolean;
         F:          Text; // The file
      public
         Name:       String;
         Folder:     String;
         Found:      boolean;
         Prog:       boolean;
         DependsOn:  tFPList; // List of tCode
         UsedBy:     tFPList; // List of tCode
         constructor Create( iName: String; iFolder: String);
         destructor  Destroy(); override;
         procedure   Dump( NameOnly: boolean = false; Indent: string = ''); // debug
         function    FullFileName(): string;
      private
         Line:       string;  // The current line as we parse the file
         iLine:      integer; // Current Position in the line.
         LLine:      integer; // The length of the line.   
         procedure   Open(); // Open the file
         procedure   Close(); // Close the file if it is open
         function    FullFileName(): string;
      end; // tCode class

{ Notes  Curly Braces and (* *) are multi line.  // is to end of line}

// ***********************************************************************
// * Create() - constructor
// ***********************************************************************

constructor tCode.Create( iName: String; iFolder: String);
   begin
      inherited Create();
      Name:=       iName;
      Folder:=     iFolder;
      Found:=      false;
      Prog:=       false;
      DependsOn:=  tFPList.Create();
      UsedBy:=     tFPList.Create();
      FIsOpen:=    false;
   end; // Create()


// ***********************************************************************
// * Destroy() - destructor
// ***********************************************************************

destructor tCode.Destroy();
   begin
      DependsOn.Destroy;
      UsedBy.Destroy;
      inherited Destroy;
   end; // Destroy()


// ***********************************************************************
// * Dump() - print the record to StdOut
// ***********************************************************************

procedure tCode.Dump( NameOnly: boolean; Indent: string);
   begin
      writeln( FullFileName);
      if( not NameOnly) then begin
      end;
   end; // Dump;


// ***********************************************************************
// * FullFileName() - Returns the full path file name
// ***********************************************************************
{*
junk 1
junk 2
*}
function tCode.FullFileName(): string;
   begin
      result:= Folder +  DirectorySeparator + Name;
   end; // FullFileName()


// =======================================================================
// = Global functions and variables
// =======================================================================

var
   Progs: tFPList;  // A list of files which have been found to be programs
   Codes: tFPList;  // A list of files which initially are units and programs
                    // Later the programs will be moved to Progs.


// ***********************************************************************
// * CreateListOfFiles() - Returns an tFPList of tCode
// ***********************************************************************
{$WARNING Create an outer function which creates the tFPList and returns it}
{$WARNING It then calls the inner function which is recusive.}
function CreateListOfFiles( Path: string = '.'): tFPList;
   var
      CurrentDir: String;
      FileList:   tFPList;

   // --------------------------------------------------------------------
   // - RecursiveLOF()
   // --------------------------------------------------------------------

   procedure RecursiveLOF( Path: String);
      var
         FileInfo:   TSearchRec;
         L:          integer; // The length of the file name
         FolderList: tStringList;
         FolderName: String;
      begin
         FolderList:= tStringList.Create();
         chdir( Path);
         if( FindFirst ('*', faAnyFile and faDirectory, FileInfo) = 0) then Repeat
            if( (FileInfo.Attr and faDirectory) = faDirectory) then begin
               if( (FileInfo.Name = '.') or (FileInfo.Name = '..')) then continue;
               FolderName:= Path + DirectorySeparator + FileInfo.Name;
               FolderList.Add( FolderName);
            end else begin
               // Handle a standard file - Does it end with a *.pas or *.pp?
               L:= length( FileInfo.Name);
               if( (pos( '.pas', FileInfo.Name) = (L - 3)) or
                   (pos( '.pp',  FileInfo.Name) = (L - 2))) then begin
                  FileList.Add( tCode.Create( FileInfo.Name, Path));
               end; // if it ends in .pas or .pp
            end;
         Until FindNext( FileInfo) <> 0;
         FindClose( FileInfo);

         // Now process the list of subfolders.  We have to do it this way because
         //    Find() and FindNext() can not be called recursively.
         for FolderName in FolderList do RecursiveLOF( FolderName);
         FolderList.Clear;
         FolderList.Destroy;
      end; // RecursiveLOF()

   // --------------------------------------------------------------------

   begin
      FileList:= tFPList.Create;
      result:= FileList;
      GetDir( 0, CurrentDir);

      RecursiveLOF( CurrentDir);
      ChDir( CurrentDir);
   end; // CreateListOfFiles()


// ************************************************************************
// * main()
// ************************************************************************
var
   C:  tCode;
   i:  integer;
begin
   Codes:= CreateListOfFiles();

   // dump the contents of Codes
   for i:= 0 to Codes.Count - 1 do begin
      C:= tCode( Codes.Items[ i]);
      C.Dump;
      C.Destroy;
   end;

   Codes.Destroy;
end.  // recompile_pas
