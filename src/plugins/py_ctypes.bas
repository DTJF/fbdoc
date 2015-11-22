/'* \file py_ctypes.bas
\brief Example code for an external emitter for Python bindings

This file contains example source code for an external emitter. The
emitter outputs Python declarations from the FB headers, in order to
generate Python bindings based on
[ctypes](https://docs.python.org/2/library/ctypes.html#) for libraries
compiled in FB.

\since 0.4.0
'/

#INCLUDE ONCE "../bas/fb-doc_parser.bi"


'* Macro to place a comment in to the output (file name and line number)
#DEFINE NEW_ENTRY Code(!"\n\n# " & MID(.Fnam, INSTRREV(.Fnam, SLASH) + 1) & ": " & .LineNo)
DIM SHARED AS LONG _
  ENUM_COUNT  '*< counter for ENUM blocks
DIM SHARED AS STRING _
    T0 _      '*< first type block
  , T1 _      '*< second type block
  , T2 _      '*< the list of type names (`,` separated)
  , CLASSES _ '*< the list of class names (NL separated)
  , LIBRARY   '*< the name of the binary to include
CLASSES = !"\n"


/'* \brief Transform number literals
\param T The string to work on

This procedure checks a string for numerical literals and transforms
the FB notation to Python equivalents.

\since 0.4.0
'/
SUB genNLiteral(BYREF T AS STRING)
  FOR i AS INTEGER = 0 TO LEN(T) - 1
    IF T[i] = ASC("&") THEN
      SELECT CASE AS CONST T[i + 1]
      CASE 0 : EXIT FOR
      CASE ASC("H"), ASC("h") : MID(T, i + 1, 2) = "0x" : i += 2
      CASE ASC("O"), ASC("o") : MID(T, i + 1, 2) = " 0" : i += 2
      CASE ASC("B"), ASC("b") : MID(T, i + 1, 2) = "0b" : i += 2
      END SELECT
    END IF
  NEXT
END SUB


/'* \brief Transform a FB type in to a ctype
\param P The parser calling this emitter
\returns A string containing the type

This function transforms a FB type in to the ctypes equivalent in case
of a standard type. Otherwise the original type symbol gets returned.
Pointers get enclosed by `POINTER(...)`, but `ZSTRING PTR` gets
transformed to `c_char_p`.

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


/'* \brief Emitter to extract the types of a parameter list
\param P The parser calling this emitter

This emitter collects the types of the parameter list in global
variable `T2`, to be used in py_function().

\since 0.4.0
'/
SUB py_entryListPara CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    IF 0 = .TypTok THEN T2 &= ", ???" _
                   ELSE T2 &= ", " & genCType(P)
  END WITH
END SUB

/'* \brief Emitter to generate a line for a ENUM block entry
\param P The parser calling this emitter

This emitter gets called when the parser is in a block (`ENUM`). It
generates a line for each member and stores it (them) in the out
variable.

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
        CASE 0, ASC(!"\n"), ASC(!"\r"), ASC(","), ASC("'") : EXIT DO
        END SELECT : i += 1
      LOOP
      v = MID(.Buf, a, i - a)
      genNLiteral(v)
    ELSE
      ENUM_COUNT += 1
      v = STR(ENUM_COUNT)
    END IF
    ENUM_COUNT = IIF(.IniTok, VALINT(MID(.Buf, .IniTok[1] + 2)), ENUM_COUNT + 1)
    Code(!"\n\ntry:" _
      & !"\n    " & .SubStr(.NamTok) & " =" & v _
      & !"\nexcept:" _
      & !"\n    pass")
  END WITH
END SUB

/'* \brief Emitter to generate a line for a TYPE / UNION block entry
\param P The parser calling this emitter

This emitter gets called when the parser is in a block (`TYPE
UNION`). It generates a line for each member and stores it (them) in
the output variable.

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
    CASE .TOK_DECL
    CASE ELSE : IF 0 = .NamTok THEN EXIT SUB
      IF .TypTok THEN ctype = genCType(P)
      VAR size = ""
      IF .DimTok THEN
        VAR a = .DimTok[1] + 2, i = a
        size = " * ("
        DO
          SELECT CASE AS CONST .Buf[i]
          CASE 0, ASC(!"\n"), ASC(!"\r"), ASC("'") : EXIT DO
          CASE ASC(!")")
            VAR v = TRIM(MID(.Buf, a, i - a + 1), ANY !", \t\v")
            genNLiteral(v)
            IF LEN(size) < 6 THEN size &= v & " + 1" _
                       ELSE size &= "(" & v & " + 1)"
            EXIT DO
          CASE ASC(!",")
            VAR v = TRIM(MID(.Buf, a, i - a + 1), ANY !", \t\v")
            genNLiteral(v)
            size &= "(" & v & " + 1) * " : a = i + 1
          END SELECT : i += 1
        LOOP
        size &= ")"
      END IF
      T0 &=  !"\n    '" & .SubStr(.NamTok) & "',"
      T1 &= !"\n    ('" & .SubStr(.NamTok) & "', " & ctype & size & "),"
    END SELECT
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
        & !"\n        " & sym & ".restype = ReturnString" _
        & !"\n    else:" _
        & !"\n        " & sym & ".restype = String" _
        & !"\n        " & sym & ".errcheck = ReturnString"
      END IF
    ELSE
      typ = sym & ".restype = None"
    END IF
    T2 = ""
    IF .ParTok THEN .parseListPara(@py_entryListPara())

    NEW_ENTRY
    Code(!"\n\nif hasattr(_libs['" & LIBRARY & "'], '" & sym & "'):" _
         & !"\n    " & sym & " = _libs['" & LIBRARY & "']." & sym _
         & !"\n    " & sym & ".argtypes = [" & MID(T2, 3) & "]" _
         & !"\n    " & typ)
  END WITH
END SUB


/'* \brief Emitter called when the Parser is at a variable declaration
\param P The parser calling this emitter

FIXME

\since 0.4.0
'/
SUB py_declare CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    IF .FunTok THEN py_function(P) : EXIT SUB

    NEW_ENTRY
    VAR n = genCType(P)
    IF n <> .SubStr(.TypTok) THEN Code(!"\n\n" & .SubStr(.NamTok) & " = " & n) : EXIT SUB
    CLASSES &= n & !"\n"
    Code(!"\n\nclass = struct_" & n & "(Structure):" _
         & !"\n    pass")
  END WITH
END SUB


/'* \brief Emitter called when the Parser is at the start of a ENUM block
\param P The parser calling this emitter

FIXME

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

FIXME

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

FIXME

\since 0.4.0
'/
SUB py_class CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    T0 = "struct_" & .BlockNam & ".__slots__ = ["
    T1 = "struct_" & .BlockNam & ".__fields__ = ["
    .parseBlockTyUn(@py_emitBlockNames())
    NEW_ENTRY

    IF 0 = INSTR(CLASSES, !"\n" & .BlockNam & !"\n") THEN
      Code(!"\n\nclass struct_" & .BlockNam & "(Structure):" _
           & !"\n    pass ")
    END IF

    Code(!"\n\n" _
       & T0 & !"\n]" _
       & !"\n\n" _
       & T1 & !"\n]")
  END WITH
END SUB


/'* \brief Emitter called when the Parser is at an #`DEFINE` line or at the start of a #`MACRO`
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

    VAR v = TRIM(MID(.Buf, a, l))
    genNLiteral(v)
    NEW_ENTRY
    Code(!"\n\ntry:" _
         & !"\n    " & .SubStr(.NamTok) & " = " & v _
         & !"\nexcept:" _
         & !"\n    pass")
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


/'* \brief Emitter called after the input got parsed
\param P The parser calling this emitter

FIXME

\since 0.4.0
'/
SUB py_CTOR CDECL(BYVAL P AS Parser PTR)
  Code("# header file auto generated by fb-doc and plugin py_ctypes.bas" & NL & NL)
  Code("_libs[""" & LIBRARY & """] = load_library(""" & LIBRARY & """)")
END SUB


/'* \brief Emitter called after the input got parsed
\param P The parser calling this emitter

FIXME

\since 0.4.0
'/
SUB py_DTOR CDECL(BYVAL P AS Parser PTR)
  Code(NL)
END SUB



/'* \brief Initialize the EmitterIF and evaluate parameters
\param Emi The newly created EmitterIF to fill with our callbacks
\param Par Additional command line parameters, not parsed by \Proj

FIXME

\since 0.4.0
'/
SUB EmitterInit CDECL(BYVAL Emi AS EmitterIF PTR, BYREF Par AS STRING) EXPORT
  WITH *Emi
    .Decl_ = @py_declare()
    .Func_ = @py_function()
    .Enum_ = @py_enum()
    .Unio_ = @py_union()
    .Clas_ = @py_class()
    .Defi_ = @py_define()
    .Incl_ = @py_include()
    .CTOR_ = @py_CTOR()
    .DTOR_ = @py_DTOR()
  END WITH
  VAR a = INSTR(Par, !"\t-pylib=")
  IF a THEN
    a += 8
    VAR e = INSTR(a, Par, !"\t")
    IF 0 = e THEN e = LEN(Par) + 1
    LIBRARY = MID(Par, a,  e - a)
    Par = LEFT(Par, a - 9) & MID(Par, e)
  ELSE
    LIBRARY = "FIXME.so"
  END IF
END SUB
