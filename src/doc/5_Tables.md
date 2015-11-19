Tables  {#PagTables}
======
\tableofcontents

This chapter contains some information on \Proj in table format.

Overview  {#SecTabOverview}
========

\Proj is a multi functional tool, controlled by command line
parameters. Several run modi specify where to get input from and where
to send output at. Different emitters specify the context of the
output. The following table shows all run modi (lines) and inbuild
emitters (columns). Each run mode has its default emitter (DEF), but
can also get combined with a customized emitter in useful (+) and less
useful (-) combinations.

|                    | \ref SecEmmCSource | \ref SecEmmGtk | \ref SecEmmDoxy | \ref SecEmmLfn | \ref SecEmmSyntax |
| -----------------: | :----------------: | :------------: | :-------------: | :------------: | :---------------: |
| \ref SecModDefault |        DEF         |        +       |        +        |        +       |          +        |
| \ref SecModFile    |        DEF         |        +       |        +        |        +       |          +        |
| \ref SecModList    |         -          |        -       |        -        |       DEF      |          -        |
| \ref SecModSyntax  |         -          |        -       |        -        |        -       |         DEF       |
| \ref SecModGeany   |         +          |       DEF      |        +        |        +       |          +        |

Additional options modify the behaviour of the run modi or specific
emitters. The next table contains those operational options (columns).

specify details on how to handle input and output
(mode options) and how to generate the output (emitter options).

|  Run Mode          | \ref SecOptTree | \ref SecOptRecursiv | \ref SecOptPath || \ref SecOptEmitter || \ref SecOptDocom | \ref SecOptCStyle | \ref SecOptAsterix | Emitter            |
| -----------------: | :-------------- | :------------------ | :-------------- || :----------------: || ---------------: | ----------------: | -----------------: | :----------------- |
| \ref SecModDefault |        +        |          -          |         -       ||          *         ||        -         |         +         |          +         | \ref SecEmmCSource |
| \ref SecModFile    |        -        |         ???         |         +       ||          *         ||        -         |         -         |          -         | \ref SecEmmGtk     |
| \ref SecModList    |        -        |         ???         |         +       ||          *         ||        -         |         +         |          -         | \ref SecEmmDoxy    |
| \ref SecModSyntax  |        +        |         ???         |        ???      ||          *         ||        -         |         -         |          -         | \ref SecEmmLfn     |
| \ref SecModGeany   |       ???       |          -          |         -       ||          *         ||        +         |         -         |          -         | \ref SecEmmSyntax  |



Emitter  {#SecTabEmitter}
=======

\Proj has five inbuild emitters to generate different kinds of output.
By setting a run mode (\ref SecOptModes) a default emitter gets
specified. Use option `--emitter` (`-e`) after the run mode option to
override the default setting. See chapter \ref PagEmitter for details.

\note Only one emitter can be in use at a time.

<table>
<tr>
<th> Name
<th> Default in Mode
<th> Function
</th>
<tr>
<td> \ref SecEmmCSource
<td> default mode (Doxy-Filter) and `--file-mode`
<td> Translate FB source and documentational comments in intermediate format.
<tr>
<td> \ref SecEmmGtk
<td> `--geany-mode`
<td> Emit original source code and prepend documentation relevant
     constructs by templates for gtk-doc. Prefered usage in
     `--geany-mode`.
<tr>
<td> \ref SecEmmDoxy
<td> none
<td> Emit original source code and prepend documentation relevant
     constructs by templates for Doxygen. Prefered usage in
     `--geany-mode`.
<tr>
<td> \ref SecEmmLfn
<td> `--list-mode`
<td> Emit a list of all function names. Prefered usage in `--list-mode`
     to generate the file *fb-doc.lfn*.
<tr>
<td> \ref SecEmmSyntax
<td> `--syntax-mode`
<td> Emit all source code encapsulated by syntax highlighting tags.
     Prefered usage in `--syntax-mode` (for Doxygen output in
     <em>*.html, *.tex</em> and <em>*.xml</em> files; in other run
     modes *html* tags).
</table>


Run Modi  {#SecTabRunModi}
========

The data flow, that is where to get input from and where to write
output at, gets specified by the run mode. The following table shows
the relations between run mode and input / output targets, See \ref
SecOptModes for details.

<table>
<tr>
<th> Option
<th> Default Emitter
<th> Input
<th> Output
</th>
<tr>
<td> none (Doxy-Filter-Mode)
<td> \ref SecEmmCSource
<td> one file
<td> stream to STDOUT
<tr>
<td> \ref SubSecOptFile
<td> \ref SecEmmCSource
<td> controlled by file specification[s]
<td> *.\em c and *.\em h files
<tr>
<td> \ref SubSecOptGeany
<td> \ref SecEmmGtk
<td> stream from STDIN
<td> stream to STDOUT
<tr>
<td> \ref SubSecOptList
<td> \ref SecEmmLfn
<td> controlled by file specification[s]
<td> file \em fb-doc.lfn
<tr>
<td> \ref SubSecOptSyntax
<td> \ref SecEmmSyntax
<td> Doxyfile (+ files *.\em bas, *.\em bi, *.\em html, *.\em tex or *.\em xml)
<td> files *.\em html, *.\em tex or *.\em xml
<tr>
<td> \ref SubSecOptHelp
<td> none
<td> none
<td> stream to STDOUT
<tr>
<td> \ref SubSecOptVersion
<td> none
<td> none
<td> stream to STDOUT
</table>

\note The default mode is the Doxygen filter mode, since Doxygen
      doesn't allow to send further options (directly).

\note The modi `--help` (`-h`) and `--version` (`-v`) are not related
      to any FB source. They emit their output always on STDOUT.


Options  {#SecTabOptions}
=======

The following table contains an overview of all \Proj options. An
option either starts by a minus character followed by a single
character (short form) or by two minus characters followed by a word or
pair of words (LONG form). Both forms have the same meaning.

Some options expect an additional parameter, separated by a whitespace
character. Each further word in the command line (without the leading
'-' character) gets interpreted as a file name or pattern, see \ref
PagOptionDetails .

<table>
<tr>
<th> Option (short) <th> Parameter <th> Description
<tr>
<td> \ref SubSecOptAsterix
<td> none
<td> The C_Source emitter generates lines in a multi line comment block
     with leading '* ' characters (gtk-doc style).
<tr>
<td> \ref SubSecOptCStyle
<td> none
<td> The C_Source emitter generates types in real C syntax
     (instead of FB styled pseudo C syntax). Also used in emitter
     `DoxygenTemplates`.
<tr>
<td> \ref SubSecOptDocom
<td> none
<td> The syntax highlight emitter transfers documentational comments to
     the output (by default they get removed since the context is
     already in the html tree).
<tr>
<td> \ref SubSecOptEmitter
<td> Emitter name
<td> Customized emitter selection. \Proj compares the parameter with
     the names of the internal emitters. In case of no match it tries to
     find and load an external with this name.
<tr>
<td> \ref SubSecOptFile
<td> none
<td> Read FB source files and write output to similar named files
     (overriding existend, if any).
<tr>
<td> \ref SubSecOptGeany
<td> Emitter name
<td> Read input from STDIN and write to STDOUT. The parameter is optional. (No file specs.)
<tr>
<td> \ref SubSecOptHelp
<td> none
<td> Print the help text and quit.
<tr>
<td> \ref SubSecOptList
<td> none
<td> Read FB source files and write output to file *fb-doc.lfn*.
<tr>
<td> \ref SubSecOptPath
<td> path
<td> Set folder for file output.
<tr>
<td> \ref SubSecOptRecursiv
<td> none
<td> Scan for input files in the working folder and all subfolders.
     Works only in combination with file patterns.
<tr>
<td> \ref SubSecOptSyntax
<td> none
<td> Scan a Doxyfile (or multiple) for its output and fix syntax
     highlighting.
<tr>
<td> \ref SubSecOptTree
<td> none
<td> Follow the #`INCLUDE` statements in the source tree (if
     possible -- not available in run mode \ref SubSecOptGeany).
<tr>
<td> \ref SubSecOptVersion
<td> none
<td> Print the version information and quit.
</table>

\note An empty command line makes \Proj to output the help text
      (as if option `--help` was given).

\note Multiple run modes raise an error message, only one run mode is
      allowed at a time.


File Specifications  {#SecTabFileSpecs}
===================

Any text in the command line not matching an option or its parameter
gets interpreted as a file specification, that is either a file name or
a file pattern. File specs get added to a queue and \Proj executes
this queue in the given order. Depending on the file spec[s] and the
run mode, \Proj operates in different ways:

<table>
<tr>
<th> Option (run-mode)
<th> no file specs
<th> file name
<th> file pattern
</th>
<tr>
<td> default
<td> print help text
<td> load file, emit output to STDOUT
<td> load all files matching the pattern, emit output to STDOUT
<tr>
<td> -f *or* --file-mode <td> load all *.\em bas and *.\em
     bi files, emit output for each file to a *.\em c or *.\em h file
<td> load file, emit output to a *.\em c or *.\em h file
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
<td> load file, emit output to one file named \em fb-doc.lfn</td>
<td> load all files matching the file spec, emit output to one file
     named \em fb-doc.lfn</td>
</table>

\note A file name may be prepended by a relative or an absolute path.

\note File names or paths including a space character have to be
      enclosed by single or double quotes.

\note Multiple file names get separated by a space character or by a
      ; character.

\note Multiple file specs (names and patterns) can get specified in the
      command line.

\note In case of file output the extension of the output file depends
      on the extension of the input file: *.\em bas gets *.\em c and
      *.\em bi gets *.\em h.

\note A file name cannot start with a minus character and cannot
      include single or double quote characters.

\note On UNIX like systems usually the shell (bash) expands the file
      patterns (\Proj doesn't see the pattern, but gets the files
      list instead, so option `--recursive` doesn't work -- enclose
      the pattern by single or double quotes to hinder that).


Intermediate Format  {#SecTabInterForm}
===================

The following table contains some examples on how FB source code gets
transformed to the intermediate (C-like) format.

The main trick to make a C parsers work on FB source is to transform
the declarations for variables and functions. FB syntax is full of
keywords for better human readability. Most of them are unknown for the
C parser (fbc-0.90 has more than 400 keyword, in C it's less than 50).

A type specification may have more than one word, the C parsers expect
just a single word. That's why \Proj packs all FB information in a
single word type name, so that the C tool can handle this fantasy type
and build the documentation output.

Therefor the FB keywords get mangled in to one single word, separated
by underscore characters. This mangling can get suppressed by option
`--cstyle`, to get real C types emitted. There's also some influences
on the emitted TYPEs and file names of include files.

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
|                   #`INCLUDE ONCE "abc.bi"` | #`include "abc.bi"`                | #`include "abc.h"`    |
|                  #`INCLUDE ONCE "xyz.bas"` | #`include "xyz.bas"`               | #`include "xyz.c"`    |


Files  {#SecTabFiles}
=====

The source files of this project are listed and described in detail in
this documentation. The following tables give an overview on file types
used by \Proj and additional files not listed in the file browser.


File Types  {#SubSecFileTypes}
----------

Different file types are used by \Proj as input and output. The input
depends on the emitter in use, the output depends on the run mode and
the emitter.

<table>
<tr>
<th> Type
<th> Direction
<th> Emitter
<th> Function
</th>
<tr>
<td> \ref SubSecBasBi
<td> in
<td> *ALL*
<td> Source code to parse
<tr>
<td> \ref SubSecInLfn
<td> in
<td> \ref SecEmmCSource
<td> List of function names
<tr>
<td> \ref SubSecDoxyfile
<td> in
<td> \ref SecEmmLfn and \ref SecEmmSyntax
<td> Parameters for reading source code
<tr>
<td> \ref SubSecInHtml
<td> in
<td> \ref SecEmmSyntax
<td> Header, footer and links
<tr>
<td> \ref SubSecInTex
<td> in
<td> \ref SecEmmSyntax
<td> Header, footer and links
<tr>
<td> \ref SubSecInXml
<td> in
<td> \ref SecEmmSyntax
<td> Header, footer and links
<tr>
<td> \ref SubSecInModules
<td> in
<td> *CUSTOM*
<td> Executable binary
<tr>
<td> \ref SubSecOutCH
<td> out
<td> \ref SecEmmCSource
<td> Transformed C-like output
<tr>
<td> \ref SubSecOutLfn
<td> out
<td> \ref SecEmmCSource
<td> List of function names
<tr>
<td> \ref SubSecOutLfn
<td> out
<td> \ref SecEmmLfn
<td> List of function names
<tr>
<td> \ref SubSecOutHtml
<td> out
<td> \ref SecEmmSyntax
<td> Source listing with corrected syntax highlighting
<tr>
<td> \ref SubSecOutTex
<td> out
<td> \ref SecEmmSyntax
<td> Source listing with corrected syntax highlighting
<tr>
<td> \ref SubSecOutXml
<td> out
<td> \ref SecEmmSyntax
<td> Source listing with corrected syntax highlighting
</table>


Undocumented files  {#SubSecFileUnDocu}
------------------

The folder *doc* contains configuration files to build this
documentation by executing Doxygen in this folder, check its manual for
details. Those files are not listed in the Files browser, here're the
their functions

|        fb-doc/doc | Function                                                            |
| ----------------: | :------------------------------------------------------------------ |
|          Doxyfile | A configuration file, controlling the Doxygen and \Proj operations. |
| DoxygenLayout.xml | A configuration file, controlling the index of these *html* pages.  |
|  DoxyExtension.in | A configuration file for CMake, containing global information.      |
|        fb-doc.lfn | A list of function names generated by executing `fb-doc -l`.        |
|        fb-doc.css | A customized style sheet specifying the colors.                     |

To generate caller / callee graphs in the documentation (as in this
html files) you have to install the *dot* tool from the *GraphViz*
package. Executing `fb-doc -l` before doxygen is mandatory to update
the file fb-doc.lfn.

This will generate the documentation with FB source files in
intermediate format. For correct syntax highlighting execute `fb-doc
-s` after the doxygen run. It will replace the Doxygen output files in
the output folders.

\note For this to work, the file Doxyfile must contain the path to all
      FB source files in the first entry (`INPUT =`).
