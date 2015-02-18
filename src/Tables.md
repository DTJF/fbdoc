Tables  {#pageTables}
======
\tableofcontents

This page contains some information on fb-doc in table format.

\section sectTabOverview Overview

fb-doc is a multi functional tool. While several \ref sectTabRunModi
specify where to get input from and where to write output to, several
\ref sectTabEmitters generate different kind of output. Here's a table
of all run modes against the inbuild emitters ("DEF" = default
configuration, "+" = useful combination, "-" = combination not useful).

| Emitter \ Run Mode | default | `--file-mode` | `--list-mode` | `--syntax-mode` | `--geany-mode` |
| -----------------: | :-----: | :-----------: | :-----------: | :-------------: | :------------: |
| C_Source           |   DEF   |      DEF      |       -       |        -        |        +       |
| GtkDocTemplates    |    +    |       +       |       -       |        -        |       DEF      |
| DoxygenTemplates   |    +    |       +       |       -       |        -        |        +       |
| FunctionNames      |    +    |       +       |      DEF      |        -        |        +       |
| SyntaxHighLighting |    +    |       +       |       -       |       DEF       |        +       |


\section sectTabOptions Options

The following table contains an overview of all fb-doc options. An
option either starts by a minus character followed by a single
character (short form) or by two minus characters followed by a word or
pair of words (LONG form). Both forms have the same meaning.

Some options expect an additional parameter. Each further word in the
command line (without the leading '-' character) gets interpreted as a
file name or pattern, see \ref pageOptionDetails for details.

<table>
<tr>
<th> Option <th> Parameter <th> Description
</th>
<tr>
<td> \ref subsectOptAsterix
<td> none
<td> The C_Source emitter generates lines in a multi line comment block
     with leading '* ' characters (gtk-doc style).
<tr>
<td> \ref subsectOptCstyle
<td> none
<td> The C_Source emitter generates types in real C syntax
     (instead of FB styled pseudo C syntax). Also used in emitter
     `DoxygenTemplates`.
<tr>
<td> \ref subsectOptEmitters
<td> Emitter name
<td> Customized emitter selection. fb-doc compares the parameter with
     the names of the internal emitters. In case of no match it tries to
     find and load an external with this name.
<tr>
<td> \ref subsectOptFileMode
<td> none
<td> Read FB source files and write output to similar named files
     (overriding existend, if any).
<tr>
<td> \ref subsectOptGeanyMode
<td> Emitter name
<td> Read input from STDIN and write to STDOUT. The parameter is optional.
<tr>
<td> \ref subsectOptHelp
<td> none
<td> Print the help text and stop.
<tr>
<td> \ref subsectOptListMode
<td> none
<td> Read FB source files and write output to file *fb-doc.lfn*.
<tr>
<td> \ref subsectOptOutpath
<td> path
<td> Set folder for file output.
<tr>
<td> \ref subsectOptRecursiv
<td> none
<td> Scan for input files in the working folder and all subfolders.
     Works only in combination with file patterns.
<tr>
<td> \ref subsectOptSyntaxMode
<td> none
<td> Scan a Doxyfile (or multiple) for its output and fix syntax
     highlighting.
<tr>
<td> \ref subsectOptTree
<td> none
<td> Follow the \#`INCLUDE` statements in the source tree (if
     possible -- not available in \ref subsectOptGeanyMode).
<tr>
<td> \ref subsectOptVersion
<td> none
<td> Print the version information and stop.
</table>

\note An empty command line makes fb-doc to output the help text 
       (as if option `--help` was given).


\section sectTabEmitters Inbuild Emitters

fb-doc has five inbuild emitters to generate different kinds of output.
All \ref sectOptModes set their default emitter, but you can customize
selection by option `--emitter` (`-e`) afterwards. Also this option is
used to choose an external emitter (plugin), see \ref pageExtend for
details.

\note Only one emitter can be in use at a time.

<table>
<tr>
<th> Name
<th> Default in Mode
<th> Function
</th>
<tr>
<td> \ref sectEmitterCSource
<td> `--file-mode` and default (Doxy-Filter)
<td> Translated FB source in intermediate format (C-like syntax). Use
     FB-like typenames (default) or real C syntax (option `--cstyle`).
     Prepend asterix in comment blocks (option `--asterix`).
<tr>
<td> \ref sectEmitterGtkTempl
<td> `--geany-mode`
<td> Emit source code and prepend documentation relevant constructs by
     templates for gtk-doc. Prefered usage in `--geany-mode`.
<tr>
<td> \ref sectEmitterDoxyTempl
<td> none
<td> Emit source code and prepend documentation relevant constructs by
     templates for Doxygen. Prefered usage in `--geany-mode`.
<tr>
<td> \ref sectEmitterLfn
<td> `--list-mode`
<td> Emit a list of all function names. Prefered usage in `--list-mode`
     to generate the file *fb-doc.lfn*.
<tr>
<td> \ref sectEmitterSyntax
<td> `--syntax-mode`
<td> Emit all source code surrounded by syntax highlighting tags. In
     `--syntax-mode` for Doxygen output in <em>*.html, *.tex</em> and
     <em>*.xml</em> files. In other modes *html* tags only.
</table>


\section sectTabRunModi Input / Output

Some options control the execution of fb-doc and the streams of input
and output data. The following table shows the relations between run
mode and input / output targets, See \ref sectOptModes for details.

<table>
<tr>
<th> Option
<th> Input
<th> Output
<th> Default Emitter
</th>
<tr>
<td> none (Doxy-Filter-Mode)
<td> one file
<td> standard out (STDOUT)
<td> C_Source
<tr>
<td> `-f` *or* `--file-mode`
<td> one file, a list of file names, a file pattern, a list of file patterns or all source files
<td> *.\em c and *.\em h files
<td> C_Source
<tr>
<td> `-g` *or* `--geany-mode`
<td> standard in (STDIN)
<td> standard out (STDOUT)
<td> GtkDocTemplates
<tr>
<td> `-l` *or* `--list-mode`
<td> files matching a pattern or all source files
<td> file \em fb-doc.lfn
<td> FunctionNames
<tr>
<td> `-h` *or* `--help`
<td> none
<td> standard out (STDOUT)
<td> none
<tr>
<td> `-v` *or* `--version`
<td> none
<td> standard out (STDOUT)
<td> none
</table>

\note the default mode is the Doxygen filter mode, since Doxygen 
       doesn't allow to send further options (directly).

\note Input and output channels are fixed to the listed options. 
       But you can apply changes, ie by specifying an other emitter 
       with option `--emitter` or input more than one file by walking 
       through the source tree with option `--tree`, ...

\note The modi `--help` (`-h`) and `--version` (`-v`) 
       are not related to any FB source. Instead of using an emitter 
       they create fixed output on standard output channel (STDOUT).

\note When more then one run mode is specified in the command line, 
       the latest is the dominant.


\section sectTabFileNames File Specifications

Any text in the command line not matching an option or its parameter 
gets interpreted as a file name or file pattern. They get added to a 
queue and fb-doc executes this queue in the given order. Depending on 
the file name and the run mode fb-doc operates in different ways:

<table>
<tr>
<th> Option (run-mode)
<th> no name
<th> exact name
<th> pattern
</th>
<tr>
<td> default
<td> print help text
<td> load file, emit output to STDOUT
<td> load all files matching the pattern, emit output to STDOUT
<tr>
<td> -f *or* --file-mode <td> load all *.\em bas and *.\em 
     bi files, emit output for each file to a *.\em c or *.\em h file 
    
<td> load this one file, scan the source tree and load each 
     \#`INCLUDE` file, emit output for each file to a *.\em c or *.\em
     h file
<td> load all files matching the pattern, emit output for each file 
     to a *.\em c or *.\em h file
<tr>
<td> `-g` *or* `--geany-mode`
<td> ignored
<td> ignored
<td> ignored
<tr>
<td> `-l` *or* `--list-mode` <td> load all *.\em bas and *.
     \em bi files, emit output to one file named \em fb-doc.lfn 
<td> load this one file, scan the source tree and load each 
     \#`INCLUDE` file, emit output to one file named \em fb-doc.lfn</td>
<td> load all files matching the pattern (or multiple patterns), emit
     output to one file named \em fb-doc.lfn</td>
</table>

\note A file name may be prepended by a relative or an absolute path.

\note File names or paths including a space character have to be 
       enclosed by single or double quotes.

\note Multiple file names get separated by a space character or by a 
       ; character.

\note You can list several file names and patterns in the command line.

\note A file name cannot start with a minus character and cannot 
       include single or double quote characters.

\note On UNIX like systems usually the shell (bash) expands the file
       patterns (fb-doc doesn't see the pattern, but gets the files
       list instead, so option `--recursive` doesn't work -- enclose
       the pattern by single or double quotes to hinder that).


\section sectTabInterForm Intermediate Format

The main trick to make a C parsers work on FB source is to transform
the declarations for variables and functions. FB syntax is full of
keywords for better human readability. Most of them are unknown for the
C parser (fbc-0.90 has more than 400 keyword, in C it's less than 50).

And the C parsers expect just a single word for a type declaration. But
when we pack all FB information in a single word type name, the C tool
can  handle this syntax and build the documentation output.

Therefor the FB keywords get mangled in to one single word, separated
by an underscore character. The following table contains some examples.
This mangling can get suppressed by option `--cstyle`, to get real C
types emitted. There's also some influences on the emitted TYPEs and
file names of include files.

|                                  FB source |            default                 | `--cstyle`            |
| -----------------------------------------: | :--------------------------------: | :-------------------- |
|                       `DIM AS INTEGER Nam` | `INTEGER Nam`                      | `int Nam`             |
|                       `DIM Nam AS INTEGER` | `INTEGER Nam`                      | `int Nam`             |
|                     `CONST Nam AS INTEGER` | `CONST_AS_INTEGER Nam`             | `const int Nam`       |
|                    `Extern Nam AS INTEGER` | `Extern_AS_INTEGER Nam`            | `extern int Nam`      |
| `DECLARE PROPERTY Cu.Tok() AS INTEGER PTR` | `PROPERTY_AS_INTEGER_PTR Cu.Tok()` | `int *Cu.Tok(void)`   |
|                `BYVAL Export_ AS EmitFunc` | `BYVAL_AS_EmitFunc Export_`        | `EmitFunc *Export_`   |
|                          `byref Z as byte` | `byref_as_byte Z`                  | `char *Z`             |
|                          `byval Z as byte` | `byval_as_byte Z`                  | `char Z`              |
|                    `TYPE Udt ... END TYPE` | `class Udt{ ... };`                | `typedef Udt{ ... };` |
|                  \#`INCLUDE ONCE "abc.bi"` | \#`include "abc.bi"`               | \#`include "abc.h"`   |
|                 \#`INCLUDE ONCE "xyz.bas"` | \#`include "xyz.bas"`              | \#`include "xyz.c"`   |


\section sectTabFiles Files

Here's an overview on the important files in the archive *fb-doc.zip*.

The folder *src* contains the source code files of fb-doc and some
additional text for this documentation in the file *Tutorial.bi*.

|        fb-doc/src | Function                                                             |
| ----------------: | :------------------------------------------------------------------- |
|        fb-doc.bas | The main source code to compile (\#`INCLUDE`s other files).          |
|       Tutorial.bi | The text of this Tutorial (no FB source in there).                   |
|        Plugin.bas | The source code for an external emitter (example).                   |
|  other *.bas *.bi | The source code.                                                     |

The folder *doc* is to build this documentation by executing Doxygen in
this folder, check its manual for details. If you want caller / callee
graphs in the documentation you have to install the *dot* tool from
the *GraphViz* package and you have to execute `fb-doc -l` before you
start doxygen. For repairing the syntax highlighting in the Doxygen
output run `fb-doc -s` afterwards in this folder.

|        fb-doc/doc | Function                                                             |
| ----------------: | :------------------------------------------------------------------- |
|          Doxyfile | A configuration file, controlling the Doxygen and fb-doc operations. |
| DoxygenLayout.xml | A configuration file, controlling the index of these *html* pages.   |
|        fb-doc.lfn | A list of function names generated by executing `fb-doc -l`.         |
