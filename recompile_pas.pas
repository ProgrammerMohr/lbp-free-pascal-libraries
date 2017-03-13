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
      public
         Name:       string;
         Folder:     string;
         Found:      boolean;
         Prog:       boolean;
         DependsOn:  tFPList;
         UsedBy:     tFPList;
         constructor Create( iName: string; iFolder: string);
         destructor  Destroy(); override;
      end; // tCode class


// ***********************************************************************
// * Create() - constructor
// ***********************************************************************

constructor tCode.Create( iName: string; iFolder: string);
   begin
      Name:=       iName;
      Folder:=     iFolder;
      Found:=      false;
      Prog:=       false;
      DependsOn:=  tFPList.Create();
      UsedBy:=     tFPList.Create();
   end; // Create()


// ***********************************************************************
// * Destroy() - destructor
// ***********************************************************************

destructor tCode.Destroy();
   begin
      DependsOn.Destroy;
      UsedBy.Destroy;
   end; // Destroy()

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
      CurrentDir: UnicodeString;

   // --------------------------------------------------------------------
   // - RecusiveLOF()
   // --------------------------------------------------------------------

   procedure RecusiveLOF( Path: UnicodeString);
      var
         FileInfo: TUnicodeSearchRec;
         L: integer; // The length of the file name
      begin
         chdir( Path);
         if( FindFirst ('*', faAnyFile and faDirectory, FileInfo) = 0) then Repeat
            if( (FileInfo.Attr and faDirectory) = faDirectory) then begin
               
               Writeln( 'Directory');
               Writeln( '   Name = ', FileInfo.Name);
               Writeln( '   Path = ', Path);
               // Call the recursive function
            end else begin
               // Handle a standard file - Does it end with a *.pas or *.pp?
               L:= length( FileInfo.Name);
               if( (pos( '.pas', FileInfo.Name) = (L - 3)) or
                   (pos( '.pp',  FileInfo.Name) = (L - 2))) then begin
                  writeln( 'Pascal file = ', FileInfo.Name);
               end; // if it ends in .pas or .pp
            end;
         Until FindNext( FileInfo) <> 0;
      end; // RecursiveLOF()

   // --------------------------------------------------------------------

   begin
      result:= tFPList.Create;
      GetDir( 0, CurrentDir);

      RecusiveLOF( CurrentDir);
      ChDir( CurrentDir);
   end; // CreateListOfFiles()


// ************************************************************************
// * main()
// ************************************************************************

begin
   Codes:= CreateListOfFiles();

   Codes.Destroy;
end.  // recompile_pas
