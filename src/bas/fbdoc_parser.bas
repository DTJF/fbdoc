/'* \file fbdoc_parser.bas
\brief Source code for the \ref Parser class.

This file contains the source code for the Parser class. It's used
to scan the FB input for relevant constructs and call the matching
function in the \ref EmitterIF.

'/

#INCLUDE ONCE "fbdoc_options.bi"
#INCLUDE ONCE "fbdoc_version.bi"


/'* \brief The constructor
\param Em A pointer to the emitter interface to use

Initialize the start values. We get the pointer to the \ref EmitterIF
to use and we create a short token list (just two entries) for usage
inside the parser. This token list is static and it doesn't change its
adress (unlike the list \ref Parser::Tok that may shift when growing).

'/
CONSTRUCTOR Parser(BYVAL Em AS EmitterIF PTR)
  STATIC AS LONG ToLi(...) = {0, 0, 0, 0, 0, 0}

  Emit = Em
  StaTok = @ToLi(0)
  A = @ToLi(1)
  L = @ToLi(2)
END CONSTRUCTOR


/'* \brief Snippet to skip to the next token '/
#DEFINE SKIP Tk += 3


/'* \brief Move to the next comma and one step beyond
\returns The (doubled) number of steps gone in the token list (or
         MSG_ERROR on error and MSG_STOP on the end of the token list)

We step trough the token list and search for the next comma,
skipping nested pairs of parenthesis. When we find a comma we walk
one step beyond. Otherwise we stop at the next right parenthesis or
the next colon or line end.

'/
FUNCTION Parser.skipOverComma() AS INTEGER
  VAR t = Tk, kl = 0
  WHILE Tk < EndTok
    SELECT CASE AS CONST *Tk
    CASE MSG_ERROR, TOK_EOS :                            RETURN Tk - t
    CASE TOK_COMMA : IF kl <= 0 THEN              SKIP : RETURN Tk - t
    CASE TOK_BROPN, TOK_KLOPN : kl += 1
    CASE TOK_BRCLO, TOK_KLCLO : kl -= 1 : IF kl < 0 THEN RETURN Tk - t
    END SELECT : SKIP
  WEND
END FUNCTION


/'* \brief Move to the matching right parenthesis and one step beyond
\returns The (doubled) number of steps gone in the token list (or
         MSG_ERROR on error and MSG_STOP on the end of the token list)

Step through the token list and search for the next right
parenthesis, skipping nested pairs of paranethesis. When we find a
matching right parenthesis we walk one step beyond. Else we
stop at the next colon or line end.

'/
FUNCTION Parser.skipOverBrclo() AS INTEGER
  VAR t = Tk, kl = 0
  WHILE Tk < EndTok
    SELECT CASE AS CONST *Tk
    CASE MSG_ERROR, TOK_EOS                         : RETURN Tk - t
    CASE TOK_BROPN : kl += 1
    CASE TOK_BRCLO : kl -= 1 : IF kl <= 0 THEN SKIP : RETURN Tk - t
    END SELECT : SKIP
  WEND
END FUNCTION


/'* \brief Move to the end of statement and one step beyond
\returns The (doubled) number of steps gone in the token list (or
         MSG_ERROR on error and MSG_STOP on the end of the token list)

Step through the token list and search for the end of the current
statement. Then walk one step beyond, if not end of token list.

'/
FUNCTION Parser.skipOverColon() AS INTEGER
  VAR t = Tk, fl = 0
  WHILE Tk < EndTok
    IF *Tk = TOK_EOS THEN fl = 1 ELSE IF fl THEN RETURN Tk - t
    SKIP
  WEND : RETURN Tk - t
END FUNCTION


/'* \brief Evaluate a name, dimension and initializer in the token list
\param MinTk The token to start at
\param DeclMod The modus (normal or declaration)
\returns The (doubled) number of steps gone in the token list (or
         MSG_ERROR on error and MSG_STOP on the end of the token list)

Check the token list for a declaration of a name, starting at the
current token (ie. behind a VAR keyword). Also checking for
parenthesis to specify a dimension and the equal '=' character of an
initializer. After execution the current position is at the next
token after the equal character, or behind the closing parenthesis,
or the name. An error is returned if there is no word at the current
position.

'/
FUNCTION Parser.demuxNam(BYVAL MinTk AS INTEGER = TOK_WORD, BYVAL DeclMod AS INTEGER = 0) AS INTEGER
  DimTok = 0 : IniTok = 0 : BitTok = 0

  IF *Tk >= MinTk THEN NamTok = Tk           ELSE NamTok = 0 : RETURN MSG_ERROR
  DO
    SELECT CASE AS CONST *Tk
    CASE TOK_BROPN, TOK_EQUAL
                 IF Tk > NamTok THEN EXIT DO ELSE NamTok = 0 : RETURN MSG_ERROR
    CASE  TOK_DOT : IF Tk[3] < MinTk         THEN NamTok = 0 : RETURN MSG_ERROR
    CASE TOK_WORD : IF Tk[3] <> TOK_DOT THEN SKIP : EXIT DO
    CASE ELSE
      IF 0 = LevelCount ORELSE *Tk < MinTk   THEN NamTok = 0 : RETURN MSG_ERROR
      SKIP : EXIT DO
    END SELECT : SKIP
  LOOP : IF DeclMod                                       THEN RETURN Tk - NamTok

  IF *Tk = TOK_BROPN THEN DimTok = Tk : skipOverBrclo()

  IF *Tk = TOK_AS THEN                                         RETURN Tk - NamTok

  IF *Tk = TOK_EQUAL                        THEN IniTok = Tk : RETURN Tk - NamTok
  IF 0 = LevelCount ORELSE _
     *Tk <> TOK_EOS ORELSE _
     Buf[Tk[1]] <> ASC(":")                               THEN RETURN Tk - NamTok

  VAR x = Tk + 3 '                        check for bitfield declaration
  IF *x >= MinTk THEN
    x += 3
    IF *x = TOK_EOS ANDALSO Buf[x[1]] <> ASC(":") THEN _
                                        BitTok = Tk : Tk = x : RETURN Tk - NamTok
  END IF

  SELECT CASE AS CONST *x
  CASE TOK_EQUAL : BitTok = Tk : Tk = x : IniTok = x
  CASE TOK_COMMA : BitTok = Tk : Tk = x
  CASE ELSE
    FOR i AS INTEGER = Tk[1] + 1 TO Tk[4] - 1
      SELECT CASE AS CONST Buf[i]
      CASE ASC(" "), ASC(!"\t"), ASC(!"\v")
      CASE ASC("0") TO ASC("9") : BitTok = Tk : EXIT FOR
      CASE ELSE : EXIT FOR
      END SELECT
    NEXT
  END SELECT : RETURN Tk - NamTok
END FUNCTION


/'* \brief Evaluate a function declaration in the token list
\returns The the result of demuxTyp() (or MSG_ERROR on error and
         MSG_STOP on the end of the token list)

Pre-check the token list for a declaration of a function, starting at
the token behind the `DECLARE` statement. When OK, use demuxTyp() to
evaluate the type of the declaration.

'/
FUNCTION Parser.demuxDecl() AS INTEGER
  SELECT CASE AS CONST *Tk
  CASE TOK_CONS, TOK_STAT, TOK_VIRT, TOK_ABST : DivTok = Tk : SKIP
  CASE ELSE : DivTok = 0
  END SELECT

  FunTok = Tk : DimTok = 0 : IniTok = 0 : BitTok = 0
  SELECT CASE AS CONST *Tk
  CASE TOK_CTOR, TOK_DTOR
    SKIP : IF *Tk = TOK_WORD THEN NamTok = Tk : SKIP ELSE NamTok = 0
    IF *Tk = TOK_EOS THEN RETURN TOK_EOS ELSE RETURN demuxTyp(1)
  CASE TOK_OPER
    DO
      SKIP
      IF *Tk = TOK_BROPN THEN EXIT DO
      IF *Tk < TOK_BROPN THEN EXIT SELECT
    LOOP UNTIL Tk >= EndTok : RETURN demuxTyp(1)
  CASE TOK_PROP
    SKIP : IF *Tk = TOK_WORD THEN NamTok = Tk ELSE EXIT SELECT
    SKIP : IF *Tk = TOK_EOS THEN RETURN TOK_EOS ELSE RETURN demuxTyp(1)
  CASE TOK_SUB, TOK_FUNC
    SKIP : IF *Tk = TOK_WORD THEN NamTok = Tk ELSE EXIT SELECT
    SKIP : IF *Tk = TOK_LIB THEN SKIP : IF *Tk = TOK_QUOTE THEN SKIP ELSE EXIT SELECT
    IF *Tk = TOK_EOS THEN RETURN TOK_EOS ELSE RETURN demuxTyp(1)
  END SELECT : TypTok = 0 : FunTok = 0 : NamTok = 0 : RETURN MSG_ERROR
END FUNCTION


/'* \brief Evaluate a type declaration in the token list
\param DeclMod The modus (normal or declaration)
\returns The (doubled) number of steps gone in the token list (or
         MSG_ERROR on error and MSG_STOP on the end of the token list)

Check the token list for a type declaration. Starting at the AS
statement we read the name of the type and all following 'PTR'
statements. The type may be a `SUB, FUNCTION, PROPERTY, ...` After
execution the current position is at the next token behind the last
`PTR`, or at the type name, or at the closing parenthesis. An error is
returned if there is no word at the current position, or the token
list doesn't start with 'AS', or the next token isn't a word.

'/
FUNCTION Parser.demuxTyp(BYVAL DeclMod AS INTEGER = 0) AS INTEGER
  VAR t = Tk
  ParTok = 0
  CalTok = 0
  AliTok = 0
  TypTok = 0
  As_Tok = 0
  ShaTok = 0
  Co1Tok = 0
  Co2Tok = 0
  PtrTok = 0
  PtrCount = 0

  IF 0 = DeclMod THEN
    DivTok = 0
    IF *Tk = TOK_AS THEN As_Tok = Tk : SKIP    ELSE RETURN MSG_ERROR

    SELECT CASE AS CONST *Tk
    CASE TOK_SUB  : FunTok = Tk
    CASE TOK_FUNC : FunTok = Tk
    CASE ELSE
      IF *Tk = TOK_CONS THEN Co1Tok = Tk : SKIP
      IF *Tk < TOK_BYTE ORELSE *Tk > TOK_WORD THEN  RETURN MSG_ERROR
      TypTok = Tk : FunTok = 0
    END SELECT : SKIP
  END IF

  SELECT CASE AS CONST *Tk
  CASE TOK_EQUAL
    IF FunTok THEN TypTok = 0                     : RETURN MSG_ERROR
    IniTok = Tk                                   : RETURN Tk - t
  CASE TOK_BROPN : IF 0 = FunTok               THEN RETURN Tk - t
    ParTok = Tk : skipOverBrclo()
  CASE ELSE
    IF 0 = FunTok THEN
      IF *Tk = TOK_CONS THEN
        Co2Tok = Tk : SKIP
        IF *Tk <> TOK_PTR THEN TypTok = 0         : RETURN MSG_ERROR
      ELSE
        IF *Tk <> TOK_PTR THEN                      RETURN Tk - t
      END IF

      PtrTok = Tk : WHILE *Tk = TOK_PTR : PtrCount += 1 : SKIP : WEND

      IF *Tk = TOK_EQUAL THEN IniTok = Tk
                                                    RETURN Tk - t
    END IF

    IF *Tk = TOK_EOS THEN RETURN IIF(*FunTok = TOK_FUNC, MSG_ERROR, TOK_EOS)

    SELECT CASE AS CONST *Tk
    CASE TOK_CDEC, TOK_STCL, TOK_PASC : CalTok = Tk : SKIP
    END SELECT

    IF *Tk = TOK_OVER THEN SKIP
    IF *Tk = TOK_ALIA THEN
      AliTok = Tk
      SKIP : IF *Tk <> TOK_QUOTE THEN TypTok = 0  : RETURN MSG_ERROR
      SKIP
    END IF

    IF *Tk = TOK_BROPN THEN ParTok = Tk : skipOverBrclo()
  END SELECT

  IF *Tk = TOK_AS THEN
    As_Tok = Tk : SKIP
    IF *Tk = TOK_CONS THEN Co1Tok = Tk : SKIP
    TypTok = Tk : SKIP
    IF *Tk = TOK_CONS THEN
      Co2Tok = Tk : SKIP
      IF *Tk <> TOK_PTR THEN FunTok = 0: TypTok = 0 : RETURN MSG_ERROR
    END IF
    PtrTok = Tk : WHILE *Tk = TOK_PTR : PtrCount += 1 : SKIP : WEND
  ELSE
    IF *FunTok = TOK_FUNC THEN RETURN MSG_ERROR
  END IF

  IF *Tk = TOK_STAT THEN
    SKIP : IF *Tk = TOK_EXPO THEN SKIP
  ELSE
    IF *Tk = TOK_EXPO THEN SKIP : IF *Tk = TOK_STAT THEN SKIP
  END IF : RETURN Tk - t
END FUNCTION


/'* \brief Evaluate a list of names
\param Export_ The function to call on each find

Scan the token list for variable declarations and call the emitter
for each find (ie. for constructs like `DIM AS BYTE Nam1, Nam2(5) =
{0,1,2,3,4,5}, Nam3, ...`).

'/
SUB Parser.parseListNam(BYVAL Export_ AS EmitFunc) EXPORT
  VAR count = 1
  TypTok = 0 : FunTok = 0
  DO
    Tk1 = Tk
    IF MSG_ERROR >= demuxNam() THEN Errr("name expected") : skipOverComma() : CONTINUE DO
    skipOverComma() : ListCount = count : Export_(@THIS) : count += 1
  LOOP UNTIL *Tk <= TOK_COMMA
END SUB


/'* \brief Evaluate a list of declarations
\param Export_ The function to call on each find

Scan the token list for variable declarations and call the emitter
for each find (ie. for constructs like `DIM Nam1 AS BYTE, Nam2(5) AS
UBYTE = {0,1,2,3,4,5}, Nam3 AS STRING, ...`).

'/
SUB Parser.parseListNamTyp(BYVAL Export_ AS EmitFunc) EXPORT
  VAR count = 1
  DO
    Tk1 = Tk
    IF MSG_ERROR >= demuxNam() THEN Errr("name expected") : skipOverComma() : CONTINUE DO
    IF MSG_ERROR >= demuxTyp() THEN Errr("type expected") : skipOverComma() : CONTINUE DO
    skipOverComma() : ListCount = count : Export_(@THIS) : count += 1
  LOOP UNTIL *Tk <= TOK_COMMA
END SUB


/'* \brief Evaluate the context of an ENUM block
\param Export_ The function to call on each find

The emitter calls us to evaluate statements inside an `ENUM` block. So
we stop after finding a statement and call the emitter handler
one-by-one.

'/
SUB Parser.parseBlockEnum(BYVAL Export_ AS EmitFunc) EXPORT
  VAR lico = 0
  TypTok = 0 : FunTok = 0 : LevelCount += 1
  WHILE Tk < EndTok
    Tk1 = Tk
    SELECT CASE AS CONST *Tk
    CASE TOK_END
      SKIP : IF *Tk = TOK_ENUM THEN EXIT WHILE
      Errr("END ENUM expected") : EXIT WHILE
    CASE TOK_LATTE : skipOverColon()
    CASE ELSE
      IF MSG_ERROR >= demuxNam() THEN Errr("name expected") : skipOverColon() : EXIT SELECT
      ListCount = lico
      skipOverComma() : IF *Tk = TOK_EOS THEN lico = 0 : skipOverColon() ELSE lico += 1
      Export_(@THIS)
    END SELECT
  WEND : skipOverColon() : LevelCount -= 1
END SUB


/'* \brief Evaluate the context of a block
\param Export_ The function to call on each find

The emitter calls us to evaluate constructs inside a block (TYPE /
UNION). So we stop after finding a statement and call the emitter
handler one-by-one.

'/
SUB Parser.parseBlockTyUn(BYVAL Export_ AS EmitFunc) EXPORT
  VAR in_tk1 = iif(LevelCount, *Tk1, *StaTok)
  LevelCount += 1
  DO
    Tk1 = Tk
    VAR nextok = Tk[3]
    SELECT CASE AS CONST nextok
    CASE TOK_AS, TOK_BROPN
      BitTok = 0
      SELECT CASE AS CONST *Tk1
      CASE TOK_DIM, TOK_RDIM : SKIP
        IF MSG_ERROR >= demuxTyp() THEN _
          IF Errr("type expected1") = MSG_ERROR THEN CONTINUE DO _
                                               ELSE EXIT DO
        IF MSG_ERROR >= demuxNam(TOK_ABST) THEN _
          IF Errr("name expected1") = MSG_ERROR THEN CONTINUE DO _
                                               ELSE EXIT DO
        skipOverComma()
        *NamTok = TOK_WORD : ListCount = 0 : Export_(@THIS)
        IF *Tk >= TOK_ABST THEN parseListNam(Export_)
      CASE ELSE
        IF MSG_ERROR >= demuxNam(TOK_ABST) THEN _
          IF Errr("name expected") = MSG_ERROR THEN CONTINUE DO _
                                               ELSE EXIT DO
        IF MSG_ERROR >= demuxTyp() THEN _
          IF Errr("type expected") = MSG_ERROR THEN CONTINUE DO _
                                               ELSE EXIT DO
        skipOverComma()
        *NamTok = TOK_WORD : ListCount = 0 : Export_(@THIS)
        IF *Tk >= TOK_ABST THEN parseListNamTyp(Export_)
      END SELECT
      skipOverColon()
    CASE ELSE
      SELECT CASE AS CONST *Tk1
      CASE TOK_LATTE : skipOverColon()
      CASE TOK_DIM, TOK_RDIM : SKIP
        IF MSG_ERROR >= demuxNam(TOK_ABST) THEN _
          IF Errr("name expected") = MSG_ERROR THEN CONTINUE DO _
                                               ELSE EXIT DO
        IF *Tk <> TOK_AS THEN _
          IF Errr("'AS' expected->" & SubStr(Tk) & "<-") = MSG_ERROR THEN CONTINUE DO _
                                               ELSE EXIT DO
        IF MSG_ERROR >= demuxTyp() THEN _
          IF Errr("type expected") = MSG_ERROR THEN CONTINUE DO _
                                               ELSE EXIT DO
        skipOverComma()
        *NamTok = TOK_WORD : ListCount = 0 : Export_(@THIS)
        IF *Tk >= TOK_ABST THEN parseListNamTyp(Export_)
        skipOverColon()
      CASE TOK_AS
        BitTok = 0
        IF MSG_ERROR >= demuxTyp() THEN _
          IF Errr("type expected") = MSG_ERROR THEN CONTINUE DO _
                                               ELSE EXIT DO
        IF MSG_ERROR >= demuxNam(TOK_ABST) THEN _
          IF Errr("name expected") = MSG_ERROR THEN CONTINUE DO _
                                               ELSE EXIT DO
        skipOverComma()
        *NamTok = TOK_WORD : ListCount = 0 : Export_(@THIS)
        IF *Tk >= TOK_ABST THEN parseListNam(Export_)
        skipOverColon()
      CASE TOK_END
        IF nextok = in_tk1                     THEN EXIT DO
        IF Errr("not supported") < MSG_ERROR   THEN EXIT DO
        skipOverColon()

      CASE TOK_DECL : SKIP
        IF MSG_ERROR >= demuxDecl() THEN _
          IF Errr("syntax error " & SubStr(NamTok)) = MSG_ERROR _
            THEN skipOverColon() : EXIT SELECT _
            ELSE EXIT DO
        skipOverColon() : Export_(@THIS)

      CASE TOK_PUBL, TOK_PRIV, TOK_PROT
        skipOverColon() : Export_(@THIS)

      CASE TOK_ENUM, TOK_TYPE, TOK_UNIO, TOK_CLAS
        VAR n = BlockNam
        IF nextok = TOK_WORD THEN SKIP : BlockNam = SubStr ELSE BlockNam = ""
        skipOverColon() : Export_(@THIS) : BlockNam = n
      CASE ELSE
        skipOverColon() : IF Errr("not supported: " & SubStr(Tk1)) < MSG_ERROR THEN EXIT DO
      END SELECT
    END SELECT
  LOOP UNTIL Tk >= EndTok : skipOverColon() : LevelCount -= 1
END SUB


/'* \brief Evaluate a parameter list
\param Export_ The function to call on each find

Scan the token list for a parameter list. Evaluate declaration
specifiers (BYVAL / BYREF) and handle ellipsis, parameters without
name, initializers and empty lists.

'/
SUB Parser.parseListPara(BYVAL Export_ AS EmitFunc) EXPORT
  VAR count = 0, t = Tk
  Tk = ParTok
  SKIP
  DO
    Tk1 = Tk
    By_Tok = 0
    SELECT CASE AS CONST *Tk
    CASE TOK_BRCLO : IF count > 0 THEN Errr("parameter expected")
      ListCount = count : EXIT DO
    CASE TOK_3DOT : NamTok = Tk : TypTok = 0 : FunTok = 0
    CASE ELSE
      IF *Tk = TOK_BYVA ORELSE *Tk = TOK_BYRE THEN By_Tok = Tk : SKIP
      IF *Tk <> TOK_AS ANDALSO *Tk >= TOK_ABST THEN
        NamTok = Tk : SKIP
        IF *Tk = TOK_BROPN THEN DimTok = Tk : skipOverBrclo()
      ELSE
        NamTok = 0
      END IF
      IF MSG_ERROR >= demuxTyp()  THEN Errr("type expected") : skipOverComma() : CONTINUE DO
    END SELECT
    skipOverComma() : count += 1 : ListCount = count : Export_(@THIS)
  LOOP UNTIL *Tk < TOK_COMMA : By_Tok = 0 : Tk = t
END SUB


/'* \brief Evaluate a TYPE or CLASS statement
\returns MSG_ERROR (or MSG_STOP on the end of the token list)

The pre-parser found a TYPE or CLASS keyword. In case of TYPE we
tokenize the line and check if it is an alias declaration. In that
case we call the emitter for a declaration on that single line.
Otherwise we tokenize the complete block and call the emitter for a
TYPE block. Or we call Errr() on syntax problems.

Note: the C emitter creates
 - 'typedef Typ Nam' for 'TYPE AS Typ Nam'
 - 'typedef struct Typ Nam' for 'TYPE Nam AS Typ'

'/
FUNCTION Parser.TYPE_() AS INTEGER
  IF 3 > tokenize(TO_COLON)               THEN RETURN Errr("syntax error")

  DimTok = 0 : IniTok = 0 : BitTok = 0
  IF *StaTok = TOK_TYPE THEN
    IF *Tk = TOK_AS THEN
      IF MSG_ERROR >= demuxTyp()          THEN RETURN Errr("type expected")
      IF *Tk = TOK_WORD THEN NamTok = Tk  ELSE RETURN Errr("name expected")
      skipOverComma()
      IF Emit->Decl_ THEN Emit->Decl_(@THIS)
                                               RETURN MSG_ERROR
    ELSE
      IF *Tk = TOK_WORD THEN NamTok = Tk : SKIP ELSE RETURN Errr("name expected")
      IF *Tk = TOK_AS THEN
        IF MSG_ERROR >= demuxTyp()        THEN RETURN Errr("type expected")
        skipOverComma()
        IF Emit->Decl_ THEN Emit->Decl_(@THIS)
                                               RETURN MSG_ERROR
      END IF
    END IF
  ELSE
    IF *Tk = TOK_WORD THEN NamTok = Tk    ELSE RETURN Errr("name expected")
  END IF
  IF 0 = Emit->Clas_                      THEN RETURN MSG_ERROR
  BlockNam = SubStr(NamTok)
  IF 9 > tokenize(TO_END_BLOCK)           THEN RETURN Errr("syntax error")
  Emit->Clas_(@THIS) :                         RETURN MSG_ERROR
END FUNCTION


/'* \brief Evaluate a variable declaration
\returns MSG_ERROR (or MSG_STOP on the end of the token list)

The pre-parser found a VAR, DIM, REDIM, CONST, EXTERN, COMMON or STATIC
keyword. We tokenize the current line and send the result to the
emitter, or we call Errr() on syntax problems.

'/
FUNCTION Parser.VAR_() AS INTEGER
  IF 3 > tokenize(TO_COLON) THEN _
         RETURN IIF(*StaTok = TOK_EXRN, MSG_ERROR, Errr("syntax error"))
  IF *Tk <> TOK_PRES THEN DivTok = 0 ELSE DivTok = Tk : SKIP
  IF *Tk <> TOK_SHAR THEN ShaTok = 0 ELSE ShaTok = Tk : SKIP

  IF *Tk = TOK_AS THEN
    IF MSG_ERROR >= demuxTyp() THEN RETURN Errr("type expected")
    IF MSG_ERROR >= demuxNam() THEN RETURN Errr("name expected")
  ELSE
    IF *StaTok = TOK_EXRN THEN      RETURN MSG_ERROR
    IF MSG_ERROR >= demuxNam() THEN RETURN Errr("name expected")
    IF *Tk = TOK_AS THEN demuxTyp() ELSE TypTok = 0 : FunTok = 0
    IF 0 = TypTok ANDALSO 0 = FunTok THEN
      SELECT CASE AS CONST *StaTok
      CASE TOK_VAR, TOK_CONS
        IF  0 = IniTok THEN         RETURN Errr("initialization expected")
      CASE ELSE                   : RETURN Errr("type expected")
      END SELECT
    END IF
  END IF

  skipOverComma()
  Emit->Decl_(@THIS)
  IF *Tk <= TOK_EOS THEN RETURN MSG_ERROR
  IF NamTok > TypTok THEN parseListNam(Emit->Decl_) _
                     ELSE parseListNamTyp(Emit->Decl_)
  RETURN MSG_ERROR
END FUNCTION


/'* \brief Evaluate an ENUM block
\returns MSG_ERROR (or MSG_STOP on the end of the token list)

The pre-parser found an ENUM keyword. We tokenize the context of the
complete block and call the emitter, or we call Errr() on
syntax problems.

'/
FUNCTION Parser.ENUM_() AS INTEGER
  IF 9 > tokenize(TO_END_BLOCK)         THEN RETURN Errr("syntax error")
  IF *Tk = TOK_WORD THEN BlockNam = SubStr : SKIP ELSE BlockNam = ""
  IF *Tk = TOK_EOS THEN skipOverColon() ELSE RETURN Errr("syntax error")
  Tk1 = StaTok
  Emit->Enum_(@THIS)
  RETURN MSG_ERROR
END FUNCTION


/'* \brief Evaluate a UNION block
\returns MSG_ERROR (or MSG_STOP on the end of the token list)

The pre-parser found an UNION keyword. We tokenize the context of the
complete block and call the emitter, or we call Errr() on
syntax problems.

'/
FUNCTION Parser.UNION_() AS INTEGER
  IF 9 > tokenize(TO_END_BLOCK)         THEN RETURN Errr("syntax error")
  IF *Tk <> TOK_WORD                    THEN RETURN Errr("name expected")
  BlockNam = SubStr()
  skipOverColon()
  Tk1 = StaTok
  Emit->Unio_(@THIS)
  RETURN MSG_ERROR
END FUNCTION


/'* \brief Evaluate a function
\returns MSG_ERROR (or MSG_STOP on the end of the token list)

The pre-parser found a SUB, FUNCTION, CONSTRUCTOR, DESTRUCTOR,
PROPERTY or OPERATOR keyword. We tokenize the complete block,
evaluate the name and type and send the result to the emitter, or we
call Errr() on syntax problems.

'/
FUNCTION Parser.FUNCTION_() AS INTEGER
  SELECT CASE AS CONST ToLast
  CASE TOK_PUBL, TOK_PRIV, TOK_ABST, TOK_VIRT : DivTok = StaTok
  CASE ELSE : DivTok = 0
  END SELECT
  IF 9 > tokenize(TO_END_BLOCK)         THEN RETURN Errr("syntax error")
  FunTok = StaTok

  IF DivTok THEN DivTok = Tk1
  IF MSG_ERROR >= demuxNam(TOK_WORD, 1) THEN RETURN Errr("name expected")
  IF MSG_ERROR >= demuxTyp(1)           THEN RETURN Errr("syntax error")

  FOR i AS INTEGER = 0 TO 1
    SELECT CASE AS CONST *Tk
    CASE TOK_STAT : SKIP ' !!! ToDo
    CASE TOK_EXPO : SKIP ' !!! ToDo
    CASE ELSE : EXIT FOR
    END SELECT
  NEXT
  skipOverBrclo()
  Emit->Func_(@THIS)
  RETURN MSG_ERROR
END FUNCTION


/'* \brief Evaluate a forward declaration
\returns MSG_ERROR (or MSG_STOP on the end of the token list)

The pre-parser found a DECLARE keyword. We tokenize the current line
and send the result to the emitter, or we call Errr() on syntax
problems.

'/
FUNCTION Parser.DECLARE_() AS INTEGER
  IF 3 > tokenize(TO_COLON)   THEN RETURN Errr("syntax error")
  IF MSG_ERROR >= demuxDecl() THEN RETURN Errr("syntax error")
  Emit->Decl_(@THIS)
  RETURN MSG_ERROR
END FUNCTION


/'* \brief Evaluate an #`INCLUDE` line
\returns MSG_ERROR (or MSG_STOP on the end of the token list)

The pre-parser found an #`INCLUDE` line. We tokenize the line and call
the emitter, or we call Errr() handler on syntax problems. It's up
to the emitter function to follow the source tree (= create a new
parser and load the file).

'/
FUNCTION Parser.INCLUDE_() AS INTEGER
  IF 3 > tokenize(TO_EOL) THEN RETURN Errr("syntax error")
  IF *Tk = TOK_ONCE THEN DivTok = Tk : SKIP ELSE DivTok = 0
  IF *Tk <> TOK_QUOTE     THEN RETURN Errr("file name expected")
  NamTok = Tk
  Emit->Incl_(@THIS)
END FUNCTION


/'* \brief Evaluate a #`MACRO` declaration
\returns MSG_ERROR (or MSG_STOP on the end of the token list)

The pre-parser found a #`MACRO` block. We tokenize the block and call
the emitter, or we call Errr() handler on syntax problems.

'/
FUNCTION Parser.MACRO_() AS INTEGER
  IF 3 > tokenize(TO_END_BLOCK) THEN RETURN Errr("syntax error")
  IF *Tk <> TOK_WORD            THEN RETURN Errr("name expected")
  NamTok = Tk : SKIP
  IF *Tk <> TOK_BROPN           THEN RETURN Errr("'()' expected")
  ParTok = Tk
  skipOverBrclo()
  Emit->Defi_(@THIS)
  RETURN MSG_ERROR
END FUNCTION


/'* \brief Evaluate a #`DEFINE` declaration
\returns MSG_ERROR (or MSG_STOP on the end of the token list)

The pre-parser found a #`DEFINE` line. We tokenize the line and call
the emitter, or we call Errr() handler on syntax problems.

'/
FUNCTION Parser.DEFINE_() AS INTEGER
  IF 3 > tokenize(TO_EOL) THEN RETURN Errr("syntax error")
  IF *Tk <> TOK_WORD      THEN RETURN Errr("name expected")
  NamTok = Tk : SKIP
  IF *Tk = TOK_BROPN ANDALSO Tk[1] = NamTok[1] + NamTok[2] _
    THEN ParTok = Tk : skipOverBrclo() _
    ELSE ParTok = 0
  DivTok = Tk
  Tk = EndTok - 3
  Emit->Defi_(@THIS)
  RETURN MSG_ERROR
END FUNCTION


/'* \brief Emit an error message
\param E The reason for the error message
\returns MSG_ERROR (and MSG_STOP at end of file)

Create an error message and call the error function of the emitter.
It depends on the emitter if and where the error gets shown.

'/
FUNCTION Parser.Errr(BYREF E AS STRING) AS INTEGER
  VAR z = LineNo
  IF LevelCount THEN '                         adapt line number counter
    FOR i AS INTEGER = Tk[1] TO EndTok[1]
      IF Buf[i] = ASC(!"\n") THEN z -= 1
    NEXT
  END IF
  ErrMsg = "-error(" & z & "): " & E & ", found '" & SubStr(Tk) & "' "

  SELECT CASE AS CONST *StaTok
  CASE TOK_DIM  : ErrMsg &= "(DIM)"
  CASE TOK_RDIM : ErrMsg &= "(REDIM)"
  CASE TOK_VAR  : ErrMsg &= "(VAR)"
  CASE TOK_CONS : ErrMsg &= "(CONST)"
  CASE TOK_STAT : ErrMsg &= "(STATIC)"
  CASE TOK_COMM : ErrMsg &= "(COMMON)"
  CASE TOK_EXRN : ErrMsg &= "(EXTERN)"
  CASE TOK_TYPE : ErrMsg &= "(TYPE)"
  CASE TOK_CLAS : ErrMsg &= "(CLASS)"
  CASE TOK_SUB  : ErrMsg &= "(SUB)"
  CASE TOK_FUNC : ErrMsg &= "(FUNCTION)"
  CASE TOK_PROP : ErrMsg &= "(PROPERTY)"
  CASE TOK_CTOR : ErrMsg &= "(CONSTRUCTOR)"
  CASE TOK_DTOR : ErrMsg &= "(DESTRUCTOR)"
  CASE TOK_NAMS : ErrMsg &= "(NAMESPACE)"
  CASE TOK_SCOP : ErrMsg &= "(SCOPE)"
  CASE TOK_ENUM : ErrMsg &= "(ENUM)"
  CASE TOK_UNIO : ErrMsg &= "(UNION)"
  CASE TOK_DECL : ErrMsg &= "(DECLARE)"
  CASE TOK_DEFI : ErrMsg &= "(#DEFINE)"
  CASE TOK_MACR : ErrMsg &= "(#MACRO)"
  CASE ELSE     : ErrMsg &= "(???)"
  END SELECT
  IF Emit->Error_ THEN Emit->Error_(@THIS)
  ErrMsg = ""

  RETURN IIF(Buf[Po] = 0, MSG_STOP, MSG_ERROR)
END FUNCTION


/'* \brief Check word at current parser position
\returns: The token for the word at current position

This function checks the word at the current parser position. In
case of a keyword the matching token gets returned. Otherwise \ref
Parser::TOK_WORD gets returned.

'/
FUNCTION Parser.getToken() AS INTEGER
  SELECT CASE AS CONST Buf[*A]
  CASE ASC("A"), ASC("a")
    SELECT CASE USubStr()
    CASE "AS" : RETURN TOK_AS
    CASE "ALIAS" : RETURN TOK_ALIA
    CASE "ANY" : RETURN TOK_ANY
    CASE "ABSTRACT" : RETURN TOK_ABST
    END SELECT
  CASE ASC("B"), ASC("b")
    SELECT CASE USubStr()
    CASE "BYTE" : RETURN TOK_BYTE
    CASE "BYREF" : RETURN TOK_BYRE
    CASE "BYVAL" : RETURN TOK_BYVA
    END SELECT
  CASE ASC("C"), ASC("c")
    SELECT CASE USubStr()
    CASE "CAST" : RETURN TOK_CAST
    CASE "CDECL" : RETURN TOK_CDEC
    CASE "CLASS" : RETURN TOK_CLAS
    CASE "CONST" : RETURN TOK_CONS
    CASE "COMMON" : RETURN TOK_COMM
    CASE "CONSTRUCTOR" : RETURN TOK_CTOR
    END SELECT
  CASE ASC("D"), ASC("d")
    SELECT CASE USubStr()
    CASE "DIM" : RETURN TOK_DIM
    CASE "DOUBLE" : RETURN TOK_DOUB
    CASE "DEFINE" : IF ToLast = TOK_LATTE THEN RETURN TOK_DEFI
    CASE "DECLARE" : RETURN TOK_DECL
    CASE "DESTRUCTOR" : RETURN TOK_DTOR
    END SELECT
  CASE ASC("E"), ASC("e")
    SELECT CASE USubStr()
    CASE "END" : RETURN TOK_END
    CASE "ENUM" : RETURN TOK_ENUM
    CASE "EXTERN" : RETURN TOK_EXRN
    CASE "EXPORT" : RETURN TOK_EXPO
    CASE "EXTENDS" : RETURN TOK_EXDS
    CASE "ENDMACRO" : IF ToLast = TOK_LATTE THEN RETURN TOK_EMAC
    END SELECT
  CASE ASC("F"), ASC("f")
    SELECT CASE USubStr()
    CASE "FUNCTION" :  RETURN TOK_FUNC
    CASE "FIELD" : RETURN TOK_FILD
    END SELECT
  CASE ASC("I"), ASC("i")
    SELECT CASE USubStr()
    CASE "INCLUDE" : IF ToLast = TOK_LATTE THEN RETURN TOK_INCL
    CASE "INTEGER" : RETURN TOK_INT
    END SELECT
  CASE ASC("L"), ASC("l")
    SELECT CASE USubStr()
    CASE "LIB" : RETURN TOK_LIB
    CASE "LONG" : RETURN TOK_LONG
    CASE "LONGINT" : RETURN TOK_LINT
    END SELECT
  CASE ASC("M"), ASC("m") : IF USubStr() = "MACRO" THEN IF ToLast = TOK_LATTE THEN RETURN TOK_MACR
  CASE ASC("N"), ASC("n") : IF USubStr() = "NAMESPACE" THEN RETURN TOK_NAMS
  CASE ASC("O"), ASC("o")
    SELECT CASE USubStr()
    CASE "ONCE" : RETURN TOK_ONCE
    CASE "OPERATOR" : RETURN TOK_OPER
    CASE "OVERLOAD" : RETURN TOK_OVER
    END SELECT
  CASE ASC("P"), ASC("p")
    SELECT CASE USubStr()
    CASE "PTR" : RETURN TOK_PTR
    CASE "PEEK" : RETURN TOK_PEEK
    CASE "POINTER" : RETURN TOK_PTR
    CASE "PRESERVE" : RETURN TOK_PRES
    CASE "PROPERTY" : RETURN TOK_PROP
    CASE "PUBLIC" : RETURN TOK_PUBL
    CASE "PRIVATE" : RETURN TOK_PRIV
    CASE "PROTECTED" : RETURN TOK_PROT
    CASE "PASCAL" : RETURN TOK_PASC
    END SELECT
  CASE ASC("R"), ASC("r") : IF USubStr() = "REDIM" THEN RETURN TOK_RDIM
  CASE ASC("S"), ASC("s")
    SELECT CASE USubStr()
    CASE "SUB" : RETURN TOK_SUB
    CASE "SCOPE" : RETURN TOK_SCOP
    CASE "SHORT" : RETURN TOK_SHOR
    CASE "SINGLE" : RETURN TOK_SING
    CASE "SHARED" : RETURN TOK_SHAR
    CASE "STRING" : RETURN TOK_STRI
    CASE "STATIC" : RETURN TOK_STAT
    CASE "STDCALL" : RETURN TOK_STCL
    END SELECT
  CASE ASC("T"), ASC("t") : IF USubStr() = "TYPE" THEN RETURN TOK_TYPE
  CASE ASC("U"), ASC("u")
    SELECT CASE USubStr()
    CASE "UNION" : RETURN TOK_UNIO
    CASE "UBYTE" : RETURN TOK_UBYT
    CASE "ULONG" : RETURN TOK_ULNG
    CASE "ULONGINT" : RETURN TOK_ULIN
    CASE "UINTEGER" : RETURN TOK_UINT
    CASE "USHORT" : RETURN TOK_USHO
    END SELECT
  CASE ASC("V"), ASC("v")
    SELECT CASE USubStr()
    CASE "VAR" : RETURN TOK_VAR
    CASE "VIRTUAL" : RETURN TOK_VIRT
    END SELECT
  CASE ASC("W"), ASC("w")
    SELECT CASE USubStr()
    CASE "WITH" : RETURN TOK_WITH
    CASE "WSTRING" : RETURN TOK_WSTR
    END SELECT
  CASE ASC("Z"), ASC("z") : IF USubStr() = "ZSTRING" THEN RETURN TOK_ZSTR
  END SELECT : RETURN TOK_WORD
END FUNCTION


/'* \brief Find the end of a multi line comment

This snippet is used to find the end of a multi line comment block. It
stops at the characters `&apos;/`.

'/
#MACRO SCAN_ML_COMM()
  Po += 2
  DO
    SELECT CASE AS CONST Buf[Po]
    CASE 0 : EXIT DO
    CASE ASC(!"\n") : LineNo += 1
    CASE ASC("'")
      SELECT CASE AS CONST Buf[Po + 1]
      CASE 0 : EXIT DO
      CASE ASC("/") : Po += 1 : EXIT DO
      END SELECT
    END SELECT : Po += 1
  LOOP
#ENDMACRO


/'* \brief Find the end of a word

This snippet is used to find the end of a word in the input buffer.
Po is at the first non-word character when done.

'/
#MACRO SCAN_WORD()
  *A = Po
  Po += 1
  DO
    SELECT CASE AS CONST Buf[Po]
    CASE ASC("0") TO ASC("9"), _
         ASC("A") TO ASC("Z"), _
         ASC("a") TO ASC("z"), ASC("_") : Po += 1
    CASE ELSE : EXIT DO
    END SELECT
  LOOP
#ENDMACRO

'* snippet to set the current token
#DEFINE SETOK(_T_,_A_,_L_) Tok &= MKL(_T_) & MKL(_A_) & MKL(_L_) : ToLast = _T_

'* snippet to exit in case of end of file
#DEFINE EXIT_STOP  SETOK(MSG_STOP, Po, 1) : Po -= 1 : EXIT DO

/'* \brief Parse a relevant construct, create a token list
\param Stop_ The condition where to end parsing
\returns The length of the token list in byte (at least 8)

Start at the current position of the input buffer to check each
character. Sort the input in to a token list. The token list
contains three values in each entry: the type of the input, its
start and its length.

The end of this process gets specified by the Stop_ parameter. It's
one of the #EoS_Modi enumerators.

'/
FUNCTION Parser.tokenize(BYVAL Stop_ AS EoS_Modi) AS INTEGER
  VAR coca = 0, endcount = 0, newblock = 0 ', currTok = MSG_ERROR, fl_end = 0
  VAR tok_begin = LEN(Tok) SHR 2
  ToLast = IIF(*StaTok = TOK_TYPE, TOK_EOS, MSG_ERROR)
  A += 3 : L += 3
  DO
    SELECT CASE AS CONST Buf[Po]
    CASE 0 : EXIT_STOP
    CASE ASC(!"\n") : LineNo += 1 : IF coca THEN coca = 0 : EXIT SELECT
      IF ToLast = TOK_EOS THEN EXIT SELECT
      SETOK(TOK_EOS, Po, 1) : IF Stop_ >= TO_EOL       THEN EXIT DO
      IF newblock THEN endcount += 1 : newblock = 0
    CASE   ASC(":")
      SETOK(TOK_EOS, Po, 1)   : IF Stop_ >= TO_COLON   THEN EXIT DO
      IF newblock THEN endcount += 1 : newblock = 0
    CASE   ASC(",") : SETOK(TOK_COMMA, Po, 1)
    CASE   ASC("-") : IF Buf[Po + 1] <> ASC(">")       THEN EXIT SELECT
      SETOK(TOK_MEOP, Po, 2)         : Po += 2       : CONTINUE DO
    CASE   ASC(".")
      IF Buf[Po + 1] = ASC(".") ANDALSO _
         Buf[Po + 2] = ASC(".") ANDALSO _
         Buf[Po + 3] <> ASC(".") _
           THEN SETOK(TOK_3DOT, Po, 3) : Po += 3     : CONTINUE DO
      SETOK(TOK_DOT, Po, 1)
    CASE   ASC("=") : SETOK(TOK_EQUAL, Po, 1)
    CASE   ASC("{"), ASC("[") : SETOK(TOK_KLOPN, Po, 1)
    CASE   ASC("}"), ASC("]") : SETOK(TOK_KLCLO, Po, 1)
    CASE   ASC("(")           : SETOK(TOK_BROPN, Po, 1)
    CASE   ASC(")")           : SETOK(TOK_BRCLO, Po, 1)
    CASE   ASC("#") : SETOK(TOK_LATTE, Po, 1)

    CASE ASC("A") TO ASC("Z"), ASC("a") TO ASC("z"), ASC("_")
      SCAN_WORD()
      *L = Po - *A : IF *L = 1 ANDALSO Buf[*A] = ASC("_") THEN coca = *A : CONTINUE DO

      VAR pretok = ToLast
      SETOK(getToken(), *A, *L)
      newblock = 0
      IF pretok = TOK_END THEN
        SELECT CASE AS CONST *StaTok
        CASE TOK_SUB, TOK_FUNC, TOK_PROP, TOK_OPER, TOK_CTOR, TOK_DTOR, TOK_ENUM
          IF ToLast = *StaTok THEN Stop_ = TO_COLON
          CONTINUE DO
        CASE TOK_UNIO, TOK_TYPE, TOK_CLAS
          IF ToLast <> *StaTok THEN CONTINUE DO
        CASE ELSE : CONTINUE DO
        END SELECT
        endcount -= 1 : IF endcount < 0 THEN Stop_ = TO_COLON
      ELSE
        SELECT CASE AS CONST *StaTok
        CASE TOK_UNIO, TOK_TYPE, TOK_CLAS
          IF pretok <> TOK_EOS THEN CONTINUE DO
          IF ToLast = *StaTok THEN newblock = 1
        CASE TOK_MACR : IF ToLast = TOK_EMAC THEN Stop_ = TO_COLON
        END SELECT
      END IF : CONTINUE DO

    CASE ASC("""")
      *A = Po
      SCAN_QUOTE(Buf,Po)
      SETOK(TOK_QUOTE, *A, Po - *A + 1)
      IF Buf[Po] <> ASC("""") THEN EXIT_STOP
    CASE ASC("'")
      SCAN_SL_COMM(Buf,Po)
      CONTINUE DO
    CASE ASC("/") : IF Buf[Po + 1] <> ASC("'") THEN   EXIT SELECT
      SCAN_ML_COMM()
      IF Buf[Po] <> ASC("/") THEN EXIT_STOP
    END SELECT : Po += 1
  LOOP : A -= 3 : L -= 3 : Po += 1

  Tk1 = CAST(LONG PTR, SADD(Tok))
  EndTok = Tk1 + (LEN(Tok) SHR 2) - 3
  Tk = Tk1 + tok_begin
  RETURN EndTok - Tk
END FUNCTION


/'* \brief Pre-parse all FB source code, search relevant constructs

Search the input buffer for a relevant construct. Start detailed
parsing on each relevant construct. Otherways skip the current line.
Export comments on the way.

'/
SUB Parser.pre_parse()
  *L = 0
  Po = 0
  ToLast = MSG_ERROR
  LineNo = 1
  Tok = ""
  IF Emit->Init_ THEN Emit->Init_(@THIS)
  DO
    SELECT CASE AS CONST Buf[Po] '                           search word
    CASE 0 : EXIT DO
    CASE ASC(!"\n") : *L = 0 : LineNo += 1
    CASE   ASC(":") : *L = 0 : ToLast = 0
    CASE   ASC("#") : ToLast = TOK_LATTE
    CASE ASC("""")
      SCAN_QUOTE(Buf,Po)
      ToLast = TOK_QUOTE : IF Buf[Po] <> ASC("""") THEN EXIT DO
    CASE ASC("'")
      SCAN_SL_COMM(Buf,Po)
      CONTINUE DO
    CASE ASC("/") : IF Buf[Po + 1] <> ASC("'") THEN EXIT SELECT
      SCAN_ML_COMM()
      IF Buf[Po] <> ASC(!"/") THEN EXIT DO

    CASE ASC("_"), ASC("A") TO ASC("Z"), ASC("a") TO ASC("z")
      SCAN_WORD() :  IF *L THEN ToLast = 0 : CONTINUE DO ' skip word, if not first
      *L = Po - *A : IF *L = 1 ANDALSO Buf[*A] = ASC("_") THEN ToLast = 0 : *L = 0 : CONTINUE DO

      ListCount = 0
      LevelCount = 0
      *StaTok = getToken()
      SELECT CASE AS CONST *StaTok
      CASE TOK_SUB, TOK_FUNC, TOK_PROP, TOK_OPER, TOK_CTOR, TOK_DTOR
                      IF Emit->Func_ ANDALSO FUNCTION_() = MSG_STOP THEN EXIT DO
      CASE TOK_DIM, TOK_RDIM, TOK_VAR, TOK_CONS, TOK_COMM, TOK_EXRN, TOK_EXPO, TOK_STAT
                      IF Emit->Decl_ ANDALSO      VAR_() = MSG_STOP THEN EXIT DO
      CASE TOK_TYPE, TOK_CLAS
                      IF                         TYPE_() = MSG_STOP THEN EXIT DO
      CASE TOK_UNIO : IF Emit->Unio_ ANDALSO    UNION_() = MSG_STOP THEN EXIT DO
      CASE TOK_ENUM : IF Emit->Enum_ ANDALSO     ENUM_() = MSG_STOP THEN EXIT DO
      CASE TOK_DECL
        IF 0 = Emit->Decl_ THEN ToLast = *StaTok : Tok = "" : CONTINUE DO
        IF                                    DECLARE_() = MSG_STOP THEN EXIT DO
      CASE TOK_DEFI : IF Emit->Defi_ ANDALSO   DEFINE_() = MSG_STOP THEN EXIT DO
      CASE TOK_MACR : IF Emit->Defi_ ANDALSO    MACRO_() = MSG_STOP THEN EXIT DO
      CASE TOK_INCL : IF Emit->Incl_ ANDALSO  INCLUDE_() = MSG_STOP THEN EXIT DO
      CASE TOK_PUBL, TOK_PRIV, TOK_ABST, TOK_VIRT
        SETOK(*StaTok, *A, *L) : *L = 0 : CONTINUE DO
      'CASE TOK_NAMS : ' !!! ToDo
      'CASE TOK_SCOP : ' !!! ToDo
      CASE ELSE :  ToLast = *StaTok : CONTINUE DO
      END SELECT : ToLast = *StaTok : Tok = "" : *L = 0 : CONTINUE DO
    END SELECT : Po += 1
  LOOP : IF Emit->Exit_ THEN Emit->Exit_(@THIS)
END SUB


/'* \brief Read a buffer from a file and parse
\param File The name of the file to translate
\param Tree If to follow source tree #`INCLUDE`
\returns The translated code (if any)

Read a file in to input buffer. Start detailed parsing on each
relevant construct. Otherwise skip the current line. Export comments
on the way. Do nothing if file doesn't exist or isn't readable.

'/
SUB Parser.File_(BYREF File AS STRING, BYVAL Tree AS INTEGER)
  VAR fnr = FREEFILE
  IF OPEN(File FOR INPUT AS #fnr) _
    THEN ErrMsg = "couldn't read file """ & File & """ " &_
                  "(ERR = " & ERR & "), currdir=" & CURDIR : EXIT SUB
  Buf = STRING(LOF(fnr), 0)
  GET #fnr, , Buf
  CLOSE #fnr

  InTree = Tree
  Fin = LEN(Buf) - 1
  IF OPT->InTree THEN InPath = LEFT(File, INSTRREV(File, SLASH))
  Fnam = File
  pre_parse()
  ErrMsg = "done"
END SUB


/'* \brief Read a buffer from pipe `STDIN` and parse
\returns The translated code (or an informal text)

Get all characters from `STDIN`. Start the parsing process. If there is
no input (an empty line) then call function \ref EmitterIF::Empty_().
(Useful for generating file templates in mode \ref SecModGeany.)

'/
SUB Parser.StdIn()
  Buf = ""
  VAR fnr = FREEFILE
  OPEN CONS FOR INPUT AS #fnr
    WHILE NOT EOF(fnr)
      DIM AS UBYTE z
      GET #fnr, , z
      Buf &= CHR(z)
    WEND
  CLOSE #fnr

  IF LEN(Buf) < 3 THEN
    IF Emit->Empty_ THEN Emit->Empty_(@THIS)
    EXIT SUB
  END IF

  Fin = LEN(Buf) - 1
  pre_parse() : IF Po THEN EXIT SUB

  Code(  "'                   " & PROJ_NAME & ": no --geany-mode output:" & _
    NL & "'                        select either a line" & _
    NL & "'         DIM, COMMON, CONST, EXTERN, STATIC, DECLARE, #DEFINE" & _
    NL & "'                              or a block" & _
    NL & "'                       ENUM, UNION, TYPE, #MACRO" & _
    NL & "'                                or a" & _
    NL & "'                      SUB, FUNCTION or PROPERTY" & _
    NL & "'                            declaration or" & _
    NL & "'                   place the cursor in an empty line" & _
    NL)
END SUB


/'* \brief Write a piece of output (for external emitters only)
\param T The text to write

External emitters cannot use the streams opened in the main program
directly. They have to send text to this procedure to use the standard
output stream.

'/
SUB Parser.writeOut(BYREF T AS STRING) EXPORT
  Code(T)
END SUB


/'* \brief The current token
\returns The token the parser currently stopping at

This property returns the parser token (where the parser currently
stops).

'/
PROPERTY Parser.CurTok() AS LONG PTR EXPORT
  RETURN Tk
END PROPERTY

/'* \brief The initialization of a bitfield
\returns The bitfield initialization

This property returns the initialization of a bitfield in a `TYPE` /
`UNION` block. The size of the bitfield may either be an integer number
or a macro (= TOK_WORD).

'/
PROPERTY Parser.BitIni() AS STRING EXPORT
  IF BitTok[3] = TOK_WORD THEN RETURN ": " & SubStr(BitTok + 3)
  VAR a = BitTok[1] + 1, l = 0
  FOR i AS INTEGER = a TO BitTok[4] - 1
    SELECT CASE AS CONST Buf[i]
    CASE ASC(" "), ASC(!"\t"), ASC(!"\v") : IF l THEN EXIT FOR
    CASE ASC("0") TO ASC("9") : IF l THEN l += 1 ELSE a = i : l = 1
    CASE ELSE : EXIT FOR
    END SELECT
  NEXT : RETURN ": " & MID(Buf, a + 1, l)
END PROPERTY

/'* \brief Context of current token
\returns The context of the current token

This property returns the context of the current token from the
input buffer.

'/
PROPERTY Parser.SubStr() AS STRING EXPORT
  IF 0 = Tk THEN RETURN " ?? 0 ?? "
  RETURN MID(Buf, Tk[1] + 1, Tk[2])
END PROPERTY

/'* \brief Context of current token at position T
\param T The token to read
\returns The context of the token T

This property returns the context of the token at position T from the
input buffer.

'/
PROPERTY Parser.SubStr(BYVAL T AS LONG PTR) AS STRING EXPORT
  IF 0 = T THEN RETURN " ?? 0 ?? "
  RETURN MID(Buf, T[1] + 1, T[2])
END PROPERTY


/'* \brief Check current token position, extract word if string type
\returns The current word in upper case

This property returns the context of the current parser position in the
input buffer in upper case characters.

'/
PROPERTY Parser.USubStr() AS STRING
  RETURN UCASE(MID(Buf, *A + 1, Po - *A))
END PROPERTY


/'* \brief Start a new parser to #`INCLUDE` a file
\param N The (path, if any, and) file name

This procedure is used by the emitter handlers for #`INCLUDE`
statements. It checks if the file has been done already or can get
opened. If one of these fails a message gets sent to `STDERR` and the
file gets skipped.

Otherwise a new parser gets started to operate on that file.

'/
SUB Parser.Include(BYVAL N AS STRING)
  WITH *OPT ' & typedef Options* Options_PTR;
    IF .RunMode = .GEANY_MODE THEN EXIT SUB

    VAR i = INSTRREV(N, SLASH)
    VAR fnam = .addPath(InPath, LEFT(N, i)) & MID(N, i + 1)

    IF DivTok ANDALSO INSTR(.FileIncl, !"\n" & fnam & !"\r") THEN _
      MSG_LINE(fnam) : _
      MSG_CONT("skipped (already done)") : EXIT SUB

    VAR fnr = FREEFILE
    IF OPEN(fnam FOR INPUT AS #fnr) THEN _
      MSG_LINE(fnam) : _
      MSG_CONT("skipped (couldn't open)") : EXIT SUB
    CLOSE #fnr
    .FileIncl &= !"\n" & fnam & !"\r"

    VAR pars_old = .Pars : .Pars = NEW Parser(.EmitIF)
    .Pars->UserTok = pars_old->UserTok

    MSG_CONT("include ...")
    .Level += 1
    .doFile(fnam)
    .Level -= 1
    MSG_CONT("done")

    DELETE .Pars : .Pars = pars_old
  END WITH
END SUB
