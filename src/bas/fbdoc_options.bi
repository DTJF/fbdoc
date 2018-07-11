/'* \file fbdoc_options.bi
\brief Header file for options

This file contains the declaration of the \ref Options class. It's used
to scan options and parameters in the command line and to control
execution.

'/

#INCLUDE ONCE "dir.bi"
#INCLUDE ONCE "fbdoc_parser.bi"

CONST _
  LFN_FILE = "fb-doc.lfn" _ '*< File name for list of function names (caller / callees graphs)
 , LFN_SEP = !"\n"          '*< Separator for entries in file `fb-doc.lfn` (one character!).


/'* \brief Emit an error message to `STDERR` '/
#DEFINE ERROUT(_T_) PRINT #OPT->Efnr, PROJ_NAME & ": " & _T_

/'* \brief Emit a message to `STDERR` '/
#DEFINE MSG_LINE(_T_) PRINT #OPT->Efnr, NL; SPC(38 - LEN(_T_)); _T_; " -->";

/'* \brief Emit a message to `STDERR` '/
#DEFINE MSG_CONT(_T_) PRINT #OPT->Efnr, " " & _T_;

/'* \brief Emit a message to `STDERR` '/
#DEFINE MSG_END(_T_) PRINT #OPT->Efnr, _T_


/'* \brief Evaluate parameters from command line

This class is designed to scan options and parameters from command
line. The command line gets parsed once at the program start. Since
this structure is global, the settings are available in all internal
modules.

'/
TYPE Options
  /'* \brief \Proj operation modes. '/
  ENUM RunModes

    /'* \brief Report an error found in the command line

    The parser found an error in the command line and we cannot operate.
    Output the error message and stop. '/
    ERROR_MESSAGE

    /'* \brief Print the helptext

    Stop after printing out some help information on how to start \Proj
    and how to use options at the command line (mode \ref SecModHelp). '/
    HELP_MESSAGE

    /'* \brief Print version information

    Print out the version information and stop (mode \ref SecModVersion). '/
    VERSION_MESSAGE

    /'* \brief Operate in Geany mode

    Input from `STDIN` and output on `STDOUT`. Usually this is to generate
    templates in Geany, but it also can be used with pipes (mode \ref SecModGeany). '/
    GEANY_MODE

    /'* \brief Operate as Doxygen filter

    Read a file and generate C-source to `STDOUT` (mode \ref SecModDef). '/
    DEF_MODE

    /'* \brief Operate in scan mode

    Read input from one or more files, write output to files. Usually
    this is to generate pseudo C source output, but an alternative
    emitter can be specified. When no file name or pattern is specified,
    all *.bas and *.bi files in the current folder gets parsed (mode
    \ref SecModFile). '/
    FILE_MODE

    /'* \brief Operate in list mode

    Read input from one or more files, write output to a single file
    `fb-doc.lfn`. Generate a list of callee names in this file. When no
    file name or pattern is specified, all <em>*.bas</em> and
    <em>*.bi</em> files in the current folder gets parsed (mode
    \ref SecModList). '/
    LIST_MODE

    /'* \brief Operate in syntax-highlighting mode

    Read input from one or more files, write output to a several files
    (mode \ref SecModSyntax). As input \Proj reads files created by
    Doxygen, containing the source listings in the intermediate format.
    The file types depend on the settings in the Doxyfile. It may be
    `*.html`, `*.tex` and `*.xml`, depending on tags `SOURCE_BROWSER =`
    and `GENERATE_HTML =`, `GENERATE_LATEX =` / `LATEX_SOURCE_CODE =`
    and `GENERATE_XML =` / `XML_PROGRAMLISTING`. '/
    SYNT_MODE

  END ENUM

  /'* \brief The style of the types in the C source

  A FB type can be translated to a C type or it can be shown as a
  pseudo type. Ie. instead of the C type void the pseudo type SUB can
  be used. '/
  ENUM TypesStyle
    C_STYLE  '*< types gets translated to C
    FB_STYLE '*< pseudo FB types are used
  END ENUM

  '* \brief The letter-case mode for keywords
  ENUM CaseModes
    CASE_ORIGN '*< Output original formating
    CASE_LOWER '*< Output keywords in lower case
    CASE_MIXED '*< Output keywords in mixed case
    CASE_UPPER '*< Output keywords in upper case
  END ENUM

  AS STRING _
          Errr = "" _ '*< the error message (if any)
     , InFiles = "" _ '*< name or pattern of all input file[s]
   , StartPath = "" _ '*< path at program start
    , FileIncl = "" _ '*< names of #`INCLUDE` files
     , OutPath = "" _ '*< path for file output (option \ref SecOptOutpath)
      , LfnPnN = ""   '*< path and name of custom list of function name file

  AS RunModes      RunMode = DEF_MODE '*< the mode to operate (defaults to DOXYFILTER)
  AS TypesStyle      Types = FB_STYLE '*< the style for the type generation (defaults to FB_STYLE)
  AS Parser PTR       Pars = 0        '*< the parser we use
  AS EmitterTypes  EmitTyp = C_SOURCE '*< the emitter type (defaults to `C_Source`)
  AS CaseModes    CaseMode = CASE_ORIGN '*< the emitter type (defaults to `C_Source`)
  AS EmitterIF PTR  EmitIF = 0        '*< the emitter we use (set in \ref Options::parseCLI())
  AS ANY PTR    DllEmitter = 0        '*< the pointer for an external emitter
#IFDEF __FB_UNIX__
'&ZSTRING_PTR DirUp = "../";  //!< sequence to get one directory up
'&/* tricky declaration for Doxygen (it miss-interpretes the @ character)
  AS ZSTRING PTR     DirUp = @"../"
#ELSE
  AS ZSTRING PTR     DirUp = @"..\"
'&*/
#ENDIF
  AS INTEGER _
       Asterix = 0 _ '*< comment block style for emitter \ref SecEmmCSource
       , DoCom = 0 _ '*< include documentational comments in source code (\ref SecEmmSyntax)
  , AllCallees = 0 _ '*< export external callee names as well (mode \ref SecModList)
  , InRecursiv = 0 _ '*< flag set when InFiles should get scaned recursiv in subfolders (option \ref SecOptRecursiv)
      , InTree = 0 _ '*< flag set when source tree should get scanned (option \ref SecOptTree)
       , Level = 0 _ '*< counter for #`INCLUDE`s
        , Efnr = 0 _ '*< file number for error messages (file modes)
        , Ocha = 0   '*< file number for output
  AS UBYTE _
    JoComm = ASC("*") _ '*< magic character to start a documentational comment
  , AdLine = ASC("&")   '*< magic character to start a comment for direct export
  AS EmitFunc _
    CreateFunction _  '*< emitter for a function declaration with parameter list
  , CreateVariable    '*< emitter for a variable declaration

  DECLARE CONSTRUCTOR()
  DECLARE DESTRUCTOR()
  DECLARE FUNCTION parseCLI() AS RunModes
  DECLARE FUNCTION parseOptpara(BYREF Idx AS INTEGER) AS STRING
  DECLARE FUNCTION chooseEmitter(BYREF F AS STRING, BYREF AS STRING) as EmitterIF PTR
  DECLARE SUB FileModi()
  DECLARE SUB doFile(BYREF AS STRING)
  DECLARE FUNCTION checkDir(BYREF AS STRING) AS INTEGER
  DECLARE FUNCTION scanFiles(BYREF AS STRING, BYREF AS STRING) AS STRING
  DECLARE FUNCTION addPath(BYREF AS STRING, BYREF AS STRING) AS STRING
END TYPE

'&typedef Options* Options_PTR; //!< Doxygen internal (ignore this).
/'* \brief The global struct for all parameters read from the command line '/
COMMON SHARED AS Options PTR OPT

' Forward declaration of internal emitter init functions
DECLARE SUB init_csource(BYVAL AS EmitterIF PTR)
DECLARE SUB init_doxy(BYVAL AS EmitterIF PTR)
DECLARE SUB init_gtk(BYVAL AS EmitterIF PTR)
DECLARE SUB init_lfn(BYVAL AS EmitterIF PTR)
DECLARE SUB init_syntax(BYVAL AS EmitterIF PTR)
