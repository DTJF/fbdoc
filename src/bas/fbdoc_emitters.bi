/'* \file fbdoc_emitters.bi
\brief Header file for \ref EmitterIF

This file contains the declaration code for the EmitterIF.

'/


#IFDEF __FB_UNIX__
 CONST _
   SLASH = "/" _ '*< separator for folders (unix version)
    , NL = !"\n" '*< separator for lines (unix version)
'&/*
#ELSE
 CONST _
   SLASH = "\" _
    , NL = !"\r\n"
'&*/
#ENDIF


CONST _
COMM_END = NL & "'/" & NL, _ '*< the end of an FB comment block (in templates)
   TOFIX = "FIXME"                '*< the text to initialize entry fields (in templates)


/'* \brief Enumerators for in-build emitters

By default these five emitters are available in \Proj, the sixth entry
is for external plugins. The enumerators are used for default settings
in the Options class. The user can choose the emitter by option \ref
SecOptEmitter.

'/
ENUM EmitterTypes
  C_SOURCE          '*< emit pseudo C source (default and option `--file-mode`)
  FUNCTION_NAMES    '*< emit a list of function names (option `--list-mode`)
  GTK_DOC_TEMPLATES '*< emit templates for gtk-doc (option `--geany-mode gtk`)
  DOXYGEN_TEMPLATES '*< emit templates for Doxygen (option `--geany-mode doxy`)
  SYNTAX_REPAIR     '*< fix syntax highlighting of Doxygen listings (option `--syntax-mode`)
  EXTERNAL          '*< external emitter loaded as plugin
END ENUM

/'* \brief Forward declaration '/
TYPE AS Parser Parser_

/'* \brief Function type for EmitterIF to emit a piece of code
\param P The parser calling this handler '/
TYPE EmitFunc AS SUB CDECL(BYVAL P AS Parser_ PTR)

/'* \brief Forward declaration '/
TYPE AS Options Options_

/'* \brief Function type for EmitterIF `CTOR` and `DTOR`
\param O The Options calling the  `CTOR` or `DTOR` '/
TYPE TorFunc AS SUB CDECL(BYVAL O AS Options_ PTR)


'&typedef EmitterIF* EmitterIF_PTR; //!< Doxygen internal (ignore this).
/'* \brief The emitter interface

The emitters interface is a UDT containing function pointers. The
\ref Parser calls the matching function in the EmitterIF after
scanning a relevant construct. The emitter function extracts the
necessary information from the parser data, formats it as desired
and sends it to the output stream.

Only one emitter can be active at a time. Either one of the inbuild
\Proj emitters or an external emitter plugin can be choosen by option
\ref SecOptEmitter.

The function pointers get initialized with null pointers, resulting in
no output. The parser skips those constructs. In the `init_XYZ`
function the emitters fill some or all of the pointers by their
customized functions to create a specific output.

Since Doxygen doesn't support to generate documentation for such an
interface, it cannot create caller or callee graphs for the emitter
functions. But we use \Proj and can work-around this by creating
additional C output in form of member function. These functions are
unvisible for the FreeBASIC compiler, but get emitted to the pseudo C
source for the Doxygen back-end and produce the desired output for
the documentation.

'/
TYPE EmitterIF
' This is tricky code to make Doxygen document an interface:
'&/* Doxygen shouldn't parse this ...
  AS TorFunc _
     CTOR_ = 0 _
   , DTOR_ = 0
  AS EmitFunc _
     Init_ = 0 _
   , Decl_ = 0 _
   , Func_ = 0 _
   , Enum_ = 0 _
   , Unio_ = 0 _
   , Clas_ = 0 _
   , Defi_ = 0 _
   , Incl_ = 0 _
  , Error_ = 0 _
  , Empty_ = 0 _
   , Exit_ = 0
'&... but the following pseudo inline members instead */

'*Function called at program start-up (once)
'&inline void CTOR_ (void){c_CTOR();};

'*Function called at program end (once)
'&inline void DTOR_ (void){};

'*Function called before parsing a source file
'&inline void Init_ (void){c_Init(); geany_init(); synt_init();};

'*Function called after parsing the source file
'&inline void Exit_ (void){c_exit(); geany_exit(); synt_exit();};

'*Emitter for a declaration (`VAR  DIM  REDIM  CONST  COMMON  EXTERN  STATIC`)
'&inline void Decl_ (void){c_decl_(); gtk_decl_(); doxy_decl_(); lfn_decl_();};

'*Emitter for a function (`SUB  FUNCTION  PROPERTY  CONSTRUCTOR  DESTRUCTOR`)
'&inline void Func_ (void){c_func_(); gtk_func_(); doxy_func_(); lfn_func_(); synt_func_();};

'*Emitter for an `ENUM` block
'&inline void Enum_ (void){c_Block(); gtk_Block(); doxy_Block();};

'*Emitter for an `UNION` block
'&inline void Unio_ (void){c_Block(); gtk_Block(); doxy_Block(); lfn_class_();};

'*Emitter for a user defined structure (`TYPE  CLASS` blocks)
'&inline void Clas_ (void){c_Block(); gtk_Block(); doxy_Block(); lfn_class_();};

'*Emitter for a macro (#`DEFINE`, #`MACRO`)
'&inline void Defi_ (void){c_defi_(); gtk_defi_(); doxy_defi_();};

'*Emitter for includes (#`INCLUDE`)
'&inline void Incl_ (void){c_include(); lfn_include(); synt_incl();};

'*Emitter for an error message
'&inline void Error_ (void){emit_error();};

'*Emitter for an empty line in mode \ref SecModGeany
'&inline void Empty_ (void){gtk_empty(); doxy_empty(); synt_empty();};
END TYPE

'&/*
DECLARE SUB geany_init CDECL(BYVAL AS Parser_ PTR)
DECLARE SUB geany_exit CDECL(BYVAL AS Parser_ PTR)
DECLARE SUB emit_comments CDECL(BYVAL AS Parser_ PTR, BYVAL AS INTEGER)
DECLARE SUB emit_source CDECL(BYVAL AS Parser_ PTR, BYVAL AS INTEGER)
DECLARE SUB emit_error CDECL(BYVAL AS Parser_ PTR)
DECLARE SUB cNam CDECL(BYVAL AS Parser_ PTR)
DECLARE SUB CreateIni CDECL(BYVAL AS Parser_ PTR)
DECLARE SUB cppCreateFunction CDECL(BYVAL AS Parser_ PTR)
DECLARE SUB cCreateFunction CDECL(BYVAL AS Parser_ PTR)
DECLARE SUB cppCreateTypNam CDECL(BYVAL AS Parser_ PTR)
DECLARE SUB cCreateTypNam CDECL(BYVAL AS Parser_ PTR)
'&*/

