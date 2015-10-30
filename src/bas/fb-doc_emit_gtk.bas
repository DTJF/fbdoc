/'* \file fb-doc_emit_gtk.bas
\brief Emitter for gtk-doc templates

This file contains the emitter called "GtkDocTemplates", used as
default emitter to generate templates for the gtk-doc back-end in
`--geany-mode`.

The emitters returns all original source code unchanged. Additionally,
relevant constructs (statements or code blocks) get prepended by a multi line block
of documentation in Doxygen syntax. This works for

- blocks like `TYPE, UNION` and `ENUM`, and

- statements like `SUB`, `FUNCTION`, `VAR`, `DIM`, `CONST`, `COMMON`, `EXTERN`, `STATIC`, #`DEFINE` and #`MACRO`

The documentation template contains

- the name of the construct, appended by a colon
- the list of members with a leading @ character (parameters in case of a SUB FUNCTION or member variables in case of a block)
- the description area
- a footer

The placeholder `FIXME` is used to mark the positions where the
documentation context should get filled in. See section \ref
SubSecExaGtkdoc for an example.

'/

#INCLUDE ONCE "fb-doc_parser.bi"
#INCLUDE ONCE "fb-doc.bi"
#INCLUDE ONCE "fb-doc_options.bi"
#INCLUDE ONCE "fb-doc_version.bi"


CONST _
      SINCE = NL & NL & "Since: 0.0", _ '*< text added at each block end
  GTK_START =           "/'* ", _       '*< the start of a comment block
    GTK_END = NL & _
              NL & FIXME & _
                   SINCE & _
                   COMM_END             '*< the end of a comment block


/'* \brief Emitter to generate a name line
\param P the parser calling this emitter

Generate a name for a gtk-doc template. Used in lists (parameters or
variable declarations) or blocks (`ENUM, TYPE, UNION`). It generates a
line to document the variable and sends it to the output stream.

'/
SUB gtk_emit_Name CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    IF .NamTok THEN Code(NL & "@" & P->SubStr(P->NamTok) & ": " & FIXME)
  END WITH
END SUB


/'* \brief Emitter to generate a macro template
\param P the parser calling this emitter

This emitter gets called when the parser finds a macro (#`DEFINE` /
#`MACRO`). It generates a template to document the macro and sends it
to the output stream.

'/
SUB gtk_defi_ CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    cEmitSource(P, .StaTok[1])
    Code(GTK_START & .SubStr(.NamTok) & ":" & GTK_END)
  END WITH
END SUB


/'* \brief Emitter to generate a template for a declaration
\param P the parser calling this emitter

This emitter gets called when the parser is in a declaration (`VAR
DIM  CONST  COMMON  EXTERN  STATIC`). It generates a line for
each variable name and sends it (them) to the output stream.

'/
SUB gtk_decl_ CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    IF 0 = .ListCount THEN
      cEmitSource(P, .Tk1[1])
      Code(GTK_START & .SubStr(.NamTok) & ":")
    END IF

    IF 0 = .FunTok THEN gtk_emit_Name(P) _
                   ELSE IF .ParTok THEN .parseListPara(@gtk_emit_Name)
'&gtk_emit_Name(); // pseudo function call (helps Doxygen documenting the interface)

    IF *.CurTok > .TOK_EOS THEN EXIT SUB
    Code(GTK_END)

    IF 0 = .FunTok THEN EXIT SUB
    Code("'' " & PROJ_NAME & "-hint: consider to document the functions body instead." & NL)
  END WITH
END SUB


/'* \brief Emitter to generate a template for a function
\param P the parser calling this emitter

This emitter gets called when the parser finds a function (`SUB
FUNCTION  PROPERTY  CONSTRUCTOR  DESTRUCTOR`). It generates a
template to document the function and its parameter list and
sends it to the output stream.

'/
SUB gtk_func_ CDECL(BYVAL P AS Parser PTR) ' !!! ToDo member functions
  WITH *P '&Parser* P;
    VAR t = .TypTok
    cEmitSource(P, .StaTok[1])
    Code(GTK_START & .SubStr(.NamTok) & ":")
    IF .ParTok THEN .parseListPara(@gtk_emit_Name)
'&gtk_emit_Name(); // pseudo function call (helps Doxygen documenting the interface)

    Code( _
        NL & _
        NL & FIXME)
    IF t THEN Code( _
        NL & _
        NL & "Returns: " & FIXME)
    Code(    SINCE & _
             COMM_END)
  END WITH
END SUB


/'* \brief Emitter to generate a line for a block entry
\param P the parser calling this emitter

This emitter gets called when the parser is in a block (`TYPE  ENUM
UNION`). It generates a line for each member and sends it (them) to
the output stream.

'/
SUB gtk_emitBlockNames CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    SELECT CASE AS CONST *.Tk1
    CASE .TOK_PRIV, .TOK_PROT ': .SrcBgn = 0 ' !!! ToDo: hide private?
    CASE .TOK_PUBL            ': .SrcBgn = 1
    CASE .TOK_CLAS, .TOK_TYPE, .TOK_UNIO
      .parseBlockTyUn(@gtk_emitBlockNames)
'&gtk_emitBlockNames(); // pseudo function call (helps Doxygen documenting the interface)
    CASE .TOK_ENUM
      .parseBlockEnum(@gtk_emit_Name)
    CASE ELSE : IF 0 = .NamTok THEN EXIT SUB
      gtk_emit_Name(P)
    END SELECT
  END WITH
END SUB


/'* \brief Emitter to generate templates for blocks
\param P the parser calling this emitter

This emitter gets called when the parser finds a block (`TYPE  UNION
ENUM`). It generates a template to document the block with one line
for each member and sends it to the output stream.

'/
SUB gtk_Block CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    cEmitSource(P, .StaTok[1])
    Code( GTK_START)
    IF LEN(.BlockNam) THEN Code(.BlockNam & ":")

    SELECT CASE AS CONST *.Tk1
    CASE .TOK_ENUM : .parseBlockEnum(@gtk_emit_Name)
    CASE ELSE :      .parseBlockTyUn(@gtk_emitBlockNames)
    END SELECT
'&gtk_emit_Name(); gtk_emitBlockNames(); // pseudo function calls (help Doxygen documenting the interface)

    Code(GTK_END)
  END WITH
END SUB


/'* \brief Emitter for an empty Geany block
\param P the parser calling this emitter

This emitter gets called when an empty block gets send by Geany. It
generates a template to document the source file and sends it to the
output stream.

'/
SUB gtk_empty CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    Code(  GTK_START & _
           "SECTION: " & FIXME & _
      NL & "@short_description: " & FIXME & _
      NL & "@title: " & FIXME & _
      NL & "@section_id: " & FIXME & _
      NL & "@see_also: " & FIXME & _
      NL & "@stability: " & FIXME & _
      NL & "@include: " & FIXME & _
      NL & "@image: " & FIXME & _
           GTK_END & _
      NL)
  END WITH
END SUB


' place the handlers in the emitter interface
WITH_NEW_EMITTER(EmitterTypes.GTK_DOC_TEMPLATES)
     .Nam = "GtkDocTemplates"
  .Error_ = @c_error  '*< we use the standard error emitter here

   .Func_ = @gtk_func_
   .Decl_ = @gtk_decl_
   .Defi_ = @gtk_defi_
   .Enum_ = @gtk_Block
   .Unio_ = @gtk_Block
   .Clas_ = @gtk_Block
   .Init_ = @geany_init
   .Exit_ = @geany_exit
  .Empty_ = @gtk_empty
END WITH

