/'* \file py_ctypes.bas
\brief Code example for an external emitter, generating Python bindings

This file contains example source code for an external emitter. The
emitter outputs Python declarations from the FB source code, in order
to generate Python bindings based on
[ctypes](https://docs.python.org/2/library/ctypes.html#) for libraries
compiled in FB.

The author is neither keen on Python syntax, nor on ctypes specials.
Rather than a perfect example, this code is more like a quick and dirty
solution to generate a Phyton binding for the library
[libpruio](http://github.com/DTJF/libpruio). But interrested users may
find some inspiration in the code.

Example:

In order to compute a ctypes binding for libpruio, execute in the
folder `src/bas/plugins` the following command:

~~~{txt}
fb-doc -e "py_ctypes" -t -pylib=pruio ../libpruio/src/pruio/pruio.bi
~~~

Options

- `-e "py_ctypes"`: choose external emitter named py_ctypes (filename `libpy_ctypes.[so|dll])
- `-t`: follow source tree
- `-pylib=pruio`: binary name to include for python code (special plugin option, unknown for \Proj)
- `../libpruio/src/pruio/pruio.bi`: the start file (expects that libpruio source is installed at the same directory level as \Proj project source)

The output comes at STOUT (in the shell). In order to write it to a
file just append `> pruio.py` to the command, like

~~~{txt}
fb-doc -e "py_ctypes" -t -pylib=libpruio ../libpruio/src/pruio/pruio.bi > libpruio.py
~~~

\since 0.4.0
'/

#INCLUDE ONCE "../fbdoc_options.bi"


'* Macro to place a comment in to the output (file name and line number)
#DEFINE NEW_ENTRY Code(NL & NL & "# " & MID(.Fnam, INSTRREV(.Fnam, SLASH) + 1) & ": " & .LineNo)
DIM SHARED AS LONG _
  ENUM_COUNT  '*< A counter for ENUM blocks
DIM SHARED AS STRING _
    T1 _      '*< The _fields_ type block
  , T2 _      '*< The list of type names (`,` separated)
  , CLASSES _ '*< The list of class names (`!"\n"` separated)
  , LIBRARY _ '*< The name of the binary to build
  , PRELOAD _ '*< The file to prepend, if any
  , HEADER    '*< The header for the output
CLASSES = !"\n" ' initialize the list


/'* \brief Transform number literals
\param T The string to work on
\returns The transformed number

Helper procedure that checks a string for numerical literals and
transforms the FB notation to Python equivalents.

\since 0.4.0
'/
FUNCTION genNLiteral(BYREF T AS STRING) AS STRING
  FOR i AS INTEGER = 0 TO LEN(T) - 1
    SELECT CASE AS CONST T[i]
    CASE 0 TO 31, ASC("'"), ASC(",") : RETURN LEFT(T, i)
    CASE ASC("/") : IF T[i + 1] = ASC("'") THEN RETURN LEFT(T, i)
    CASE ASC("&")
      SELECT CASE AS CONST T[i + 1]
      CASE 0 : RETURN LEFT(T, i)
      CASE ASC("H"), ASC("h") : MID(T, i + 1, 2) = "0x" : i += 2
      CASE ASC("O"), ASC("o") : MID(T, i + 1, 2) = " 0" : i += 2
      CASE ASC("B"), ASC("b") : MID(T, i + 1, 2) = "0b" : i += 2
      END SELECT
    END SELECT
  NEXT : RETURN T
END FUNCTION


/'* \brief Transform a FB type in to a ctype
\param P The parser calling this emitter
\returns A string containing the type

Helper function that transforms a FB type in to the ctypes equivalent
in case of a standard type. Otherwise the original type symbol gets
returned. Pointers get enclosed by `POINTER(...)`, but `ZSTRING PTR`
gets transformed to `c_char_p`.

\since 0.4.0
'/
FUNCTION genCType(BYVAL P AS Parser PTR) AS STRING
  WITH *P '&Parser* P;
    VAR r = ""
    FOR i AS INTEGER = 1 TO .PtrCount : r = "POINTER(" : NEXT
    SELECT CASE UCASE(.SubStr(.TypTok))
    CASE     "BYTE" : r &= "c_byte"
    CASE    "UBYTE" : r &= "c_ubyte"
    CASE    "SHORT" : r &= "c_short"
    CASE   "USHORT" : r &= "c_ushort"
    CASE     "LONG" : r &= "c_long"
    CASE    "ULONG" : r &= "c_ulong"
    CASE  "INTEGER" : IF SIZEOF(INTEGER) > 4 THEN r &= "c_longlong"  ELSE r &= "c_int"
    CASE "UINTEGER" : IF SIZEOF(INTEGER) > 4 THEN r &= "c_ulonglong" ELSE r &= "c_uint"
    CASE  "LONGINT" : r &= "c_longlong"
    CASE "ULONGINT" : r &= "c_ulonglong"
    CASE   "SINGLE" : r &= "c_float"
    CASE   "DOUBLE" : r &= "c_double"
    CASE      "ANY" : RETURN "c_void_p"
    CASE  "ZSTRING"
      IF .PtrCount = 1 THEN RETURN "c_char_p"
      r &= "c_char"
    CASE ELSE       : r &= .SubStr(.TypTok)
    END SELECT
    FOR i AS INTEGER = 1 TO .PtrCount : r &= ")" : NEXT
    RETURN r
  END WITH
END FUNCTION


/'* \brief Export the initializer(s) for a variable
\param P the parser calling this emitter

This sub reads the initializer from the input buffer and emits them
unchanged. This may be a bunch of text in case of an array initializer.

'/
SUB py_CreateIni CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    VAR kl = 0, i = .IniTok[1], a = i, e = 0, atc = 0, tup = *.StaTok = .TOK_CONS
    Code(" ")
    DO
      i += 1
      SELECT CASE AS CONST .Buf[i]
      CASE 0 : EXIT DO
      CASE ASC(!"\n")
        Code(MID(.Buf, a + 1, IIF(e, e, i) - a))
        a = i + 1
        IF kl <= 0 ANDALSO (e = 0 ORELSE .Buf[e] <> ASC("_")) THEN EXIT SUB
        Code(NL)
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
      CASE ASC("("), ASC("{"), ASC("[") : kl += 1 : .Buf[i] = IIF(tup, ASC("("), ASC("["))
      CASE ASC(")"), ASC("}"), ASC("]") : kl -= 1 : .Buf[i] = IIF(tup, ASC(")"), ASC("]")) : IF kl <  0 THEN EXIT DO
      CASE ASC(",")                               : IF kl <= 0 THEN EXIT DO
      END SELECT
    LOOP UNTIL i >= .EndTok[1] : IF i <= a THEN EXIT SUB
    Code(MID(.Buf, a + 1, IIF(e, e, i) - a))
    IF atc THEN .Buf[atc] = ASC("@")
  END WITH
END SUB


/'* \brief Emitter to extract the types of a parameter list
\param P The parser calling this emitter

Emitter that collects the types of the parameter list in global
variable `T2`, to be used in py_function().

\since 0.4.0
'/
SUB py_entryListPara CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    IF 0 = .TypTok THEN T2 &= ", ???" _
                   ELSE T2 &= ", " & genCType(P)
  END WITH
END SUB


/'* \brief Emitter called when the Parser is on top of a function body
\param P The parser calling this emitter

FIXME

\since 0.4.0
'/
SUB py_function CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    VAR sym = .SubStr(IIF(.NamTok[3] = .TOK_DOT, .NamTok + 6, .NamTok)) _
      , typ = ""
    IF .TypTok THEN
      typ = genCType(P)
      IF typ = "c_char_p" THEN
        typ =    "if sizeof(c_int) == sizeof(c_void_p):" _
        & NL & "      " & sym & ".restype = ReturnString" _
        & NL & "  else:" _
        & NL & "      " & sym & ".restype = String" _
        & NL & "      " & sym & ".errcheck = ReturnString"
      ELSE
        typ = sym & ".restype = " & typ
      END IF
    ELSE
      typ = sym & ".restype = None"
    END IF
    T2 = ""
    IF .ParTok THEN .parseListPara(@py_entryListPara())

    NEW_ENTRY
    Code(NL & "if hasattr(_libs['" & LIBRARY & "'], '" & sym & "'):" _
       & NL & "  " & sym & " = _libs['" & LIBRARY & "']." & sym _
       & NL & "  " & sym & ".argtypes = [" & MID(T2, 3) & "]" _
       & NL & "  " & typ)
  END WITH
END SUB


/'* \brief Emitter to generate a line for a ENUM block entry
\param P The parser calling this emitter

Emitter that gets called when the parser is in a block (`ENUM`). It
generates a line for each member and writes it (them) to the output.

\since 0.4.0
'/
SUB py_emitEnumNames CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    IF 0 = .NamTok THEN EXIT SUB
    VAR v = ""
    IF .IniTok THEN
      VAR a = .IniTok[1] + 2, i = a
      ENUM_COUNT = VALINT(MID(.Buf, a))
      DO
        SELECT CASE AS CONST .Buf[i]
        CASE 0 TO 31, ASC(","), ASC("'") : EXIT DO
        END SELECT : i += 1
      LOOP
      v = genNLiteral(MID(.Buf, a, i - a + 1))
    ELSE
      ENUM_COUNT += 1
      v = STR(ENUM_COUNT)
    END IF
    ENUM_COUNT = IIF(.IniTok, VALINT(MID(.Buf, .IniTok[1] + 2)), ENUM_COUNT + 1)
    Code(NL & "try: " & .SubStr(.NamTok) & " =" & v _
       & NL & "except: pass")
  END WITH
END SUB

/'* \brief Emitter to generate a line for a TYPE / UNION block entry
\param P The parser calling this emitter

This emitter gets called when the parser is in a block (`TYPE` or `UNION`).
It generates a line for each member and writes it (them) to the output.

\since 0.4.0
'/
SUB py_emitBlockNames CDECL(BYVAL P AS Parser PTR)
  STATIC AS STRING ctype
  WITH *P '&Parser* P;
    SELECT CASE AS CONST *.Tk1
    CASE .TOK_PRIV, .TOK_PROT ': .SrcBgn = 0 ' !!! ToDo: hide private?
    CASE .TOK_PUBL            ': .SrcBgn = 1
    CASE .TOK_CLAS, .TOK_TYPE, .TOK_UNIO
      .parseBlockTyUn(@py_emitBlockNames())
    CASE .TOK_ENUM
      .parseBlockEnum(@py_emitEnumNames())
    CASE .TOK_DECL ' skip this
    CASE ELSE : IF 0 = .NamTok THEN EXIT SUB
      VAR size = "", sym = .SubStr(.NamTok)
      IF .TypTok THEN
        ctype = genCType(P)
        IF ctype = "STRING" then ctype = "c_void_p * 3"
      END IF
      IF .FunTok THEN
        IF 0 = .TypTok THEN ctype = "None"
        T2 = ", " & ctype
        IF .ParTok THEN .parseListPara(@py_entryListPara())
        ctype = "CFUNCTYPE(" & MID(T2, 3) & ")"
      ELSEIF .DimTok THEN
        VAR a = .DimTok[1] + 2, i = a
        size = " * ("
        DO
          SELECT CASE AS CONST .Buf[i]
          CASE 0 TO 31, ASC("'") : EXIT DO
          CASE ASC(!")")
            VAR v = genNLiteral(TRIM(MID(.Buf, a, i - a + 1), ANY !", \t\v"))
            IF LEN(size) < 6 THEN size &= v & " + 1" _
                       ELSE size &= "(" & v & " + 1)"
            EXIT DO
          CASE ASC(!",")
            VAR v = genNLiteral(TRIM(MID(.Buf, a, i - a + 1), ANY !", \t\v"))
            size &= "(" & v & " + 1) * " : a = i + 1
          END SELECT : i += 1
        LOOP
        size &= ")"
      END IF
      T1 &= NL & "  ('" & sym & "', " & ctype & size & "),"
    END SELECT
  END WITH
END SUB


/'* \brief Emitter called when the Parser is at a variable declaration
\param P The parser calling this emitter

This emitter generates a variable (or function) declaration and writes
it (them) to the output.

\since 0.4.0
'/
SUB py_declare CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    IF .FunTok THEN py_function(P) : EXIT SUB

    NEW_ENTRY
    VAR n = genCType(P)
    IF n <> .SubStr(.TypTok) THEN ' type declaration
      Code(NL & .SubStr(.NamTok) & " = " & n)
    ELSEIF .IniTok THEN ' variable declaration
      Code(NL & .SubStr(.NamTok))
      py_CreateIni(P)
    ELSE ' UDT forward declaration
      CLASSES &= n & !"\n"
      Code(NL & "class " & n & "(Structure):" _
         & NL & "  pass" _
         & NL & .SubStr(.NamTok) & " = " & .SubStr(.TypTok))
    END IF
  END WITH
END SUB


/'* \brief Emitter called when the Parser is at the start of a ENUM block
\param P The parser calling this emitter

This emitter gets called when the parser starts an `ENUM` block. It
resets the counter and starts parsing line vice the contents, and
generating related output.

\since 0.4.0
'/
SUB py_enum CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    NEW_ENTRY
    ENUM_COUNT = -1
    .parseBlockEnum(@py_emitEnumNames())
  END WITH
END SUB


/'* \brief Emitter called when the Parser is at the start of a UNION block
\param P The parser calling this emitter

This emitter gets called when the parser starts an `UNION` block. It
just starts parsing line vice the contents, and generating related
output.

\since 0.4.0
'/
SUB py_union CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    .parseBlockTyUn(@py_emitBlockNames())
    NEW_ENTRY
  END WITH
END SUB


/'* \brief Emitter called when the Parser is at the start of a TYPE block
\param P The parser calling this emitter

This emitter gets called when the parser starts a `TYPE` block. It
stores the block name and starts parsing line vice the contents, as
well as generating related output.

\since 0.4.0
'/
SUB py_class CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    T1 = .BlockNam & "._fields_ = ["
    .parseBlockTyUn(@py_emitBlockNames())
    NEW_ENTRY

    IF 0 = INSTR(CLASSES, !"\n" & .BlockNam & !"\n") THEN
      Code(NL & NL & "class " & .BlockNam & "(Structure):" _
              & NL & "  pass ")
    END IF

    Code(NL & T1 & NL & "]")
  END WITH
END SUB


/'* \brief Emitter called when the Parser is at a #`DEFINE` line or at the start of a #`MACRO`
\param P The parser calling this emitter

FIXME

\since 0.4.0
'/
SUB py_define CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    IF .ParTok THEN EXIT SUB ' no MACRO or DEFINE with parameter list

    VAR a = .NamTok[1] + .NamTok[2] + 1 _
      , l = .EndTok[1] + .EndTok[2] - a
    IF 0 = l THEN EXIT SUB ' skip empty defines

    VAR v = genNLiteral(TRIM(MID(.Buf, a, l)))
    NEW_ENTRY
    Code(NL & "try: " & .SubStr(.NamTok) & " = " & v _
       & NL & "except: pass")
  END WITH
END SUB


/'* \brief Emitter called when the Parser is at an #`INCLUDE` line
\param P The parser calling this emitter

FIXME

\since 0.4.0
'/
SUB py_include CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    IF .InTree THEN .Include(TRIM(.SubStr(.NamTok), """"))
  END WITH
END SUB


/'* \brief Emitter called when the Parser is at the start of a file
\param P The parser calling this emitter

This emitter sends the HEADER information to the output once.

\since 0.4.0
'/
SUB py_init CDECL(BYVAL P AS Parser PTR)
  IF LEN(PRELOAD) THEN
    VAR fnr = FREEFILE
    IF 0 = OPEN(PRELOAD FOR INPUT AS fnr) THEN
      VAR t = ""
      WHILE NOT EOF(fnr)
        LINE INPUT #fnr, t
        Code(t & NL)
      WEND : CLOSE fnr
    END IF
  END IF : HEADER = ""
  IF LEN(HEADER) THEN Code(HEADER) : HEADER = ""
END SUB


/'* \brief Emitter called when the Parser is at the end of a input file
\param P The parser calling this emitter

This emitter just adds a new line character to the output.

\since 0.4.0
'/
SUB py_exit CDECL(BYVAL P AS Parser PTR)
  Code(NL)
END SUB


/'* \brief Constructor called before the first input gets parsed
\param O The Options UDT calling this constructor

FIXME

\since 0.4.0
'/
SUB py_CTOR CDECL(BYVAL O AS Options PTR)
  HEADER = "# header file auto generated by fb-doc and plugin py_ctypes.bas" _
    & NL & "# to be inported by libpruio.py (do not change)" _
    & NL & "from ctypesloader import *" _
    & NL _
    & NL & "_libs = {}" _
    & NL & "_libs['" & LIBRARY & "'] = load_library('" & LIBRARY & "')"
END SUB


'/'* \brief Emitter called after the input got parsed
'\param O The parser calling this emitter

'Maybe useful in future.

'\since 0.4.0
''/
'SUB py_DTOR CDECL(BYVAL O AS Options PTR)
  'Code(NL)
'END SUB



/'* \brief Initialize the EmitterIF and evaluate parameters
\param Emi The newly created EmitterIF to fill with our callbacks
\param Par Additional command line parameters, not parsed by \Proj

When the user requires to load this plugin by option \ref
SecOptEmitter, this SUB gets called to initialize the EmitterIF. Here,
all default pointers (= NULL) get replaced by custom functions. Those
functions just report all the \Proj function calls, in order to make
the parsing process transparent.

The second parameter `Par` is a list of all command line parameters
which are unknown to \Proj. Those options get collected in a string,
separated by tabulators (`!"\n"), and starting by a tabulator. This SUB
extracts and evaluates its parameters from the string. When the string
isn't empty at the end of this SUB, the calling \Proj program stops
execution by an `unknown options` error.

\since 0.4.0
'/
SUB EmitterInit CDECL(BYVAL Emi AS EmitterIF PTR, BYREF Par AS STRING) EXPORT
  WITH *Emi
    .CTOR_ = @py_CTOR()
    '.DTOR_ = @py_DTOR()
    .Init_ = @py_init()
    .Exit_ = @py_exit()

    .Decl_ = @py_declare()
    .Func_ = @py_function()
    .Enum_ = @py_enum()
    .Unio_ = @py_union()
    .Clas_ = @py_class()
    .Defi_ = @py_define()
    .Incl_ = @py_include()
  END WITH

  VAR a = INSTR(Par, !"\t-py lib=")
  IF a THEN
    a += 8
    VAR e = INSTR(a, Par, !"\t")
    IF 0 = e THEN e = LEN(Par) + 1
    LIBRARY = TRIM(MID(Par, a,  e - a), ANY "'""")
    Par = LEFT(Par, a - 9) & MID(Par, e)
  ELSE
    LIBRARY = "FIXME.so"
  END IF

  a = INSTR(Par, !"\t-py_preload=")
  IF a THEN
    a += 12
    VAR e = INSTR(a, Par, !"\t")
    IF 0 = e THEN e = LEN(Par) + 1
    PRELOAD = TRIM(MID(Par, a,  e - a), ANY "'""")
    Par = LEFT(Par, a - 13) & MID(Par, e)
  ELSE
    PRELOAD = ""
  END IF
END SUB
