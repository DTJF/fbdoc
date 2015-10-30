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

#INCLUDE ONCE "fb-doc_emitters.bi" ' declaration of the emitter interface
#INCLUDE ONCE "fb-doc_parser.bi"   ' declaration of the Parser members (not used here)


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
  PRINT __FUNCTION__
END SUB

'* \brief Emitter called after the input got parsed and the parser got deleted
SUB dll_DTOR CDECL(BYVAL P AS Parser PTR)
  PRINT __FUNCTION__
END SUB


' place the handlers in the emitter interface
WITH_NEW_EMITTER(EmitterTypes.EXTERNAL)
    .Nam = "Plugin"
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
