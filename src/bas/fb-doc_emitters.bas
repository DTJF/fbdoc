/'* \file fb-doc_emitters.bas
\brief Default emitter to create pseudo C source, \#`INCLUDE`s the other emitters

This file is the main file for emitters. It contains some helper
functions to extract original source code and comments. And it
contains the standard emitter to translate the FB source to pseudo C
source.

The pseudo C emitter is designed to create C source out of the FB
code including the documentation comments. Comments may be multi
line comment blocks or line end comments. The emitter tries to place
the comments similar as in the FB source (but a comment inside a
statement will be placed at the end of the corresponding C statement).

The emitter is designed to be used to generate output for the
documentation tool-chain back-end. This may be written to the STDOUT
pipe (default) or to one or more files (option `--fileoutout`). It
also can be used to translate an FB header to C syntax by unsing
option `--cstyle`.

'/

#INCLUDE ONCE "fb-doc_emitters.bi"
#INCLUDE ONCE "fb-doc_parser.bi"
#INCLUDE ONCE "fb-doc_options.bi"
#INCLUDE ONCE "fb-doc_version.bi"


'* The list of function names (for caller / callee graphs)
COMMON SHARED AS STRING LOFN

/'* \brief Handler for exporting comments
\param P the parser calling this handler
\param Stop_ the end position in the input buffer

Export the comments between the last position 'SrcBgn' (= source begin)
and the Stop_ position. Then, the Stop_ position gets the new 'last
position'.

'/
SUB cEmitComments CDECL(BYVAL P AS Parser PTR, BYVAL Stop_ AS INTEGER)
  WITH *P
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
        IF c THEN Code("/**")
        DO
          SELECT CASE AS CONST .Buf[i]
          CASE 0 : EXIT DO
          CASE ASC(!"\n") : IF 0 = c THEN Code(NL) : EXIT SELECT
            Code(MID(.Buf, c + 1, i - c + 1))
            c = i + 1
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
  WITH *P
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
  WITH *P
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

This sub reads the initializer from the input buffer and emits it
unchanged. This may be a bunch of text in case of an array initializer.

'/
SUB cIni CDECL(BYVAL P AS Parser PTR)
  WITH *P
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
        cEmitComments(P, i)
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
  WITH *P
    VAR t = .DimTok, kl = 0
    DO
      SELECT CASE AS CONST *t
      CASE .TOK_COMMA ':           Code(" + 1][")
        if t[-3] = .TOK_TRIDO then Code("][") _
                              else Code(" + 1][")
      CASE .TOK_BROPN : kl += 1 : Code("[")
        IF t[3] = .TOK_COMMA ORELSE t[3] = .TOK_BRCLO THEN _
          Code(MID(.Buf, t[1] + 2, t[4] - t[1] - 1))
      CASE .TOK_BRCLO : kl -= 1 ': Code(" + 1]") : IF kl <= 0 THEN EXIT DO
        if t[-3] = .TOK_TRIDO then Code("]") _
                              else Code(" + 1]")
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

 - TypTok = 0: no type, emit only the name (with a space in from)
 - NymTok = 0: no name, emit type and exit

'/
SUB cppCreateTypNam CDECL(BYVAL P AS Parser PTR)
  WITH *P
    IF .TypTok THEN
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
      THEN cEmitComments(P, .NamTok[1])

    IF .NamTok THEN   cppNam(P)
    IF .DimTok THEN   cArrDim(P)
    IF .BitTok THEN   Code(.BitIni)
    IF .IniTok THEN   cIni(P)
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

'/
SUB cCreateTypNam CDECL(BYVAL P AS Parser PTR)
  WITH *P
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
      THEN cEmitComments(P, .NamTok[1])

    SELECT CASE AS CONST *.StaTok
    CASE .TOK_TYPE, .TOK_DIM, .TOK_RDIM, .TOK_COMM, .TOK_EXRN
      IF .FunTok THEN Code("(") : cNam(P) : Code(")") : EXIT SUB
    END SELECT
    IF .NamTok THEN cNam(P)
    IF .BitTok THEN Code(.BitIni)
    IF .DimTok THEN cArrDim(P) ': Code()
    IF .IniTok THEN cIni(P)
  END WITH
END SUB


/'* \brief Handler for a parameter declaration
\param P the parser calling this handler

Generate a declaration for a parameter list. The declaration may be
empty (), may have no name (prototype declaration) or may by an
ellipsis ( ... ). Initializers get emitted "as-is".

We emit a space in front and a comma behind the parameter. When done
the first space gets replaced by a '(' and the last comma gets
replaced by a ')'.

'/
SUB cppEntryListParameter CDECL(BYVAL P AS Parser PTR)
  WITH *P
    cEmitComments(P, .Tk1[1])

    IF .FunTok THEN
      IF .By_Tok THEN Code(.SubStr(.By_Tok) & "_")
      IF .DivTok THEN Code("_" & .SubStr(.DivTok))
      cppCreateFunction(P)
    ELSEIF .TypTok THEN
      IF .By_Tok THEN Code(.SubStr(.By_Tok) & "_")
      Code(.SubStr(.As_Tok) & "_")
      cppCreateTypNam(P)
    ELSEIF *.NamTok = .TOK_TRIDO THEN
      Code("...)") : EXIT SUB
    END IF

    IF *.CurTok <> .TOK_BRCLO      THEN Code(", ") : EXIT SUB
    cEmitComments(P, .CurTok[1]) : Code(")")
  END WITH
END SUB


/'* \brief Handler for a parameter declaration
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
  WITH *P
    cEmitComments(P, .Tk1[1])

    IF .FunTok THEN
      cCreateFunction(P)
    ELSEIF .TypTok THEN
      cCreateTypNam(P)
    ELSEIF .NamTok = .TOK_TRIDO THEN
      Code("...")
    ELSE
      Code("void")
    END IF

    IF *.CurTok <> .TOK_BRCLO      THEN Code(", ") : EXIT SUB
    cEmitComments(P, .CurTok[1]) : Code(")")
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
  WITH *P
    IF .DivTok THEN Code(.SubStr(.DivTok) & " ")

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

    cEmitComments(P, .ParTok[1])
    Code(" (")
    .parseListPara(@cppEntryListParameter)
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
  WITH *P
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

    cEmitComments(P, .ParTok[1])
    Code(" (")
    .parseListPara(@cEntryListParameter)
    IF .ListCount <= 0 THEN Code("void)")
  END WITH
END SUB


/'* \brief Emitter to generate an \#`INCLUDE` translation
\param P the parser calling this emitter

This emitter gets called when the parser finds an \#`INCLUDE`
statement. It creates a C translation and sends it to the output
stream. When option `--tree` is given it checks if the file has
been done already. If not, it creates a new #Parser and starts its
scanning process.

'/
SUB c_include CDECL(BYVAL P AS Parser PTR)
  WITH *P
    cEmitComments(P, .Tk1[1])
    VAR fnam = .SubStr(.NamTok)
    IF OPT->Types = OPT->C_STYLE THEN
      VAR i = INSTRREV(fnam, ".")
      Code("#include " & LEFT(fnam, i))
      IF LCASE(RIGHT(fnam, 4)) = ".bi""" THEN Code("h""") ELSE Code("c""")
    ELSE
      Code("#include " & fnam)
    END IF
    IF OPT->InTree THEN .Include(TRIM(fnam, """"))
  END WITH
END SUB


/'* \brief Emitter to generate a macro translation
\param P the parser calling this emitter

This emitter gets called when the parser finds a macro (\#`DEFINE`
\#`MACRO`). It generates a C translation of the macro and sends it
to the output stream.

'/
SUB c_defi_ CDECL(BYVAL P AS Parser PTR)
  WITH *P
    cEmitComments(P, .Tk1[1])

    Code("#define ")
    VAR e = .EndTok[1]
    IF *.StaTok = .TOK_MACR THEN
      VAR a = .NamTok[1], l = .CurTok[1] - a
      Code(MID(.Buf, a + 1, l) & "  /* (multi line FreeBASIC #MACRO) ")
      a += l
      Code(MID(.Buf, a + 1, e - a) & " */ ")
    ELSE
      VAR a = .NamTok[1], l = .DivTok[-2] + .DivTok[-1] - a
      Code(MID(.Buf, a + 1, l))
      a += l
      l = e - a
      IF l > 0 then Code(" /* " & MID(.Buf, a + 1, e - a) & " */")
    END IF
    .SrcBgn = e
  END WITH
END SUB


/'* \brief Emitter to generate a function translation
\param P the parser calling this emitter

This emitter gets called when the parser finds a function (SUB /
FUNCTION / PROPERTY / CONSTRUCTOR / DESTRUCTOR). It translates a
function and its parameter list to C-like code and sends it to the
output stream. The function body is either empty or contains pseudo
calls.

'/
SUB c_func_ CDECL(BYVAL P AS Parser PTR) ' ToDo: internal function calls for diagrams
  WITH *P
    VAR fl = *.FunTok <> .TOK_CTOR ANDALSO _
             *.FunTok <> .TOK_DTOR ANDALSO _
              .NamTok[3] <> .TOK_DOT
    cEmitComments(P, .Tk1[1])

    OPT->CreateFunction(P)
    Code(" {")

    IF LEN(LOFN) THEN
      VAR t = .CurTok, e = .EndTok - 6
      WHILE t < e
        IF *t = .TOK_BROPN THEN
          VAR l = *(t - 1) _
            , a = *(t - 2)
          FOR i AS INTEGER = LEN(LOFN) - 2 TO 0 STEP -1
            VAR x = a + l - 1
            WHILE (.Buf[x] AND &b11011111) = (LOFN[i] AND &b11011111)
              i -= 1
              x -= 1
              IF x < a THEN
                SELECT CASE AS CONST LOFN[i]
                CASE ASC(!"\n")
                CASE ASC("."), ASC(">")
                  VAR tt = t - 9
                  WHILE tt > .Tk1
                    IF *tt <> .TOK_MEOP ORELSE *tt <> .TOK_DOT THEN EXIT WHILE
                    tt -= 6
                  WEND
                  x = *(tt - 2)
                  l += a - x - 1
                CASE ELSE : EXIT WHILE
                END SELECT

                cEmitComments(P, a)
                Code(" " & MID(.Buf, x + 2, l) & "();")
                EXIT FOR
              END IF
            WEND

            WHILE i > 0 ANDALSO LOFN[i] <> ASC(!"\n") : i -= 1 : WEND
          NEXT
        END IF : t += 3
      WEND
    END IF

    cEmitComments(P, .EndTok[1] - 1)
    Code("};")
  END WITH
END SUB


/'* \brief Emitter to generate a declaration translation
\param P the parser calling this emitter

This emitter gets called when the parser is in a declaration (VAR /
DIM / CONST / COMMON / EXTERN / STATIC). It generates a C
translation for each variable name and sends it (them) to the output
stream. Documantation comments get emitted at the appropriate place.
Each declaration get a single line, even if the original source code
is a comma-separated list. (This may destroy line synchonisation, so
it's better to place each declaration in a single line.)

'/
SUB c_decl_ CDECL(BYVAL P AS Parser PTR)
  WITH *P
    cEmitComments(P, .Tk1[1])

    IF 0 = .ListCount THEN
      SELECT CASE AS CONST *.StaTok
      CASE .TOK_CONS : Code("const ")
      CASE .TOK_STAT : Code("static ")
      CASE .TOK_COMM : Code("common ")
      CASE .TOK_EXRN : Code("extern ")
      CASE .TOK_TYPE : Code("typedef ")
        IF 0 = .FunTok ANDALSO .TypTok > .NamTok THEN Code("struct ")
      END SELECT
    END IF

    IF     .FunTok THEN : OPT->CreateFunction(P)
    ELSEIF .TypTok THEN : OPT->CreateVariable(P)
    ELSE
      IF 0 = .ListCount THEN Code("VAR ")
                             Code(.SubStr(.NamTok))
      IF .BitTok THEN        Code(.BitIni)
      IF .IniTok THEN        cIni(P)
    END IF
    IF *.CurTok <= .TOK_EOS THEN Code(";") : EXIT SUB
    IF .NamTok > .TypTok _
      THEN Code(", ") _
      ELSE Code("; ")
  END WITH
END SUB


/'* \brief Handler for an enumerator entry (inside ENUM block)
\param P the parser calling this handler

Generate an enumerator in an enum block. Name, initializers and
documentation comments are emitted. Logical operators like SHL or
AND are not handled jet.

'/
SUB cEntryBlockENUM CDECL(BYVAL P AS Parser PTR)
  WITH *P
    cEmitComments(P, .Tk1[1])

    IF 0 = .ListCount THEN Code(STRING(.LevelCount * 2, " "))
    Code(.SubStr(.NamTok))
    IF .IniTok THEN cIni(P)
    IF *.CurTok <> .TOK_END THEN Code(", ")
  END WITH
END SUB


/'* \brief Handler for a context line (TYPE / UNION block)
\param P the parser calling this handler

Generate a line in an struct or union block. Type, name,
initializers and documentation comments are emitted. Logical
operators like SHL or AND are not handled jet.

'/
SUB cEntryBlockTypeUnion CDECL(BYVAL P AS Parser PTR)
  WITH *P
    cEmitComments(P, .Tk1[1])

    SELECT CASE AS CONST *.Tk1
    CASE .TOK_PRIV : Code("private:")
    CASE .TOK_PROT : Code("protected:")
    CASE .TOK_PUBL : Code("public:")
    CASE .TOK_ENUM, .TOK_UNIO, .TOK_TYPE, .TOK_CLAS : c_Block(P)
    CASE ELSE
      IF 0 = .ListCount    THEN Code(STRING(.LevelCount * 2, " "))
      IF *.Tk1 = .TOK_DECL THEN OPT->CreateFunction(P) : Code(";") : EXIT SUB
      IF .FunTok THEN OPT->CreateFunction(P) _
                 ELSE OPT->CreateVariable(P)
      IF *.CurTok <= .TOK_EOS THEN Code(";") : EXIT SUB
      IF .NamTok  >   .TypTok THEN Code(",") ELSE Code("; ")
    END SELECT
  END WITH
END SUB


/'* \brief Emitter to generate a block translation
\param P the parser calling this emitter

This emitter gets called when the parser finds a block (TYPE / UNION
/ ENUM). It generates a C translation of the block and sends it to
the output stream.

Nested blocks get parsed recursivly.

'/
SUB c_Block CDECL(BYVAL P AS Parser PTR)
  WITH *P
    cEmitComments(P, .Tk1[1])

    IF .LevelCount THEN Code(STRING(.LevelCount * 2, " "))
    SELECT CASE AS CONST *.Tk1
    CASE .TOK_TYPE, .TOK_CLAS
      IF OPT->Types = OPT->FB_STYLE THEN
        Code("class " & .BlockNam & !"{ public:")
        .parseBlockTyUn(@cEntryBlockTypeUnion)
        .BlockNam = ""
      ELSE
        IF 0 = .LevelCount ANDALSO LEN(.BlockNam) THEN Code("typedef ")
        Code("struct " & .BlockNam & "{")
        .parseBlockTyUn(@cEntryBlockTypeUnion)
      END IF
    CASE .TOK_UNIO
      IF 0 = .LevelCount ANDALSO LEN(.BlockNam) THEN Code("typedef ")
      Code("union " & .BlockNam & "{")
      .parseBlockTyUn(@cEntryBlockTypeUnion)
    CASE .TOK_ENUM
      IF 0 = .LevelCount ANDALSO LEN(.BlockNam) THEN Code("typedef ")
      Code("enum " & .BlockNam & "{")
      .parseBlockEnum(@cEntryBlockENUM)
    CASE ELSE : Code("-???-")
    END SELECT

    cEmitComments(P, .Tk1[1])
    IF .LevelCount THEN Code(STRING(.LevelCount * 2, " "))
    Code("};")
  END WITH
END SUB


/'* \brief Emitter for an error message
\param P the parser calling this handler

Generate an error output. When the parser detects an error it calls
this function. Depending on the run-mode we do or do not emit an
information. In mode `--geany-mode` the error message gets shown in the
status line (or in the debug window).

'/
SUB c_error CDECL(BYVAL P AS Parser PTR)
  WITH *P
    SELECT CASE AS CONST OPT->RunMode
    CASE OPT->GEANY_MODE ': EXIT SUB ' or shall we output?
      Code(NL & "'!!! " & PROJ_NAME & .ErrMsg & "!" & NL)
    CASE ELSE
      ERROUT("==> " & PROJ_NAME & .ErrMsg & "!")
    END SELECT
  END WITH
END SUB


/'* \brief Emitter to be called before parsing
\param P the parser calling this emitter

This emitter gets called before the parser starts its parsing
process. It initializes the FB source code emission.

'/
SUB c_Init CDECL(BYVAL P AS Parser PTR)
  P->SrcBgn = 0
END SUB


/'* \brief Emitter to be called after parsing
\param P the parser calling this emitter

This emitter gets called after the parser ends its parsing process.
It sends the rest of the FB source code to the output stream.

'/
SUB c_exit CDECL(BYVAL P AS Parser PTR)
  cEmitComments(P, P->Fin)
END SUB


/'* \brief CTOR to be called when starting in \ref Options::FileModi
\param P the parser to be used with this emitter

This CTOR gets called when starting in a mode for file input (so not
for `--geany-mode`). It loads the file `fb-doc.lfn`, if any.

'/
SUB c_CTOR CDECL(BYVAL P AS Parser PTR)
  VAR fnr = FREEFILE
  IF OPEN(CALLEES_FILE FOR INPUT AS #fnr) THEN EXIT SUB
  MSG_LINE(CALLEES_FILE)
  LOFN = STRING(LOF(fnr), 0)
  GET #fnr, , LOFN
  CLOSE #fnr
  MSG_END("loaded")
END SUB


' place the handlers in the emitter interface
WITH_NEW_EMITTER(EmitterTypes.C_SOURCE)
     .Nam = "C_Source"
  .Error_ = @c_error

   .Defi_ = @c_defi_
   .Incl_ = @c_include
   .Func_ = @c_func_
   .Decl_ = @c_decl_
   .Enum_ = @c_Block
   .Unio_ = @c_Block
   .Clas_ = @c_Block

   .Init_ = @c_Init
   .Exit_ = @c_exit
   .CTOR_ = @c_CTOR
END WITH


/'* \brief Handler for exporting FreeBASIC source code
\param P the parser calling this handler
\param E the end position in the input buffer

Extract original source code from the input buffer \ref Parser::Buf.
The code starts at the last position and gets extracted up to the line
end before the given position. This line end gets stored as the new
'last position'.

'/
SUB cEmitSource CDECL(BYVAL P AS Parser PTR, BYVAL E AS INTEGER)
  WITH *P
    DO : IF E > 0 THEN E -= 1 ELSE EXIT SUB
    LOOP UNTIL .Buf[E] = ASC(!"\n")
    VAR a = .SrcBgn, l = E - a : .SrcBgn = E + 1
    Code(MID(.Buf, a + 1, l + 1))
  END WITH
END SUB


/'* \brief Handler for initialize the export of source code
\param P the parser calling this handler

This emitter gets called before the parser starts its parsing
process. It initializes the FB source code emission.

'/
SUB geanyInit CDECL(BYVAL P AS Parser PTR)
  P->SrcBgn = 0
END SUB


/'* \brief Handler for finalize the export of source code
\param P the parser calling this handler

This emitter gets called after the parser ends its parsing process.
It sends the rest of the FB source code to the output stream.

'/
SUB geanyExit CDECL(BYVAL P AS Parser PTR)
  WITH *P
    Code(MID(.Buf, .SrcBgn + 1))
  END WITH
END SUB


/'* \brief An empty emitter to initialize the interface
\param P the parser calling this handler '/
SUB null_emitter CDECL(BYVAL P AS Parser PTR) : END SUB
