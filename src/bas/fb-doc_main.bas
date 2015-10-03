/'* \file fb-doc_main.bas
\brief The source file with the main function

This file includes the main function to execute.

'/

#INCLUDE ONCE "fb-doc_version.bi"
#INCLUDE ONCE "fb-doc_options.bi"
#INCLUDE ONCE "fb-doc_parser.bi"
#INCLUDE ONCE "fb-doc_emitters.bi"
#INCLUDE ONCE "fb-doc_emit_callees.bi"
#INCLUDE ONCE "fb-doc.bi"


/'* \brief A dummy function

This function is not in FB code. If it is omitted, then Doxygen doesn't
create caller / callee graphs for the function calls in that code.
That's why we cover the FB main part by a a pseudo C function.

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
