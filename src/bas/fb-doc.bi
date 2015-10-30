/'* \file fb-doc.bi
\brief Header for the main source file

This file contains #`DEFINE`s for the user communication at the
command prompt and adjusts some operation system specific settings.

'/

/'* \brief The help message for the command line interface (option `--help`) '/
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
  " -l (--list-mode)   : Doxgfile inputs --> fb-doc.lfn" & NL & _
  " -s (--syntax-mode) : scan doxygen output, repair syntax highlighting" & NL & _
  " -a (--asterix)     : prepend '* ' in ML comments (gtk-doc style)" & NL & _
  " -c (--cstyle)      : emit real C types" & NL & _
  " -d (--doc-comment) : force documentational comments in listings" & NL & _
  " -e (--emitter)     : specify emitter name" & NL & _
  " -o (--outpath)     : specify output directory" & NL & _
  " -r (--recursiv)    : scan input files also in subfolders" & NL & _
  " -t (--tree)        : scan source tree (follow #INCLUDEs)" & NL & _
  "Examples:" & NL & _
  "  " & FBDOC_BINARY & " --geany-mode" & NL & _
  "      Get input from STDIN, prepend a matching comment block, emit to STDOUT" & NL & _
  "      (emits gtk-doc templates for ENUM, UNION, TYPE, SUB, FUNCTION, PROPERTY)" & NL & _
  "  " & FBDOC_BINARY & " -f -t MyProject.bas" & NL & _
  "      Load MyProject.bas from current folder and follow source tree" & NL & _
  "      emit pseudo C code in ../doc/c_src" & NL & _
  "For details see file 'ReadMe.txt' or visit:" & NL & _
  "  http://www.freebasic-portal.de/downloads/ressourcenc ompiler/fb-doc-229.html (de)" & NL & _
  "  http://www.freebasic.net/forum/viewtopic.php?f=8&t=19810 (en)" & NL

/'* \brief The welcome message, shown when running as a program (option `--file-mode`) '/
#DEFINE MSG_WELCOME _
  "version " & PROJ_VERS & ", License GPLv3" & NL & _
  "        Copyright (C) 2012-" & PROJ_YEAR & " by " & PROJ_MAIL & NL

/'* \brief The version information for the command line interface (option `--version`) '/
#DEFINE MSG_VERSION _
  "  Compiled: " & __DATE__ & ", " & __TIME__ & " for " & _
  FBDOC_TARGET & ". (" & __FB_SIGNATURE__ & ")" & NL

#IFDEF __FB_UNIX__
/'* \brief The target operation system (used in \ref MSG_VERSION, UNIX version here) '/
 #DEFINE FBDOC_TARGET "UNIX/LINUX"
/'* \brief The name of the binary (used in \ref MSG_HELP, UNIX version here) '/
 #DEFINE FBDOC_BINARY "./" & PROJ_NAME
#ELSE
'&/*
 #DEFINE FBDOC_TARGET "win/dos"
 #DEFINE FBDOC_BINARY PROJ_NAME & ".exe"
'&*/
#ENDIF

CONST _
  COMM_END = NL & NL & "'/" & NL, _ '*< the end of an FB comment block (in templates)
     FIXME = "FIXME"                '*< the text to initialize entry fields (in templates)
