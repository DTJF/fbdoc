Introduction  {#PagIntro}
============
\tableofcontents

It's state-of-the-art in software development to write and edit the
documentation context inside the source code. The programmer(s) can
adapt the documentation on each improvement or bug fix at one place.
All work is done in the source file(s), the documentation is placed in
special comments in the source code so that the compiler doesn't see
them. Beside the software compiler tool-chain, which extracts
information for the CPU, an additional tool-chain is used to parse the
special comments and the related source code constructs to build the
documentation, avoiding redundand data in separate files and keeping
documentational comments to a minimal size.

Powerful tool-chains (back-ends) exist for several programming
languages (like C) to generate output in different formats (ie. like
*html*, *pdf*, *man-pages* and others). Unfortunatelly there is no such
tool-chain for FreeBASIC source code yet (effective 2012 April, 29).
The \Proj project is designed to close that gap.

Rather than being a complete tool-chain, \Proj works as a bridge
to existing C back-ends, since it's a lot of work to build and test
such a complete tool-chain for several output formats and keep it up to
date. Instead \Proj creates an intermediate format (similar to the FB
source code, but with C-like syntax) that can be used with existing,
well developed and tested C documenting back-ends. \Proj has been
tested with

- [gtk-doc](http://developer.gnome.org/gtk-doc-manual/stable/index.html)
- [Doxygen](http://www.doxygen.org/)

The later is used for this documentation (the text you're currently
reading).

The steps to generate a well documented project are
-# generate source code, compile and test
-# add documentational comments inside the source code and keep them up
   to date
-# run \Proj on the FreeBASIC source code to build a C-like
   intermediate format
-# run the C-back-end on the intemediate format to build the
   documentation output in one or more output formats (ie. \em html,
   \em pdf, \em manpage, ...)

In case of \ref SubDoxygen step 3 can get integrated in step 4.


# Executable # {#SecIntExe}

\Proj is a multi functional tool, supporting the complete process of
documenting any FB project. It gets shipped in this package as FB
source code and can get compiled on all operating systems supported by
the FB compiler, which is currently (effective 2015, Oct.)

- DOS
- windows
- LINUX / UNIX

The executable is a

- command line tool, that
- reads input (FB source code) from `STDIN` or file[s],
- parses related constructs,
- transforms the constructs to a specific format (depending on the choosen emitter), and
- writes that output to `STDOUT` or file[s].

Several run modi control where to get input from and where to write
output to. Several emitters (named in brackets) are available do
generate different kinds of output formats, in order to

- generate a C-like intermediate syntax (`C_Source`) for the C back-ends,
- generate templates for gtk-doc (`GtkDocTemplates`) or Doxygen (`DoxyTemplates`),
- generate a list of function names (`FunctionNames`), and
- generate correct source code listings for Doxygen output (`SyntaxHighLighting`).


## Run Modi vs. Emitters ## {#SubIntRmEm}

Each run mode has its default emitter. The following table shows the
mapping, rows are run modi, columns are emitters.

|                   | \ref SecEmmCSource | \ref SecEmmGtk | \ref SecEmmDoxy | \ref SecEmmLfn | \ref SecEmmSyntax |
| ----------------: | :----------------: | :------------: | :-------------: | :------------: | :---------------: |
| \ref SecModDef    |        DEF         |        +       |        +        |        +       |          +        |
| \ref SecModFile   |        DEF         |        +       |        +        |        +       |          +        |
| \ref SecModList   |         -          |        -       |        -        |       DEF      |          -        |
| \ref SecModSyntax |         -          |        -       |        -        |        -       |         DEF       |
| \ref SecModGeany  |         +          |       DEF      |        +        |        +       |          +        |

This default mapping can get overriden. Option \ref SecOptEmitter alows
to specify a custom setting. Beside the default setting (`DEF`) some
combinations are useful (`+`) and others are less useful (`-`).
Additionaly \Proj contains an interface for external emitters
(plugins), loaded at run time.


## Options vs. Run Modi and Emitters ## {#SubIntOptions}

Further options control the behaviour of the run mode (left justified)
or the emitter (right justified), or override the default emitter
setting (centered):

|  Run Mode         | \ref SecOptTree | \ref SecOptRecursiv | \ref SecOptOutpath || \ref SecOptEmitter || \ref SecOptDocom | \ref SecOptCStyle | \ref SecOptAsterix | Emitter            |
| ----------------: | :-------------- | :------------------ | :----------------- || :----------------: || ---------------: | ----------------: | -----------------: | :----------------- |
| \ref SecModDef    |        +        |          +          |         -          ||          *         ||        -         |         +         |          +         | \ref SecEmmCSource |
| \ref SecModFile   |        +        |          +          |         +          ||          *         ||        -         |         -         |          -         | \ref SecEmmGtk     |
| \ref SecModList   |        +        |          +          |         +          ||          *         ||        -         |         +         |          -         | \ref SecEmmDoxy    |
| \ref SecModSyntax |        +        |          +          |        ???         ||          *         ||        -         |         -         |          -         | \ref SecEmmLfn     |
| \ref SecModGeany  |        -        |          -          |         -          ||          *         ||        +         |         -         |          -         | \ref SecEmmSyntax  |

\Proj gets invoked in diffenrent manners,

- by the build system in a *Makefile*,
- by *geany* as a custom command,
- by *doxygen* as a filter, or
- manualy at the command line (special tasks).

In combination with emitter \ref SecEmmDoxy several extra functions are
available, in order to

- generate caller / callee graphs, and
- generate source code listings with correct syntax highlighting and hyperlinks

for output formats HTML, TEX, PDF and XML. Therefor \Proj also reads
and parses (partialy) the Doxygen configuration file, in order to
determine some related settings, folders and file patterns. Then it
operates (like Doxygen) on multiple files in one go.

## Data Flow chart ## {#SubIntData}

Here's a grafical overview on the \Proj data flow

![Data Flow Diagram for fbdoc](Overview.png)


# About this Text # {#SecIntSelf}

Finally some words about this documentation (the text you're currently
reading). It's self-hosted. \Proj is used to build its own
documentation in combination with the Doxygen back-end. This is, you
can

- find examples for a lot of topics by studying the files and folders
  in the \Proj package, and

- use the package files to experiment with \Proj (ie. for trial and error testing).

To be honest: in some cases this documentation may be a bit overloaded
and serve more information than necessary. But one of the reasons for
creating it is to demonstrate the features of \Proj in combination with
the Doxygen back-end. Therefor not all possibilities are used to reduce
the output to the bare essentials.

\note This documentation contains information on how to integrate \Proj
      in to the workflow of some C-style documentational tool-chains.
      It's not under the scope of this documentation to describe the
      usage of any (or all possible) tool-chain(s). Please refer to the
      respective manual(s) for further information.
