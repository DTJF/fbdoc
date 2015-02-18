' coding: UTF-8
' This is
CONST PROG_NAME = "fb-doc" '*< the name of the programm
CONST PROG_VERS = "0.3.9"  '*< the program version

/'* \file fb-doc.bas
\brief The main source file to compile

This main file includes all the submodules. Compile it by
fbc (the FreeBASIC compiler) to create your fb-doc binary.

'/


/'* \mainpage fb-doc

fb-doc is a tool for generating documentation from and for FreeBasic 
source code. Rather than creating the documentation output directly, 
fb-doc is designed to close the gap between FreeBasic (= FB) and C 
syntax to allow for using any C / C++ documentation tool-chain. Also 
it supports the creation of documentational comments in the source 
and it can get extended via external plugins.

Find more information in the tutorial pages

- \subpage pageIntro
- \subpage pageInstall
- \subpage pageUsage
- \subpage pageTables
- \subpage pageOptionDetails
- \subpage pageEmitterDetails
- \subpage pageFilesUsed
- \subpage pageExamples
- \subpage pageExtend
- \subpage pageToDo

or at the world wide web:

 - en: \ProjPage
 - de: http://www.freebasic-portal.de/downloads/ressourcencompiler/fb-doc-229.html


\section licence fb-doc licence (GPLv3):

Copyright &copy; 2012-2014 by Thomas{ DoT ]Freiherr[ aT ]gmx[ dOt }net

This program is free software; you can redistribute it and/or modify 
it under the terms of the GNU General Public License as published by 
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but 
WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU 
General Public License for more details.

You should have received a copy of the GNU General Public License 
along with this program; if not, write to the Free Software 
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110- 
1301, USA. For further details please refer to: 
http://www.gnu.org/licenses/gpl-3.0.html


\section ackno Acknowledgements

Thanks go to:

 - Dimitri van Heesch (author of Doxygen)
 - Chris Lyttle, Dan Mueth, Stefan Kost (authors of gtk-doc)
 - the FreeBasic developers (a great modern programming language with fun-factor)
 - AGS (from http://www.freebasic.net/forum) for testing and bug reporting

'/

#INCLUDE ONCE "fb-doc.bi"

#INCLUDE ONCE "fb-doc_doxyfile.bas"
#INCLUDE ONCE "fb-doc_parser.bas"
#INCLUDE ONCE "fb-doc_emitters.bas"
#INCLUDE ONCE "fb-doc_options.bas"

/'* \brief A dummy function

This function is not in FB code. If it is omitted, then Doxygen doesn't
create caller / callee graphs for the function calls in that code.
That's why we cover the FB main part by a a peudo C function.

'/
'&int main () { /* dummy function for Doxygen */

OPT = NEW Options()

WITH *.OPT
  IF .Efnr THEN
    SELECT CASE AS CONST .parseCLI()
    CASE   .ERROR_MESSAGE : ERROUT("Invalid command line (" & MID(.Errr, 3) & ")")
    CASE    .HELP_MESSAGE : ERROUT(MSG_WELCOME & MSG_HELP)
    CASE .VERSION_MESSAGE : ERROUT(MSG_WELCOME & MSG_VERSION)
    CASE .GEANY_MODE
      .InTree = 0 '                                  ignore user setting
      .Ocha = FREEFILE
      OPEN CONS FOR OUTPUT AS #.Ocha
      .Pars->StdIn()
'&    Parser.StdIn() /* dummy call for Doxygen */
      CLOSE #.Ocha
    CASE ELSE
      .FileModi()
'&    Options.FileModi() /* dummy call for Doxygen */
    END SELECT
  END IF
END WITH

DELETE OPT
FOR i AS INTEGER = 0 TO UBOUND(Emitters)
  DELETE Emitters(i)
NEXT

'&}
