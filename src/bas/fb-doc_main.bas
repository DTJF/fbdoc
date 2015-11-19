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
      .Pars->StdIn()
      CLOSE #.Ocha
    CASE ELSE
      .FileModi()
    END SELECT
    DELETE .EmitIF
  END IF
END WITH

DELETE OPT

'&}
