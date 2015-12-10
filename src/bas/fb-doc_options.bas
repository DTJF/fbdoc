/'* \file fb-doc_options.bas
\brief The source code for the \ref Options class

This file contains the source code for the Options class. It's
responsible for user interaction

- parse the command line (options and file specs),
- control the execution of \Proj, and
- output messages about the current state.

'/

#INCLUDE ONCE "fb-doc_options.bi"
#INCLUDE ONCE "fb-doc_version.bi"
#INCLUDE ONCE "fb-doc_emit_syntax.bi"
#INCLUDE ONCE "fb-doc_emit_lfn.bi"
#INCLUDE ONCE "fb-doc_doxyfile.bi"


/'* \brief Read options and parameters from the command line

The constructor scans all command line arguments and checks for
options and their parameters (, see \ref SecTabOptions for
details). Options may be specified in short form (starting with a
single minus character) or in human readable LONG form (starting
with two minus characters). Some options may have an additinal
parameter.

Each command line argument that is neither an option nor its parameter
gets interpreted as a file name or pattern. \Proj collects them in
a queue and operates on this queue afterwards. The queue may have
mixed entries (names and patterns). It's recommended to specify
queue entries in single or double quotes.

'/
CONSTRUCTOR Options()
  Efnr = FREEFILE
  IF OPEN ERR (AS #Efnr) THEN ?PROJ_NAME & ": " & "couldn't open STDERR" : Efnr = 0 : EXIT CONSTRUCTOR

  CreateFunction = @cppCreateFunction()
  CreateVariable = @cppCreateTypNam()
           Types = FB_STYLE
END CONSTRUCTOR


/'* \brief The destructor

Delete the memory used for an external emitter (if any) and for the
Parser.

'/
DESTRUCTOR Options()
  IF DllEmitter THEN DYLIBFREE(DllEmitter)
  IF Pars THEN DELETE Pars
  CLOSE #Efnr
END DESTRUCTOR


/'* \brief parse an additional parameter for an option
\param Idx the current index in `COMMAND()`
\returns the parameter, without quotes if any

This function evaluates a parameter for an option. Some options need
an additional parameter (ie. like `--outpath`). It gets read by this
function, removing surrounding single or double quotes (if any).

In case of no further parameter or when the parameter starts by an
"`-`" character an error messages gets created.

'/
FUNCTION Options.parseOptpara(BYREF Idx AS INTEGER) AS STRING
  VAR p = Idx + 1
  IF LEN(COMMAND(p)) ANDALSO LEFT(COMMAND(p), 1) <> "-" THEN
    Idx = p
    SELECT CASE AS CONST ASC(COMMAND(p))
    CASE ASC(""""), ASC("'") : RETURN MID(COMMAND(p), 2, LEN(COMMAND(p)) - 2)
    END SELECT : RETURN COMMAND(p)
  END IF : Errr = ", parameter expected [" & COMMAND(Idx) & "]" : RETURN ""
END FUNCTION


/'* \brief parse the command line
\returns the RunMode

This function parses the command line. Options and its parameter (if
required) get read and the file specifier(s) are listed in the
variable \ref InFiles, separated by new line characters.

The function returns the value of \ref RunMode. In case of an error
the RunMode is \ref ERROR_MESSAGE and the variable \ref Errr
contains an message text. \Proj stops execution in that case.

Loading an external emitter plugin must be done after scanning the
COMMAND strings because DYLIBLOAD destroys the COMMAND array. All
unknown parameters get collected in the variable `par`, separated by
tabulators (`!"\t"`), in order to get passed to the plugin
initialisation function.

'/
FUNCTION Options.parseCLI() AS RunModes
  VAR i = 1, emi = "", par = ""
  WHILE LEN(COMMAND(i)) '                               evaluate options
    SELECT CASE AS CONST ASC(COMMAND(i))
    CASE ASC("-")
      SELECT CASE COMMAND(i)
      CASE "-f", "--file-mode"
        IF RunMode <> DEF_MODE THEN Errr &= ", multiple run modes" : RETURN ERROR_MESSAGE
        RunMode = FILE_MODE
        EmitTyp = C_SOURCE
      CASE "-g", "--geany-mode"
        IF RunMode <> DEF_MODE THEN Errr &= ", multiple run modes" : RETURN ERROR_MESSAGE
        RunMode = GEANY_MODE
        EmitTyp = GTK_DOC_TEMPLATES
        emi = parseOptpara(i)
      CASE "-l", "--list-mode"
        IF RunMode <> DEF_MODE THEN Errr &= ", multiple run modes" : RETURN ERROR_MESSAGE
        RunMode = LIST_MODE
        EmitTyp = FUNCTION_NAMES
      CASE "-s", "--syntax-mode"
        IF RunMode <> DEF_MODE THEN Errr &= ", multiple run modes" : RETURN ERROR_MESSAGE
        RunMode = SYNT_MODE
        EmitTyp = SYNTAX_REPAIR

      CASE "-a", "--asterix" : Asterix = 1
      CASE "-c", "--cstyle"
                 Types = C_STYLE
        CreateFunction = @cCreateFunction()
        CreateVariable = @cCreateTypNam()
      CASE "-d", "--doc-comments" : Docom = 1
      CASE "-t", "--tree" : InTree = 1

      CASE "-e", "--emitter"
        IF LEN(emi) THEN      Errr &= ", multiple emitter setting" : RETURN ERROR_MESSAGE
        emi = parseOptpara(i)
        IF 0 = LEN(emi) THEN   Errr &= ", invalid emitter setting" : RETURN ERROR_MESSAGE
      CASE "-o", "--outpath"
        IF LEN(OutPath) THEN         Errr &= ", multiple outpaths" : RETURN ERROR_MESSAGE
        OutPath = parseOptpara(i)
        IF 0 = LEN(OutPath) THEN       Errr &= ", invalid outpath" : RETURN ERROR_MESSAGE
      CASE "-r", "--recursiv" : InRecursiv = 1

      CASE "-h", "--help" : RETURN HELP_MESSAGE
      CASE "-v", "--version" : RETURN VERSION_MESSAGE

      CASE ELSE : par &= !"\t" & COMMAND(i)
      END SELECT
    CASE ELSE
      SELECT CASE AS CONST ASC(COMMAND(i))
      CASE ASC(""""), ASC("'")
                  InFiles &= MID(COMMAND(i), 2, LEN(COMMAND(i)) - 2) & !"\n"
      CASE ELSE : InFiles &= COMMAND(i) & !"\n"
      END SELECT
    END SELECT : i += 1
  WEND

  EmitIF = chooseEmitter(emi, par)
  IF LEN(par) THEN Errr &= "unknown options '" & par & "'"

  IF 0 = LEN(InFiles) ANDALSO RunMode = DEF_MODE THEN RunMode = HELP_MESSAGE
  Pars = NEW Parser(EmitIF)
  RETURN IIF(LEN(Errr), ERROR_MESSAGE, RunMode)
END FUNCTION


/'* \brief Choose a named emitter, if possible
\param F the name of the emitter to search for
\param P parameters to pass to an external emitter (plugin)

This function checks for an emitter specified by the parameter F. The
check is not case-sensitve and is done for a complete emitter name as
well as for a fragment. So it's enough to specify some of the start
characters of the emitter name (ie. `dox` instead of
`DoxygenTemplates`).

In case of no match for any internal emitter name this SUB tries to
load an external emitter (plugin), located in the current folder. See
\ref SecEmmEx for details. If this fails an error message gets created
and \Proj stops execution.

Parameter `P` contains all command line options that are unknown to
\Proj. Those options get passed to the plugins function EmitterInit().
There, all known options should get extracted and evaluated. When this
string is not empty after the plugin initialization, \Proj stops
execution by an `unknown options` error.

'/
FUNCTION Options.chooseEmitter(BYREF F AS STRING, BYREF P AS STRING) AS EmitterIF PTR
  VAR l = LEN(F)
  IF l THEN
    SELECT CASE UCASE(F)
    CASE LEFT(          "C_SOURCE", l) : EmitTyp = C_SOURCE
    CASE LEFT(     "FUNCTIONNAMES", l) : EmitTyp = FUNCTION_NAMES
    CASE LEFT(   "GTKDOCTEMPLATES", l) : EmitTyp = GTK_DOC_TEMPLATES
    CASE LEFT(  "DOXYGENTEMPLATES", l) : EmitTyp = DOXYGEN_TEMPLATES
    CASE LEFT("SYNTAXHIGHLIGHTING", l) : EmitTyp = SYNTAX_REPAIR
    CASE ELSE : EmitTyp = EXTERNAL
    END SELECT
  END IF

  VAR r = NEW EmitterIF
#IFDEF __FB_DOS__
  Errr &= ", no plugin support on DOS platform!"
#ELSE
  SELECT CASE AS CONST EmitTyp
    CASE          C_SOURCE : init_csource(r)
    CASE    FUNCTION_NAMES : init_lfn(r)
    CASE GTK_DOC_TEMPLATES : init_gtk(r)
    CASE DOXYGEN_TEMPLATES : init_doxy(r)
    CASE     SYNTAX_REPAIR : init_syntax(r)
  CASE ELSE
    DllEmitter = DYLIBLOAD(F)
    IF 0 = DllEmitter THEN Errr &= ", couldn't load plugin " & F : EXIT SELECT
    DIM ini AS FUNCTION CDECL(BYVAL AS EmitterIF PTR, BYREF AS STRING) AS EmitterIF PTR _
          = DYLIBSYMBOL(DllEmitter, "EMITTERINIT") '&EmitterInit();
    IF 0 = ini THEN Errr &= ", no EMITTERINIT function in emitter " & F : EXIT SELECT
    EmitIF = ini(r, P) : EmitTyp = EXTERNAL
  END SELECT
#ENDIF
  RETURN r
END FUNCTION


/'* \brief Scan file names of given pattern
\param Patt The name pattern to search for
\param Path A path to add
\returns A list of file names and their subfolder

This function scans the current directory for file names matching a
given pattern and the subfolders, if \ref Options::InRecursiv ist set.
It returns a list of filenames including their subfolder. The list is
separated by newline characters.

'/
FUNCTION Options.scanFiles(BYREF Patt AS STRING, BYREF Path AS STRING) AS STRING
  STATIC AS STRING p
  VAR path_l = LEN(p), f = ""
  IF LEN(Path) THEN p &= Path & SLASH

  IF InRecursiv > 0 THEN
    VAR res = 0, n = DIR("*", fbDirectory, res), t = ""
    WHILE LEN(n)
      IF res = fbDirectory ANDALSO n <> "." ANDALSO n <> ".." THEN t &= n & NL
      n = DIR()
    WEND

    VAR a = 1, e = a, l = LEN(t)
    WHILE a < l
      e = INSTR(a, t, NL)
      n = MID(t, a, e - a)
      IF 0 = CHDIR(n) THEN f &= scanFiles(Patt, n) : CHDIR ("..")
      a = e + 1
    WEND
  END IF

  VAR n = DIR(Patt), f_l = LEN(f)
  WHILE LEN(n)
    f &= p & n & NL
    n = DIR()
  WEND

  IF RunMode = FILE_MODE ANDALSO f_l > LEN(f) ANDALSO checkDir(OutPath & p) then f = ""
  p = LEFT(p, path_l)
  RETURN f
END FUNCTION


/'* \brief Add two directories
\param P1 the path of the basis directory
\param P2 the path of the directory to add
\returns a string of the combined directory

Append second path to first, if it's not an absolute path. In case
of an absolute path this path gets returned. The returned path has a
SLASH at the end and all '..' sequences are unscrambled.

'/
FUNCTION Options.addPath(BYREF P1 AS STRING, BYREF P2 AS STRING) AS STRING
  IF LEN(P1) ANDALSO RIGHT(P1, 1) <> SLASH THEN P1 &= SLASH
  IF 0 = LEN(P2) ORELSE P2 = "." THEN RETURN P1
  IF RIGHT(P2, 1) <> SLASH THEN P2 &= SLASH
#IFDEF __FB_UNIX__
  IF P2[0] = ASC("/") THEN RETURN P2
#ELSE
  IF MID(P2, 2, 1) = ":" THEN RETURN P2
#ENDIF
  VAR i = LEN(P1), s = 1
  WHILE MID(P2, s, 3) = *DirUp
    i = INSTRREV(P1, SLASH, i - 1) : IF 0 = i THEN RETURN MID(P2, s)
    s += 3
  WEND
  IF MID(P2, s, 2) = MID(*DirUp, 2) THEN s += 2
  RETURN LEFT(P1, i) & MID(P2, s)
END FUNCTION


/'* \brief Create folder (if not exists)
\param P the folder name
\returns -1 on error, else 0

This FUNCTION gets called to prepare the folders for file output in
`--file-mode`. It creates matching subfolders in the target
directory set by option `--outpath` or its default.

'/
FUNCTION Options.checkDir(BYREF P AS STRING) AS INTEGER
  VAR a = 1, e = a, l = LEN(P), cupa = CURDIR()
#IFDEF __FB_UNIX__
  IF LEFT(P, 1) = "/" THEN a = 2 : CHDIR("/")
#ELSE
  IF MID(P, 2, 1) = ":" THEN a = 4 : CHDIR(LEFT(P, 3))
#ENDIF

  DO
    e = INSTR(a, P, SLASH) : IF e = 0 THEN e = l + 1
    VAR n = MID(P, a, e - a)
    IF 0 = CHDIR(n) THEN a = e + 1 : CONTINUE DO
    MKDIR(n)
    IF 0 = CHDIR(n) THEN a = e + 1 : CONTINUE DO
    EXIT DO
  LOOP UNTIL a > l : CHDIR(cupa) : RETURN IIF(a > l, 0, 1)
END FUNCTION


/'* \brief Operate on file(s), single name and / or pattern(s)

This SUB gets called in case of file input modes. It separates the file
name specifiers from the \ref Options::InFiles list, expands file
patterns and executes the required operations.

'/
SUB Options.FileModi()
  StartPath = CURDIR()
  VAR cupa = StartPath

  IF 0 = LEN(InFiles) THEN '                            InFiles defaults
    SELECT CASE AS CONST RunMode
    CASE SYNT_MODE, LIST_MODE : InFiles = !"Doxyfile\n"
    CASE ELSE : InFiles = !"*.bas\n*.bi\n"
    END SELECT
  END IF

  IF 0 = LEN(OutPath) ANDALSO RunMode = FILE_MODE THEN
    OutPath = ".." & SLASH & "doc" & SLASH '   def. OutPath in file mode
    SELECT CASE AS CONST EmitTyp '          + emitter specific extension
    CASE C_SOURCE      : OutPath &= "c_src"
    CASE SYNTAX_REPAIR : OutPath &= "fb_html"
    CASE ELSE          : OutPath &= "src"
    END SELECT
  END IF
  OutPath = addPath(cupa, OutPath)

  IF RunMode = DEF_MODE THEN
    Ocha = FREEFILE
    OPEN CONS FOR OUTPUT AS #Ocha
  END IF

  if EmitIF->CTOR_ then EmitIF->CTOR_(@THIS)
  VAR a = 0 _              ' Start character of next file name / pattern
    , i = a _              ' Counter for characters
    , inslsh = 0 _         ' Flag, set when filename name contains a path
    , inpat = 0 _          ' Flag, set when name is a pattern
    , l = LEN(InFiles) - 1 ' Length of input queue (number of characters)

  DO
    SELECT CASE AS CONST InFiles[i]
    CASE 0 : EXIT DO
    CASE ASC("*"), ASC("?") : inpat = 1
    CASE ASC(SLASH) : inslsh = i
    CASE ASC(!"\n")
      IF 0 = inpat THEN
        doFile(MID(InFiles, a + 1, i - a))
      ELSE
        VAR in_pattern = ""
        IF inslsh THEN
          VAR path = MID(InFiles, a + 1, inslsh - a)
          IF CHDIR(path) THEN
            ERROUT("couldn't change dir to " & path)
          ELSE
            IF InTree THEN StartPath = addPath(cupa, path)
            in_pattern = scanFiles(MID(InFiles, inslsh + 2, i - inslsh - 1), "")
          END IF
        ELSE
          in_pattern = scanFiles(MID(InFiles, a + 1, i - a), "")
        END IF

        VAR aa = 1, ee = aa, ll = LEN(in_pattern)
        WHILE aa < ll
          ee = INSTR(aa + 1, in_pattern, !"\n")
          doFile(MID(in_pattern, aa, ee - aa))
          aa = ee + 1
        WEND
        IF inslsh THEN CHDIR(cupa) : StartPath = cupa : inslsh = 0
        inpat = 0
      END IF : a = i + 1
    END SELECT : i += 1
  LOOP

  if EmitIF->DTOR_ then EmitIF->DTOR_(@THIS)
  SELECT CASE AS CONST RunMode
  CASE LIST_MODE : IF Ocha THEN CLOSE #Ocha : MSG_LINE(LFN_FILE) : MSG_CONT("written")
  CASE ELSE      : IF Ocha THEN CLOSE #Ocha
  END SELECT
  MSG_END("")
END SUB


/'* \brief Operate a single file

This SUB gets called to operate on a single file. Depending on the
\ref RunMode it emits messages to STDERR and it opens a file for the
output channel \ref Ocha.

'/
SUB Options.doFile(BYREF Fnam AS STRING)
  SELECT CASE AS CONST RunMode
  CASE DEF_MODE
    MSG_LINE(Fnam)
    Pars->File_(Fnam, InTree)
    if len(Pars->ErrMsg) then MSG_CONT(Pars->ErrMsg)
  CASE SYNT_MODE
    VAR nix = NEW Highlighter(Pars)
    nix->doDoxy(Fnam)
    DELETE nix
  CASE LIST_MODE
    IF LCASE(RIGHT(Fnam, 4)) = ".bas" ORELSE _
       LCASE(RIGHT(Fnam, 3)) = ".bi" THEN
      IF 0 = Ocha THEN
        MSG_LINE(OutPath & LFN_FILE)
        Ocha = startLFN(OutPath)
        IF 0 = Ocha THEN MSG_CONT("error (couldn't write)") : EXIT SUB
        MSG_CONT("opened")
      END IF
      MSG_LINE(Fnam)
      Pars->File_(Fnam, InTree)
      if len(Pars->ErrMsg) then MSG_CONT(Pars->ErrMsg)
      EXIT SUB
    END IF

    VAR doxy = NEW DoxyUDT(Fnam) _
      , recu = InRecursiv _
      , oldo = Ocha _
      , patt = ""

    MSG_LINE(Fnam)
    IF 0 = doxy->Length THEN
      MSG_CONT(doxy->Errr) : DELETE doxy
      MSG_LINE("Doxyfile")
      IF CHDIR(Fnam) THEN MSG_CONT("error (couldn't change directory)") : EXIT SUB
      doxy = NEW DoxyUDT("Doxyfile")
      IF 0 = doxy->Length THEN MSG_CONT(doxy->Errr) : DELETE doxy : EXIT SUB
    END IF

    InRecursiv = IIF(doxy->Tag(RECURSIVE) = "YES", 1, 0)
    VAR in_path = addPath(StartPath, doxy->Tag(INPUT_TAG))
    DELETE doxy
    IF CHDIR(in_path) THEN
      MSG_CONT("error (couldn't change to " & in_path & ")")
    ELSE
      patt = scanFiles("*.bas", "") & scanFiles("*.bi", "")
      IF 0 = LEN(patt) THEN
        MSG_CONT("error (no input files in " & in_path & ")")
      ELSE
        MSG_CONT("scanned") _

        MSG_LINE(StartPath & LFN_FILE)
        Ocha = startLFN(StartPath)
        IF 0 = Ocha THEN
          MSG_CONT("error (couldn't write)")
        ELSE
          MSG_CONT("opened")
          VAR a = 1, e = a, l = LEN(patt)
          WHILE a < l
            e = INSTR(a + 1, patt, !"\n")
            Pars->File_(MID(patt, a, e - a), InTree)
            MSG_LINE(MID(patt, a, e - a)) : MSG_CONT("scanned")
            a = e + 1
          WEND
          CLOSE #Ocha : MSG_LINE(StartPath & LFN_FILE) : MSG_CONT("written")
        END IF
      END IF
    END IF

    CHDIR(StartPath)
    Ocha = oldo
    InRecursiv = recu

  CASE FILE_MODE
    STATIC AS STRING out_name
    VAR a = 1, i = INSTRREV(Fnam, ".")
    out_name = LEFT(Fnam, i)

#IFDEF __FB_UNIX__
    IF LEFT(out_name, 1) = "/" THEN a = 2
#ELSE
    IF MID(out_name, 2, 1) = ":" THEN a = 2 : out_name[1] = out_name[0]
#ENDIF
    WHILE MID(out_name, a, 3) = *DirUp
      a += 3
    WEND
    IF MID(out_name, a, 2) = MID(*DirUp, 2) THEN a += 2
    out_name = MID(out_name, a)

    VAR path = OutPath & LEFT(out_name, INSTRREV(out_name, SLASH))
    IF checkDir(path) THEN
      ERROUT("couldn't create directory " & path)
    ELSE
      out_name = OutPath & out_name & *IIF(RIGHT(FNam, 3) = ".bas", @"c", @"h")
      Ocha = FREEFILE
      IF OPEN(out_name FOR OUTPUT AS #Ocha) THEN
        ERROUT("couldn't write " & out_name)
      ELSE
        Pars->File_(Fnam, InTree)
        CLOSE #Ocha
        MSG_LINE(Fnam) : IF LEN(Pars->ErrMsg) THEN MSG_CONT(Pars->ErrMsg)
      END IF
    END IF
  END SELECT
END SUB
