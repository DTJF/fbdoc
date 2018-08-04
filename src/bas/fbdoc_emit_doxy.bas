/'* \file fbdoc_emit_doxy.bas
\brief Emitter for Doxygen templates

This file contains the emitter \ref SecEmmDoxy, which isn't use by any
run mode as default. It's used to generate templates for the Doxygen
back-end in mode \ref SecModGeany.

The emitters returns all original source code unchanged. Additionally,
relevant constructs (statements or code blocks) get prepended by a multi line block
of documentation in Doxygen syntax. This works for

- blocks like `TYPE, UNION` and `ENUM`, and

- statements like `SUB`, `FUNCTION`, `VAR`, `DIM`, `CONST`, `COMMON`, `EXTERN`, `STATIC`, #`DEFINE` and #`MACRO`

The documentation template contains

- the C declaration of the construct
- a line for the brief description
- the list of members (including keyword like `param` or `var`)
- the description area
- a footer

The placeholder `FIXME` is used to mark the positions where the
documentation context should get filled in. See section \ref
SubDoxygen for an example.

\note Since the prefered way to document with Doxygen is to write the
      comment in front of or behind a statement, this emitter is mostly
      helpful for documenting functions and their parameter lists.

'/

#INCLUDE ONCE "fbdoc_options.bi"
#INCLUDE ONCE "fbdoc_version.bi"


CONST _
   DOXY_START = NL & "/'* ", _ '*< the start of a comment block
     DOXY_END = NL _
              & NL & TOFIX _
              & NL _
              & NL & "\since " & TOFIX _
                   & COMM_END  '*< the end of a comment block


/'* \brief Emitter to generate a line for a parameter list entry
\param P the parser calling this emitter

This emitter gets called when the parser is in a parameter list of a
function (`SUB  FUNCTION  PROPERTY  CONSTRUCTOR  DESTRUCTOR`). It
generates a line for each parameter and sends it (them) to the
output stream.

'/
SUB doxy_entryListPara CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    IF .NamTok THEN Code(NL & "\param " & .SubStr(.NamTok) & " " & TOFIX)
  END WITH
END SUB


/'* \brief Emitter to generate a template for a function
\param P the parser calling this emitter

This emitter gets called when the parser finds a function (`SUB
FUNCTION  PROPERTY  CONSTRUCTOR  DESTRUCTOR`). It generates a
template to document the function and its parameter list and
sends it to the output stream.

'/
SUB doxy_func_ CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    VAR a = .StaTok[1], b = .ParTok, t = .TypTok
    emit_source(P, .StaTok[1])
    Code(     DOXY_START & "\fn ")
    OPT->CreateFunction(P)
    Code(NL & "\brief " & TOFIX)
    IF b THEN .ParTok = b : .parseListPara(@doxy_entryListPara())
    IF t THEN Code(NL & "\returns " & TOFIX)
    Code(DOXY_END)
    .SrcBgn = a
  END WITH
END SUB


/'* \brief Emitter to generate a template for a declaration
\param P the parser calling this emitter

This emitter gets called when the parser is in a declaration (`VAR
DIM  CONST  COMMON  EXTERN  STATIC`). It generates a line for
each variable name and sends it (them) to the output stream.

'/
SUB doxy_decl_ CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    IF 0 = .ListCount THEN
      emit_source(P, .StaTok[1])
      Code(DOXY_START)

      IF .FunTok THEN  Code("\fn ") _
                 ELSE  Code("\var ")

      SELECT CASE AS CONST *.StaTok
      CASE .TOK_CONS, .TOK_STAT, .TOK_COMM, .TOK_EXRN
        IF OPT->Types = OPT->C_STYLE THEN Code(LCASE(.SubStr(.StaTok)) & " ") _
                                     ELSE Code(      .SubStr(.StaTok)  & "_")
      CASE .TOK_TYPE : Code("typedef ")
        IF 0 = .FunTok ANDALSO .TypTok > .NamTok THEN Code("struct ")
      END SELECT
    END IF

    IF     .FunTok THEN
      VAR a = .SrcBgn, b = .ParTok, t = .TypTok
      OPT->CreateFunction(P)
      Code(NL & "\brief " & TOFIX)
      IF b THEN .ParTok = b : .parseListPara(@doxy_entryListPara())
      IF t THEN Code(NL & "\returns: " & TOFIX)
      Code(DOXY_END)
      .SrcBgn = a
      Code("'' " & PROJ_NAME & "-hint: consider to document the functions body instead." & NL)
    ELSEIF .TypTok THEN
      OPT->CreateVariable(P)
      Code(NL & "\brief " & TOFIX & DOXY_END)
    ELSE
      IF 0 = .ListCount THEN Code("VAR ")
                             Code(.SubStr(.NamTok))
      IF .IniTok THEN        CreateIni(P)
      Code(NL & "\brief " & TOFIX _
              & DOXY_END)
    END IF
  END WITH
END SUB


/'* \brief Emitter to generate a templates for a macro
\param P the parser calling this emitter

This emitter gets called when the parser finds a macro (#`DEFINE`
#`MACRO`). It generates a template to document the macro and sends it
to the output stream.

'/
SUB doxy_defi_ CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    emit_source(P, .StaTok[1])
    Code(  DOXY_START & "\def " & .SubStr(.NamTok) & _
      NL & "\brief " & TOFIX & _
           DOXY_END)
  END WITH
END SUB


/'* \brief Emitter to generate a line for a block entry
\param P the parser calling this emitter

This emitter gets called when the parser is in a block (`TYPE  ENUM
UNION`). It generates a line for each member and sends it (them) to
the output stream.

'/
SUB doxy_emitBlockNames CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    SELECT CASE AS CONST *.Tk1
    CASE .TOK_PRIV, .TOK_PROT ': .SrcBgn = 0 ' !!! ToDo: hide private?
    CASE .TOK_PUBL            ': .SrcBgn = 1
    CASE .TOK_CLAS, .TOK_TYPE, .TOK_UNIO
      .parseBlockTyUn(@doxy_emitBlockNames())
    CASE .TOK_ENUM
      .parseBlockEnum(@doxy_emitBlockNames())
    CASE ELSE : IF 0 = .NamTok THEN EXIT SUB
      Code(NL & "\var " & .BlockNam & "::" & .SubStr(.NamTok) &  " " & TOFIX & _
           NL & "\brief " & TOFIX)
    END SELECT
  END WITH
END SUB


/'* \brief Emitter to generate templates for blocks
\param P the parser calling this emitter

This emitter gets called when the parser finds a block (`TYPE  UNION
ENUM`). It generates a template to document the block with one line
for each member and sends it to the output stream.

'/
SUB doxy_Block CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    emit_source(P, .StaTok[1])
    SELECT CASE AS CONST *.Tk1
    CASE .TOK_ENUM
      Code(  DOXY_START & "\enum " & .BlockNam & _
        NL & "\brief " & TOFIX _
           & DOXY_END)
      .parseBlockEnum(@doxy_emitBlockNames())
    CASE .TOK_UNIO
      Code(  DOXY_START & "\union " & .BlockNam & _
        NL & "\brief " & TOFIX _
           & DOXY_END)
      .parseBlockTyUn(@doxy_emitBlockNames())
    CASE ELSE
      IF OPT->Types = OPT->FB_STYLE _
        THEN Code(DOXY_START & "\class ") _
        ELSE Code(DOXY_START & "\struct ")
      Code(  .BlockNam & _
        NL & "\brief " & TOFIX _
           & DOXY_END)
      .parseBlockTyUn(@doxy_emitBlockNames())
    END SELECT
    Code(NL & COMM_END)
  END WITH
END SUB


/'* \brief Emitter for an empty Geany block
\param P the parser calling this emitter

This emitter gets called when an empty block gets send by Geany. It
generates a template to document the source file and sends it to the
output stream.

'/
SUB doxy_empty CDECL(BYVAL P AS Parser PTR)
  WITH *P '&Parser* P;
    Code(  DOXY_START & "\file " & TOFIX & _
      NL & "\brief " & TOFIX & _
           DOXY_END)
  END WITH
END SUB



/'* \brief Initialize the `DoxygenTemplates` EmitterIF
\param Emi The EmitterIF to initialize

FIXME

\since 0.4.0
'/
SUB init_doxy(BYVAL Emi AS EmitterIF PTR)
  WITH *Emi
    .Error_ = @emit_error() '           we use the standard error emitter here

     .Func_ = @doxy_func_()
     .Decl_ = @doxy_decl_()
     .Defi_ = @doxy_defi_()
     .Enum_ = @doxy_Block()
     .Unio_ = @doxy_Block()
     .Clas_ = @doxy_Block()
     .Init_ = @geany_init() '       ... and the Geany init / exit functions
     .Exit_ = @geany_exit()
    .Empty_ = @doxy_empty()
  END WITH
END SUB

