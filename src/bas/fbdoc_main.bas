/'* \file fbdoc_main.bas
\brief The source file with the main function

This file includes the main function to execute.

'/

#INCLUDE ONCE "fbdoc_options.bi"
#INCLUDE ONCE "fbdoc_version.bi"


/'* \brief The help message for the command line interface (mode \ref SecModHelp) '/
#DEFINE MSG_HELP _
  "Command line tool for generating documentation from FreeBASIC source code." & NL & NL & _
  "Usage" & NL & _
  "  " & FBDOC_BINARY & " [Options] [file specs]" & NL & NL & _
  "Options:" & NL & _
  " -h (--help)    : print this help text and stop" & NL & _
  " -v (--version) : print version information and stop" & NL & _
  "       none         : file in --> STDOUT" & NL & _
  " -f (--file-mode)   : file in --> file out" & NL & _
  " -g (--geany-mode)  : STDIN --> STDOUT" & NL & _
  " -l (--list-mode)   : Doxgfile inputs --> fbdoc.lfn" & NL & _
  " -s (--syntax-mode) : scan doxygen output, repair syntax highlighting" & NL & _
  " -a (--asterix)     : prepend '* ' in ML comments (gtk-doc style)" & NL & _
  " -c (--cstyle)      : emit real C types" & NL & _
  " -d (--doc-comment) : force documentational comments in listings" & NL & _
  " -e (--emitter)     : specify emitter name" & NL & _
  " -L (--ListFunctionNames) : specify path & name of *.lfn file" & NL & _
  " -o (--outpath)     : specify output directory" & NL & _
  " -r (--recursiv)    : scan input files also in subfolders" & NL & _
  " -t (--tree)        : scan source tree (follow #INCLUDEs)" & NL & _
  "Examples:" & NL & _
  "  " & FBDOC_BINARY & " --geany-mode" & NL & _
  "      Get input from STDIN, prepend a matching comment block, emit to STDOUT" & NL & _
  "      (emits gtk-doc templates for ENUM, UNION, TYPE, SUB, FUNCTION, PROPERTY)" & NL & _
  "  " & FBDOC_BINARY & " -f -t MyProject.bas" & NL & _
  "      Load MyProject.bas from current folder and follow source tree" & NL & _
  "      emit pseudo C code in ../c_src" & NL & _
  "Find detailed description at:" & NL & _
  "  " & PROJ_WEBS & NL

/'* \brief The welcome message, shown when running as a program (mode \ref SecModFile) '/
#DEFINE MSG_WELCOME _
  "version " & PROJ_VERS & ", License GPLv3" & NL & _
  "        Copyright (C) 2012-" & PROJ_YEAR & " by " & PROJ_MAIL & NL

/'* \brief The version information for the command line interface (mode \ref SecModVersion) '/
#DEFINE MSG_VERSION _
  "  Compiled: " & __DATE__ & ", " & __TIME__ & " for " & _
  FBDOC_TARGET & ". (" & __FB_SIGNATURE__ & ")" & NL

#IFDEF __FB_UNIX__
/'* \brief The target operation system (used in \ref MSG_VERSION, UNIX version here) '/
 #DEFINE FBDOC_TARGET "UNIX/LINUX"
/'* \brief The name of the binary (used in \ref MSG_HELP, UNIX version here) '/
 #DEFINE FBDOC_BINARY PROJ_NAME
#ELSE
'&/*
 #DEFINE FBDOC_TARGET "win/dos"
 #DEFINE FBDOC_BINARY PROJ_NAME & ".exe"
'&*/
#ENDIF


/'* \brief A dummy function

This function is not in FB code. It's necessary to make Doxygen create
caller / callee graphs for the function calls in that code. That's why
we cover the main code in FB source by a pseudo C function.

'/
'&int main () { /* dummy function and calls for Doxygen */
'&Parser.StdIn(); Options.FileModi()

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
      IF .EmitIF->CTOR_ THEN .EmitIF->CTOR_(OPT)
      .Pars->StdIn()
      IF .EmitIF->DTOR_ THEN .EmitIF->DTOR_(OPT)
      CLOSE #.Ocha
    CASE ELSE
      .FileModi()
    END SELECT
    DELETE .EmitIF
  END IF
END WITH

DELETE OPT

'&}
