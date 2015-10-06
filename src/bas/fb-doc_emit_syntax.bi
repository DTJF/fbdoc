/'* \file fb-doc_emit_syntax.bi
\brief Declarations for syntax highlighting emitter.

This file contains the emitter for html syntax highlighting. The
emitter is designed to create code listings with high-linghting tags
defined by Doxygen. This emitter reads the original Doxygen output
files and replaces the code section. This works for html, LaTeX and XML
output.

The code includes links to the documentation. These links are extracted
from the original Doxygen output. Since the names in the link tags
change the repairing process can be done only once (ie the name of the
constructor *Parser::Parser* in intermediate format gets just *Parser*
in FB source).

'/

#INCLUDE ONCE "fb-doc_parser.bi"
#INCLUDE ONCE "fb-doc_version.bi"


/'* \brief A container for string replacements

This class is to store two tables, one of search strings and a second
one of their replacements. It's used to collect the links from the
original source and replace symbol names in the emitter output, as well
as referenced line numbers and \#`INCLUDE` files.

'/
TYPE RepData
  AS STRING _
      O _                 '*< The output (a list of counters and strings)
    , I = MKl(0) & CHR(1) '*< The input (a list of strings to search for)
  DECLARE FUNCTION add(BYREF AS STRING, BYREF AS STRING) AS ZSTRING PTR
  DECLARE FUNCTION rep(BYREF AS STRING) AS ZSTRING PTR
END TYPE

DECLARE FUNCTION html_eol(BYVAL AS RepData PTR, BYREF AS INTEGER) AS STRING
DECLARE FUNCTION html_specials(BYVAL AS UBYTE PTR, BYVAL AS INTEGER, BYVAL AS INTEGER) AS STRING


/'* \brief Class to process the syntax highlighting

The class is used to process the replacement of the Doxygen syntax
highlighting for HTML, LaTeX and XML output. It contains members to

- scan for the files (Doxygen outputs),
- to read files and extract links,
- copy context to new files (header and footer)
- replace original file by fixed version.

'/
TYPE Highlighter
  '* \brief The high-lighting categories
  ENUM WordTypes
    FB_CODE  '*< Normal code, no high-lighting
    FB_KEYW  '*< A keyword
    FB_KWTP  '*< A keyword type
    FB_KWFL  '*< A flow keyword (currently not used)
    FB_PREP  '*< A preprocessor statement
    FB_SYMB  '*< A linked Symbol
  END ENUM

  AS STRING _
      FbPath _   '*< The path to read FB code files from
    , FbFiles _  '*< A list of all FB file names
    , InPath _   '*< The path to read Doxygen files from
    , DoxyFiles _'*< A list of all Doxygen file names
    , HtmlPath _ '*< The path for html files
    , HtmlSuff _ '*< The filename suffix for html files
    , TexPath _  '*< The path for LaTeX files
    , XmlPath _  '*< The path for XML files
    , LastLine   '*< The last line red from the input file
  AS RepData PTR Symbols '*< The list of linked symbols
  AS Parser PTR Pars '*< The parser to operate with
  AS ZSTRING PTR _
      FBDOC_MARK = @"<!-- Syntax-highlighting by fb-doc -->" _ '*< Text to mark the output
    , KEYW_A = @"<span class=""keyword"">"             _ '*< Code to start highlighting a keyword
    , KWTP_A = @"<span class=""keywordtype"">"         _ '*< Code to start highlighting a keywordtype
    , KWFL_A = @"<span class=""keywordflow"">"         _ '*< Code to start highlighting a flow keyword (not used yet)
    , PREP_A = @"<span class=""preprocessor"">"        _ '*< Code to start highlighting a preprocessor statement
    , CMNT_A = @"<span class=""comment"">"             _ '*< Code to start highlighting a comment
    , SPAN_E = @"</span>"                              _ '*< Code to end highlighting
    , QUOT_A = @"<span class=""stringliteral"">&quot;" _ '*< Code to start highlighting a string literal
    , QUOT_E = @"&quot;</span>"                          '*< Code to end highlighting a string literal
  AS INTEGER _
      Ifnr _  '*< The file number for input
    , LineNo  '*< The current line number

  UNION
    TYPE
      AS UBYTE _
        GenHtml      _ '*< Flag for html output
       , GenTex      _ '*< Flag for LaTeX output
       , GenXml        '*< Flag for XML output
    END TYPE
    AS LONG GenAny '*< All output flags
  END UNION

  DECLARE CONSTRUCTOR()
  DECLARE CONSTRUCTOR(BYVAL AS Parser PTR)
  DECLARE SUB doDoxy(BYREF AS STRING)
  DECLARE SUB do_files()
  DECLARE STATIC FUNCTION prepare_tex(BYVAL AS Highlighter PTR) AS STRING
  DECLARE STATIC FUNCTION prepare_xml(BYVAL AS Highlighter PTR) AS STRING
  DECLARE STATIC FUNCTION prepare_html(BYVAL AS Highlighter PTR) AS STRING
  DECLARE SUB generate_all(BYVAL AS ZSTRING PTR, BYVAL AS INTEGER)
  DECLARE FUNCTION generate_code(BYVAL AS ZSTRING PTR, BYVAL AS INTEGER, BYVAL AS INTEGER) AS STRING
  DECLARE FUNCTION word_type(BYREF AS STRING) AS ZSTRING PTR
  DECLARE FUNCTION searchPathNam(BYREF AS STRING) AS STRING

  '* \brief the function called to end a line and start a new one
  eol AS FUNCTION(BYVAL AS RepData PTR, BYref AS INTEGER) AS STRING _
    = @html_eol()
  '* \brief the function called to extract links from original files
  prepare AS FUNCTION(BYVAL AS Highlighter PTR) AS STRING _
    = @prepare_html()
  '* \brief the function called for normal code to replace special characters
  special_chars AS FUNCTION(BYVAL AS UBYTE PTR, BYVAL AS INTEGER, BYVAL AS INTEGER) AS STRING _
    = @html_specials()
END TYPE
