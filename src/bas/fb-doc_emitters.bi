/'* \file fb-doc_emitters.bi
\brief Header file for \ref EmitterIF

This file contains the declaration of the emitters interface, a UDT
(User Defined Type) that contains function pointers. The \ref
Parser calls the matching function in the active emitter after
scanning a relevant construct. The emitter function extracts the
necessary information from the parser data, formats it as desired
and sends it to the output stream.

'/


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

/'* \brief Forward declaration '/
TYPE AS Parser Parser_

/'* \brief Function to emit a piece of code
\param P the parser calling this handler '/
TYPE EmitFunc AS SUB CDECL(BYVAL AS Parser_ PTR)
'TYPE EmitFunc AS SUB CDECL(BYVAL AS Parser PTR)

DECLARE SUB null_emitter CDECL(BYVAL AS Parser_ PTR)


/'* \brief The emitter interface

The emitters interface is a UDT containing function pointers. The
\ref Parser calls the matching function in the active emitter after
scanning a relevant construct. The emitter function extracts the
necessary information from the parser data, formats it as desired
and sends it to the output stream.

Only one emitter can be active at a time. Either one of the four
inbuild fb-doc emitters or an external emitter plugin can be choosen
by option `--emitter`.

The function pointers get initialized with the null_emitter()
function (SUB), that creates no output at all. Each emitter modul can
replace one or more of the pointers by a customized function to
create a specific output.

Since Doxygen doesn't support to generate documentation for such an
interface, it cannot create caller or callee graphs for the emitter
functions. But we use fb-doc and can work-around this by creating
additional C output in form of member function. These functions are
unvisible for the FreeBasic compiler, but get emitted to the pseudo C
source for the Doxygen back-end and produce the desired output for
the documentation.

'/
TYPE EmitterIF
  AS STRING _
       Nam = ""  '*< the emitters name
' This is tricky code to make Doxygen document an interface:
'&/* Doxygen shouldn't parse this ...
  AS EmitFunc _
     Decl_ = @null_emitter _ '*< handler for `DECLARE`
   , Func_ = @null_emitter _ '*< handler for `FUNCTION  SUB  PROPERTY  CONSTRUCTOR  DESTRUCTOR`
   , Enum_ = @null_emitter _ '*< handler for `ENUM` blocks
   , Unio_ = @null_emitter _ '*< handler for `UNION` blocks
   , Clas_ = @null_emitter _ '*< handler for `TYPE  CLASS` blocks
   , Defi_ = @null_emitter _ '*< handler for \#`DEFINE` \#`MACRO`
   , Incl_ = @null_emitter _ '*< handler for \#`INCLUDE`
   , Init_ = @null_emitter _ '*< handler for start-up
  , Error_ = @null_emitter _ '*< handler for errors
  , Empty_ = @null_emitter _ '*< handler for empty Geany block
   , Exit_ = @null_emitter _ '*< handler for end-up
   , CTOR_ = @null_emitter _ '*< CONSTRUCTOR for emitter
   , DTOR_ = @null_emitter _ '*< DESTRUCTOR for emitter
'& ... but the following pseudo inline members instead */

'* function called before parsing a source code
'& inline void Init_ (void){c_Init(); geanyInit(); synt_init();};

'* emitter for a declaration (VAR / DIM / CONST / COMMON / EXTERN / STATIC)
'& inline void Decl_ (void){c_decl_(); gtk_decl_(); doxy_decl_(); callees_decl_();};

'* emitter for a function (SUB / FUNCTION / PROPERTY / CONSTRUCTOR / DESTRUCTOR)
'& inline void Func_ (void){c_func_(); gtk_func_(); doxy_func_(); callees_func_(); synt_func_();};

'* emitter for a ENUM block
'& inline void Enum_ (void){c_Block(); gtk_Block(); doxy_Block();};

'* emitter for a UNION block
'& inline void Unio_ (void){c_Block(); gtk_Block(); doxy_Block(); callees_class_();};

'* emitter for a struct (TYPE / CLASS block)
'& inline void Clas_ (void){c_Block(); gtk_Block(); doxy_Block(); callees_class_();};

'* emitter for a macro (\#`DEFINE` / \#`MACRO`)
'& inline void Defi_ (void){c_defi_(); gtk_defi_(); doxy_defi_();};

'* emitter for includes (\#`INCLUDE`)
'& inline void Incl_ (void){c_include(); callees_include(); synt_incl();};

'* emitter for an error message
'& inline void Error_ (void){c_error();};

'* emitter for an empty Geany block
'& inline void Empty_ (void){gtk_empty(); doxy_empty(); synt_empty();};

'* function called after parsing the source code
'& inline void Exit_ (void){c_exit(); geanyExit(); synt_exit();};

'* function called at program start-up (once)
'& inline void CTOR_ (void){synt_CTOR();};

'* function called at program end (once)
'& inline void DTOR_ (void){synt_DTOR();};
END TYPE

DECLARE SUB c_Block CDECL(BYVAL P AS Parser_ PTR)
DECLARE SUB cNam CDECL(BYVAL AS Parser_ PTR)
DECLARE SUB cEmitSource CDECL(BYVAL AS Parser_ PTR, BYVAL AS INTEGER)
DECLARE SUB cIni CDECL(BYVAL AS Parser_ PTR)
DECLARE SUB c_error CDECL(BYVAL AS Parser_ PTR)
DECLARE SUB geanyInit CDECL(BYVAL AS Parser_ PTR)
DECLARE SUB geanyExit CDECL(BYVAL AS Parser_ PTR)
DECLARE SUB cppCreateFunction CDECL(BYVAL AS Parser_ PTR)
DECLARE SUB cCreateFunction CDECL(BYVAL AS Parser_ PTR)
DECLARE SUB cppCreateTypNam CDECL(BYVAL AS Parser_ PTR)
DECLARE SUB cCreateTypNam CDECL(BYVAL AS Parser_ PTR)

'* the SHARED array for the emitter interfaces
COMMON SHARED AS EmitterIF PTR Emitters()
REDIM PRESERVE SHARED AS EmitterIF PTR Emitters(0 TO EmitterTypes.EXTERNAL)

/'* \brief Snippet to create a new \ref EmitterIF (for new customized emitter modules) '/
#MACRO WITH_NEW_EMITTER(_N_)
 Emitters(_N_) = NEW EmitterIF
 WITH *Emitters(_N_)
#ENDMACRO
