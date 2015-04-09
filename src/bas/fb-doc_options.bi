/'* \file fb-doc_options.bi
\brief Header file for options

This file contains the declaration of the \ref Options class. It's used
to scan options and parameters in the command line and to control
execution.

'/

#INCLUDE ONCE "dir.bi"


/'* \brief Emit an error message to STDERR '/
#DEFINE ERROUT(_T_) PRINT #OPT->Efnr, PROJ_NAME & ": " & _T_

/'* \brief Emit a message to STDERR '/
#DEFINE MSG_LINE(_T_) PRINT #OPT->Efnr, SPC(38 - LEN(_T_)); _T_; " --> ";

/'* \brief Emit a message to STDERR '/
#DEFINE MSG_END(_T_) PRINT #OPT->Efnr, _T_


/'* \brief File name for list of function names (caller / callees graphs) '/
CONST CALLEES_FILE = "fb-doc.lfn"

/'* \brief Parameters red from the command line

The class to scan options and parameters from command line. the 
command line gets parsed once at the program start. Since this 
structure is global, the settings are available in all internal 
modules.

'/
TYPE Options
/'* \brief fb-doc operation modes. '/
  ENUM RunModes

    /'* \brief Report an error found in the command line
    
    The parser found an error in the command line and we cannot operate.
    Output the error message and stop. '/
    ERROR_MESSAGE

    /'* \brief Print the helptext
    
    Stop after printing out some help information on how to start fb-doc 
    and how to use options at the command line. (Option `--help`). '/
    HELP_MESSAGE

    /'* \brief Print version information
    
    Print out the version information and stop (Option `--version`). '/
    VERSION_MESSAGE

    /'* \brief Operate in Geany mode
    
    Input from STDIN and output on STDOUT. Usually this is to generate 
    templates in Geany, but it also can be used with pipes. (Option \em 
    --geany-mode). '/
    GEANY_MODE

    /'* \brief Operate as Doxygen filter
    
    Read a file and generate C-source to STDOUT. (Default mode). '/
    DEF_MODE

    /'* \brief Operate in scan mode
    
    Read input from one or more files, write output to files. Usually 
    this is to generate pseudo C source output, but an alternative 
    emitter can be specified. When no file name or pattern is specified, 
    all *.bas and *.bi files in the current folder gets parsed. (Option 
    `--file-mode`). '/
    FILE_MODE

    /'* \brief Operate in list mode
    
    Read input from one or more files, write output to a single file \em
    fb-doc.lfn. Generate a list of callee names in this file. When no file
    name or pattern is specified, all <em>*.bas</em> and <em>*.bi</em>
    files in the current folder gets parsed. (Option `--list-mode`). '/
    LIST_MODE 

    /'* \brief Operate in syntax-highlighting mode
    
    Read input from one or more files, write output to a several files. As
    input fb-doc reads files created by Doxygen, containing the source
    listings in the intermediate format. The file types depend on the
    settings in the Doxyfile. It may be <em>*.html, *.tex</em> and
    <em>*.xml</em>, depending on GENERATE_HTML & SOURCE_BROWSER,
    GENERATE_LATEX & LATEX_SOURCE_CODE and GENERATE_XML &
    XML_PROGRAMLISTING. '/
    SYNT_MODE 

  END ENUM
  
  /'* \brief In-build emitters
  
  By default these four emitters are available in fb-doc. The 
  enumerators are used for default settings in the Options class. The 
  user can choose the emitter by option `--emitter`. The parameter 
  gets checked against the \ref EmitterIF::Nam string (or parts of it). '/
  ENUM EmitterTypes
    C_SOURCE          '*< emit pseudo C source (default and option `--file-mode`)
    FUNCTION_NAMES    '*< emit a list of function names (option `--list-mode`)
    GTK_DOC_TEMPLATES '*< emit templates for gtk-doc (option `--geany-mode gtk`)
    DOXYGEN_TEMPLATES '*< emit templates for Doxygen (option `--geany-mode doxy`)
    SYNTAX_REPAIR     '*< fix syntax highlighting of Doxygen listings (option `--syntax-mode`)
    EXTERNAL          '*< external emitter loaded as plugin
  END ENUM

  /'* \brief The style of the types in the C source
  
  A FB type can be translated to a C type or it can be shown as a 
  pseudo type. Ie instead of the C type void the pseudo type SUB can 
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
  
  AS RunModes      RunMode = DEF_MODE '*< the mode to operate (defaults to DOXYFILTER)
  AS TypesStyle      Types = FB_STYLE '*< the style for the type generation (defaults to FB_STYLE)
  AS Parser PTR       Pars = 0        '*< the parser we use
  AS EmitterTypes  EmitTyp = C_SOURCE '*< the emitter type (defaults to \em C_Source)
  AS CaseModes    CaseMode = CASE_ORIGN '*< the emitter type (defaults to \em C_Source)
  AS EmitterIF PTR  EmitIF = 0        '*< the emitter we use (set in \ref Options::parseCLI())
  AS ANY PTR    DllEmitter = 0        '*< the pointer for an external emitter
#IFDEF __FB_UNIX__ '& ZSTRING_PTR DirUp = "../";  /* tricky declaration for Doxygen (miss-interpretes the @ character)
  AS ZSTRING PTR     DirUp = @"../"   '*< sequence to get one directory up
#ELSE
  AS ZSTRING PTR     DirUp = @"..\"   '*< sequence to get one directory up
#ENDIF '&*/ 
  AS STRING _
       InFiles = "" _ '*< name or pattern of all input file[s]
   , StartPath = "" _ '*< path at program start
    , FileIncl = "" _ '*< names of \#`INCLUDE` files
     , OutPath = "" _ '*< path for file output (option `--outpath`)
        , Errr = ""   '*< path for file output (option `--outpath`)
  AS INTEGER _
       Asterix = 0 _ '*< style for C_Source emitter to export comment blocks
  , AllCallees = 0 _ '*< export external callee names as well (option `--list-mode`)
  , InRecursiv = 0 _ '*< flag set when InFiles should get scaned recursiv in subfolders
      , InTree = 0 _ '*< flag set when source tree should get scanned
       , Level = 0 _ '*< counter for \#`INCLUDE`s
        , Efnr = 0 _ '*< file number for error messages (file modes)
        , Ocha = 0   '*< file number for output
  AS UBYTE _
    JoComm = ASC("*") _ '*< magic character to start a documentation comment
  , AdLine = ASC("&")   '*< magic character to start a comment for direct export
  AS EmitFunc _
    CreateFunction _  '*< emitter for a function declaration with parameter list
  , CreateVariable    '*< emitter for a variable declaration

  DECLARE CONSTRUCTOR()
  DECLARE DESTRUCTOR()
  DECLARE FUNCTION parseCLI() AS RunModes
  DECLARE FUNCTION parseOptpara(byref Idx AS INTEGER) AS STRING
  DECLARE SUB chooseEmitter(BYREF F AS STRING)
  DECLARE SUB FileModi()
  DECLARE SUB doFile(BYREF AS STRING)
  DECLARE FUNCTION checkDir(BYREF AS STRING) AS INTEGER
  DECLARE FUNCTION scanFiles(BYREF AS STRING, BYREF AS STRING) AS STRING
  DECLARE FUNCTION addPath(BYREF AS STRING, BYREF AS STRING) AS STRING

END TYPE


/'* \brief The global struct for all parameters red from the command line '/
DIM SHARED AS Options PTR OPT
