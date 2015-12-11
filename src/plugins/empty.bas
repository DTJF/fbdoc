/'* \file empty.bas
\brief Example code for an empty external emitter

This file contains example source code for an external emitter. It
isn't used in the \Proj source tree. See \ref SecEmmEx for details.

This emitter generates a list of the function names called via the
emitter interface. So when you input some FB source to \Proj and use
this emitter, the output is a list of the \Proj functions called by the
parser for this input.

Before you can use this emitter, you have to compile it first, using
the command

~~~{.sh}
fbc -dylib empty.bas
~~~

The result is a binary called

  - libempty.so  (LINUX)
  - libempty.dll (windows)

There's no way to compile or use an external emitter on DOS since
DOS doesn't support dynamic linked libraries.

To use this emitter in \Proj set its name (without the suffix .bas) as
parameter to option `-e`. Ie. the emitter output for the context of
this file can get written to a text file by

~~~{.sh}
./fb-doc --emitter "empty" empty.bas > test.txt
~~~

(LINUX example) and this will generate the following output in file
`test.txt`:

\verbatim

EMPTY_CTOR
EMPTY_INIT
EMPTY_INCLUDE: 77 "../bas/fb-doc_parser.bi"
EMPTY_FUNCTION: 89 empty_declare
EMPTY_FUNCTION: 104 empty_function
EMPTY_FUNCTION: 116 empty_enum
EMPTY_FUNCTION: 128 empty_union
EMPTY_FUNCTION: 140 empty_class
EMPTY_FUNCTION: 152 empty_define
EMPTY_FUNCTION: 168 empty_include
EMPTY_FUNCTION: 180 empty_init
EMPTY_FUNCTION: 192 empty_error
EMPTY_FUNCTION: 204 empty_empty
EMPTY_FUNCTION: 216 empty_exit
EMPTY_FUNCTION: 228 empty_CTOR
EMPTY_FUNCTION: 240 empty_DTOR
EMPTY_FUNCTION: 287 EmitterInit
EMPTY_EXIT
EMPTY_DTOR
\endverbatim

- The constructor (`EMPTY_CTOR`) is called once at the start after loading the plugin.
- The `EMPTY_INIT` function is called at the start of each file (#`INCLUDE`).
- The middle part contains `EMPTY_FUNCTION` calls here (, since the source contains only `SUB`s and `FUNCTION`s).
- The `EMPTY_EXIT` function is called at the end of each file (#`INCLUDE`).
- The destructor (`EMPTY_DTOR`) is called once after finishing all input.

Test the plugin with other input files, check also option `-t` to
follow a source tree.

\note  \Proj checks for internal names first, so don't name your
       customized emitter similar to an internal emitter name.

\since 0.2.0
'/

#INCLUDE ONCE "../bas/fbdoc_options.bi"


/'* \brief Emitter called when the Parser is at a variable declaration
\param P The parser calling this emitter

FIXME

\since 0.2.0
'/
SUB empty_declare CDECL(BYVAL P AS Parser PTR)
  Code(NL & __FUNCTION__ & ": " & P->LineNo & " " & P->SubStr(P->NamTok))
END SUB


/'* \brief Emitter called when the Parser is on top of a function body
\param P The parser calling this emitter

FIXME

\since 0.2.0
'/
SUB empty_function CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    VAR nam = .SubStr(IIF(.NamTok[3] = .TOK_DOT, .NamTok + 6, .NamTok))
    Code(NL & __FUNCTION__ & ": " & .LineNo & " " & nam)
  END WITH
END SUB


/'* \brief Emitter called when the Parser is at the start of a ENUM block
\param P The parser calling this emitter

FIXME

\since 0.2.0
'/
SUB empty_enum CDECL(BYVAL P AS Parser PTR)
  Code(NL & __FUNCTION__)
END SUB


/'* \brief Emitter called when the Parser is at the start of a UNION block
\param P The parser calling this emitter

FIXME

\since 0.2.0
'/
SUB empty_union CDECL(BYVAL P AS Parser PTR)
  Code(NL & __FUNCTION__)
END SUB


/'* \brief Emitter called when the Parser is at the start of a TYPE block
\param P The parser calling this emitter

FIXME

\since 0.2.0
'/
SUB empty_class CDECL(BYVAL P AS Parser PTR)
  Code(NL & __FUNCTION__)
END SUB


/'* \brief Emitter called when the Parser is at an #`DEFINE` line or at the start of a #`MACRO`
\param P The parser calling this emitter

FIXME

\since 0.2.0
'/
SUB empty_define CDECL(BYVAL P AS Parser PTR)
  Code(NL & __FUNCTION__)
END SUB


/'* \brief Emitter called when the Parser is at an #`INCLUDE` line
\param P The parser calling this emitter

FIXME

\since 0.2.0
'/
SUB empty_include CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    VAR nam = .SubStr(.NamTok)
    Code(NL & __FUNCTION__ & ": " & .LineNo & " " & nam)
    IF .InTree THEN .Include(TRIM(nam, """"))
  END WITH
END SUB


/'* \brief Emitter called before the input gets parsed
\param P The parser calling this emitter

FIXME

\since 0.2.0
'/
SUB empty_init CDECL(BYVAL P AS Parser PTR)
  Code(NL & __FUNCTION__)
END SUB


/'* \brief Emitter called for an error
\param P The parser calling this emitter

FIXME

\since 0.2.0
'/
SUB empty_error CDECL(BYVAL P AS Parser PTR)
  Code(NL & __FUNCTION__)
END SUB


/'* \brief Emitter called for an empty block in mode `--geany-mode`
\param P The parser calling this emitter

FIXME

\since 0.2.0
'/
SUB empty_empty CDECL(BYVAL P AS Parser PTR)
  Code(NL & __FUNCTION__)
END SUB


/'* \brief Emitter called after the input got parsed
\param P The parser calling this emitter

FIXME

\since 0.2.0
'/
SUB empty_exit CDECL(BYVAL P AS Parser PTR)
  Code(NL & __FUNCTION__)
END SUB


/'* \brief Emitter called before the parser gets created and the input gets parsed
\param O The Options UDT calling this constructor

FIXME

\since 0.2.0
'/
SUB empty_CTOR CDECL(BYVAL O AS Options PTR)
  PRINT NL & __FUNCTION__
END SUB


/'* \brief Emitter called after the input got parsed and the parser got deleted
\param O The Options UDT calling this destructor

FIXME

\since 0.2.0
'/
SUB empty_DTOR CDECL(BYVAL O AS Options PTR)
  PRINT NL & __FUNCTION__ & NL
END SUB


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
    .CTOR_ = @empty_CTOR()
    .DTOR_ = @empty_DTOR()

    .Decl_ = @empty_declare()
    .Func_ = @empty_function()
    .Enum_ = @empty_enum()
    .Unio_ = @empty_union()
    .Clas_ = @empty_class()
    .Defi_ = @empty_define()
    .Incl_ = @empty_include()
    .Init_ = @empty_init()
   .Error_ = @empty_error()
   .Empty_ = @empty_empty()
    .Exit_ = @empty_exit()
  END WITH

  VAR a = INSTR(Par, !"\t-empty=")           ' get out parameter, if any
  IF a THEN
    a += 8
    VAR e = INSTR(a, Par, !"\t")
    IF 0 = e THEN e = LEN(Par) + 1
    PRINT "parameter is '" & MID(Par, a,  e - a) & "'"
    Par = LEFT(Par, a - 9) & MID(Par, e)
  END IF
END SUB
