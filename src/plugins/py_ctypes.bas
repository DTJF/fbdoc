/'* \file py_ctypes.bas
\brief Example code for an external emitter for Python bindings

This file contains example source code for an external emitter. The
emitter outputs Python declarations from the FB headers, in order to
generate Python bindings based on
[ctypes](https://docs.python.org/2/library/ctypes.html#) for libraries
compiled in FB.

'/

#INCLUDE ONCE "../bas/fb-doc_emitters.bi" ' declaration of the emitter interface
#INCLUDE ONCE "../bas/fb-doc_parser.bi"   ' declaration of the Parser members (not used here)


'* Macro to place a comment in to the output (file name and line number)
#DEFINE NEW_ENTRY Code(!"\n\n# " & MID(.Fnam, 23) & ": " & .LineNo)
DIM SHARED AS LONG _
  ENUM_COUNT
DIM SHARED AS STRING _
    T0 _
  , T1 _
  , T2 _
  , CLASSES _
  , LIBRARY
CLASSES = !"\n"
LIBRARY = "libpruio.so"


/'* \brief Procedure to transform number literals
\param T The string to work on

This procedure checks a string for numerical literals and transforms
the FB notation to Python equivalents.

'/
SUB doNLiterals(BYREF T AS STRING)
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


/'* \brief Transform a TB type in to a ctype
\param P The parser calling this emitter
\returns A string containing the type

This function transforms a FB type in to the ctypes equivalent in case
of a standard type. Otherwise the original type symbol gets returned.
Pointers get enclosed by `POINTER(...)`, but `ZSTRING PTR` gets
transformed to `c_char_p`.

'/
FUNCTION doCType(BYVAL P AS Parser PTR) AS STRING
  WITH *P
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

'/
SUB py_entryListPara CDECL(BYVAL P AS Parser PTR)
  WITH *P
    IF 0 = .TypTok THEN T2 &= ", ???" _
                   ELSE T2 &= ", " & doCType(P)
  END WITH
END SUB

/'* \brief Emitter to generate a line for a ENUM block entry
\param P The parser calling this emitter

This emitter gets called when the parser is in a block (`ENUM`). It
generates a line for each member and stores it (them) in the out
variable.

'/
SUB py_emitEnumNames CDECL(BYVAL P AS Parser PTR)
  WITH *P
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
      doNLiterals(v)
    ELSE
      ENUM_COUNT += 1
      v = STR(ENUM_COUNT)
    END IF
    ENUM_COUNT = IIF(.IniTok, VALINT(MID(.Buf, .IniTok[1] + 2)), ENUM_COUNT + 1)
    Code(!"\n\ntry:" _
      & !"\n    " & .SubStr(.NamTok) & " =" & v _
      & !"\nexcept:" _
      & !"\n    pass")
'& py_emitBlockNames(); // pseudo function call (helps Doxygen documenting the interface)
  END WITH
END SUB

/'* \brief Emitter to generate a line for a TYPE / UNION block entry
\param P The parser calling this emitter

This emitter gets called when the parser is in a block (`TYPE
UNION`). It generates a line for each member and stores it (them) in
the output variable.

'/
SUB py_emitBlockNames CDECL(BYVAL P AS Parser PTR)
  STATIC AS STRING ctype
  WITH *P
    SELECT CASE AS CONST *.Tk1
    CASE .TOK_PRIV, .TOK_PROT ': .SrcBgn = 0 ' !!! ToDo: hide private?
    CASE .TOK_PUBL            ': .SrcBgn = 1
    CASE .TOK_CLAS, .TOK_TYPE, .TOK_UNIO
      .parseBlockTyUn(@py_emitBlockNames)
    CASE .TOK_ENUM
      .parseBlockEnum(@py_emitEnumNames)
    CASE .TOK_DECL
    CASE ELSE : IF 0 = .NamTok THEN EXIT SUB
      IF .TypTok THEN ctype = doCType(P)
      VAR size = ""
      IF .DimTok THEN
        VAR a = .DimTok[1] + 2, i = a
        size = " * ("
        DO
          SELECT CASE AS CONST .Buf[i]
          CASE 0, ASC(!"\n"), ASC(!"\r"), ASC("'") : EXIT DO
          CASE ASC(!")")
            VAR v = TRIM(MID(.Buf, a, i - a + 1), ANY !", \t\v")
            doNLiterals(v)
            IF LEN(size) < 6 THEN size &= v & " + 1" _
                       ELSE size &= "(" & v & " + 1)"
            EXIT DO
          CASE ASC(!",")
            VAR v = TRIM(MID(.Buf, a, i - a + 1), ANY !", \t\v")
            doNLiterals(v)
            size &= "(" & v & " + 1) * " : a = i + 1
          END SELECT : i += 1
        LOOP
        size &= ")"
      END IF
      T0 &=  !"\n    '" & .SubStr(.NamTok) & "',"
      T1 &= !"\n    ('" & .SubStr(.NamTok) & "', " & ctype & size & "),"
    END SELECT
'& py_emitBlockNames(); // pseudo function call (helps Doxygen documenting the interface)
  END WITH
END SUB

'* \brief Emitter called when the Parser is on top of a function body
SUB py_function CDECL(BYVAL P AS Parser PTR)
  WITH *P
    VAR nam = .SubStr(IIF(.NamTok[3] = .TOK_DOT, .NamTok + 6, .NamTok)) _
      , typ = ""
    IF .TypTok THEN
      typ = doCType(P)
      IF typ = "c_char_p" THEN
        typ =    "if sizeof(c_int) == sizeof(c_void_p):" _
        & !"\n        " & nam & ".restype = ReturnString" _
        & !"\n    else:" _
        & !"\n        " & nam & ".restype = String" _
        & !"\n        " & nam & ".errcheck = ReturnString"
      END IF
    ELSE
      typ = nam & ".restype = None"
    END IF
    T2 = ""
    IF .ParTok THEN .parseListPara(@py_entryListPara)

    NEW_ENTRY
    Code(!"\n\nif hasattr(_libs['" & LIBRARY & "'], '" & nam & "'):" _
         & !"\n    " & nam & " = _libs['" & LIBRARY & "']." & nam _
         & !"\n    " & nam & ".argtypes = [" & MID(T2, 3) & "]" _
         & !"\n    " & typ)
  END WITH
END SUB

'* \brief Emitter called when the Parser is at a variable declaration
SUB py_declare CDECL(BYVAL P AS Parser PTR)
  WITH *P
    IF .FunTok THEN py_function(P) : EXIT SUB

    NEW_ENTRY
    VAR n = doCType(P)
    IF n <> .SubStr(.TypTok) THEN Code(!"\n\n" & .SubStr(.NamTok) & " = " & n) : EXIT SUB
    CLASSES &= n & !"\n"
    Code(!"\n\nclass = struct_" & n & "(Structure):" _
         & !"\n    pass")
  END WITH
END SUB

'* \brief Emitter called when the Parser is at the start of a ENUM block
SUB py_enum CDECL(BYVAL P AS Parser PTR)
  WITH *P
    NEW_ENTRY
    ENUM_COUNT = -1
    .parseBlockEnum(@py_emitEnumNames)
  END WITH
END SUB

'* \brief Emitter called when the Parser is at the start of a UNION block
SUB py_union CDECL(BYVAL P AS Parser PTR)
  WITH *P
    .parseBlockTyUn(@py_emitBlockNames)
    NEW_ENTRY
  END WITH
END SUB

'* \brief Emitter called when the Parser is at the start of a TYPE block
SUB py_class CDECL(BYVAL P AS Parser PTR)
  WITH *P
    T0 = "struct_" & .BlockNam & ".__slots__ = ["
    T1 = "struct_" & .BlockNam & ".__fields__ = ["
    .parseBlockTyUn(@py_emitBlockNames)
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

'* \brief Emitter called when the Parser is at an \#`DEFINE` line or at the start of a \#`MACRO`
SUB py_define CDECL(BYVAL P AS Parser PTR)
  WITH *P
    IF .ParTok THEN EXIT SUB ' no MACRO or DEFINE with parameter list

    VAR a = .NamTok[1] + .NamTok[2] + 1 _
      , l = .EndTok[1] + .EndTok[2] - a
    IF 0 = l THEN EXIT SUB ' skip empty defines

    VAR v = TRIM(MID(.Buf, a, l))
    doNLiterals(v)
    NEW_ENTRY
    Code(!"\n\ntry:" _
         & !"\n    " & .SubStr(.NamTok) & " = " & v _
         & !"\nexcept:" _
         & !"\n    pass")
  END WITH
END SUB

'* \brief Emitter called when the Parser is at an \#`INCLUDE` line
SUB py_include CDECL(BYVAL P AS Parser PTR)
  WITH *P
    IF .InTree THEN .Include(TRIM(.SubStr(.NamTok), """"))
  END WITH
END SUB

'* \brief Emitter called before the input gets parsed
SUB py_init CDECL(BYVAL P AS Parser PTR)
  Code(NL & __FUNCTION__)
END SUB

'* \brief Emitter called for an error
SUB py_error CDECL(BYVAL P AS Parser PTR)
  Code(NL & __FUNCTION__)
END SUB

'* \brief Emitter called for an empty block in mode `--geany-mode`
SUB py_empty CDECL(BYVAL P AS Parser PTR)
  Code(NL & __FUNCTION__)
END SUB

'* \brief Emitter called after the input got parsed
SUB py_exit CDECL(BYVAL P AS Parser PTR)
  'Code(NL & __FUNCTION__ & NL)
  Code(!"\n\n")
END SUB

'* \brief Emitter called after the input got parsed
SUB py_CTOR CDECL(BYVAL P AS Parser PTR)
  PRINT __FUNCTION__
END SUB

'* \brief Emitter called after the input got parsed
SUB py_DTOR CDECL(BYVAL P AS Parser PTR)
  'PRINT __FUNCTION__
  PRINT
END SUB


' place the handlers in the emitter interface
WITH_NEW_EMITTER(EmitterTypes.EXTERNAL)
    .Nam = "py_ctypes"
  .Decl_ = @py_declare
  .Func_ = @py_function
  .Enum_ = @py_enum
  .Unio_ = @py_union
  .Clas_ = @py_class
  .Defi_ = @py_define
  .Incl_ = @py_include
  '.Init_ = @py_init
 '.Error_ = @py_error
 '.Empty_ = @py_empty
  '.Exit_ = @py_exit
  '.CTOR_ = @py_CTOR
  .DTOR_ = @py_DTOR
END WITH


'* \brief Function called by fb-doc to get the \ref EmitterIF
FUNCTION EmitterInit CDECL() AS EmitterIF PTR EXPORT
  'PRINT __FUNCTION__
  'RETURN Emitters(0)
  RETURN Emitters(EmitterTypes.EXTERNAL)
END FUNCTION

