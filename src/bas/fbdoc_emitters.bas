/'* \file fbdoc_emitters.bas
\brief Code for EmitterIF and auxiliary functions.

This file contains the main source for EmitterIF, used by all emitters.
The Parser calls the matching function in the active EmitterIF, after
scanning a relevant construct. The emitter function extracts the
necessary information from the parser data, formats it as desired and
sends it to the output stream.

The file also includes some helper functions to extract code and
comments from the original source. And it contains the standard emitter
to translate to pseudo C intermediate format, either in C or CPP style
(the later is default, used for the Doxygen documentation back-end).

This format includes minimal C source code and all the documentation
comments (multi line comment blocks or line end). In order to get the
links working, which connects the documentation context and the source
code listings, the emitter places all C constructs in the same line
number as in the FB code. Also inside the lines, the emitter tries to
place all constructs similar as in the FB source (but a comment inside
a statement will be placed at the end of the corresponding C
statement).

'/

#INCLUDE ONCE "fbdoc_options.bi"
#INCLUDE ONCE "fbdoc_version.bi"


/'* \brief Handler to export comments
\param P the parser calling this handler
\param Stop_ the end position in the input buffer

Export the comments between the last position `SrcBgn` (= source begin)
and the `Stop_` position. After processing, the `Stop_` position gets
the new `SrcBgn`.

'/
SUB emit_comments CDECL(BYVAL P AS Parser PTR, BYVAL Stop_ AS INTEGER)
  WITH *P '&Parser* P;
    VAR i = .SrcBgn
    WHILE i <= Stop_
      SELECT CASE AS CONST .Buf[i]
      CASE 0 : EXIT WHILE
      CASE ASC(!"\n") : Code(NL)
      CASE ASC("""")
        SCAN_QUOTE(.Buf,i)
      CASE ASC("'")
        VAR c = i + 1
        SCAN_SL_COMM(.Buf,i)
        IF .Buf[c] = OPT->JoComm THEN c += 1 : Code("//!" & MID(.Buf, c + 1, i - c))
        IF .Buf[c] = OPT->AdLine THEN c += 1 : Code(MID(.Buf, c + 1, i - c))
        CONTINUE WHILE
      CASE ASC("/") : IF .Buf[i + 1] <> ASC("'") THEN EXIT SELECT
        i += 2
        VAR c = IIF(.Buf[i] = OPT->JoComm, i + 1, 0)
        IF c THEN Code(*IIF(OPT->Types = OPT->C_STYLE ,@"/**", @"/*!"))
        DO
          SELECT CASE AS CONST .Buf[i]
          CASE 0 : EXIT DO
          CASE ASC(!"\n") : IF 0 = c THEN Code(NL) : EXIT SELECT
            Code(MID(.Buf, c + 1, i - c + 1))
            c = i + 1
            IF .Buf[c] = ASC("'") ANDALSO .Buf[c + 1] = ASC("/") THEN EXIT SELECT
            IF OPT->Asterix THEN Code("* ")
          CASE ASC("'")
            SELECT CASE AS CONST .Buf[i + 1]
            CASE 0 : EXIT SUB
            CASE ASC("/") : i += 1 : EXIT DO
            END SELECT
          END SELECT : i += 1
        LOOP
        IF c THEN Code(MID(.Buf, c + 1, i - c - 1) & "*/")
      END SELECT : i += 1
    WEND : IF .SrcBgn < i THEN .SrcBgn = i
  END WITH
END SUB


/'* \brief Export the name (including double colons for member functions)
\param P the parser calling this emitter

This property reads the name of a construct from the input buffer
and emits all words, concatenated by double colons.

\returns the name including dots (colons)

'/
SUB cppNam CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    VAR t = .NamTok
    Code(.SubStr(t))
    WHILE t < .EndTok
      t += 3
      SELECT CASE AS CONST *t
      CASE  .TOK_DOT : Code("::")
      CASE .TOK_WORD : Code(.SubStr(t))
      CASE ELSE : EXIT WHILE
      END SELECT
    WEND
  END WITH
END SUB


/'* \brief Export the name (including dots for member functions)
\param P the parser calling this emitter

This sub reads the name of a construct from the input buffer
and emits all words as in the original source.

\returns the name including dots (colons)

'/
SUB cNam CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    FOR i AS INTEGER = 1 TO .PtrCount : Code("*") : NEXT
    VAR t = .NamTok, a = t[1], l = t[2]
    WHILE t < .EndTok
      t += 3
      SELECT CASE AS CONST *t
      CASE .TOK_DOT, .TOK_WORD : l += t[2]
      CASE ELSE : EXIT WHILE
      END SELECT
    WEND : Code(MID(.Buf, a + 1, l))
  END WITH
END SUB


/'* \brief Export the initializer(s) for a variable
\param P the parser calling this emitter

This sub reads the initializer from the input buffer and emits them
unchanged. This may be a bunch of text in case of an array initializer.

'/
SUB CreateIni CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    VAR kl = 0, i = .IniTok[1], a = i, e = 0, atc = 0
    Code(" ")
    DO
      i += 1
      SELECT CASE AS CONST .Buf[i]
      CASE 0 : EXIT DO
      CASE ASC(!"\n")
        Code(MID(.Buf, a + 1, IIF(e, e, i) - a))
        a = i + 1
        IF kl <= 0 ANDALSO (e = 0 ORELSE .Buf[e] <> ASC("_")) THEN EXIT SUB
        emit_comments(P, i)
        e = 0
      CASE ASC("@")
        IF kl <= 0 THEN atc = i
      CASE ASC("_")
        IF .Buf[i + 1] < ASC("0") ANDALSO .Buf[i - 1] < ASC("0") THEN e = IIF(e, e, i)
      CASE ASC("'")
        e = IIF(e, e, i)
      CASE ASC("/")
        IF .Buf[i + 1] = ASC("'") THEN e = IIF(e, e, i)
      CASE ASC("""")
        VAR esc = IIF(.Buf[i - 1] = ASC("!"), 1, 0)
        IF atc THEN .Buf[atc] = ASC(" ")
        DO
          i += 1
          SELECT CASE AS CONST .Buf[i]
          CASE 0, ASC(!"\n") : i -= 1 : EXIT DO
          CASE ASC("\") : IF esc THEN i += 1
          CASE ASC("""") : IF .Buf[i + 1] = ASC("""") THEN i += 1 ELSE EXIT DO
          END SELECT
        LOOP
      CASE ASC("("), ASC("{"), ASC("[") : kl += 1
      CASE ASC(")"), ASC("}"), ASC("]") : kl -= 1 : IF kl <  0 THEN EXIT DO
      CASE ASC(",")                               : IF kl <= 0 THEN EXIT DO
      END SELECT
    LOOP UNTIL i >= .EndTok[1] : IF i <= a THEN EXIT SUB
    Code(MID(.Buf, a + 1, IIF(e, e, i) - a))
    IF atc THEN .Buf[atc] = ASC("@")
  END WITH
END SUB


/'* \brief The dimension of a variable
\param P the parser calling this emitter

This property reads the dimension of a construct from the input buffer.

\returns the name including round or squared brackets

'/
SUB cArrDim CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    VAR t = .DimTok, kl = 0
    DO
      SELECT CASE AS CONST *t
      CASE .TOK_COMMA
        SELECT CASE AS CONST t[-3]
        CASE .TOK_3DOT, .TOK_ANY : Code("][")
        CASE ELSE :                Code(" + 1][")
        END SELECT
      CASE .TOK_BROPN : kl += 1 : Code("[")
        IF t[3] = .TOK_COMMA ORELSE t[3] = .TOK_BRCLO THEN _
          Code(MID(.Buf, t[1] + 2, t[4] - t[1] - 1))
      CASE .TOK_BRCLO : kl -= 1
        SELECT CASE AS CONST t[-3]
        CASE .TOK_3DOT, .TOK_ANY : Code("]")
        CASE ELSE :                Code(" + 1]")
        END SELECT
        IF kl <= 0 THEN EXIT DO
      CASE ELSE                 : Code(.SubStr(t))
      END SELECT : t += 3
    LOOP UNTIL t >= .EndTok
  END WITH
END SUB


/'* \brief Create pseude C declaration
\param P the parser calling this emitter

Create a declaration for the construct at the current parser
position using FB style. All FB keywords gets mangled to a single
word to get a FreeBASIC look-and-feel in the documentation. Ie. we emit

 - "SUB Name();" (instead of "void Name(void);")
 - "INTEGER varnam" (instead of "int varname")
 - "BYREF_AS_STRING strng" (instead of "char** strng")
 - "FUNCTION_CDECL_AS_SINGLE xyz CDECL(BYVAL_AS_BYTE C)" (instead of
   "float xyz(char C)")
 - ...

The C lexer of the back-end (gtk-doc or Doxygen) interprets this
single word as a C type declaration (or macro) and can handle FB
source code that way.

Exeptions handled in this SUB:

 - TypTok = 0: no type, emit only the name (with a space in front)
 - NymTok = 0: no name, emit type and exit

'/
SUB cppCreateTypNam CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    IF .TypTok THEN
      IF .ShaTok THEN Code(.SubStr(.ShaTok) & "_")
      IF .Co1Tok THEN Code(.SubStr(.Co1Tok) & "_")
                      Code(.SubStr(.TypTok))
      IF .Co2Tok THEN Code("_" & .SubStr(.Co2Tok))
      FOR i AS INTEGER = 1 TO .PtrCount
                      Code("_" & .SubStr(.PtrTok)) : NEXT
      IF .NamTok THEN Code(" ") ELSE EXIT SUB
    ELSE
      Code(" ")
    END IF

    IF .NamTok > .TypTok _
      THEN emit_comments(P, .NamTok[1])

    IF .NamTok THEN   cppNam(P)
    IF .DimTok THEN   cArrDim(P)
    IF .BitTok THEN   Code(.BitIni)
    IF .IniTok THEN   CreateIni(P)
  END WITH
END SUB


/'* \brief Create C declaration
\param P the parser calling this emitter

Create a C declaration for the construct at the current parser
position. All FB keywords gets translated to their C expressions. Ie.
we emit

 - "void Name(void);" (instead of "SUB Name();")
 - "int varname" (instead of "INTEGER varnam")
 - "char** strng" (instead of "BYREF_AS_STRING strng")
 - "float xyz(char C)" (instead of "FUNCTION_CDECL_AS_SINGLE
    xyz CDECL(BYVAL_AS_BYTE C)")
 - ...

The C source code is very useful when you use a library compiled
with FreeBASIC in a other language like C or C++. \Proj can
auto-generate the header files (just check initializers and array
dimensioning manually).

Exeptions handled in this SUB:

 - TypTok = 0: no type, emit only the name (with a space in from)
 - NymTok = 0: no name, emit type and exit
 - ParTok <> 0: parameter list, emit name and exit (no default value)

'/
SUB cCreateTypNam CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    IF .TypTok THEN
      IF .Co1Tok THEN             Code("const ")

      SELECT CASE AS CONST *.TypTok
      CASE            .TOK_BYTE : Code("signed char")
      CASE            .TOK_UBYT : Code("unsigned char")
      CASE            .TOK_SHOR : Code("short")
      CASE            .TOK_USHO : Code("unsigned short")
      CASE            .TOK_STRI : Code("char*") ' ??? FB_STRING, g_string
      CASE            .TOK_SING : Code("float")
      CASE            .TOK_DOUB : Code("double")
      CASE            .TOK_ZSTR : Code("char")
      CASE            .TOK_WSTR : Code("wchar")
      CASE .TOK_INT,  .TOK_LONG : Code("int")
      CASE .TOK_UINT, .TOK_ULNG : Code("unsigned int")
      CASE            .TOK_LINT : Code("LONG int")
      CASE            .TOK_ULIN : Code("unsigned LONG int")
      CASE ELSE                 : Code(.SubStr(.TypTok))
      END SELECT

      IF .Co2Tok THEN             Code(" " & .SubStr(.Co2Tok))
      IF .By_Tok ANDALSO *.By_Tok = .TOK_BYRE THEN .PtrCount += 1
      IF .NamTok THEN Code(" ") ELSE EXIT SUB
    END IF

    IF .NamTok > .TypTok _
      THEN emit_comments(P, .NamTok[1])

    IF .FunTok THEN
      SELECT CASE AS CONST *.StaTok
      CASE .TOK_TYPE, .TOK_DIM, .TOK_RDIM, .TOK_COMM, .TOK_EXRN
        FOR i AS INTEGER = 1 TO .PtrCount : Code("*") : NEXT
        .PtrCount = 0
        Code(" (*") : cNam(P) : Code(")") : EXIT SUB
      END SELECT
    END IF
    IF .NamTok THEN cNam(P)
    IF .ParTok THEN EXIT SUB
    IF .BitTok THEN Code(.BitIni)
    IF .DimTok THEN cArrDim(P) ': Code()
    IF .IniTok THEN CreateIni(P)
  END WITH
END SUB


/'* \brief Handler for a parameter declaration in CPP style
\param P the parser calling this handler

Generate a declaration for a parameter list. The declaration may be
empty (), may have no name (prototype declaration) or may by an
ellipsis ( ... ). Initializers get emitted "as-is".

We emit a space in front and a comma behind the parameter. When done
the first space gets replaced by a '(' and the last comma gets
replaced by a ')'.

'/
SUB cppEntryListParameter CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    emit_comments(P, .Tk1[1])

    IF .FunTok THEN
      IF .By_Tok THEN Code(.SubStr(.By_Tok) & "_")
      IF .DivTok THEN Code("_" & .SubStr(.DivTok))
      cppCreateFunction(P)
    ELSEIF .TypTok THEN
      IF .By_Tok THEN Code(.SubStr(.By_Tok) & "_")
      Code(.SubStr(.As_Tok) & "_")
      cppCreateTypNam(P)
    ELSE
      IF *.NamTok = .TOK_3DOT  THEN Code("...") _
                               ELSE Code("void")
    END IF

    IF *.CurTok <> .TOK_BRCLO THEN Code(", ") : EXIT SUB
    emit_comments(P, .CurTok[1]) : Code(")")
  END WITH
END SUB


/'* \brief Handler for a parameter declaration in C-style
\param P the parser calling this handler

Generate a declaration for a parameter list. The declaration may be
empty (), may have no name (prototype declaration) or may by an
ellipsis ( ... ). Initializers get emitted "as-is", this means you
have to check if they contain FB keywords (and translate manually, if
so).

We emit a space in front and a comma behind the parameter. When done
the first space gets replaced by a '(' and the last comma gets
replaced by a ')'.

'/
SUB cEntryListParameter CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    emit_comments(P, .Tk1[1])

    IF .FunTok THEN
      cCreateFunction(P)
    ELSEIF .TypTok THEN
      cCreateTypNam(P)
    ELSE
      IF *.NamTok = .TOK_3DOT  THEN Code("...") _
                               ELSE Code("void")
    END IF

    IF *.CurTok <> .TOK_BRCLO      THEN Code(", ") : EXIT SUB
    emit_comments(P, .CurTok[1]) : Code(")")
  END WITH
END SUB


/'* \brief Create a function declaration
\param P the parser calling this handler

Generate a declaration for a function (SUB, FUNCTION, DESTRUCTOR,
CONSTRUCTOR, PROPERTY). We emit a type, a name and a parameter list.

Exceptions:

 - in a declaration a CONSTRUCTOR or DESTRUCTOR have no name

'/
SUB cppCreateFunction CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    'IF .DivTok THEN Code(.SubStr(.DivTok) & " ")
    IF .DivTok THEN Code(LCASE(.SubStr(.DivTok)) & " ")

    SELECT CASE AS CONST *.FunTok
    CASE .TOK_CTOR
      IF .NamTok THEN Code(.SubStr(.NamTok) & "::" & .SubStr(.NamTok)) ELSE _
                      Code(.BlockNam)
    CASE .TOK_DTOR
      IF .NamTok THEN Code(.SubStr(.NamTok) & "::~" & .SubStr(.NamTok)) ELSE _
                      Code("~" & .BlockNam)
    CASE ELSE
                      Code(.SubStr(.FunTok))
      IF .CalTok THEN Code("_" & .SubStr(.CalTok))
      IF .AliTok THEN Code("_" & .SubStr(.AliTok))
      IF .TypTok ANDALSO .As_Tok THEN _
                      Code("_" & .SubStr(.As_Tok) & "_")
      cppCreateTypNam(P)
    END SELECT : IF 0 = .ParTok THEN Code("(void)") : EXIT SUB

    emit_comments(P, .ParTok[1])
    Code(" (")
    .parseListPara(@cppEntryListParameter())
    IF .ListCount <= 0 THEN Code(")")
  END WITH
END SUB


/'* \brief Create a function declaration
\param P the parser calling this handler

Generate a declaration for a function (SUB, FUNCTION, DESTRUCTOR,
CONSTRUCTOR, PROPERTY). We emit a type, a name and the parameter list.

Exceptions:

 - in a declaration a CONSTRUCTOR or DESTRUCTOR has no name. We use the
   block name instead.

'/
SUB cCreateFunction CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    IF .DivTok THEN Code(.SubStr(.DivTok) & " ")

    SELECT CASE AS CONST *.FunTok
    CASE .TOK_CTOR
      Code(.SubStr(.FunTok) & " ")
      IF .NamTok THEN Code(.SubStr(.NamTok) & "." & .SubStr(.NamTok)) _
                 ELSE Code(.BlockNam)
    CASE .TOK_DTOR
      Code(.SubStr(.FunTok) & " ")
      IF .NamTok THEN Code(.SubStr(.NamTok) & "." & .SubStr(.NamTok)) _
                 ELSE Code(.BlockNam)
    CASE ELSE
      IF 0 = .TypTok THEN Code("void ")
      cCreateTypNam(P)
    END SELECT : IF 0 = .ParTok THEN Code("(void)") : EXIT SUB

    emit_comments(P, .ParTok[1])
    Code(" (")
    .parseListPara(@cEntryListParameter())
    IF .ListCount <= 0 THEN Code("void)")
  END WITH
END SUB


/'* \brief Emitter for an error message
\param P the parser calling this handler

Generate an error output. When the parser detects an error it calls
this function. Depending on the run-mode we do or do not emit an
information. In mode \ref SecModGeany the error message gets shown in
the status line (or in the debug window).

'/
SUB emit_error CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    SELECT CASE AS CONST OPT->RunMode
    CASE OPT->GEANY_MODE ': EXIT SUB ' or shall we output?
      Code(NL & "'!!! " & PROJ_NAME & .ErrMsg & "!" & NL)
    CASE ELSE
      ERROUT("==> " & PROJ_NAME & .ErrMsg & "!")
    END SELECT
  END WITH
END SUB


/'* \brief Handler to exporting FreeBASIC source code
\param P the parser calling this handler
\param E the end position in the input buffer

Extract original source code from the input buffer \ref Parser::Buf.
The code starts at the last position and gets extracted up to the line
end before the given position. This line end gets stored as the new
'last position'.

'/
SUB emit_source CDECL(BYVAL P AS Parser PTR, BYVAL E AS INTEGER)
  WITH *P '&Parser* P;
    DO : IF E > 0 THEN E -= 1 ELSE EXIT SUB
    LOOP UNTIL .Buf[E] = ASC(!"\n")
    VAR a = .SrcBgn, l = E - a : .SrcBgn = E + 1
    Code(MID(.Buf, a + 1, l + 1))
  END WITH
END SUB


/'* \brief Handler to initialize the source code export
\param P the parser calling this handler

This emitter gets called before the parser starts its parsing
process. It initializes the FB source code emission.

'/
SUB geany_init CDECL(BYVAL P AS Parser PTR)
  P->SrcBgn = 0
END SUB


/'* \brief Handler to finalize the export of source code
\param P the parser calling this handler

This emitter gets called after the parser ends its parsing process.
It sends the rest of the FB source code to the output stream.

'/
SUB geany_exit CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    Code(MID(.Buf, .SrcBgn + 1))
  END WITH
END SUB


'/'* \brief Emitter with no action, to initialize the interface
'\param P the parser calling this handler '/
'SUB null_emitter CDECL(BYVAL P AS Parser PTR) : END SUB
