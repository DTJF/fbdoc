/'* \file fbdoc_emit_csource.bas
\brief Emitter to generate the pseudo C intermediate format.

This file contains the emitter \ref SecEmmCSource, which is the default
emitter in modes \ref SecModFile and \ref SecModDef. It's designed to
generate the pseudo C intermediate format for the documentation
back-ends (ie. for the Doxygen filter feature).

The emitter transforms FB source to C like constructs and copies the
documentational comments unchaned. Everything get placed in the same
line as in the FB source, in order to get correct line references from
Doxygen.

\since 0.4.0
'/

#INCLUDE ONCE "fbdoc_options.bi"


'* The list of function names (for caller / callee graphs)
DIM SHARED AS STRING LOFN


/'* \brief CTOR to be called when starting in \ref Options::FileModi
\param O the parser to be used with this emitter

This CTOR gets called when starting in a mode for file input (so not
for mode \ref SecModGeany). It loads the file \ref SubInLfn, if any.

'/
SUB c_CTOR CDECL(BYVAL O AS Options PTR)
  WITH *O
    IF 0 = LEN(.LfnPnN) THEN .LfnPnN = .OutPath & LFN_FILE
    MSG_LINE(.LfnPnN)
    VAR fnr = FREEFILE
    IF OPEN(.LfnPnN FOR INPUT AS #fnr) THEN
      MSG_CONT("not present (List fo Function Names)")
    ELSE
      LOFN = STRING(LOF(fnr), 0)
      GET #fnr, , LOFN
      CLOSE #fnr
      MSG_CONT("loaded")
    END IF
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
  emit_comments(P, P->Fin)
END SUB


/'* \brief Emitter to generate an #`INCLUDE` translation
\param P the parser calling this emitter

This emitter gets called when the parser finds an #`INCLUDE`
statement. It creates a C translation and sends it to the output
stream. When option \ref SecOptTree is given it checks if the file has
been done already. If not, it creates a new #Parser and starts its
scanning process.

'/
SUB c_include CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    emit_comments(P, .Tk1[1])
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

This emitter gets called when the parser finds a macro (#`DEFINE`,
#`MACRO`). It generates a C translation of the macro and sends it
to the output stream.

'/
SUB c_defi_ CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    emit_comments(P, .Tk1[1])

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
      IF l > 0 THEN Code(" /* " & MID(.Buf, a + 1, e - a) & " */")
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
  WITH *P '&Parser* P;
    var futo = .FunTok, nato = .NamTok
    emit_comments(P, .Tk1[1])

    OPT->CreateFunction(P)
    Code(" {")

    IF LEN(LOFN) THEN
      'VAR cfl = .TOK_CTOR = *futo ORELSE _
                '.TOK_DTOR = *futo ORELSE _
                '.TOK_DOT  = nato[3]
      VAR cna = UCASE(.SubStr(nato)) _
      , wtype = "" _
          , t = .CurTok _
          , e = .EndTok - 6
      WHILE t < e
        SELECT CASE AS CONST *t
        CASE .TOK_END
          t += 3
          IF *t = .TOK_WITH THEN wtype = ""
        CASE .TOK_WITH
          VAR p = t[1] + t[2]
          t += 3
          WHILE t < e
            IF *t > .TOK_EOS andalso *t < .TOK_COMSL THEN t += 3 ELSE EXIT WHILE
          WEND
          wtype = TRIM(MID(.Buf, p + 2, *(t-2) + *(t-1) - p - 1))
          IF wtype[0] = ASC("*") THEN wtype = MID(wtype, 2) & "->" ELSE wtype &= "."
        CASE .TOK_BROPN
          VAR a = *(t - 2) _
            , l = *(t - 1) _
            , g = 0
          FOR i AS INTEGER = LEN(LOFN) - 2 TO 0 STEP -1
            VAR x = a + l - 1
            WHILE (.Buf[x] AND &b11011111) = (LOFN[i] AND &b11011111)
              i -= 1
              x -= 1
              IF x < a THEN ' end of source word
                VAR tt = t - 6
                SELECT CASE AS CONST LOFN[i]
                CASE ASC(LFN_SEP) : g = 0 : x += 2 ' global function `symbol()`
                CASE ASC(".") '                      member function `udtname.symbol()`
                  IF .Buf[x] = ASC(".") ORELSE .Buf[x] = ASC(">") THEN ' chain of one or more member functions
                    WHILE tt > .Tk1
                      IF *tt = .TOK_MEOP ORELSE *tt = .TOK_DOT _
                                         THEN tt -= 3 ELSE tt += 3 : x = tt[1] + 1 : g = 0 : EXIT WHILE ' `symbol.symbol()`, `symbol->symbol()`
                      IF .Buf[tt[4] - 1] < ASC("A")   THEN tt += 3 : x = tt[1] + 2 : g = 1 : EXIT WHILE ' .symbol()
                      IF *tt = .TOK_WORD THEN tt -= 3 ELSE tt += 6 : x = tt[1] + 1 : g = 1 : EXIT WHILE ' .symbol()
                    WEND
                    l += a - x + 1
                  ELSE ' no chain, just a single name
                     'IF 0 = cfl                            THEN EXIT WHILE
                     VAR z = i : i = INSTRREV(LOFN, LFN_SEP, z)
                     IF cna <> UCASE(MID(LOFN, i + 1, z - i)) THEN
'MSG_LINE(cna & " / " & MID(LOFN, i + 1, z - i) & " / " & MID(LOFN, z + 2, l))
                       if MID(LOFN, i + 1, z - i) <> MID(LOFN, z + 2, l) then EXIT WHILE
                       g = 1 : x += 2 : wtype = MID(.Buf, z, l) & "." ' CTOR
                     else
                       g = 0 : x += 2
                     END IF
                  END IF
                CASE ELSE : EXIT WHILE '             no match
                END SELECT
                emit_comments(P, a)
                IF g THEN Code(" " & wtype & MID(.Buf, x, l) & "();") _
                     ELSE Code(" " &         MID(.Buf, x, l) & "();")
                EXIT FOR
              END IF
            WEND

            WHILE i > 0 ANDALSO LOFN[i] <> ASC(LFN_SEP) : i -= 1 : WEND
          NEXT
        END SELECT : t += 3
      WEND
    END IF

    emit_comments(P, .EndTok[1] - 1)
    Code("};")
  END WITH
END SUB


/'* \brief Emitter to generate a `DECLARE` translation
\param P the parser calling this emitter

This emitter gets called when the parser is in a declaration (VAR /
DIM / CONST / COMMON / EXTERN / STATIC). It generates a C
translation for each variable name and sends it (them) to the output
stream. Documentation comments get emitted at the appropriate place.
Each declaration get a single line, even if the original source code
is a comma-separated list. (This may destroy line synchonisation, so
it's better to place each declaration in a single line.)

'/
SUB c_decl_ CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    emit_comments(P, .Tk1[1])

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
      IF .IniTok THEN        CreateIni(P)
    END IF
    IF *.CurTok <= .TOK_EOS THEN Code(";") : EXIT SUB
    IF .NamTok > .TypTok    THEN Code(", ") _
                            ELSE Code("; ")
  END WITH
END SUB


DECLARE SUB c_Block CDECL(BYVAL AS Parser PTR)

/'* \brief Handler for an enumerator entry (inside ENUM block)
\param P the parser calling this handler

Generate an enumerator in an enum block. Name, initializers and
documentation comments are emitted. Logical operators like SHL or
AND are not handled jet.

'/
SUB cEntryBlockENUM CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    emit_comments(P, .Tk1[1])

    IF 0 = .ListCount THEN Code(STRING(.LevelCount * 2, " "))
    Code(.SubStr(.NamTok))
    IF .IniTok THEN CreateIni(P)
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
  WITH *P '&Parser* P;
    emit_comments(P, .Tk1[1])

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


/'* \brief Emitter to generate a block translation (ENUM, TYPE, UNION)
\param P the parser calling this emitter

This emitter gets called when the parser finds a block declaration like
TYPE, UNION or ENUM. It generates a C translation of the block and
sends it to the output stream.

Nested blocks get parsed recursivly.

'/
SUB c_Block CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    emit_comments(P, .Tk1[1])

    IF .LevelCount THEN Code(STRING(.LevelCount * 2, " "))
    SELECT CASE AS CONST IIF(.LevelCount, *.Tk1, *.StaTok)
    CASE .TOK_TYPE, .TOK_CLAS
      IF OPT->Types = OPT->FB_STYLE THEN
         Code("class " & .BlockNam)
        VAR t = .Tk1 + 3
        IF *t = .TOK_EXDS THEN Code(" : public " & .SubStr(t + 3)) ' ToDo: parse list of names
        Code("{ public:")
        .parseBlockTyUn(@cEntryBlockTypeUnion())
        .BlockNam = ""
      ELSE
        IF 0 = .LevelCount ANDALSO LEN(.BlockNam) THEN Code("typedef ")
        Code("struct " & .BlockNam & "{")
        .parseBlockTyUn(@cEntryBlockTypeUnion())
      END IF
    CASE .TOK_UNIO
      IF 0 = .LevelCount ANDALSO LEN(.BlockNam) THEN Code("typedef ")
      Code("union " & .BlockNam & "{")
      .parseBlockTyUn(@cEntryBlockTypeUnion())
    CASE .TOK_ENUM
      IF 0 = .LevelCount ANDALSO LEN(.BlockNam) THEN Code("typedef ")
      Code("enum " & .BlockNam & "{")
      .parseBlockEnum(@cEntryBlockENUM())
    CASE ELSE : Code("-???-")
    END SELECT

    emit_comments(P, .Tk1[1])
    IF .LevelCount THEN Code(STRING(.LevelCount * 2, " "))
    Code("};")
  END WITH
END SUB


/'* \brief Initialize the `C_Source` EmitterIF
\param Emi The EmitterIF to initialize

FIXME

\since 0.4.0
'/
SUB init_csource(byval Emi as EmitterIF PTR)
  WITH *Emi
    .Error_ = @emit_error()

     .Defi_ = @c_defi_()
     .Incl_ = @c_include()
     .Func_ = @c_func_()
     .Decl_ = @c_decl_()
     .Enum_ = @c_Block()
     .Unio_ = @c_Block()
     .Clas_ = @c_Block()

     .Init_ = @c_Init()
     .Exit_ = @c_exit()
     .CTOR_ = @c_CTOR()
  END WITH
END SUB


