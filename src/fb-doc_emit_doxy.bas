/'* \file fb-doc_emit_doxy.bas
\brief Emitter for Doxygen templates

This file contains emitter functions for the \ref EmitterIF to 
generate template blocks for the Doxygen Back-end. It's designed to 
be used in Geany mode (see section \ref subsectExaDoxy for an example).

The emitters return all original source code unchanged. Additionally 
relevant lines (or code blocks) get prepended by a multi line block 
of documentation. This works for `SUB`s, `FUNCTION`s, `TYPE, UNION` and 
`ENUM` blocks, declarations (`VAR  DIM  CONST  COMMON  EXTERN  
STATIC`) and \#`DEFINE`s or \#`MACRO`s.

The block starts with the C declaration of the construct and a line 
for the brief description. Then the members are listed with leading 
param or var keyword and followed by a line for the brief 
description. The block ends by a `FIXME` text for the detailed 
description.

Since the prefered way to document variables with Doxygen is to 
write the comment behind the variable, this emitter is mostly 
helpful for documenting functions and their parameter lists.

When an empty line is send by Geany, the text of the \ref doxy_empty() 
function gets emitted. This is a comment block template to describe 
the source file.

'/


CONST _
   DOXY_START = NL & "/'* ", _ '*< the start of a comment block
     DOXY_END = NL & _
                NL & FIXME & _
                     COMM_END  '*< the end of a comment block


/'* \brief Emitter to generate a line for a parameter list entry
\param P the parser calling this emitter

This emitter gets called when the parser is in a parameter list of a 
function (`SUB  FUNCTION  PROPERTY  CONSTRUCTOR  DESTRUCTOR`). It 
generates a line for each parameter and sends it (them) to the 
output stream.

'/
SUB doxy_entryListPara CDECL(BYVAL P AS Parser PTR)
  WITH *P
    IF .NamTok THEN Code(NL & "\param " & .SubStr(.NamTok) & " " & FIXME)
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
  WITH *P
    VAR a = .StaTok[1], b = .ParTok, t = .TypTok
    cEmitSource(P, .StaTok[1])
    Code(     DOXY_START & "\fn ")
    OPT->CreateFunction(P)
    Code(NL & "\brief " & FIXME)
    IF b THEN .ParTok = b : .parseListPara(@doxy_entryListPara)
'& doxy_entryListPara(); // pseudo function call (helps Doxygen documenting the interface)
    IF t THEN Code(NL & "\returns " & FIXME)
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
  WITH *P
    IF 0 = .ListCount THEN
      cEmitSource(P, .StaTok[1])
      Code(DOXY_START)

      IF .FunTok THEN  Code("\fn ") _
                 ELSE  Code("\var ")

      SELECT CASE AS CONST *.StaTok
      CASE .TOK_CONS,.TOK_STAT, .TOK_COMM, .TOK_EXRN
        IF OPT->Types = OPT->C_STYLE THEN Code(LCASE(.SubStr(.StaTok)) & " ") _
                                     ELSE Code(      .SubStr(.StaTok)  & "_")
      CASE .TOK_TYPE : Code("typedef ")
        IF 0 = .FunTok ANDALSO .TypTok > .NamTok THEN Code("struct ")
      END SELECT
    END IF

    IF     .FunTok THEN
      VAR a = .SrcBgn, b = .ParTok, t = .TypTok
      OPT->CreateFunction(P)
      Code(NL & "\brief " & FIXME)
      IF b THEN .ParTok = b : .parseListPara(@doxy_entryListPara)
'& doxy_entryListPara(); // pseudo function call (helps Doxygen documenting the interface)
      IF t THEN Code(NL & "\returns: " & FIXME)
      Code(DOXY_END)
      .SrcBgn = a
      Code("'' " & PROG_NAME & "-hint: consider to document the functions body instead." & NL)
    ELSEIF .TypTok THEN
      OPT->CreateVariable(P)
      Code(NL & "\brief " & FIXME & DOXY_END)
    ELSE
      IF 0 = .ListCount THEN Code("VAR ")
                             Code(.SubStr(.NamTok))
      'IF .IniTok THEN        Code(" " & .VarIni)
      IF .IniTok THEN        cIni(P)
      Code(NL & "\brief " & FIXME & DOXY_END)
    END IF
  END WITH
END SUB


/'* \brief Emitter to generate a templates for a macro
\param P the parser calling this emitter

This emitter gets called when the parser finds a macro (\#`DEFINE`  
\#`MACRO`). It generates a template to document the macro and sends it 
to the output stream.

'/
SUB doxy_defi_ CDECL(BYVAL P AS Parser PTR)
  WITH *P
    cEmitSource(P, .StaTok[1])
    Code(  DOXY_START & "\def " & .SubStr(.NamTok) & _
      NL & "\brief " & FIXME & _
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
  WITH *P
    SELECT CASE AS CONST *.Tk1
    CASE .TOK_PRIV, .TOK_PROT ': .SrcBgn = 0 ' !!! ToDo: hide private?
    CASE .TOK_PUBL            ': .SrcBgn = 1
    CASE .TOK_CLAS, .TOK_TYPE, .TOK_UNIO
      .parseBlockTyUn(@doxy_emitBlockNames)
    CASE .TOK_ENUM
      .parseBlockEnum(@doxy_emitBlockNames)
    CASE ELSE : IF 0 = .NamTok THEN EXIT SUB
      Code(NL & "\var " & .BlockNam & "::" & .SubStr(.NamTok) &  " " & FIXME & _
           NL & "\brief " & FIXME)
    END SELECT
'& doxy_emitBlockNames(); // pseudo function call (helps Doxygen documenting the interface)
  END WITH
END SUB


/'* \brief Emitter to generate templates for blocks
\param P the parser calling this emitter

This emitter gets called when the parser finds a block (`TYPE  UNION 
ENUM`). It generates a template to document the block with one line 
for each member and sends it to the output stream.

'/
SUB doxy_Block CDECL(BYVAL P AS Parser PTR)
  WITH *P
    cEmitSource(P, .StaTok[1])
    SELECT CASE AS CONST *.Tk1
    CASE .TOK_ENUM
      Code(  DOXY_START & "\enum " & .BlockNam & _
        NL & "\brief " & FIXME & _
        NL & _
        NL & FIXME & _
        NL)
      .parseBlockEnum(@doxy_emitBlockNames)
    CASE .TOK_UNIO
      Code(  DOXY_START & "\union " & .BlockNam & _
        NL & "\brief " & FIXME & _
        NL & _
        NL & FIXME & _
        NL)
      .parseBlockTyUn(@doxy_emitBlockNames)
    CASE ELSE
      IF OPT->Types = OPT->FB_STYLE _
        THEN Code(DOXY_START & "\class ") _
        ELSE Code(DOXY_START & "\struct ")
      Code(  .BlockNam & _
        NL & "\brief " & FIXME & _
        NL & _
        NL & FIXME & _
        NL)
      .parseBlockTyUn(@doxy_emitBlockNames)
    END SELECT
'& doxy_emitBlockNames(); // pseudo function call (helps Doxygen documenting the interface)
    Code(COMM_END)
  END WITH
END SUB


/'* \brief Emitter for an empty Geany block
\param P the parser calling this emitter

This emitter gets called when an empty block gets send by Geany. It
generates a template to document the source file and sends it to the
output stream.

'/
SUB doxy_empty CDECL(BYVAL P AS Parser PTR)
  WITH *P
    Code(  DOXY_START & "\file " & FIXME & _
      NL & "\brief " & FIXME & _
           DOXY_END)
  END WITH
END SUB


WITH_NEW_EMITTER("DoxygenTemplates")
   .Error_ = @c_error '           we use the standard error emitter here

    .Func_ = @doxy_func_
    .Decl_ = @doxy_decl_
    .Defi_ = @doxy_defi_
    .Enum_ = @doxy_Block
    .Unio_ = @doxy_Block
    .Clas_ = @doxy_Block
    .Init_ = @geanyInit '        ... and the Geany init / exit functions
    .Exit_ = @geanyExit
   .Empty_ = @doxy_empty
END WITH

