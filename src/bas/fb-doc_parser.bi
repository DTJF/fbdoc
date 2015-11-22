/'* \file fb-doc_parser.bi
\brief Header file for the #Parser class

This file contains the declaration of the \ref Parser, a class for
loading and scanning FB source code. It calls the matching functions in
the \ref EmitterIF.

'/

#INCLUDE ONCE "fb-doc_emitters.bi"

#IF __FB_OUT_DLL__ OR DEFINED(__FB_DOC_PLUGIN__)
 '* Convenience macro for output (plugins)
  #DEFINE Code(_T_) P->writeOut(_T_)
#print __FB_OUT_DLL__ OR DEFINED(__FB_DOC_PLUGIN__)
'&/*
#ELSE
 #DEFINE Code(_T_) PRINT #OPT->Ocha, _T_; ' Convenience macro for output (\Proj intern)
'&*/
#ENDIF

#IFDEF __FB_UNIX__
 CONST _
   SLASH = "/" _ '*< separator for folders (unix version)
    , NL = !"\n" '*< separator for lines (unix version)
'&/*
#ELSE
 CONST _
   SLASH = "\" _
    , NL = !"\r\n"
'&*/
#ENDIF

/'* \brief The parser

Class to handle FreeBASIC source code. A Parser allways work on
exactly one input stream, comming from a file or from STDIN. The
Parser does

 - read the source from an input channel (see \ref StdIn(), \ref File_())
 - call function \ref EmitterIF::Init_() before parsing
 - pre-parse the source for relavant code fractions (see \ref pre_parse())
   and call the comments emitter-handler on the way.
 - fine-scan any relavant code fractions (see \ref tokenize()) and call
   the matching emitter-handler for this code (done by the private
   functions ie. like \ref DEFINE_(), \ref FUNCTION_(), \ref VAR_(), ...)
 - provide functions to extract elements form the source (like
   \ref SubStr(), \ref CurTok(), \ref BitIni(), ...)
 - call matching emitter functions to generaate the output stream
 - call function \ref EmitterIF::Exit_() after parsing

When \Proj follows the source tree (option `--tree`), the
function \ref EmitterIF::Incl_() creates a new Parser for each file.

'/
'&typedef Parser* Parser_PTR;
TYPE Parser
Public:

/'* \brief The tokens used by the parser

Enumerators used to classify the type of a token found in the FreeBASIC
source code. Most of them are used in equal / not equal checks, but a
few are used with greater or smaller operators. Those are marked as
labeled enumerators. Don't change the order (without adapting the
source code).

'/
  ENUM ParserTokens
    MSG_STOP = -1 '*< end of file / token list reached
    MSG_ERROR     '*< create error message, continue parsing (labeled enumerator)
    TOK_EOS   '*< end of statement (either new line or `":"`, labeled enumerator)
    TOK_BRCLO '*< right parenthesis
    TOK_COMMA '*< a comma (labeled enumerator)

    TOK_KLOPN '*< left other bracket
    TOK_KLCLO '*< right other bracket
    TOK_DOT   '*< a dot
    TOK_MEOP  '*< the pointer to memory access operator "->"
    TOK_3DOT  '*< three dots
    TOK_QUOTE '*< a string constant (including quotes)
    TOK_LATTE '*< the '#' character
    TOK_BROPN '*< left parenthesis (labeled enumerator)
    TOK_EQUAL '*< the '=' character

    TOK_ABST  '*< the ABSTRACT keyword (labeled enumerator)
    TOK_ALIA  '*< the ALIAS keyword
    TOK_AS    '*< the AS keyword
    TOK_BYRE  '*< the BYREF keyword
    TOK_BYVA  '*< the BYVAL keyword
    TOK_CAST  '*< the CAST keyword
    TOK_CDEC  '*< the CDECL keyword
    TOK_CLAS  '*< the CLASS keyword
    TOK_COMM  '*< the COMMON keyword
    TOK_CONS  '*< the CONST keyword
    TOK_DECL  '*< the DECLARE keyword
    TOK_DEFI  '*< the #`DEFINE` keyword
    TOK_DIM   '*< the DIM keyword
    TOK_END   '*< the END keyword
    TOK_ENUM  '*< the ENUM keyword
    TOK_EXDS  '*< the EXTENDS keyword
    TOK_EMAC  '*< the #`ENDMACRO` keyword
    TOK_EXRN  '*< the EXTERN keyword
    TOK_EXPO  '*< the EXPORT keyword
    TOK_INCL  '*< the #`INCLUDE` keyword
    TOK_LIB   '*< the LIB keyword
    TOK_MACR  '*< the #`MACRO` keyword
    TOK_WITH  '*< the WITH keyword
    TOK_NAMS  '*< the NAMESPACE keyword
    TOK_ONCE  '*< the ONCE keyword
    TOK_OVER  '*< the OVERLOAD keyword
    TOK_PASC  '*< the PASCAL keyword
    TOK_PRIV  '*< the PRIVATE keyword
    TOK_PROT  '*< the PROTECTED keyword
    TOK_RDIM  '*< the REDIM keyword
    TOK_PTR   '*< the PTR or POINTER keyword
    TOK_PEEK  '*< the PEEK keyword
    TOK_PUBL  '*< the PUBLIC keyword
    TOK_SCOP  '*< the SCOPE keyword
    TOK_SHAR  '*< the SHARED keyword
    TOK_PRES  '*< the PRESERVE keyword
    TOK_STAT  '*< the STATIC keyword
    TOK_STCL  '*< the STDCALL keyword
    TOK_TYPE  '*< the TYPE keyword
    TOK_UNIO  '*< the UNION keyword
    TOK_VAR   '*< the VAR keyword
    TOK_VIRT  '*< the VIRTUAL keyword

    TOK_FUNC  '*< the FUNCTION keyword
    TOK_FILD  '*< the FIELD keyword
    TOK_OPER  '*< the OPERATOR keyword
    TOK_PROP  '*< the PROPERTY keyword
    TOK_SUB   '*< the SUB keyword
    TOK_CTOR  '*< the CONSTRUCTOR keyword
    TOK_DTOR  '*< the DESTRUCTOR keyword

    TOK_BYTE  '*< the BYTE data type (labeled enumerator)
    TOK_DOUB  '*< the DOUBLE data type
    TOK_INT   '*< the INTEGER data type
    TOK_LONG  '*< the LONG data type
    TOK_LINT  '*< the LONGINT data type
    TOK_STRI  '*< the STRING data type
    TOK_SHOR  '*< the SHORT data type
    TOK_SING  '*< the SINGLE data type
    TOK_UBYT  '*< the UBYTE data type
    TOK_ULNG  '*< the ULONG data type
    TOK_ULIN  '*< the ULONGINT data type
    TOK_UINT  '*< the UINTEGER data type
    TOK_USHO  '*< the USHORT data type
    TOK_WSTR  '*< the ZSTRING data type
    TOK_ZSTR  '*< the ZSTRING data type
    TOK_ANY   '*< the ANY keyword
    TOK_WORD  '*< a word (labeled enumerator)

    TOK_COMSL '*< line end comment (single line, labeled enumerator)
    TOK_COMML '*< multi line comment
  END ENUM

/'* \name Parser STRINGs

STRING variables to exchange data with th emitters.

\{
'/
  AS STRING _
    InPath = "" _ '*< path of current of input file (option `--tree`)
  , Fnam _        '*< the name of the input file
  , Buf _         '*< the input buffer
  , ErrMsg _      '*< an error message
  , Tok _         '*< the token list (binaries)
  , BlockNam      '*< the name of a block (ENUM, UNION, TYPE)

'* \}


/'* \name Parser token pointers

Pointers to the token list, used to specify the result of the
parsing process. The tokens specify the construct in progress and
they are used by the emitters to create their output.

Four main tokens specify the kind of the construct:

 - StaTok: the start of the current construct
 - NamTok - subtokens: DimTok, IniTok (may be zero in parameter lists)
 - TypTok - subtokens: ShaTok, PtrTok, Co1Tok, Co2Tok (is zero for VAR, may be zero for CONST)
 - FunTok - subtokens: ParTok, AliTok, DivTok, By_Tok (is zero for variables)

Other tokens are only valid if the main token is not zero.

\{
'/
  AS LONG PTR _
    StaTok, _  '*< the pre-parsed token
    NamTok, _  '*< the name token of the construct
    DimTok, _  '*< the token of the left parenthesis of a dimension
    IniTok, _  '*< the start token of an initializer ('=')
    BitTok, _  '*< the start token of an bitfiled declaration (':')
    TypTok, _  '*< the token of the type keyword
    ShaTok, _  '*< the token of the SHARED keyword
    PtrTok, _  '*< the token of the first PTR keyword
    Co1Tok, _  '*< the token of the first CONST keyword (if any)
    Co2Tok, _  '*< the token of the second CONST keyword (if any)
    FunTok, _  '*< type of the pre-parsed token
    CalTok, _  '*< the token of the calling convention keyword (if any)
    AliTok, _  '*< the token of the ALIAS keyword (if any)
    As_Tok, _  '*< the token of the AS keyword (if no SUB)
    ParTok, _  '*< the token of the left parenthesis of a parameter list
    By_Tok, _  '*< the token of the declaration specifier (BYVAL / BYREF)
    DivTok, _  '*< the token of different purposes like the STATIC keyword in a member function declaration (if any) or the LIB keyword in a normal declaration
    Tk1, _     '*< the first token in a statment
    EndTok, _   '*< the last token in the list
    UserTok    '*< a token for customised usage in emitter-handlers

'* \}

/'* \name Parser counters, integers and pointers

Diverse variables used on different events. They inform the emitters
about the state of the parser.

\{
'/
  AS LONG _
    Po, _         '*< the current position in the input buffer \ref Parser::Buf
    Fin, _        '*< the last position in the input buffer \ref Parser::Buf
    PtrCount, _   '*< the number of PTR keywords
    SrcBgn, _     '*< start position to export FB source
    LineNo, _     '*< the current line in the input buffer \ref Parser::Buf
    LevelCount, _ '*< the level in nested blocks (one based)
    InTree,     _ '*< flag to indicate if to follow source tree #`INCLUDE`s
    ListCount     '*< the current entry in a list (zero based)

'* \}

  DECLARE CONSTRUCTOR(BYVAL AS EmitterIF PTR)

/'* \name Filehandlers

Filehandlers are used to load some FreeBASIC source code input in to
the buffer \ref Parser::Buf from different input channels (may be the
STDIN pipe, a single file or all files in a folder). Afterwards the
source code gets parsed and translated output created by the emitter
gets returned.

\{
'/
  DECLARE SUB File_(BYREF AS STRING, BYVAL AS INTEGER)
  DECLARE SUB StdIn()
  DECLARE SUB Include(BYVAL AS STRING)
  DECLARE SUB writeOut(BYREF AS STRING)
'* \}

/'* \name Properties to extract original source code

Properties are used to extract original text from the input buffer
at a certain position. This is the current position of the parser,
or the position  of the given parameter.

\{
'/
  DECLARE PROPERTY CurTok() AS LONG PTR
  DECLARE PROPERTY BitIni() AS STRING
  DECLARE PROPERTY SubStr() AS STRING
  DECLARE PROPERTY SubStr(BYVAL AS LONG PTR) AS STRING
'* \}

/'* \name Parsers for lists and blocks

External demuxers are called from emitter-handlers when they sit on
a list of statments, ie. in an ENUM block or in a DIM statement with
more than one variable.

\{
'/
  DECLARE SUB parseListNam(BYVAL AS EmitFunc)
  DECLARE SUB parseListNamTyp(BYVAL AS EmitFunc)
  DECLARE SUB parseListPara(BYVAL AS EmitFunc)
  DECLARE SUB parseBlockEnum(BYVAL AS EmitFunc)
  DECLARE SUB parseBlockTyUn(BYVAL AS EmitFunc)
'* \}

Private:

/'* \brief The modi for end of statement searching

Enumerators used in internal in the parser to specify where to stop
to tokenize the input buffer

'/
  ENUM EoS_Modi
    TO_END_BLOCK  '*< tokenize to the end of the structure
    TO_END        '*< stop at the end of the token list
    TO_EOL        '*< stop at the next line end
    TO_COLON      '*< stop at the next line end or colon
  END ENUM

/'* \name Internal values

Variables used in pre-parsing process.

\{
'/
  AS LONG _
    ToLast    '*< the type of the token before the current one

  AS LONG PTR _
    Tk, _     '*< the current token of the parser
    A, _      '*< start of a word in pre-parsing
    L         '*< length of a word in pre-parsing

  AS EmitterIF PTR Emit  '*< the emitter interface

'* \}

/'* \name Internal parsers

Functions for evaluating a construct in the FreeBASIC source code after
a relevant keyword was found in the pre-parsering process. After the
fine-parsing process the matching emitter-handler gets called. (Or the
function \ref EmitterIF::Error_() in case of a syntax problem. It's up
to the emitter if and where the user sees the error message.)

\{
'/
  DECLARE SUB pre_parse()
  DECLARE PROPERTY USubStr() AS STRING
  DECLARE FUNCTION getToken() AS INTEGER
  DECLARE FUNCTION tokenize(BYVAL AS EoS_Modi) AS INTEGER
  DECLARE FUNCTION Errr(BYREF AS STRING) AS INTEGER

  DECLARE FUNCTION demuxNam(BYVAL AS INTEGER = TOK_WORD, BYVAL AS INTEGER = 0) AS INTEGER
  DECLARE FUNCTION demuxTyp(BYVAL AS INTEGER = 0) AS INTEGER
  DECLARE FUNCTION demuxDecl() AS INTEGER

  DECLARE FUNCTION skipOverColon() AS INTEGER
  DECLARE FUNCTION skipOverBrclo() AS INTEGER
  DECLARE FUNCTION skipOverComma() AS INTEGER

  DECLARE FUNCTION VAR_() AS INTEGER
  DECLARE FUNCTION TYPE_() AS INTEGER
  DECLARE FUNCTION ENUM_() AS INTEGER
  DECLARE FUNCTION UNION_() AS INTEGER
  DECLARE FUNCTION FUNCTION_() AS INTEGER
  DECLARE FUNCTION DECLARE_() AS INTEGER
  DECLARE FUNCTION INCLUDE_() AS INTEGER
  DECLARE FUNCTION DEFINE_() AS INTEGER
  DECLARE FUNCTION MACRO_() AS INTEGER
'* \}

END TYPE


/'* \brief Find the end of a Quote

This snippet is used to find the end of a quoted string. It checks
if the string uses escape sequences and evaluates '\\"' . It stops at
the last double quote (if Buf[Po] isn't ASC(!"\\"") then the end of
the buffer is reached).

'/
#MACRO SCAN_QUOTE(Buf,Po)
  VAR esc = IIF(Po, IIF(Buf[Po - 1] = ASC("!"), 1, 0), 0)
  DO
    Po += 1
    SELECT CASE AS CONST Buf[Po]
    CASE 0, ASC(!"\n") : Po -= 1 : EXIT DO
    CASE ASC("\") : IF esc THEN Po += 1
    CASE ASC("""") : IF Buf[Po + 1] = ASC("""") THEN Po += 1 ELSE EXIT DO
    END SELECT
  LOOP
#ENDMACRO


/'* \brief Find the end of a line end comment

This snippet is used to find the end of a line end comment. It
checks for a ASC(!"\n") and evaluates line concatenations ( _ ) on
the way. It stops at the line end (if Buf[Po] isn't ASC(!"\n") then
the end of the buffer is reached).

'/
#MACRO SCAN_SL_COMM(Buf,Po)
  DO
    Po += 1
    SELECT CASE AS CONST Buf[Po]
    CASE 0, ASC(!"\n") : EXIT DO
    END SELECT
  LOOP
#ENDMACRO
