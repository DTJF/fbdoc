/'* \file fb-doc.bas
\brief The main source file to compile

This main file includes all the submodules. Compile it by
fbc (the FreeBASIC compiler) to create your fb-doc binary.

'/


#INCLUDE ONCE "version.bas"
#INCLUDE ONCE "fb-doc.bi"

#INCLUDE ONCE "fb-doc_doxyfile.bas"
#INCLUDE ONCE "fb-doc_parser.bas"
#INCLUDE ONCE "fb-doc_emitters.bas"
#INCLUDE ONCE "fb-doc_options.bas"

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
