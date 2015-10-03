Emitters in Detail  {#PagEmitter}
==================
\tableofcontents


C_Source  {#SecEmmCSource}
========

| Emitter                 | C_Source                                        |
| ----------------------: | :---------------------------------------------- |
| `-a` *or* `--asterix`   | prepend "* " to each line in multi line comment |
| `-c` *or* `--cstyle`    | emit real C types, \#`include "*.c" "*.h"`      |
| `-t` *or* `--tree`      | follow source tree \#`INCLUDES`                 |

This emitter translates its input in to the intermediate format,
usually used by the C back-end. It's not a real compiler, just the
documentation relevant constructs get emitted. This is declarations and
a few further constructs.

|            Construct | Keywords                                               |
| -------------------: | :----------------------------------------------------- |
|            variables | `VAR  DIM  CONST  COMMON  EXTERN  STATIC`              |
|               blocks | `ENUN  UNION  TYPE  CLASS`                             |
| forward declarations | `TYPE  TYPE alias`                                     |
|            functions | `SUB  FUNCTION  PORPERTY  CONSTRUCTOR  DESTRUCTOR`     |
|               macros | \#`DEFINE`  \#`MACRO`                                  |

It doesn't handle SCOPE nor NAMESPACE blocks yet.

The output contains translated C source code and the special comments
for the FB source. Everything is at the same line number and in the
original order.

The translation can either contain type declarations in the mangeled
(FB-like) style or real types in C syntax. The first is default and the
second is set by option `--cstyle`. This option also influences the
translation of `TYPE`s (`class{public:` *or* `typedef struct{`),
`CONSTRUCTOR`s and `DESTRUCTOR`s (`name::name()` *or* `void()`) and the
names in \#`include` statements (original *or* suffix `".c" ".h"`).

Option `--asterix` makes fb-doc to start each line in a special multi
line comment block by the characters '* '. This is mandatory for the
gtk-doc back-end. Adding these characters to the FB source code has two
downsides: it blows up the code size and these characters complicate
automatic formating of the context in an editor.

The emitter is designed to be used in standard mode (Doxygen filter)
and in mode `--file-mode` to generate the intermediate format for the
back-end.

Furthermore the output can be helpful when you intend to write a
library in FB and later use this library in a C project. This emitter
can translate the FB headers to real C headers by using option
`--cstyle`. You just have to translate the \#`define` lines manually.


GtkDoc Templates  {#SecEmmGtk}
================

| Emitter                           | GtkDocTemplates                   |
| --------------------------------: | :-------------------------------- |
| -a *or* --asterix                 |                                   |
|                                   |                                   |
|                                   |                                   |

This emitter is designed to generate templates for documenting FB code
with gtk-doc tool chain (back-end). It generates output containing the
all original code. Documentation relevant parts of the code get
prepended by a template for gtk-doc. This template contains the symbol
names extracted from the source code and `FIXME` marks for the
individual text fragments.

The emitter is designed to be used in mode `--geany-mode`. Installed as
a custom command in Geany IDE it receives selected source code and
returns it with one or more the templates added.

It doesn't really make sense to use this emitter in modes `--file-mode`,
`--list-mode` or `--syntax-mode`, since their output files are used for
other context.

Further usage may be generating templates for a complete file


Doxygen Templages  {#SecEmmDoxy}
=================

| Emitter                           | DoxygenTemplates                  |
| --------------------------------: | :-------------------------------- |
| -a *or* --asterix                 | no effect                         |
| -                                 |                                   |
|                                   |                                   |

This emitter is designed to

The emitter is designed to be used in mode `--`

It doesn't really make sense to use this emitter in modes `--file-mode`,
`--list-mode` or `--syntax-mode`, since their output files are used for
other context.

Further usage may be


FunctionNames  {#SecEmmLfn}
=============

| Emitter                 | FunctionNames                   |
| ----------------------: | :------------------------------ |
| `-a` *or* `--asterix`   | no effect                       |
| `-c` *or* `--cstyle`    | no effect                       |
| `-t` *or* `--tree`      | follow source tree \#`INCLUDES` |

This emitter outputs the function names from FB source code. It emitts
a list with one name per line for `SUB`s, `FUNCTION`s and `PROPERTY`s.
In case of an UDT member the UDT name also gets emitted.

It is designed to generate the list of function names file *fb-doc.lfn*
in mode `--list_mode`. This file is used for caller / callee graphs and
gets read by the emitter `C_Source`. In this mode the output in the file
starts with a header line and the list begins in the second line. The
list contains line ends in UNIX style (no caridge return, just a line
feed). This must not be changed!

In other run modes no header line gets emitted. The list starts with
the first function name found in the input. There is no separator
between the output from different input files. But when used in mode
`--file-mode` the output is one file per input file.


SyntaxHighLighting  {#SecEmmSyntax}
===================

| Emitter                 | SyntaxHighLighting              |
| ----------------------: | :------------------------------ |
| `-a` *or* `--asterix`   | no effect                       |
| `-c` *or* `--cstyle`    | no effect                       |
| `-t` *or* `--tree`      | follow source tree \#`INCLUDES` |

This emitter outputs the the original source code, wherein the FB
syntax is highlighted by enclosing tags. In mode `--syntax-mode`
three different tag formats can get generated

|      file type | tags in `--syntax-mode`                   |
| -------------: | :---------------------------------------- |
| Html (default) | `<span class="...">CODE</span>`           |
|          LaTeX | `\textcolor{...}{CODE}`                |
|            XML | `<highlight class="...">CODE</highlight>` |

In other run modes the emitter generates Html output.

Each line starts with a line number. All input gets separated in to
these categories (replacing the '...' in the above tag format examples)

|     style class | used for                                                            |
| --------------: | :------------------------------------------------------------------ |
|          `line` | normal code no special highlighting                                 |
|       `keyword` | FB keywords like `FOR, NEXT, DECLARE, ...`                          |
|   `keywordtype` | inbuild types like `UBYTE, INTEGER, ...` and also `BYREF, AS, ...`  |
|  `preprocessor` | preprocessor statements like \#`if`, \#`INCLUDE`, ...               |
| `stringliteral` | string literals like `"Hello world"`                                |
|       `comment` | comments (multi line /&apos; ... &apos;/ or single line &apos; ...) |
|        `lineno` | style class for the line number (starting at 1)                     |

Doxygen supports a further style class named `keywordflow`, meant to be
used for keywords like `WHILE ... WEND`, `DO ...LOOP` and so on. This
doesn't work for FB code since some keywords are used in different
meanings (ie `FOR ... next` and also `open(... FOR input)`). So fb-doc
doesn't use this style class.

This emitter is designed to be used in mode `--syntax_mode` to repair
the syntax hightlighting in Doxygen output. In this mode fb-doc reads
the original Doxygen output files and extracts the links to the
documentation. The header and footer of the original file get copied to
the new file and the listing section get filled with fresh code,
including the highlighting tags and also the links from the
original Doxygen output.

In other modes like `--geany-mode` or `--list-mode` the emitter works
in its default mode. Its output contains plain Html code using the
above mentioned style tags.

Line numbers start at one, in mode `--file-mode` for each file. In
other modes when the output is generated from several input files, the
line numbers increase continuously.

To use the output in any Html page it needs a header (or file)
defining the above mentioned style classes. As an example check any
Doxygen output (ie the Html tree of this documentation and the file
*fb-doc.css*).
