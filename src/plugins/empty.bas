/'* \file empty.bas
\brief Example code for an empty external emitter

This file contains example source code for an external emitter. It
isn't used in the \Proj source tree. See \ref PagExtend for details.

This emitter generates a list of the function names called via the
emitter interface. So when you input some FB source to \Proj and use
this emitter, the output is a list of the \Proj functions called by the
parser for this input.

Before you can use this emitter, you have to compile it first, using
the command

\code fbc -dylib Plugin.bas \endcode

The result is a binary called

  - libdll_emitter.so  (LINUX)
  - libdll_emitter.dll (windows)

There's no way to compile or use an external emitter on DOS since
DOS doesn't support dynamic linked libraries.

To use this emitter in \Proj set its name (without the suffix .bas)
just as an internal name (,so don't name your customized emitter
similar to an internal emitter name).

Ie. the emitter output for the context of this file can be viewed in
the terminal by
~~~{.sh}
./fb-doc --emitter "Plugin" Plugin.bas
~~~
(LINUX example) and will generate the following output:

\verbatim
DLL_INIT
DLL_INCLUDE
DLL_INCLUDE
DLL_FUNCTION
DLL_FUNCTION
DLL_FUNCTION
DLL_FUNCTION
DLL_FUNCTION
DLL_FUNCTION
DLL_FUNCTION
DLL_FUNCTION
DLL_FUNCTION
DLL_FUNCTION
DLL_FUNCTION
DLL_FUNCTION
DLL_EXIT
\endverbatim

'/

#INCLUDE ONCE "../bas/fb-doc_parser.bi"   ' declaration of the Parser members (not used here)


'* \brief Emitter called when the Parser is at a variable declaration
SUB dll_declare CDECL(BYVAL P AS Parser PTR)
  Code(NL & __FUNCTION__ & ": " & P->LineNo & " " & P->SubStr(P->NamTok))
END SUB

'* \brief Emitter called when the Parser is on top of a function body
SUB dll_function CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    VAR nam = .SubStr(IIF(.NamTok[3] = .TOK_DOT, .NamTok + 6, .NamTok))
    Code(NL & __FUNCTION__ & ": " & .LineNo & " " & nam)
  END WITH
END SUB

'* \brief Emitter called when the Parser is at the start of a ENUM block
SUB dll_enum CDECL(BYVAL P AS Parser PTR)
  Code(NL & __FUNCTION__)
END SUB

'* \brief Emitter called when the Parser is at the start of a UNION block
SUB dll_union CDECL(BYVAL P AS Parser PTR)
  Code(NL & __FUNCTION__)
END SUB

'* \brief Emitter called when the Parser is at the start of a TYPE block
SUB dll_class CDECL(BYVAL P AS Parser PTR)
  Code(NL & __FUNCTION__)
END SUB

'* \brief Emitter called when the Parser is at an #`DEFINE` line or at the start of a #`MACRO`
SUB dll_define CDECL(BYVAL P AS Parser PTR)
  Code(NL & __FUNCTION__)
END SUB

'* \brief Emitter called when the Parser is at an #`INCLUDE` line
SUB dll_include CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    VAR nam = .SubStr(.NamTok)
    Code(NL & __FUNCTION__ & ": " & .LineNo & " " & nam)
    IF .InTree THEN .Include(TRIM(nam, """"))
  END WITH
END SUB

'* \brief Emitter called before the input gets parsed
SUB dll_init CDECL(BYVAL P AS Parser PTR)
  Code(NL & __FUNCTION__)
END SUB

'* \brief Emitter called for an error
SUB dll_error CDECL(BYVAL P AS Parser PTR)
  Code(NL & __FUNCTION__)
END SUB

'* \brief Emitter called for an empty block in mode `--geany-mode`
SUB dll_empty CDECL(BYVAL P AS Parser PTR)
  Code(NL & __FUNCTION__)
END SUB

'* \brief Emitter called after the input got parsed
SUB dll_exit CDECL(BYVAL P AS Parser PTR)
  Code(NL & __FUNCTION__ & NL)
END SUB

'* \brief Emitter called before the parser gets created and the input gets parsed
SUB dll_CTOR CDECL(BYVAL P AS Parser PTR)
  Code(NL & __FUNCTION__)
END SUB

'* \brief Emitter called after the input got parsed and the parser got deleted
SUB dll_DTOR CDECL(BYVAL P AS Parser PTR)
  Code(NL & __FUNCTION__)
END SUB


/'* \brief Initialize the emitter interface
\param Emi The newly created EmitterIF to fill with our callbacks
\param Par Additional command line parameters, not parsed by \Proj

When the user required to load this plugin by option `-e "empty"`, this
SUB gets called to initialize the EmitterIF. Here, all default
callbacks (= null_emitter() ) get replaced by custom functions. Here
those functions just report all the \Proj function calls, in order to
make the parsing process transparent.

The second parameter `Par` is a list of all command line parameters
which are unknown to \Proj. Those options get collected in a string,
separated by tabulators (`!"\n"), and starting by a tabulator. This SUB
extracts and avaluates the known parameters. When this string isn't
empty at the end of this SUB, the calling \Proj program stops execution
by an `unknown options` error.

\since 0.4.0
'/
SUB EmitterInit CDECL(BYVAL Emi AS EmitterIF PTR, BYREF Par AS STRING) EXPORT
  WITH *Emi
    .Decl_ = @dll_declare
    .Func_ = @dll_function
    .Enum_ = @dll_enum
    .Unio_ = @dll_union
    .Clas_ = @dll_class
    .Defi_ = @dll_define
    .Incl_ = @dll_include
    .Init_ = @dll_init
   .Error_ = @dll_error
   .Empty_ = @dll_empty
    .Exit_ = @dll_exit
    .CTOR_ = @dll_CTOR
    .DTOR_ = @dll_DTOR
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
