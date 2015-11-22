/'* \file fb-doc_emit_callees.bas
\brief Emitter to generate the file \em fb-doc.lfn.

This file contains the emitter called "FunctionNames", used to generate
the file \em fb-doc.lfn for the Doxygen Back-end filter feature. It's
the default emitter in mode `--list-mode`.

The emitter writes the names of all functions (`SUB` / `FUNCTION` /
`PROPERTY`) to the output stream, one in a line, separated by a new
line character `CHR(10)`.

'/

#INCLUDE ONCE "fb-doc_emit_callees.bi"
#INCLUDE ONCE "fb-doc_options.bi"


CONST CALLEE_TR = !"\n" '*< Separator for entries in file \em fb-doc.lfn.


FUNCTION startLFN(BYREF Path AS STRING) AS INTEGER
  VAR fnr = FREEFILE
  IF OPEN(Path & CALLEES_FILE FOR OUTPUT AS #fnr) THEN RETURN 0
  PRINT #fnr, "+++ List of Function Names +++"
  RETURN fnr
END FUNCTION


'SUB callees_CTOR CDECL(BYVAL P AS Parser PTR)
      'IF 0 = Ocha THEN
        'MSG_LINE(OutPath & CALLEES_FILE)
        'Ocha = startLFN(OutPath)
        'IF 0 = Ocha THEN MSG_END("error (couldn't write)") : EXIT SUB
        'MSG_END("opened")
      'END IF
'END SUB


SUB callees_DTOR CDECL(BYVAL P AS Parser PTR)
END SUB


/'* \brief Emitter to generate a declaration line
\param P the parser calling this emitter

This emitter gets called when the parser is in a declaration (VAR /
DIM / CONST / COMMON / EXTERN / STATIC / DECLARE). It generates a line for
each variable name and sends it (them) to the output stream.

'/
SUB callees_decl_ CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    SELECT CASE AS CONST *.StaTok
    CASE .TOK_SUB, .TOK_FUNC, .TOK_PROP
    CASE ELSE : EXIT SUB
    END SELECT : IF 0 = .NamTok ORELSE 0 = .FunTok THEN EXIT SUB
    .PtrCount = 0
    cNam(P)
    Code(CALLEE_TR)
  END WITH
END SUB


/'* \brief Emitter to start parsing of blocks
\param P the parser calling this emitter

This emitter gets called when the parser finds a block (`TYPE  UNION
ENUM`). It starts the scanning process in the block.

'/
SUB callees_class_ CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    IF OPT->AllCallees THEN .parseBlockTyUn(@callees_decl_())
  END WITH
END SUB


/'* \brief Emitter to generate a line for a function name
\param P the parser calling this emitter

This emitter gets called when the parser finds a function (`SUB
FUNCTION  PROPERTY`). It generates a line with the name of the
function and sends it to the output stream.

'/
SUB callees_func_ CDECL(BYVAL P AS Parser PTR) ' !!! ToDo member functions
  WITH *P '&Parser* P;
    SELECT CASE AS CONST *.StaTok
    CASE .TOK_SUB, .TOK_FUNC, .TOK_PROP
    CASE ELSE : EXIT SUB
    END SELECT
    .PtrCount = 0
    cNam(P)
    Code(CALLEE_TR)
  END WITH
END SUB


/'* \brief Emitter to import a source file
\param P the parser calling this emitter

This emitter gets called when the parser finds an #`INCLUDE`
statement and option `--recursiv` is given. It checks if the file
has been done already. If not, it creates a new #Parser and starts
the scanning process.

'/
SUB callees_include CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    IF OPT->InTree THEN .Include(TRIM(.SubStr(.NamTok), """"))
  END WITH
END SUB



/'* \brief FIXME
\param P FIXME

FIXME

\since 0.4.0
'/
SUB callees_init(BYVAL P AS EmitterIF PTR)
  WITH *P
    .Clas_ = @callees_class_
    .Unio_ = @callees_class_
    .Func_ = @callees_func_
    .Decl_ = @callees_decl_
    .Incl_ = @callees_include
  END WITH
END SUB

