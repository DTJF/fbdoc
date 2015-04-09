Extending fb-doc  {#pageExtend}
================
\tableofcontents

fb-doc is an open source project and everybody is able to customize the
source code to his personal needs. Forking the project has the downside
that changes have to be redone in case of an update of the original
source.

fb-doc offers an alternative by its included interface for external
emitters (= plugins). An external emitter is a shared library that gets
loaded at runtime. The fb-doc project and the plugin are independend
projects. In worst case the external modul has to get recompiled when
the used headers were changed in fb-doc.

\section sectExtInternals Internals

Before we can extend fb-doc we should first understand some internals
on how it works and how it serves the handlers in the \ref EmitterIF.

fb-doc loads the input in to a parsers buffer \ref Parser::Buf. Then
the parser scans this context in two phases:

-# searching end of statements (new line or colon) and checking the
   start of the next statement
-# if this is a relevant construct it gets tokenized by \ref
   Parser::tokenize()

So only relevant constructs get checked in detail. The tokenizer
generates a list of tokens containing three INTEGER values for each
entry:

-# the token type \ref Parser::ParserTokens
-# the start of the token in the buffer (zero based) and
-# its length in bytes

The complete construct gets tokenized. This is a single line in case of
an \#`INCLUDE`, but also may be a bunch of lines in case of a block
(\#`MACRO  ENUM  TYPE  SUB  ...`). The tokenizer uses just a subset of
the FB keywords, check function \ref Parser::getToken() for details.
All other words from the source code get `TOK_WORD` in the list. White
spaces (like space, tab, caridge return, vertical tab, ...) and also
other context without a specifier in \ref Parser::ParserTokens like
numerical expressions get no entry in the token list. If this stuff is
needed for an emitter, the emitter has to do the parsing itself.

Then the parser checks the token list at the beginning of the construct.

In case of syntax errors the handler \ref EmitterIF::Error_() gets
called and the parser drops the construct. It's up to the emitter how
and where to output the error message or to parse the buggy construct
anyway.

In case of correct syntax the parser calls the matching emitter handler
in the \ref EmitterIF. Priviously, during the syntax check, some
pointers are set to the tokens in the list. The handler can use this
pointers and the tokenlist to generate its output.

These most important pointers are set always

- \ref Parser::StaTok the first (start) token of the construct (*ie*
  `TOK_SUB` *in* `SUB name ...` *and* `TOK_DECL` *in* `DECLARE SUB
  name ...`)
- \ref Parser::EndTok the last token in a construct (`TOK_EOS`, *check*
  \ref Parser::Buf[TokEnd[1]] <em>if it's a colon or a new line</em>)
- \ref Parser::Tk The current position of the parser.

More than 15 further pointers are used in the parsers check, see \ref
Parser for details. But not all pointers are set or reset for each
construct. Find further information the source code of these parser
functions:

|                 Function | Constructs                                                     |
| -----------------------: | :------------------------------------------------------------- |
| \ref Parser::FUNCTION_() | `SUB  FUNCTION  PROPERTY  OPERERATOR  CONSTRUTOR  DESTRUCTOR` |
| \ref Parser::VAR_()      | `DIM  REDIM  VAR  CONST  COMMON  EXTERN  EXPORT  STATIC`      |
| \ref Parser::TYPE_()     | `TYPE  CLASS`                                                 |
| \ref Parser::UNION_()    | `UNION`                                                       |
| \ref Parser::ENUM_()     | `ENUM`                                                        |
| \ref Parser::DECLARE_()  | `DECLARE`                                                     |
| \ref Parser::DEFINE_()   | \#`DEFINE`                                                    |
| \ref Parser::MACRO_()    | \#`MACRO`                                                     |
| \ref Parser::INCLUDE_()  | \#`INCLUDE`                                                   |

Some functions are available to parse advanced constructs like lists of
several variable declarations:

- \ref Parser::parseListNam evaluate a list of names
- \ref Parser::parseListNamTyp evaluate a list of declarations (name and type)
- \ref Parser::parseListPara evaluate a parameter list
- \ref Parser::parseBlockEnum 

As paratmeter these helpers get a function pointer to an \ref EmitFunc
handler. This handler gets called on each member of the list. Each
member is of the same type here (parameter, enumerator, variable, ...).

It's a little more complex when you have to handle a `TYPE` or
`UNION` block. The helper function for this to parse is:

- \ref Parser::parseBlockTyUn

and the passed handler function has to deal with several kinds of
context (like variable declarations or `function declarations). Also
these blocks may contain further nested blocks that may or may not get
parsed recursivly (depending on the purpose of the emitter). The
handler has to deal with all this kind of stuff. Find examples in any
\ref EmitterIF::Clas_ handler, ie in the handler \ref c_Block().


\section sectExtFlow Control Flow

When loading an external emitter plugin fb-doc first calls the function
\ref EmitterInit to receive the pointer to the external \ref EmitterIF.
This gets done right after parsing the command line and before a \ref
Parser UDT is created.

???


\section sectExtPlugin Example Plugin.bas

Enough of theory, let's switch to practise. The fb-doc parser calls
emitter functions via the emitter interface \ref EmitterIF, so it can
easy get extended by new emitters providing additional features (ie
support further C tools like <em>source navigator</em>).

The *plugins* folder of archive *fb-doc.zip* contains the file empty.bas.
This file is an example source code for an external emitter modul and
contains this further information:

\dontinclude empty.bas
\skipline This emitter generates
\until endverbatim

\note The entry in \ref EmitterIF::Nam of an external emitter plugin is
       not used in fb-doc, its free for any usage.
