/'* \file fb-doc_emit_syntax.bas
\brief Emitter for repairing the Doxygen syntax highlighting.

This file contains the emitter for html syntax highlighting. The
emitter is designed to create code listings with high-linghting tags
defined by Doxygen. This emitter reads the original Doxygen output
files and replaces the code section. This works for html, LaTeX and XML
output.

The code includes links to the documentation. These links are extracted
from the original Doxygen output. Since the names in the link tags
change the repairing process can be done only once (ie. the name of the
constructor *Parser::Parser* in intermediate format gets just *Parser*
in FB source).

'/

#INCLUDE ONCE "fb-doc_parser.bi"
#INCLUDE ONCE "fb-doc_emit_syntax.bi"
#INCLUDE ONCE "fb-doc.bi"
#INCLUDE ONCE "fb-doc_options.bi"
#INCLUDE ONCE "fb-doc_version.bi"
#INCLUDE ONCE "fb-doc_doxyfile.bi"


/'* \brief Add a new element pair
\param S The string to search for
\param R The string to replace with
\returns zero on success, otherwise a ZSTRING PTR to an error code

Add a new pair of strings to the container tables. The function checks
if the search string contains illegal characters or if it's already
defined. In this cases nothing happens and an error message gets
returned. Otherwise the search string and its replacement gets stored
in the container.

The search string must not contain characters in the range CHR(0) to
CHR(2).

'/
FUNCTION RepData.add(BYREF S AS STRING, BYREF R AS STRING) AS ZSTRING PTR
  IF S = "" THEN RETURN 0
  IF INSTR(S, ANY !"\000\001\002") THEN RETURN @"undefined char (search)"
  VAR c = CHR(1) & S & CHR(2) : IF INSTR(5, I, c) THEN RETURN @"already defined"
  *CAST(LONG PTR, SADD(I)) += 1 : I &= MID(c, 2) & HEX(LEN(O) + 4) & CHR(1)
  O &= MKl(0) & R & CHR(0) : RETURN 0
END FUNCTION

/'* \brief Search for a string, get its replacement (if any)
\param S The string to search for
\returns A pointer to the replacement (if any)

This function searches for the string given as parameter. If the string
is in the search words, a pointer to it's replacement gets returned.
Otherwise a pointer to the original string gets returned.

The function searches case sensitive.

'/
FUNCTION RepData.rep(BYREF S AS STRING) AS ZSTRING PTR
  VAR a = INSTR(I, CHR(1) & S & CHR(2)) : IF a THEN a += LEN(S) + 2 ELSE RETURN SADD(S)
  VAR e = INSTR(a, I, CHR(1)) + 1
  DIM AS ZSTRING PTR z = SADD(O) + VALINT("&h" & MID(I, a, e - a))
  *CAST(LONG PTR, z - 4) += 1 : RETURN z
END FUNCTION


/'* \brief Replace special characters for HTML output
\param T The Buffer to read from
\param A Start position (zero based)
\param L Length of substring
\returns A string with replaced special characters

The function is used as \ref Highlighter::special_chars() function. It
extracts a substring from the input buffer. Special characters are
replaced by their HTML equivalents.

'/
FUNCTION html_specials(BYVAL T AS UBYTE PTR, BYVAL A AS INTEGER, BYVAL L AS INTEGER) AS STRING
  STATIC AS STRING r
  r = ""
  FOR i AS INTEGER = A TO A + L - 1
    SELECT CASE AS CONST T[i]
    CASE ASC("&")  : r &= "&amp;"
    CASE ASC("<")  : r &= "&lt;"
    CASE ASC(">")  : r &= "&gt;"
    CASE ASC("""") : r &= "&quot;"
    CASE ELSE : r &= CHR(T[i])
    END SELECT
  NEXT
  RETURN r
END FUNCTION

/'* \brief Replace special characters for LaTeX output
\param T The Buffer to read from
\param A Start position (zero based)
\param L Length of substring
\returns A string with replaced special characters

The function is used as \ref Highlighter::special_chars() function. It
extracts a substring from the input buffer. Special characters are
replaced by their LaTeX equivalents.

'/
FUNCTION tex_specials(BYVAL T AS UBYTE PTR, BYVAL A AS INTEGER, BYVAL L AS INTEGER) AS STRING
  STATIC AS STRING r
  r = ""
  FOR i AS INTEGER = A TO A + L - 1
    SELECT CASE AS CONST T[i]
    CASE ASC("\") : r &= "\(\backslash\)"
    CASE ASC("#") : r &= "\#"
    CASE ASC("%") : r &= "\%"
    CASE ASC("_") : r &= "\_"
    CASE ASC("{") : r &= "\{"
    CASE ASC("}") : r &= "\}"
    CASE ELSE : r &= CHR(T[i])
    END SELECT
  NEXT
  RETURN r
END FUNCTION

/'* \brief Replace special characters for XML output
\param T The Buffer to read from
\param A Start position (zero based)
\param L Length of substring
\returns A string with replaced special characters

The function is used as \ref Highlighter::special_chars() function. It
extracts a substring from the input buffer. Special characters are
replaced by their XML equivalents.

'/
FUNCTION xml_specials(BYVAL T AS UBYTE PTR, BYVAL A AS INTEGER, BYVAL L AS INTEGER) AS STRING
  STATIC AS STRING r
  r = ""
  FOR i AS INTEGER = A TO A + L - 1
    SELECT CASE AS CONST T[i]
    CASE ASC("&")  : r &= "&amp;"
    CASE ASC("<")  : r &= "&lt;"
    CASE ASC(">")  : r &= "&gt;"
    CASE ASC("""") : r &= "&quot;"
    CASE ASC("'")  : r &= "&apos;"
    CASE ASC(" ")  : r &= "<sp/>"
    CASE ELSE : r &= CHR(T[i])
    END SELECT
  NEXT
  RETURN r
END FUNCTION


/'* \brief Generate end of line code for HTML output
\param Symb Symbol table for cross-referencing
\param Nr Line number
\returns A string to end the current line and start a new one

The function is used as \ref Highlighter::eol() function. It generates
code to end the current line and start a new one with the next line
number. The number counter gets increased and returned as a BYREF
parameter. Special line numbers are

- 1: the first line (emit no line end but the line start)
- 0: the last line (emit the line end but no line start)

'/
FUNCTION html_eol(BYVAL Symb AS RepData PTR, BYREF Nr AS INTEGER) AS STRING
  IF Nr = 0 THEN RETURN "</div>"
  VAR r = "<div class=""line"">", nstr = RIGHT("    " & Nr, 5)
  IF Symb THEN
    r &= "<a name=""l" & RIGHT("0000" & Nr, 5) & """></a>"
    VAR res = Symb->rep(nstr)
    IF res = SADD(nstr) THEN r &= "<span class=""lineno"">" & nstr _
                        ELSE r &= "<span class=""lineno"">" & *res
  ELSE
    r &= "<span class=""lineno"">" & nstr
  END IF
  Nr += 1
  IF Nr = 2 THEN RETURN r & "</span>&#160;"
  RETURN !"</div>" & NL & r & "</span>&#160;"
END FUNCTION

/'* \brief Generate end of line code for LaTeX output
\param Symb Symbol table for cross-referencing
\param Nr Line number
\returns A string to end the current line and start a new one

The function is used as \ref Highlighter::eol() function. It generates
code to end the current line and start a new one with the next line
number. The number counter gets increased and returned as a BYREF
parameter. Special line no. are

- 1: the first line (emit no line end but the line start)
- 0: the last line (emit the line end but no line start)

'/
FUNCTION tex_eol(BYVAL Symb AS RepData PTR, BYREF Nr AS INTEGER) AS STRING
  IF Nr = 0 THEN RETURN ""
  VAR  r = "" _
  , nstr = RIGHT("0000" & Nr, 5) _
   , res = IIF(Symb, Symb->rep(nstr), SADD(nstr))
  IF res = SADD(nstr) THEN r &= nstr _
                      ELSE r &= *res
  Nr += 1
  IF Nr = 2 THEN RETURN r & " "
  RETURN NL & r & " "
END FUNCTION

/'* \brief Generate end of line code for XML output
\param Symb Symbol table for cross-referencing
\param Nr Line number
\returns A string to end the current line and start a new one

The function is used as \ref Highlighter::eol() function. It generates
code to end the current line and start a new one with the next line
number. The number counter gets increased and returned as a BYREF
parameter. Special line numbers are

- 1: the first line (emit no line end but the line start)
- 0: the last line (emit the line end but no line start)

'/
FUNCTION xml_eol(BYVAL Symb AS RepData PTR, BYREF Nr AS INTEGER) AS STRING
  IF Nr = 0 THEN RETURN "</codeline>"
  VAR  r = "<codeline lineno=""" _
  , nstr = "" & Nr _
   , res = IIF(Symb, Symb->rep(nstr), SADD(nstr))
  IF res = SADD(nstr) THEN r &= nstr &""">" _
                      ELSE r  = *res
  Nr += 1
  IF Nr = 2 THEN RETURN r
  RETURN "</codeline>" & NL & r
END FUNCTION


/'* \brief Constructor executing the complete process
\param P The parser for input

This constructor connects to the parser in use.

'/
CONSTRUCTOR Highlighter(BYVAL P AS Parser PTR)
  Pars = P
  Pars->UserTok = CAST(LONG PTR, @THIS)
END CONSTRUCTOR


/'* \brief Procedure to control the repairing process
\param Fnam The path / file name of the Doxygen configuration file

This SUB controls the complete repairing process

- load and parse Doxyfile for paths and output types
- scan FB directory for file names
- switch to matching emitter parameters
- scan output directories and process files

'/
SUB Highlighter.doDoxy(BYREF Fnam AS STRING)
   Var doxy = NEW Doxyfile(Fnam) _
     , recu = OPT->InRecursiv _
     , tree = OPT->InTree

  MSG_END(PROJ_NAME & " syntax highlighting")
  MSG_LINE("Doxyfile " & Fnam)
  WHILE doxy->Length
    GenHtml = IIF(doxy->Tag(GENERATE_HTML) = "YES" ANDALSO _
                  doxy->Tag(SOURCE_BROWSER) = "YES", 1, 0)
    GenTex  = IIF(doxy->Tag(GENERATE_LATEX) = "YES" ANDALSO _
                  doxy->Tag(LATEX_SOURCE_CODE) = "YES", 1, 0)
    GenXml  = IIF(doxy->Tag(GENERATE_XML) = "YES" ANDALSO _
                  doxy->Tag(XML_PROGRAMLISTING) = "YES", 1, 0)

    IF GenAny THEN MSG_END("parsed") _
              ELSE MSG_END("nothing to do") : EXIT WHILE

    FbPath = doxy->Tag(INPUT_TAG)
    OPT->InRecursiv = IIF(doxy->Tag(RECURSIVE) = "YES", 1, 0)
    MSG_LINE("FB source " & FbPath)
    CHDIR(OPT->StartPath)
    IF CHDIR(FbPath) THEN MSG_END("error (couldn't change directory)") : EXIT WHILE
    FbFiles = NL & OPT->scanFiles("*.bas", "") _
                 & OPT->scanFiles("*.bi", "")
    IF LEN(FbFiles) > 1 THEN MSG_END("scanned") _
                        ELSE MSG_END("error (no FB source files)") : EXIT WHILE
    FbPath = OPT->addPath(OPT->StartPath, FbPath)

    OPT->InTree = 0
    InPath = OPT->addPath(OPT->StartPath, doxy->Tag(OUTPUT_DIRECTORY))
    IF GenHtml THEN
      HtmlPath = OPT->addPath(InPath, doxy->Tag(HTML_OUTPUT))
      HtmlSuff = doxy->Tag(HTML_FILE_EXTENSION)
      IF 0 = LEN(HtmlSuff) THEN HtmlSuff = ".html"
      OPT->InRecursiv = IIF(doxy->Tag(CREATE_SUBDIRS) = "YES", 1, 0)
      CHDIR(OPT->StartPath)
      MSG_LINE("HTML source " & LEFT(HtmlPath, LEN(HtmlPath) - 1))
      IF CHDIR(HtmlPath) THEN
        MSG_END("error (couldn't change directory)")
      ELSE
        DoxyFiles = OPT->scanFiles("*_8bas_source" & HtmlSuff, "") _
                  & OPT->scanFiles("*_8bi_source" & HtmlSuff, "")

        IF LEN(DoxyFiles) > 1 THEN MSG_END("scanned") : do_files() _
                              ELSE MSG_END("scanned (no files)")
      END IF
    END IF
    OPT->InRecursiv = 0
    IF GenTex THEN
      TexPath = OPT->addPath(InPath, doxy->Tag(LATEX_OUTPUT))
      MSG_LINE("LaTeX source " & LEFT(TexPath, LEN(TexPath) - 1))
      CHDIR(OPT->StartPath)
      IF CHDIR(TexPath) THEN
        MSG_END("error (couldn't change directory)")
      ELSE
        DoxyFiles = OPT->scanFiles("*_8bas_source.tex", "") _
                  & OPT->scanFiles("*_8bi_source.tex", "")
        IF LEN(DoxyFiles) > 1 THEN
          MSG_END("scanned")
          FBDOC_MARK = @"%%% Syntax-highlighting by fb-doc %%%"
          KEYW_A = @"\textcolor{keyword}{"
          KWTP_A = @"\textcolor{keywordtype}{"
          KWFL_A = @"\textcolor{keywordflow}{"
          PREP_A = @"\textcolor{preprocessor}{"
          CMNT_A = @"\textcolor{comment}{"
          SPAN_E = @"}"
          QUOT_A = @"\textcolor{stringliteral}{"""
          QUOT_E = @"""}"
          eol = @tex_eol()
          special_chars = @tex_specials()
          prepare = @prepare_tex()
          do_files()
        ELSE
          MSG_END("scanned (no files)")
        END IF
      END IF
    END IF
    IF GenXml THEN
      XmlPath = OPT->addPath(InPath, doxy->Tag(XML_OUTPUT))
      MSG_LINE("XML source " & LEFT(XmlPath, LEN(XmlPath) - 1))
      CHDIR(OPT->StartPath)
      IF CHDIR(XmlPath) THEN
        MSG_END("error (couldn't change directory)")
      ELSE
        DoxyFiles = OPT->scanFiles("*_8bas.xml", "") _
                  & OPT->scanFiles("*_8bi.xml", "")
        IF LEN(DoxyFiles) > 1 THEN
          MSG_END("scanned")
          FBDOC_MARK = @"<!-- Syntax-highlighting by fb-doc -->"
          KEYW_A = @"<highlight class=""keyword"">"
          KWTP_A = @"<highlight class=""keywordtype"">"
          KWFL_A = @"<highlight class=""keywordflow"">"
          PREP_A = @"<highlight class=""preprocessor"">"
          CMNT_A = @"<highlight class=""comment"">"
          SPAN_E = @"</highlight>"
          QUOT_A = @"<highlight class=""stringliteral"">"""
          QUOT_E = @"""</highlight>"
          eol = @xml_eol()
          special_chars = @xml_specials()
          prepare = @prepare_xml()
          do_files()
        ELSE
          MSG_END("scanned (no files)")
        END IF
      END IF
    END IF
    EXIT WHILE
  WEND
  DELETE doxy
  OPT->InTree = tree
  OPT->InRecursiv = recu
  CHDIR(OPT->StartPath)
END SUB


/'* \brief Operate on all files

The procedure operates on all file names specified in \ref DoxyFiles. It
opens the input file, generated by Doxygen, writes a new file to copy
the original context to (file start and end) and starts the emitter to
replaces the source code section with advanced syntax highlighting.

Each file can only be fixed once (because the link texts from the
original files are used and they change during the operation).

When done, the original file is killed and replaced by the new file,
which is renamed to the original file name.

'/
SUB Highlighter.do_files()
  VAR a = 1, e = a, l = LEN(DoxyFiles)
  WHILE a < l
    e = INSTR(a + 1, DoxyFiles, !"\n")
    VAR in_fnam = MID(DoxyFiles, a, e - a)
    Symbols = NEW RepData
    MSG_LINE(in_fnam)
    OPT->Ocha = FREEFILE
    IF OPEN(in_fnam & "_" FOR OUTPUT AS OPT->Ocha) THEN
      MSG_END("error (couldn't write)")
    ELSE
      Ifnr = FREEFILE
      IF OPEN(in_fnam FOR INPUT AS Ifnr) THEN
        MSG_END("error (couldn't read)")
        CLOSE #OPT->Ocha
        KILL(in_fnam & "_")
      ELSE
        VAR fb_nam = prepare(@THIS)
        IF LEN(fb_nam) THEN
          Pars->File_(FbPath & fb_nam, 0)

          PRINT #OPT->Ocha, LastLine
          WHILE NOT EOF(Ifnr)
            LINE INPUT #Ifnr, LastLine
            PRINT #OPT->Ocha, LastLine
          WEND
          CLOSE #Ifnr
          CLOSE #OPT->Ocha
          KILL(in_fnam)
          NAME(in_fnam & "_", in_fnam)
          MSG_END(Pars->ErrMsg)
        ELSE
          CLOSE #Ifnr
          CLOSE #OPT->Ocha
          KILL(in_fnam & "_")
          IF LastLine = *FBDOC_MARK THEN
            MSG_END("error (couldn't operate twice)")
          ELSE
            MSG_END("error (incompatible format)")
          END IF
        END IF
      END IF
    END IF
    DELETE Symbols
    a = e + 1
  WEND
END SUB

/'* \brief Emit source code with syntax highlighting
\param Buf The buffer to read from
\param Stop_ The position to stop at

This procedure parses a source code section, starting at \ref
Parser::SrcBgn up to the given parameter Stop_. It orperates on all
kind of code (strings, comments and normal code). The output gets
written to the \ref Options::Ocha file.

'/
SUB Highlighter.generate_all(BYVAL Buf AS ZSTRING PTR, BYVAL Stop_ AS INTEGER)
  WITH *Pars
    VAR i = .SrcBgn, start = i
    WHILE i <= Stop_
      SELECT CASE AS CONST Buf[i]
      CASE 0 : EXIT WHILE
      CASE ASC(!"\n")
        IF i <= start THEN Code(eol(Symbols, LineNo)) : start = i + 1 : EXIT SELECT
        Code(generate_code(Buf, start, i - start) & eol(Symbols, LineNo))
        start = i + 1
      CASE ASC("""")
        IF i >= start THEN Code(generate_code(Buf, start, i - start))
        start = i
        SCAN_QUOTE(Buf,i)
        Code(*QUOT_A & special_chars(Buf, start + 1, i - start - 1) & *QUOT_E)
        start = i + 1
      CASE ASC("'")
        IF i >= start THEN Code(generate_code(Buf, start, i - start))
        start = i
        SCAN_SL_COMM(Buf,i)
        IF Buf[start + 1] <> OPT->JoComm ORELSE OPT->Docom THEN _
          Code(*CMNT_A & special_chars(Buf, start, i - start) & *SPAN_E)
        start = i
        CONTINUE WHILE
      CASE ASC("/") : IF Buf[i + 1] <> ASC("'") THEN EXIT SELECT
        i += 2
        start = i - 2
        VAR fl = Buf[i] <> OPT->JoComm OR OPT->Docom
        DO
          SELECT CASE AS CONST Buf[i]
          CASE 0 : EXIT DO
          CASE ASC(!"\n")
            IF i <= start THEN
              IF fl THEN Code(eol(Symbols, LineNo)) ELSE LineNo += 1
              start = i + 1 : EXIT SELECT
            END IF
            IF fl THEN Code(*CMNT_A & special_chars(Buf, start, i - start) & *SPAN_E & eol(Symbols, LineNo)) ELSE LineNo += 1
            start = i + 1
          CASE ASC("'")
            SELECT CASE AS CONST Buf[i + 1]
            CASE 0 : EXIT WHILE
            CASE ASC("/") : i += 1 : EXIT DO
            END SELECT
          END SELECT : i += 1
        LOOP

        IF fl THEN Code(*CMNT_A & special_chars(Buf, start, i - start + 1) & *SPAN_E)
        DO
          SELECT CASE AS CONST Buf[i]
          CASE 0 : EXIT WHILE
          CASE ASC(!"\r")
          CASE ASC(!"\n") : IF fl THEN Code(eol(Symbols, LineNo)) ELSE LineNo += 1
          CASE ELSE : EXIT DO
          END SELECT : i += 1
        LOOP : start = i + 1
      END SELECT : i += 1
    WEND : IF .SrcBgn < i THEN .SrcBgn = i
  END WITH
END SUB


/'* \brief Check type of word
\param W The word to check
\returns The type of the word (first byte) & formated word

Check a word in the source context and return its type and a string in
camel-case letters for formating in mixed cases. The first byte of this
string is the word type (1 = keyword, 2 = preprocessor).

'/
FUNCTION Highlighter.word_type(BYREF W AS STRING) AS ZSTRING PTR
  SELECT CASE AS CONST W[0]
    CASE ASC("_")
      SELECT CASE W
        CASE               "__DATE__" : RETURN @!"\004__Date__"
        CASE           "__DATE_ISO__" : RETURN @!"\004__Date_Iso__"
        CASE           "__FB_64BIT__" : RETURN @!"\004__Fb_64Bit__"
        CASE            "__FB_ARGC__" : RETURN @!"\004__Fb_Argc__"
        CASE            "__FB_ARGV__" : RETURN @!"\004__Fb_Argv__"
        CASE         "__FB_BACKEND__" : RETURN @!"\004__Fb_Backend__"
        CASE       "__FB_BIGENDIAN__" : RETURN @!"\004__Fb_Bigendian__"
        CASE      "__FB_BUILD_DATE__" : RETURN @!"\004__Fb_Build_Date__"
        CASE          "__FB_CYGWIN__" : RETURN @!"\004__Fb_Cygwin__"
        CASE          "__FB_DARWIN__" : RETURN @!"\004__Fb_Darwin__"
        CASE           "__FB_DEBUG__" : RETURN @!"\004__Fb_Debug__"
        CASE             "__FB_DOS__" : RETURN @!"\004__Fb_Dos__"
        CASE             "__FB_ERR__" : RETURN @!"\004__Fb_Err__"
        CASE          "__FB_FPMODE__" : RETURN @!"\004__Fb_Fpmode__"
        CASE             "__FB_FPU__" : RETURN @!"\004__Fb_Fpu__"
        CASE         "__FB_FREEBSD__" : RETURN @!"\004__Fb_Freebsd__"
        CASE            "__FB_LANG__" : RETURN @!"\004__Fb_Lang__"
        CASE           "__FB_LINUX__" : RETURN @!"\004__Fb_Linux__"
        CASE            "__FB_MAIN__" : RETURN @!"\004__Fb_Main__"
        CASE     "__FB_MIN_VERSION__" : RETURN @!"\004__Fb_Min_Version__"
        CASE              "__FB_MT__" : RETURN @!"\004__Fb_Mt__"
        CASE          "__FB_NETBSD__" : RETURN @!"\004__Fb_Netbsd__"
        CASE         "__FB_OPENBSD__" : RETURN @!"\004__Fb_Openbsd__"
        CASE    "__FB_OPTION_BYVAL__" : RETURN @!"\004__Fb_Option_Byval__"
        CASE  "__FB_OPTION_DYNAMIC__" : RETURN @!"\004__Fb_Option_Dynamic__"
        CASE   "__FB_OPTION_ESCAPE__" : RETURN @!"\004__Fb_Option_Escape__"
        CASE "__FB_OPTION_EXPLICIT__" : RETURN @!"\004__Fb_Option_Explicit__"
        CASE    "__FB_OPTION_GOSUB__" : RETURN @!"\004__Fb_Option_Gosub__"
        CASE  "__FB_OPTION_PRIVATE__" : RETURN @!"\004__Fb_Option_Private__"
        CASE         "__FB_OUT_DLL__" : RETURN @!"\004__Fb_Out_Dll__"
        CASE         "__FB_OUT_EXE__" : RETURN @!"\004__Fb_Out_Exe__"
        CASE         "__FB_OUT_LIB__" : RETURN @!"\004__Fb_Out_Lib__"
        CASE         "__FB_OUT_OBJ__" : RETURN @!"\004__Fb_Out_Obj__"
        CASE            "__FB_PCOS__" : RETURN @!"\004__Fb_Pcos__"
        CASE       "__FB_SIGNATURE__" : RETURN @!"\004__Fb_Signature__"
        CASE             "__FB_SSE__" : RETURN @!"\004__Fb_Sse__"
        CASE            "__FB_UNIX__" : RETURN @!"\004__Fb_Unix__"
        CASE       "__FB_VECTORIZE__" : RETURN @!"\004__Fb_Vectorize__"
        CASE       "__FB_VER_MAJOR__" : RETURN @!"\004__Fb_Ver_Major__"
        CASE       "__FB_VER_MINOR__" : RETURN @!"\004__Fb_Ver_Minor__"
        CASE       "__FB_VER_PATCH__" : RETURN @!"\004__Fb_Ver_Patch__"
        CASE         "__FB_VERSION__" : RETURN @!"\004__Fb_Version__"
        CASE           "__FB_WIN32__" : RETURN @!"\004__Fb_Win32__"
        CASE            "__FB_XBOX__" : RETURN @!"\004__Fb_Xbox__"
        CASE               "__FILE__" : RETURN @!"\004__File__"
        CASE            "__FILE_NQ__" : RETURN @!"\004__File_Nq__"
        CASE           "__FUNCTION__" : RETURN @!"\004__Function__"
        CASE        "__FUNCTION_NQ__" : RETURN @!"\004__Function_Nq__"
        CASE               "__LINE__" : RETURN @!"\004__Line__"
        CASE               "__PATH__" : RETURN @!"\004__Path__"
        CASE               "__TIME__" : RETURN @!"\004__Time__"
      END SELECT
    CASE ASC("#")
      SELECT CASE W
        CASE   "#ASSERT" : RETURN @!"\004#Assert"
        CASE      "#DEF" : RETURN @!"\004#Def"
        CASE   "#DEFINE" : RETURN @!"\004#Define"
        CASE     "#ELSE" : RETURN @!"\004#Else"
        CASE   "#ELSEIF" : RETURN @!"\004#ElseIf"
        CASE    "#ENDIF" : RETURN @!"\004#EndIf"
        CASE "#ENDMACRO" : RETURN @!"\004#EndMacro"
        CASE    "#ERROR" : RETURN @!"\004#Error"
        CASE       "#IF" : RETURN @!"\004#If"
        CASE    "#IFDEF" : RETURN @!"\004#IfDef"
        CASE   "#IFNDEF" : RETURN @!"\004#IfNDef"
        CASE  "#INCLUDE" : RETURN @!"\004#Include"
        CASE   "#INCLIB" : RETURN @!"\004#IncLib"
        CASE     "#LANG" : RETURN @!"\004#Lang"
        CASE  "#LIBPATH" : RETURN @!"\004#LibPath"
        CASE     "#LINE" : RETURN @!"\004#Line"
        CASE    "#MACRO" : RETURN @!"\004#Macro"
        CASE   "#PRAGMA" : RETURN @!"\004#Pragma"
        CASE    "#PRINT" : RETURN @!"\004#Print"
        CASE    "#UNDEF" : RETURN @!"\004#UnDef"
      END SELECT
    'CASE ASC("$") ' I don't wonna test this old stuff
      'SELECT CASE W
        'CASE "$INCLUDE" : RETURN @!"\004$Include"
        'CASE "$DYNAMIC" : RETURN @!"\004$Dynamic"
        'CASE    "$LANG" : RETURN @!"\004$Lang"
        'CASE  "$STATIC" : RETURN @!"\004$Static"
      'END SELECT
    CASE ASC("A")
      SELECT CASE W
        CASE        "ABS" : RETURN @!"\001Abs"
        CASE   "ABSTRACT" : RETURN @!"\001Abstract"
        CASE     "ACCESS" : RETURN @!"\001Access"
        CASE       "ACOS" : RETURN @!"\001Acos"
        CASE        "ADD" : RETURN @!"\001Add"
        CASE      "ALIAS" : RETURN @!"\001Alias"
        CASE   "ALLOCATE" : RETURN @!"\001Allocate"
        CASE      "ALPHA" : RETURN @!"\001Alpha"
        CASE        "AND" : RETURN @!"\001And"
        CASE    "ANDALSO" : RETURN @!"\001AndAlso"
        CASE        "ANY" : RETURN @!"\001Any"
        CASE     "APPEND" : RETURN @!"\001Append"
        CASE         "AS" : RETURN @!"\002As"
        CASE        "ASC" : RETURN @!"\001Asc"
        CASE       "ASIN" : RETURN @!"\001Asin"
        CASE        "ASM" : RETURN @!"\001Asm"
        CASE     "ASSERT" : RETURN @!"\001Assert"
        CASE "ASSERTWARN" : RETURN @!"\001Assertwarn"
        CASE      "ATAN2" : RETURN @!"\001Atan2"
        CASE        "ATN" : RETURN @!"\001Atn"
      END SELECT
    CASE ASC("B")
      SELECT CASE W
        CASE     "BASE" : RETURN @!"\001Base"
        CASE     "BEEP" : RETURN @!"\001Beep"
        CASE      "BIN" : RETURN @!"\001Bin"
        CASE   "BINARY" : RETURN @!"\001Binary"
        CASE      "BIT" : RETURN @!"\001Bit"
        CASE "BITRESET" : RETURN @!"\001BitReset"
        CASE   "BITSET" : RETURN @!"\001BitSet"
        CASE    "BLOAD" : RETURN @!"\001Bload"
        CASE    "BSAVE" : RETURN @!"\001BSave"
        CASE     "BYTE" : RETURN @!"\002Byte"
        CASE    "BYREF" : RETURN @!"\002ByRef"
        CASE    "BYVAL" : RETURN @!"\002ByVal"
      END SELECT
    CASE ASC("C")
      SELECT CASE W
        CASE          "CALL" : RETURN @!"\001Call"
        CASE     "CALLOCATE" : RETURN @!"\001CAllocate"
        CASE         "CALLS" : RETURN @!"\001Calls"
        CASE          "CASE" : RETURN @!"\001Case"
        CASE          "CAST" : RETURN @!"\001Cast"
        CASE         "CBYTE" : RETURN @!"\001CByte"
        CASE          "CDBL" : RETURN @!"\001CDbl"
        CASE         "CDECL" : RETURN @!"\001Cdecl"
        CASE         "CHAIN" : RETURN @!"\001Chain"
        CASE         "CHDIR" : RETURN @!"\001ChDir"
        CASE           "CHR" : RETURN @!"\001Chr"
        CASE          "CINT" : RETURN @!"\001CInt"
        CASE        "CIRCLE" : RETURN @!"\001Circle"
        CASE         "CLASS" : RETURN @!"\001Class"
        CASE         "CLEAR" : RETURN @!"\001Clear"
        CASE          "CLNG" : RETURN @!"\001CLng"
        CASE       "CLNGINT" : RETURN @!"\001CLngInt"
        CASE         "CLOSE" : RETURN @!"\001Close"
        CASE           "CLS" : RETURN @!"\001Cls"
        CASE         "COLOR" : RETURN @!"\001Color"
        CASE           "COM" : RETURN @!"\001Com"
        CASE       "COMMAND" : RETURN @!"\001Command"
        CASE        "COMMON" : RETURN @!"\002Common"
        CASE "CONDBROADCAST" : RETURN @!"\001CondBroadcast"
        CASE    "CONDCREATE" : RETURN @!"\001CondCreate"
        CASE   "CONDDESTROY" : RETURN @!"\001CondDestroy"
        CASE    "CONDSIGNAL" : RETURN @!"\001CondSignal"
        CASE      "CONDWAIT" : RETURN @!"\001CondWait"
        CASE          "CONS" : RETURN @!"\001Cons"
        CASE         "CONST" : RETURN @!"\002Const"
        CASE   "CONSTRUCTOR" : RETURN @!"\001Constructor"
        CASE      "CONTINUE" : RETURN @!"\001Continue"
        CASE           "COS" : RETURN @!"\001Cos"
        CASE          "CPTR" : RETURN @!"\001CPtr"
        CASE        "CSHORT" : RETURN @!"\001CShort"
        CASE         "CSIGN" : RETURN @!"\001DSign"
        CASE          "CSNG" : RETURN @!"\001CSng"
        CASE        "CSRLIN" : RETURN @!"\001CsrLin"
        CASE        "CUBYTE" : RETURN @!"\001CUbyte"
        CASE         "CUINT" : RETURN @!"\001CUInt"
        CASE         "CULNG" : RETURN @!"\001CULng"
        CASE      "CULNGINT" : RETURN @!"\001CULngInt"
        CASE         "CUSNG" : RETURN @!"\001CUSng"
        CASE        "CURDIR" : RETURN @!"\001Curdir"
        CASE       "CUSHORT" : RETURN @!"\001CUShort"
        CASE        "CUSTOM" : RETURN @!"\001Custom"
        CASE           "CVD" : RETURN @!"\001Cvd"
        CASE           "CVI" : RETURN @!"\001Cvi"
        CASE           "CVL" : RETURN @!"\001CVL"
        CASE     "CVLONGINT" : RETURN @!"\001CVLongInt"
        CASE           "CVS" : RETURN @!"\001Cvs"
        CASE       "CVSHORT" : RETURN @!"\001CVShort"
      END SELECT
    CASE ASC("D")
      SELECT CASE W
        CASE        "DATA" : RETURN @!"\001Data"
        CASE        "DATE" : RETURN @!"\001Date"
        CASE     "DATEADD" : RETURN @!"\001DateAdd"
        CASE    "DATEDIFF" : RETURN @!"\001DateDiff"
        CASE    "DATEPART" : RETURN @!"\001DatePart"
        CASE  "DATESERIAL" : RETURN @!"\001DateSerial"
        CASE   "DATEVALUE" : RETURN @!"\001DateValue"
        CASE         "DAY" : RETURN @!"\001Day"
        CASE  "DEALLOCATE" : RETURN @!"\001DeAllocate"
        CASE     "DECLARE" : RETURN @!"\001Declare"
        CASE     "DEFBYTE" : RETURN @!"\001DefByte"
        CASE      "DEFDBL" : RETURN @!"\001DefDbl"
        CASE     "DEFINED" : RETURN @!"\004Defined"
        CASE      "DEFINT" : RETURN @!"\001DefInt"
        CASE      "DEFLNG" : RETURN @!"\001DefLng"
        CASE  "DEFLONGINT" : RETURN @!"\001DefLongInt"
        CASE    "DEFSHORT" : RETURN @!"\001DefShort"
        CASE      "DEFSNG" : RETURN @!"\001DefSng"
        CASE      "DEFSTR" : RETURN @!"\001DefStr"
        CASE    "DEFUBYTE" : RETURN @!"\001DefUbyte"
        CASE     "DEFUINT" : RETURN @!"\001DefUInt"
        CASE "DEFULONGINT" : RETURN @!"\001DefULongInt"
        CASE   "DEFUSHORT" : RETURN @!"\001DefUShort"
        CASE      "DELETE" : RETURN @!"\001Delete"
        CASE  "DESTRUCTOR" : RETURN @!"\001Destructor"
        CASE         "DIM" : RETURN @!"\002Dim"
        CASE         "DIR" : RETURN @!"\001Dir"
        CASE          "DO" : RETURN @!"\001Do"
        CASE      "DOUBLE" : RETURN @!"\002Double"
        CASE        "DRAW" : RETURN @!"\001Draw"
        CASE   "DYLIBFREE" : RETURN @!"\001DyLibFree"
        CASE   "DYLIBLOAD" : RETURN @!"\001DyLibLoad"
        CASE "DYLIBSYMBOL" : RETURN @!"\001DyLibSymbol"
        CASE     "DYNAMIC" : RETURN @!"\001Dynamic"
      END SELECT
    CASE ASC("E")
      SELECT CASE W
        CASE     "ELSE" : RETURN @!"\001Else"
        CASE   "ELSEIF" : RETURN @!"\001ElseIf"
        CASE "ENCODING" : RETURN @!"\001Encoding"
        CASE      "END" : RETURN @!"\001End"
        CASE    "ENDIF" : RETURN @!"\001EndIf"
        CASE     "ENUM" : RETURN @!"\001Enum"
        CASE  "ENVIRON" : RETURN @!"\001Environ"
        CASE      "EOF" : RETURN @!"\001Eof"
        CASE      "EQV" : RETURN @!"\001Eqv"
        CASE    "ERASE" : RETURN @!"\001Erase"
        CASE     "ERFN" : RETURN @!"\001Erfn"
        CASE      "ERL" : RETURN @!"\001Erl"
        CASE     "ERMN" : RETURN @!"\001Ermn"
        CASE      "ERR" : RETURN @!"\001Err"
        CASE    "ERROR" : RETURN @!"\001Error"
        CASE   "ESCAPE" : RETURN @!"\001Escape"
        CASE     "EXEC" : RETURN @!"\001Exec"
        CASE  "EXEPATH" : RETURN @!"\001ExePath"
        CASE "EXPLICIT" : RETURN @!"\001Explicit"
        CASE     "EXIT" : RETURN @!"\001Exit"
        CASE      "EXP" : RETURN @!"\001Exp"
        CASE   "EXPORT" : RETURN @!"\001Export"
        CASE  "EXTENDS" : RETURN @!"\001Extends"
        CASE   "EXTERN" : RETURN @!"\002Extern"
        CASE   "ESCAPE" : RETURN @!"\001Escape"
        CASE "EXPLICIT" : RETURN @!"\001Explicit"
      END SELECT
    CASE ASC("F")
      SELECT CASE W
        CASE        "FIELD" : RETURN @!"\001Field"
        CASE     "FILEATTR" : RETURN @!"\001FileAttr"
        CASE     "FILECOPY" : RETURN @!"\001FileCopy"
        CASE "FILEDATETIME" : RETURN @!"\001FileDateTime"
        CASE   "FILEEXISTS" : RETURN @!"\001FileExists"
        CASE      "FILELEN" : RETURN @!"\001FileLen"
        CASE          "FIX" : RETURN @!"\001Fix"
        CASE         "FLIP" : RETURN @!"\001Flip"
        CASE          "FOR" : RETURN @!"\001For"
        CASE       "FORMAT" : RETURN @!"\001Format"
        CASE         "FRAC" : RETURN @!"\001Frac"
        CASE          "FRE" : RETURN @!"\001Fre"
        CASE     "FREEFILE" : RETURN @!"\001FreeFile"
        CASE     "FUNCTION" : RETURN @!"\001Function"
      END SELECT
    CASE ASC("G")
      SELECT CASE W
        CASE         "GET" : RETURN @!"\001Get"
        CASE "GETJOYSTICK" : RETURN @!"\001GetJoyStick"
        CASE      "GETKEY" : RETURN @!"\001GetKey"
        CASE    "GETMOUSE" : RETURN @!"\001GetMouse"
        CASE       "GOSUB" : RETURN @!"\001GoSub"
        CASE        "GOTO" : RETURN @!"\001Goto"
      END SELECT
    CASE ASC("H")
      SELECT CASE W
        CASE    "HEX" : RETURN @!"\001Hex"
        CASE "HIBYTE" : RETURN @!"\001HiByte"
        CASE "HIWORD" : RETURN @!"\001HiWord"
        CASE   "HOUR" : RETURN @!"\001Hour"
      END SELECT
    CASE ASC("I")
      SELECT CASE W
        CASE              "IF" : RETURN @!"\001If"
        CASE             "IIF" : RETURN @!"\001IIf"
        CASE "IMAGECONVERTROW" : RETURN @!"\001ImageConvertRow"
        CASE     "IMAGECREATE" : RETURN @!"\001ImageCreate"
        CASE    "IMAGEDESTROY" : RETURN @!"\001ImageDestroy"
        CASE       "IMAGEINFO" : RETURN @!"\001ImageInfo"
        CASE             "IMP" : RETURN @!"\001Imp"
        CASE      "IMPLEMENTS" : RETURN @!"\001Implements"
        CASE          "IMPORT" : RETURN @!"\001Import"
        CASE           "INKEY" : RETURN @!"\001InKey"
        CASE             "INP" : RETURN @!"\001Inp"
        CASE           "INPUT" : RETURN @!"\001Input"
        CASE           "INSTR" : RETURN @!"\001Instr"
        CASE        "INSTRREV" : RETURN @!"\001InstrRev"
        CASE             "INT" : RETURN @!"\001Int"
        CASE         "INTEGER" : RETURN @!"\002Integer"
        CASE              "IS" : RETURN @!"\001Is"
        CASE          "ISDATE" : RETURN @!"\001IsDate"
        CASE    "ISREDIRECTED" : RETURN @!"\001IsRedirected"
      END SELECT
    CASE ASC("K")
      SELECT CASE W
        CASE "KILL" : RETURN @!"\001Kill"
      END SELECT
    CASE ASC("L")
      SELECT CASE W
        CASE  "LBOUND" : RETURN @!"\001LBound"
        CASE   "LCASE" : RETURN @!"\001LCase"
        CASE    "LEFT" : RETURN @!"\001Left"
        CASE     "LEN" : RETURN @!"\001Len"
        CASE     "LET" : RETURN @!"\001Let"
        CASE     "LIB" : RETURN @!"\001Lib"
        CASE    "LINE" : RETURN @!"\001Line"
        CASE  "LOBYTE" : RETURN @!"\001LoByte"
        CASE     "LOC" : RETURN @!"\001Loc"
        CASE   "LOCAL" : RETURN @!"\001Local"
        CASE  "LOCATE" : RETURN @!"\001Locate"
        CASE    "LOCK" : RETURN @!"\001Lock"
        CASE     "LOF" : RETURN @!"\001Lof"
        CASE     "LOG" : RETURN @!"\001Log"
        CASE    "LONG" : RETURN @!"\002Long"
        CASE "LONGINT" : RETURN @!"\002LongInt"
        CASE    "LOOP" : RETURN @!"\001Loop"
        CASE  "LOWORD" : RETURN @!"\001LoWord"
        CASE    "LPOS" : RETURN @!"\001LPos"
        CASE  "LPRINT" : RETURN @!"\001LPrint"
        CASE     "LPT" : RETURN @!"\001Lpt"
        CASE    "LSET" : RETURN @!"\001LSet"
        CASE   "LTRIM" : RETURN @!"\001LTrim"
      END SELECT
    CASE ASC("M")
      SELECT CASE W
        CASE          "MID" : RETURN @!"\001Mid"
        CASE       "MINUTE" : RETURN @!"\001Minute"
        CASE          "MKD" : RETURN @!"\001MKD"
        CASE        "MKDIR" : RETURN @!"\001MkDir"
        CASE          "MKI" : RETURN @!"\001MKi"
        CASE          "MKL" : RETURN @!"\001MKl"
        CASE    "MKLONGINT" : RETURN @!"\001MKLongInt"
        CASE          "MKS" : RETURN @!"\001MKs"
        CASE      "MKSHORT" : RETURN @!"\001MKShort"
        CASE          "MOD" : RETURN @!"\001Mod"
        CASE        "MONTH" : RETURN @!"\001Month"
        CASE    "MONTHNAME" : RETURN @!"\001MonthName"
        CASE     "MULTIKEY" : RETURN @!"\001MultiKey"
        CASE  "MUTEXCREATE" : RETURN @!"\001MutexCreate"
        CASE "MUTEXDESTROY" : RETURN @!"\001MutexDestroy"
        CASE    "MUTEXLOCK" : RETURN @!"\001MutexLock"
        CASE  "MUTEXUNLOCK" : RETURN @!"\001MutexUnlock"
      END SELECT
    CASE ASC("N")
      SELECT CASE W
        CASE     "NAKED" : RETURN @!"\001Naked"
        CASE      "NAME" : RETURN @!"\001Name"
        CASE "NAMESPACE" : RETURN @!"\001Namespace"
        CASE       "NEW" : RETURN @!"\001New"
        CASE      "NEXT" : RETURN @!"\001Next"
        CASE       "NOT" : RETURN @!"\001Not"
        CASE       "NOW" : RETURN @!"\001Now"
        CASE   "NOGOSUB" : RETURN @!"\001NoGoSub"
        CASE "NOKEYWORD" : RETURN @!"\001NoKeyWord"
      END SELECT
    CASE ASC("O")
      SELECT CASE W
        CASE   "OBJECT" : RETURN @!"\001Object"
        CASE      "OCT" : RETURN @!"\001Oct"
        CASE "OFFSETOF" : RETURN @!"\001OffsetOf"
        CASE       "ON" : RETURN @!"\001On"
        CASE     "ONCE" : RETURN @!"\004Once"
        CASE     "OPEN" : RETURN @!"\001Open"
        CASE "OPERATOR" : RETURN @!"\001Operator"
        CASE   "OPTION" : RETURN @!"\001Option"
        CASE       "OR" : RETURN @!"\001Or"
        CASE   "ORELSE" : RETURN @!"\001OrElse"
        CASE      "OUT" : RETURN @!"\001Out"
        CASE   "OUTPUT" : RETURN @!"\001Output"
        CASE "OVERLOAD" : RETURN @!"\001Overload"
        CASE "OVERRIDE" : RETURN @!"\001Override"
        CASE   "OPTION" : RETURN @!"\001Option"
      END SELECT
    CASE ASC("P")
      SELECT CASE W
        CASE     "PAINT" : RETURN @!"\001Paint"
        CASE   "PALETTE" : RETURN @!"\001Palette"
        CASE    "PASCAL" : RETURN @!"\001Pascal"
        CASE     "PCOPY" : RETURN @!"\001PCopy"
        CASE      "PEEK" : RETURN @!"\001Peek"
        CASE      "PIPE" : RETURN @!"\001Pipe"
        CASE      "PMAP" : RETURN @!"\001Pmap"
        CASE     "POINT" : RETURN @!"\001Point"
        CASE   "POINTER" : RETURN @!"\001Pointer"
        CASE      "POKE" : RETURN @!"\001Poke"
        CASE       "POS" : RETURN @!"\001Pos"
        CASE       "POP" : RETURN @!"\001Pop"
        CASE  "PRESERVE" : RETURN @!"\001Preserve"
        CASE    "PRESET" : RETURN @!"\001Preset"
        CASE     "PRINT" : RETURN @!"\001Print"
        CASE   "PRIVATE" : RETURN @!"\001Private"
        CASE   "PROCPTR" : RETURN @!"\001ProcPtr"
        CASE  "PROPERTY" : RETURN @!"\001Property"
        CASE "PROTECTED" : RETURN @!"\001Protected"
        CASE      "PSET" : RETURN @!"\001PSet"
        CASE       "PTR" : RETURN @!"\002Ptr"
        CASE    "PUBLIC" : RETURN @!"\001Public"
        CASE       "PUT" : RETURN @!"\001Put"
        CASE      "PUSH" : RETURN @!"\001Push"
      END SELECT
    CASE ASC("R")
      SELECT CASE W
        CASE     "RANDOM" : RETURN @!"\001Random"
        CASE  "RANDOMIZE" : RETURN @!"\001Randomize"
        CASE       "READ" : RETURN @!"\001Read"
        CASE "REALLOCATE" : RETURN @!"\001ReAllocate"
        CASE      "REDIM" : RETURN @!"\001ReDim"
        CASE        "REM" : RETURN @!"\001Rem"
        CASE      "RESET" : RETURN @!"\001Reset"
        CASE    "RESTORE" : RETURN @!"\001Restore"
        CASE     "RESUME" : RETURN @!"\001Resume"
        CASE     "RETURN" : RETURN @!"\001Return"
        CASE        "RGB" : RETURN @!"\001RGB"
        CASE       "RGBA" : RETURN @!"\001RGBA"
        CASE      "RIGHT" : RETURN @!"\001Right"
        CASE      "RMDIR" : RETURN @!"\001RmDir"
        CASE        "RND" : RETURN @!"\001Rnd"
        CASE       "RSET" : RETURN @!"\001RSet"
        CASE      "RTRIM" : RETURN @!"\001RTrim"
        CASE        "RUN" : RETURN @!"\001Run"
      END SELECT
    CASE ASC("S")
      SELECT CASE W
        CASE          "SADD" : RETURN @!"\001SAdd"
        CASE         "SCOPE" : RETURN @!"\001Scope"
        CASE        "SCREEN" : RETURN @!"\001Screen"
        CASE "SCREENCONTROL" : RETURN @!"\001ScreenControl"
        CASE    "SCREENCOPY" : RETURN @!"\001ScreenCopy"
        CASE   "SCREENEVENT" : RETURN @!"\001ScreenEvent"
        CASE  "SCREENGLPROC" : RETURN @!"\001ScreenGlProc"
        CASE    "SCREENINFO" : RETURN @!"\001ScreenInfo"
        CASE    "SCREENLIST" : RETURN @!"\001ScreenList"
        CASE    "SCREENLOCK" : RETURN @!"\001ScreenLock"
        CASE     "SCREENPTR" : RETURN @!"\001ScreenPtr"
        CASE     "SCREENRES" : RETURN @!"\001ScreenRes"
        CASE     "SCREENSET" : RETURN @!"\001ScreenSet"
        CASE    "SCREENSYNC" : RETURN @!"\001ScreenSync"
        CASE  "SCREENUNLOCK" : RETURN @!"\001ScreenUnlock"
        CASE          "SCRN" : RETURN @!"\001Scrn"
        CASE        "SECOND" : RETURN @!"\001Second"
        CASE          "SEEK" : RETURN @!"\001Seek"
        CASE        "SELECT" : RETURN @!"\001Select"
        CASE       "SETDATE" : RETURN @!"\001SetDate"
        CASE    "SETENVIRON" : RETURN @!"\001SetEnviron"
        CASE      "SETMOUSE" : RETURN @!"\001SetMouse"
        CASE       "SETTIME" : RETURN @!"\001SetTime"
        CASE           "SGN" : RETURN @!"\001Sgn"
        CASE        "SHARED" : RETURN @!"\002Shared"
        CASE         "SHELL" : RETURN @!"\001Shell"
        CASE           "SHL" : RETURN @!"\001Shl"
        CASE         "SHORT" : RETURN @!"\002Short"
        CASE           "SHR" : RETURN @!"\001Shr"
        CASE           "SIN" : RETURN @!"\001Sin"
        CASE        "SINGLE" : RETURN @!"\002Single"
        CASE        "SIZEOF" : RETURN @!"\001SizeOf"
        CASE         "SLEEP" : RETURN @!"\001Sleep"
        CASE         "SPACE" : RETURN @!"\001Space"
        CASE           "SPC" : RETURN @!"\001Spc"
        CASE           "SQR" : RETURN @!"\001Sqr"
        CASE        "STATIC" : RETURN @!"\002Static"
        CASE       "STDCALL" : RETURN @!"\001StdCall"
        CASE          "STEP" : RETURN @!"\001Step"
        CASE         "STICK" : RETURN @!"\001Stick"
        CASE          "STOP" : RETURN @!"\001Stop"
        CASE           "STR" : RETURN @!"\001Str"
        CASE         "STRIG" : RETURN @!"\001Strig"
        CASE        "STRING" : RETURN @!"\002String"
        CASE        "STRPTR" : RETURN @!"\001StrPtr"
        CASE           "SUB" : RETURN @!"\001Sub"
        CASE          "SWAP" : RETURN @!"\001Swap"
        CASE        "SYSTEM" : RETURN @!"\001System"
      END SELECT
    CASE ASC("T")
      SELECT CASE W
        CASE          "TAB" : RETURN @!"\001Tab"
        CASE          "TAN" : RETURN @!"\001Tan"
        CASE         "THEN" : RETURN @!"\001Then"
        CASE         "THIS" : RETURN @!"\001This"
        CASE   "THREADCALL" : RETURN @!"\001ThreadCall"
        CASE "THREADCREATE" : RETURN @!"\001ThreadCreate"
        CASE "THREADDETACH" : RETURN @!"\001ThreadDetach"
        CASE   "THREADWAIT" : RETURN @!"\001ThreadWait"
        CASE         "TIME" : RETURN @!"\001Time"
        CASE        "TIMER" : RETURN @!"\001Timer"
        CASE   "TIMESERIAL" : RETURN @!"\001TimeSerial"
        CASE    "TIMEVALUE" : RETURN @!"\001TimeValue"
        CASE           "TO" : RETURN @!"\001To"
        CASE        "TRANS" : RETURN @!"\001Trans"
        CASE         "TRIM" : RETURN @!"\001Trim"
        CASE         "TYPE" : RETURN @!"\001Type"
        CASE       "TYPEOF" : RETURN @!"\004TypeOf"
      END SELECT
    CASE ASC("U")
      SELECT CASE W
        CASE   "UBOUND" : RETURN @!"\001UBound"
        CASE    "UBYTE" : RETURN @!"\002UByte"
        CASE    "UCASE" : RETURN @!"\001UCase"
        CASE "UINTEGER" : RETURN @!"\002UInteger"
        CASE    "ULONG" : RETURN @!"\002ULong"
        CASE "ULONGINT" : RETURN @!"\002ULongInt"
        CASE    "UNION" : RETURN @!"\001Union"
        CASE   "UNLOCK" : RETURN @!"\001Unlock"
        CASE "UNSIGNED" : RETURN @!"\002Unsigned"
        CASE    "UNTIL" : RETURN @!"\001Until"
        CASE   "USHORT" : RETURN @!"\002UShort"
        CASE    "USING" : RETURN @!"\001Using"
      END SELECT
    CASE ASC("V")
      SELECT CASE W
        CASE   "VA_ARG" : RETURN @!"\001Va_Arg"
        CASE "VA_FIRST" : RETURN @!"\001Va_First"
        CASE  "VA_NEXT" : RETURN @!"\001Va_Next"
        CASE      "VAL" : RETURN @!"\001Val"
        CASE    "VAL64" : RETURN @!"\001Val64"
        CASE   "VALINT" : RETURN @!"\001ValInt"
        CASE   "VALLNG" : RETURN @!"\001ValLng"
        CASE  "VALUINT" : RETURN @!"\001ValUInt"
        CASE  "VALULNG" : RETURN @!"\001ValULng"
        CASE      "VAR" : RETURN @!"\002Var"
        CASE   "VARPTR" : RETURN @!"\001VarPtr"
        CASE     "VIEW" : RETURN @!"\001View"
        CASE  "VIRTUAL" : RETURN @!"\001Virtual"
      END SELECT
    CASE ASC("W")
      SELECT CASE W
        CASE        "WAIT" : RETURN @!"\001Wait"
        CASE        "WBIN" : RETURN @!"\001WBin"
        CASE        "WCHR" : RETURN @!"\001WChr"
        CASE     "WEEKDAY" : RETURN @!"\001WeekDay"
        CASE "WEEKDAYNAME" : RETURN @!"\001WeekDayName"
        CASE        "WEND" : RETURN @!"\001Wend"
        CASE        "WHEX" : RETURN @!"\001WHex"
        CASE       "WHILE" : RETURN @!"\001While"
        CASE       "WIDTH" : RETURN @!"\001Width"
        CASE      "WINDOW" : RETURN @!"\001Window"
        CASE "WINDOWTITLE" : RETURN @!"\001WindowTitle"
        CASE      "WINPUT" : RETURN @!"\001WInput"
        CASE        "WITH" : RETURN @!"\001With"
        CASE        "WOCT" : RETURN @!"\001WOct"
        CASE       "WRITE" : RETURN @!"\001Write"
        CASE      "WSPACE" : RETURN @!"\001WSpace"
        CASE        "WSTR" : RETURN @!"\001WStr"
        CASE     "WSTRING" : RETURN @!"\002WString"
      END SELECT
    CASE ASC("X")
      SELECT CASE W
        CASE     "XOR" : RETURN @!"\001Xor"
      END SELECT
    CASE ASC("Y")
      SELECT CASE W
        CASE    "YEAR" : RETURN @!"\001Year"
      END SELECT
    CASE ASC("Z")
      SELECT CASE W
        CASE "ZSTRING" : RETURN @!"\002ZString"
      END SELECT
  END SELECT : RETURN 0
END FUNCTION

/'* \brief check a word in source code

This macro is used for single source reasons. It reads the current word
from the input buffer and checks if it matches

-# an entry in the container \ref Highlighter::Symbols (links red from orig. file),
-# the FB keyword list

The result is in the typ variable:
1. = keyword,
2. = keywordtype,
3. = preprocessor,
4. or greater = link (type gets a ZSTRING PTR to the context)

'/
#MACRO GET_WORD_TYPE()
  VAR word = MID(*T, start + 1, size)
  VAR res = IIF(Symbols, Symbols->rep(word), cast(zstring ptr, SADD(word))) ' !!! CAST is a workaround, to be replaced when fbc types OK again
  IF res = SADD(word) THEN '     no symbol, check keyword & preprocessor
    word = UCASE(word)
    res = word_type(word)
    typ = IIF(res, ASC(*res), FB_CODE)

    SELECT CASE AS CONST OPT->CaseMode '  reformat letter cases, if required
    CASE OPT->CASE_LOWER : MID(*T, start + 1, size) = LCASE(word)
    CASE OPT->CASE_MIXED : MID(*T, start + 1, size) = MID(*res, 2, size)
    CASE OPT->CASE_UPPER : MID(*T, start + 1, size) = word
    END SELECT
  ELSE
    typ = CAST(INTEGER, res) '               start of replacement string
  END IF
#ENDMACRO

/'* \brief highlight normal source code
\param T The input buffer from the parser
\param A The start of the part to operate on (zero based)
\param L The length of the part to operate on
\returns Formated html code for the input context

This function highlights a piece of code. It doesn't handle comments
nor string literals. In normal code it separates keywords,
preprocessors and symbols and encovers the context by the matching
tags. In the result special characters get replaced, like '&' by
'&amp;', '<' by '&lt;', ... (special characters are different in HTML,
LaTeX and XML output).

'/
FUNCTION Highlighter.generate_code(BYVAL T AS ZSTRING PTR, BYVAL A AS INTEGER, BYVAL L AS INTEGER) AS STRING
  VAR size = 0, start = -1, last = -1, typ = last, blcks = ""
  FOR i AS INTEGER = A TO A + L - 1
    SELECT CASE AS CONST T[i]
    CASE ASC("0") TO ASC("9")
      IF size THEN size += 1
    'CASE ASC("$") '                   I don't wonna test this old stuff
      'if size = 0 then
        'size = 1 : start = i
      'else
        'IF last <> FB_CODE THEN blcks &= MKi(FB_CODE) & MKi(i) : last = FB_CODE
      'end if
    CASE ASC("#"), ASC("_"), ASC("A") TO ASC("Z"), ASC("a") TO ASC("z")
      size += 1 : IF size = 1 THEN start = i
    CASE ELSE
      IF size THEN
        GET_WORD_TYPE()
        IF typ <> last THEN blcks &= MKI(typ) & MKI(i - size) : last = typ
        size = 0
      ENDIF

      SELECT CASE AS CONST T[i]
      CASE ASC("?")
        IF last = FB_KEYW THEN EXIT SELECT
        blcks &= MKI(FB_KEYW) & MKI(i) : last = FB_KEYW
      CASE ASC(!"\t"), ASC(!"\v"), ASC(" ") '                 skip these
        IF i > A ANDALSO typ < FB_SYMB THEN EXIT SELECT
        blcks &= MKI(FB_CODE) & MKI(i) : last = FB_CODE
      CASE ELSE
        IF last = FB_CODE THEN EXIT SELECT
        blcks &= MKI(FB_CODE) & MKI(i) : last = FB_CODE
      END SELECT
    END SELECT
  NEXT

  IF size THEN
    GET_WORD_TYPE()
    IF typ <> last THEN blcks &= MKI(typ) & MKI(A + L - size)
  ENDIF
  blcks &= MKI(-1) & MKI(A + L)

  VAR r = "" _
    , p = CAST(INTEGER PTR, SADD(blcks)) _
    , n = (LEN(blcks) \ SIZEOF(INTEGER)) - 3
  FOR i AS INTEGER = 0 TO n STEP 2
    VAR l = p[i + 3] - p[i + 1]
    IF l THEN
      SELECT CASE AS CONST p[i]
      CASE FB_KEYW : r &= *KEYW_A & special_chars(T, p[i + 1], l) & *SPAN_E
      CASE FB_KWTP : r &= *KWTP_A & special_chars(T, p[i + 1], l) & *SPAN_E
      CASE FB_KWFL : r &= *KWFL_A & special_chars(T, p[i + 1], l) & *SPAN_E
      CASE FB_PREP : r &= *PREP_A & special_chars(T, p[i + 1], l) & *SPAN_E
      CASE FB_CODE : r &=           special_chars(T, p[i + 1], l)
      CASE ELSE    : r &= PEEK(ZSTRING, p[i])
      END SELECT
    END IF
  NEXT : RETURN r
END FUNCTION


/'* \brief Search path and name of fb source
\param Nam The name of the source file
\returns The path and the file name of an FB source file (or empty string if not found)

This function prepends the path to a file name for a FB source file.

The original Doxygen output (HTM, TEX or XML) contains the name of the
related source file, but it doesn't contain the path. This function
searches the list of FB source files and returns the path (if any) and
the file name.

\note If there is no such name in the list, an empty string gets returned.

\note If there're multiple matches (several files with identical names
      in different folders), only the first match gets returned.

'/
FUNCTION Highlighter.searchPathNam(BYREF Nam AS STRING) AS STRING
  VAR p = INSTR(FbFiles, Nam)
  WHILE p
    SELECT CASE AS CONST FbFiles[p - 2]
    CASE ASC(NL) :                                            RETURN Nam ' in main folder
    CASE ASC(SLASH)
      VAR pp = INSTRREV(FbFiles, NL, p) + 1
                              RETURN MID(FbFiles, pp, p - pp + LEN(Nam)) ' in subfolder
    END SELECT
    p = INSTR(p + LEN(Nam), FbFiles, Nam)
  WEND :                                                       RETURN "" ' nothing found
END FUNCTION


/'* \brief Prepare a HTML file for syntax repairing
\param Hgh The Highlighter to operate with
\returns The file name of the FB source code

This function prepares a HTML file to replace the syntax highlighting.
It reads the header from the original output and copies the context to
the replacement file. The file name of the original FB source is
extracted from the header. Then the links from the original listing
part are extracted in to the \ref Highlighter::Symbols table.

'/
FUNCTION Highlighter.prepare_html(BYVAL Hgh AS Highlighter PTR) AS STRING
  WITH PEEK(Highlighter, Hgh)
    VAR pa = 0, fb_nam = ""
    WHILE NOT EOF(.Ifnr) '                  search start of code section
      LINE INPUT #.Ifnr, .LastLine
      pa = INSTR(.LastLine, "<div class=""line""><a name=""l00001""") : IF pa THEN EXIT WHILE
      Code(.LastLine & NL)
      pa = INSTR(.LastLine, "<div class=""title"">") ' extract file name
      IF pa THEN
        pa += 19
        VAR pe = INSTR(pa, .LastLine, "</div>")
        fb_nam = .searchPathNam(MID(.LastLine, pa, pe - pa))
        IF 0 = len(fb_nam) THEN RETURN ""
      END IF
    WEND

    IF pa <= 1 THEN .LastLine = *.FBDOC_MARK : RETURN "" '  already done
    Code(LEFT(.LastLine, pa - 1) & NL)
    Code(*.FBDOC_MARK & NL)

    WHILE NOT EOF(.Ifnr) '                              search for links
      pa = INSTR(pa + 1, .LastLine, "<a class=""code""")
      WHILE pa '                        extract all links from this line
        VAR pe = INSTR(pa + 14, .LastLine, "</a>"), pp = INSTRREV(.LastLine, ">", pe - 1) + 1
        VAR word = MID(.LastLine, pp, pe - pp)
        VAR res = .Symbols->add(word, MID(.LastLine, pa, pe - pa + 4))
        pa = INSTR(pa + 1, .LastLine, "<a class=""code""")
      WEND
      LINE INPUT #.Ifnr, .LastLine
      IF LEFT(.LastLine, 6) = "</div>" THEN EXIT WHILE
    WEND
    IF EOF(.Ifnr) THEN RETURN "" ELSE RETURN fb_nam
  END WITH
END FUNCTION

/'* \brief Prepare a LaTeX file for syntax repairing
\param Hgh The Highlighter to operate with
\returns The file name of the FB source code

This function prepares a LaTeX file to replace the syntax highlighting.
It reads the header from the original output and copies the context to
the replacement file. The file name of the odiginal FB source is
extracted from the header. Then the links from the original listing
part are extracted in to the \ref Highlighter::Symbols table.

'/
FUNCTION Highlighter.prepare_tex(BYVAL Hgh AS Highlighter PTR) AS STRING
  WITH PEEK(Highlighter, Hgh)
    LINE INPUT #.Ifnr, .LastLine '    read first line, extract file name
    Code(.LastLine & NL)
    VAR p1 = INSTR(.LastLine, "\section{") _
      , p2 = INSTR(p1 + 10, .LastLine, "}") _
      , fb_nam = ""

    FOR i AS INTEGER = p1 + 8 TO p2 - 2 '         remove LaTeX formating
      IF .LastLine[i] =  ASC("\") THEN
        SELECT CASE AS CONST .LastLine[i + 1]
        CASE ASC("+"), ASC("-"), ASC("/") : i += 1 : CONTINUE FOR
        CASE ASC("_") : CONTINUE FOR
        END SELECT
      END IF
      fb_nam &= CHR(.LastLine[i])
    NEXT
    fb_nam = .searchPathNam(fb_nam) : IF 0 = len(fb_nam) THEN RETURN ""

    WHILE NOT EOF(.Ifnr) '                  search start of code section
      LINE INPUT #.Ifnr, .LastLine
      Code(.LastLine & NL)
      IF .LastLine = "\begin{DoxyCode}" THEN EXIT WHILE
      'IF .LastLine = *.FBDOC_MARK THEN EXIT WHILE
    WEND

    IF EOF(.Ifnr) THEN RETURN ""
    LINE INPUT #.Ifnr, .LastLine : IF .LastLine = *.FBDOC_MARK THEN RETURN ""
    'LINE INPUT #.Ifnr, .LastLine : IF .LastLine = "\begin{DoxyCode}" THEN RETURN ""
    Code(*.FBDOC_MARK & NL)

    DO '                                                search for links
      VAR pa = INSTR(.LastLine, "\hyper")
      IF pa = 1 THEN                              ' link for line number
        pa = INSTR(14, .LastLine, "\hyperlink{")
        var pm = INSTR(pa + 10, .LastLine, "}{") + 2 _
          , pe = INSTR(pm, .LastLine, "}") _
           , t = LEFT(.LastLine, pa - 2) & MID(.LastLine, pm, pe - pm + 1)
        '.Symbols->add(MID(.LastLine, pm, pe - pm), LEFT(.LastLine, pe))
        .Symbols->add(MID(.LastLine, pm, pe - pm), t)
        pa = INSTR(pe + 1, .LastLine, "\hyperlink{")
      END IF
      WHILE pa '                                    links in source code
        VAR pm = INSTR(pa + 11, .LastLine, "}{") + 2 _
          , pe = INSTR(pm, .LastLine, "}") + 1 _
          , word = ""
        FOR i AS INTEGER = pm - 1 TO pe - 3
          IF .LastLine[i] <> ASC("\") THEN word &= CHR(.LastLine[i])
        NEXT
        .Symbols->add(word, MID(.LastLine, pa, pe - pa))
        pa = INSTR(pe, .LastLine, "\hyperlink{")
      WEND
      IF EOF(.Ifnr) THEN RETURN "" ELSE LINE INPUT #.Ifnr, .LastLine
    LOOP UNTIL .LastLine = "\end{DoxyCode}"
  END WITH
  RETURN fb_nam
END FUNCTION

/'* \brief Prepare a XML file for syntax repairing
\param Hgh The Highlighter to operate with
\returns The file name of the FB source code

This function prepares a HTML file to replace the syntax highlighting.
It reads the header from the original output and copies the context to
the replacement file. The file name of the odiginal FB source is
extracted from the header. Then the links from the original listing
part are extracted in to the \ref Highlighter::Symbols table.

'/
FUNCTION Highlighter.prepare_xml(BYVAL Hgh AS Highlighter PTR) AS STRING
  WITH PEEK(Highlighter, Hgh)
    VAR fb_nam = ""
    WHILE NOT EOF(.Ifnr) '                  search start of code section
      LINE INPUT #.Ifnr, .LastLine
      Code(.LastLine & NL)
      IF INSTR(.LastLine, "<programlisting>") THEN EXIT WHILE
      VAR pa = INSTR(.LastLine, "<compoundname>")
      IF pa THEN
        pa += 14
        VAR pe = INSTR(pa, .LastLine, "</compoundname>")
        'fb_nam = MID(.LastLine, pa, pe - pa)
        fb_nam = .searchPathNam(MID(.LastLine, pa, pe - pa)) : IF 0 = len(fb_nam) THEN RETURN ""
      END IF
    WEND

    LINE INPUT #.Ifnr, .LastLine : IF .LastLine = *.FBDOC_MARK THEN RETURN ""
    Code(*.FBDOC_MARK & NL)
    DO
      VAR word = "", pm = INSTR(.LastLine, "refid=""")
      IF pm THEN
        VAR pa = INSTRREV(.LastLine, "<", pm - 1)
        pm = INSTR(pm + 8, .LastLine, ">")
        IF MID(.LastLine, pa, 5) = "<ref " THEN
          VAR pe = INSTR(pm + 1, .LastLine, "</ref>")
          pm += 1
          .Symbols->add(MID(.LastLine, pm, pe - pm), MID(.LastLine, pa, pe - pa + 6))
        ELSE
          VAR pe = pm + 1
          pm = INSTR(pa + 1, .LastLine, "lineno=""") + 8
          .Symbols->add(MID(.LastLine, pm, INSTR(pm + 1, .LastLine, """") - pm), _
                        MID(.LastLine, pa, pe - pa))
        END IF
      END IF
      IF EOF(.Ifnr) THEN RETURN "" ELSE LINE INPUT #.Ifnr, .LastLine
    LOOP UNTIL INSTR(.LastLine, "</programlisting>")
    IF EOF(.Ifnr) THEN RETURN "" ELSE RETURN fb_nam
  END WITH
END FUNCTION


/'* \brief Emitter to be called per file before parsing starts
\param P the parser calling this emitter

This emitter gets called before the parser starts its parsing process.
It initializes the FB source code emission.

'/
SUB synt_init CDECL(BYVAL P AS Parser PTR)
  WITH *P
    IF 0 = .UserTok THEN  ' not in --syntax.mode, create new Highlighter
      VAR x = NEW Highlighter(P)
      IF 0 = OPT->InTree THEN .Po = .Fin '              skip all parsing
      x->LineNo = 1
    END IF
    .SrcBgn = 0
  END WITH
  WITH *CAST(Highlighter PTR, P->UserTok)
    IF .GenAny THEN .LineNo = 1 ELSE .Pars = P
    Code(.eol(.Symbols, .LineNo))
  END WITH
END SUB


/'* \brief Emitter to be called after parsing of a file
\param P the parser calling this emitter

This emitter gets called after the parser ends its parsing process.
It sends the rest of the FB source code to the output stream.

'/
SUB synt_exit CDECL(BYVAL P AS Parser PTR)
  WITH *CAST(Highlighter PTR, P->UserTok)
    .generate_all(SADD(P->Buf), P->Fin)
    'IF OPT->Level > 0 ORELSE OPT->RunMode <> OPT->FILE_MODE THEN EXIT SUB ' we're in #INCLUDE
    IF OPT->Level > 0 THEN EXIT SUB ' we're in #INCLUDE

    Code(.eol(.Symbols, 0) & NL)
    IF 0 = .GenAny THEN DELETE P->UserTok : P->UserTok = 0 ' not in --syntax-mode
  END WITH
END SUB


/'* \brief Emitter to generate an include statement
\param P the parser calling this emitter

This emitter operates on include statements. It extracts the file name
and checks the \ref Highlighter::Symbols table for a matching link. If
there is no link, nothing is done.

In case of a matching link the source code gets emitted up to the link.

File names need special handling because the string literals don't get
checked for linkage.

'/
SUB synt_incl CDECL(BYVAL P AS Parser PTR)
  WITH *CAST(Highlighter PTR, P->UserTok)
    VAR fnam = TRIM(P->SubStr(P->NamTok), """")
    fnam = .special_chars(SADD(fnam), 0, LEN(fnam)) '   LaTeX underscore
    VAR res = IIF(.Symbols, .Symbols->rep(fnam), SADD(fnam))

    IF res = SADD(fnam) THEN
      .generate_all(SADD(P->Buf), P->NamTok[1])
    ELSE
      VAR i = INSTR(*res, fnam) _
        , j = i + LEN(fnam) _
        , a = P->StaTok[1] - 1 _
        , l = P->NamTok[1] - a
      .generate_all(SADD(P->Buf), a)
      Code(.generate_code(SADD(P->Buf), a, l) _
        & *.QUOT_A & LEFT(*res, i - 1) & fnam & MID(*res, j) & *.QUOT_E)
    END IF
    P->SrcBgn = P->NamTok[1] + P->NamTok[2]
  END WITH
END SUB


/'* \brief Emitter to generate a function name
\param P the parser calling this emitter

This emitter operates on SUB / FUNCTION / PROPERTY definitions
(function body, not declaration). It extracts the function name and
checks the \ref Highlighter::Symbols table for a matching link. If
there is no link, nothing is done.

In case of a matching link the source code gets emitted up to the link.

Funktion names need special handling because the names of CONSTRUCTORs
and DESTRUCTORs vary between intermediate format and FB source.

'/
SUB synt_func_ CDECL(BYVAL P AS Parser PTR)
  WITH *CAST(Highlighter PTR, P->UserTok)
    VAR t = P->NamTok, nam = P->SubStr(t)

    SELECT CASE AS CONST *P->FunTok ' create a Doxygen name to search link
    CASE P->TOK_CTOR : t += 3 : IF OPT->Types = OPT->FB_STYLE THEN nam &= "::" & nam
    CASE P->TOK_DTOR : t += 3 : IF OPT->Types = OPT->FB_STYLE THEN nam &= "::~" & nam
    CASE ELSE
      WHILE t < P->EndTok
        t += 3
        SELECT CASE AS CONST *t
        CASE P->TOK_DOT  : IF OPT->Types = OPT->FB_STYLE THEN nam &= "::" ELSE nam &= "."
        CASE P->TOK_WORD : nam &= P->SubStr(t)
        CASE ELSE : EXIT WHILE
        END SELECT
      WEND
    END SELECT
    nam = .special_chars(SADD(nam), 0, LEN(nam)) '      LaTeX underscore
    VAR res = IIF(.Symbols, .Symbols->rep(nam), SADD(nam))
    IF res = SADD(nam) THEN EXIT SUB

    .generate_all(SADD(P->Buf), P->Tk1[1])
    VAR i = INSTR(*res, nam) _
      , j = i + LEN(nam) _
      , a = P->StaTok[1] _
      , l = P->NamTok[1] - a
    P->SrcBgn = *(t - 2) + *(t - 1)
    nam = .special_chars(SADD(P->Buf), a + l, P->SrcBgn - P->NamTok[1]) ' orig. name
    Code(.generate_code(SADD(P->Buf), a, l) _
        & LEFT(*res, i - 1) & nam & MID(*res, j))
  END WITH
END SUB


' place the handlers in the emitter interface
WITH_NEW_EMITTER(EmitterTypes.SYNTAX_REPAIR)
    .Nam = "SyntaxHighLighting"
  .Init_ = @synt_init
  .Exit_ = @synt_exit
  .Incl_ = @synt_incl
  .Func_ = @synt_func_
END WITH
