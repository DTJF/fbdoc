Options  {#PagOptions}
=======
\tableofcontents

Command line options are used to control the \Proj workflow. They are
separated by a white space and they start either

- with a single minus character (`-`), followed by a short form, or
- with two minus characters (`--`), followed by a long form as a
  human readable text.

Command line options are used to

- select a run mode (\ref SecRMod),
- customize the run mode operation (\ref SecOptMod), or
- control emitter output generation (\ref SecOptEmm).

Find an overview of most available (inbuild) options in the table in
section \ref SubIntOptions. And find detailed descriptions at this
page.

Beside those inbuild options further options may be used by external
emitters.

All other command line parameters (not starting with a minus character)
get interpreted either as

- a file name,
- a file pattern (when containing a `?` or `*` character), or
- a path (when behind the option \ref SecOptPath), or
- an emitter name (when behind option \ref SecOptEmitter or \ref SecModGeany).

\note Multiple file names can get specified in a list, separated by
      white space characters. Also mixed lists are allowed, containing
      file names and patterns. The list gets executed in the given
      order.

\note File names or patterns may get enclosed by quotes (single `'` or
      double `"` quotes), in order to handle white space characters
      (which get interpreted as parameter separator if not quoted).

\note File names or patterns may contain a path, either relative to the
      current folder or absolute. The path must not contain
      placeholders (`?` or `*` character).


# Run Modi  {#SecRMod}

The run mode option specifies how \Proj operates. It controls

- where to get input from,
- where to write output to, and
- the default emitter to use.

Some run modi don't expect any input (\ref SecModHelp and \ref
SecModVersion). Instead those run modi just output information about
\Proj to `STDOUT` (the standard output channel). Also when \Proj is
called without any option, it acts as if option \ref SecModHelp was
given. (At least a file name has to get passed at the command line to
make \Proj operate on FB source code.)

<table>
<tr>
<th> Run Mode
<th> Default Emitter
<th> Input
<th> Output
</th>
<tr>
<td> \ref SecModDef
<td> \ref SecEmmCSource
<td> one file (or a list of file names or patterns)
<td> stream to STDOUT
<tr>
<td> \ref SecModFile
<td> \ref SecEmmCSource
<td> one file (or a list of file names or patterns)
<td> files `*. c` and `*. h`
<tr>
<td> \ref SecModGeany
<td> \ref SecEmmGtk
<td> stream from STDIN
<td> stream to STDOUT
<tr>
<td> \ref SecModList
<td> \ref SecEmmLfn
<td> Doxyfile by default (or a list of file names or patterns)
<td> file `fb-doc.lfn`
<tr>
<td> \ref SecModSyntax
<td> \ref SecEmmSyntax
<td> Doxyfile by default (or a list of file names or patterns)
<td> files `*.html`, `*.tex` or `*.xml` (or `STDOUT` in case of suffix `.bas` or `.bi`)
<tr>
<td> \ref SecModHelp
<td> none
<td> none
<td> stream to STDOUT
<tr>
<td> \ref SecModVersion
<td> none
<td> none
<td> stream to STDOUT
</table>

\note Only one run mode can be active at a time. Specifying multiple
      run modi results in an error message and no operation.


## none (default)  {#SecModDef}

This run mode is designed to be used as a filter for the Doxygen
backend. Input gets read from files and output gets sent to `STDOUT`. By
default it uses the emitter \ref SecEmmCSource.

The Doxygen backend can use filters for source code files. Instead of
parsing the file contents directly, it calls an external program (=
filter) and then parses its output. The file name gets passed to the
external program as parameter. The filter reads the file context and
transforms it to something Doxygen can understand. The transformed file
context gets sent to `STDOUT`, from where Doxygen receives it for further
processing.

\note Usually a single file name gets passed by Doxygen, but \Proj can
      also use file patterns or a list of file names in this run mode.


## --file-mode (-f)  {#SecModFile}

This run mode is designed to be used as a input generator for the
gtk-doc backend. Input gets read from files and output gets sent to
files. By default it uses the emitter \ref SecEmmCSource.

Unlike Doxygen, the gtk-doc backend has no filter feature. It operates
always on files. In order to get it working on FB source code, a set of
files has to be generated, containing a transformation of the FB code
to the intermediate format. Then the tools of the gtk-doc backend are
used on this set of files.

In this run mode \Proj reads the specified files and writes the
transformed output to files in the output path, which is set to
`../c_src/` by default (to customize that path see option \ref
SecOptPath). Each input file with suffix `.bas` gets written to a file
with suffix `.c`, using the same base name. And input files with suffix
`.bi` gets written to output files with suffix `.h`. When the input
files get scanned recursivly from subfolders, similar subfolders get
created in the output path (if not present).

\note \Proj overrides the files in the output path without warning.


## --list-mode (-l)  {#SecModList}

This run mode is designed to generate the list of function names file
for the emitter \ref SecEmmCSource. Input gets read from files and all
output gets sent to a single file called `fb-doc.lfn`. By default it
uses the emitter \ref SecEmmLfn.

\Proj can support caller and callee graphs in documentation generated
by Doxygen backend. Therefor the function bodies in the intermediate
format have to contain the calls to other functions, so that Doxygen
can extract the relationships and create the graphs. In order to
generate that calls, the emitter \ref SecEmmCSource reads the function
names from the file `fb-doc.lfn`.

When no files are specified at the command line like

~~~{.txt}
fb-doc -l
~~~

then \Proj tries to load and parse the file `Doxyfile` in the current
directory for the tag `INPUT`, processing all files matching the
patterns `*.bas` and `*.bi` in that path.

When one or more file name is specified, \Proj

- either prcesses the files directly in case of suffix `.bas` or
  `.bi`,

- or tries to interpret the file as Doxygen configuration file in case
  of any other suffix, processing all files matching the patterns
  `*.bas` and `*.bi` in the `INPUT` path.


## --syntax-mode (-s)  {#SecModSyntax}

This run mode is designed to fix the syntax highlighting in source code
listings generated by Doxygen. Input gets read from files and output
gets sent to the same files, overriding the original context. By
default it uses the emitter \ref SecEmmSyntax.

Doxygen processes the (C-like) intermediate format in order to generate
the documentation. When listings are required (tags `SOURCE_BROWSER`,
`LATEX_SOURCE_CODE` or `XML_PROGRAMLISTING`), those listings are
generated from the intermediate format as well, which is unusable for
FB code documentation. This run mode is designed to fix that problem.
It replaces the bodies of the original Doxygen listings by context
generated from the FB source code with correct syntax highlighting. See
section \ref SecEmmSyntax for details.

By default this run mode evaluates the file `Doxyfile` in the current
directory. On the command line also any other valid configuration file,
file list or patterns can get specified.

\note This run mode can get processed only once, since the original
      listing files get replaced. A second run should stop with an
      error message (`cannot operate twice`).

\note This run mode is always used after the Doxygen run. In case of
      LaTeX and XML listings, it has to be procesed after the Doxygen
      run and before the further latex or xml processing.

\note It is possible to make Doxygen generate listings from the
      original source code by disabling the tag `FILTER_SOURCE_FILES`.
      In that case Doxygen generates listings from the original source
      code (FB), but in incorrect (C-like) syntax highlighting. Also
      caller / callee graphs don't work.

\note In case of file suffix `.bas` or `.bi` this run mode generates
      html output to `STDOUT` (instead of writing to files) and it
      operates on single files (considering the option \ref #SecOptTree
      setting). This is useful to generate html-formated listings for
      embedding anywhere (independandly from Doxygen output). An
      additional CSS file is necessary, specifying the classes
      `keyword`, `keywordtype`, `keywordflow`, `preprocessor`,
      `comment` and `stringliteral`.


## --geany-mode (-g)  {#SecModGeany}

This run mode is designed to be used as a filter for the [Geany
IDE][http://www.geany.org]. Input gets read from STDIN and output gets
sent to `STDOUT`. By default it uses the emitter \ref SecEmmGtk.

The Geany IDE can send selected context from an editor to an external
program and then replace the selection by the output of that program.
This feature is useful when working with backend gtk-doc, which
requires to list all symbols in the documentational comments. \Proj can
auto-generate such documentational comment blocks listing all symbols
(= template) from the FB source code, so that the programmer has a
complete list without typing errors and just has to add the description
texts. It's also useful with backend Doxygen to create templates for
`FUNCTION` documentation.

Since input comes from STDIN and no file name is required, there's a
special use case for this option. It allows to specify an emitter name
behind the option, separated by a white space character. The name can
get enclosed by quotes (single `'` or double `"` quotes). Exmples:

~~~{.txt}
fb-doc --geany-mode --emitter "DoxygenTemplates"
fb-doc --geany-mode 'DoxygenTemplates'
fb-doc -g doxy
~~~

All three lines run \Proj in Geany mode on the input at STDIN. The
default emitter \ref SecEmmGtk gets replaced by the emitter \ref
SecEmmDoxy. (See also option \ref SecOptEmitter.)



## --help (-h)  {#SecModHelp}

This run mode is designed to output a brief help text on the \Proj
usage, ie. to check for a specific option or syntax. No input is
required. The output gets sent to `STDOUT`.


## --version (-v)  {#SecModVersion}

This run mode is designed to output the version of the current \Proj
binary, ie. to check for a specific version by a build management
system like CMake. No input is required. The output gets sent to
`STDOUT`.



# Mode Options  {#SecOptMod}

Mode options control the behaviour of a specific run mode. Find an
overview of the mode options and the related run modi in section \ref
SecIntExe.


## --emitter (-e)  {#SecOptEmitter}

This option makes \Proj to override the default emitter setting. Each
run mode has its default emitter setting, see section \ref
SubIntOptions. In order to use an alternate emitter, specify its name
(or some of the starting characters) behind this option, separated by a
white space character. The name can get enclosed by quotes (single `'`
or double `"` quotes). Exmples:

~~~{.txt}
fb-doc --emitter "SyntaxHighlighting" test.bas
fb-doc -e syn test.bas
~~~

Both lines run \Proj in default mode on file `test.bas`. The default
emitter \ref SecEmmCSource gets replaced by the emitter \ref
SecEmmSyntax.

\Proj seaches for inbuild emitters first. This search in non case
sensitve and matches when all specified characters meets the start of
the inbuild emitter name. In order to use an external emitter the full
file name has to get specified. Example:

~~~{.txt}
fb-doc -e py_ctypes test.bas
~~~

This line runs \Proj in default mode on file `test.bas`. The default
emitter \ref SecEmmCSource gets replaced by the plugin emitter called
`py_ctypes`. Its binary file `libpy_ctypes.so` (or `libpy_ctypes.dll`
on non-LINUX systems) has to be located in the current folder.

\note Only one emitter can be active at a time. Specifying multiple
      emitters results in an error message and no operation.

Related run modi: all (\ref SecModDef, \ref SecModFile, \ref SecModList, \ref SecModSyntax, \ref SecModGeany)


## --outpath (-o)  {#SecOptOutpath}

This option makes \Proj to use a customized path for file output. Each
emitter with file output has its default output path. This option is
used to override the default setting. The new path gets specified
behind the option, separated by a white space character. The path can
get enclosed by quotes (single `'` or double `"` quotes).

Related run modi: \ref SecModFile, \ref SecModList, ???


## --recursiv (-r)  {#SecOptRecursiv}

This option makes \Proj to scan in subfolders for file patterns. When a
file name contains a placeholder (characters `?` or `*`), then all
files matching that pattern get executed. By default only the specified
path gets searched. When this option is set, also subfolders get
searched.

\note In case of emitters \ref SecModList and \ref SecModSyntax \Proj
      scans for source files in the path specified by the tag `INPUT`
      in the doxy file (when no `.bas` or `.bi` files are specified at
      the command line). In that case this option also affects the
      scanning process (although no file pattern is given at the
      command line).

Related run modi: \ref SecModDef, \ref SecModFile, \ref SecModList, \ref SecModSyntax


## --tree (-t)  {#SecOptTree}

This option makes \Proj to follow the source tree. By default the
parser skips the preprocessor statement #`INCLUDE` in FB source code.
When this option is set the named files get included, when the path
points to a valid file. That means it points either to relative path
starting at the current file location or to an absolute path. Standard
header files (like `dir.bi` or `fbgfx.bi`) get skipped, since their
path isn't complete (fbc reads them from the FB installation
directories).

\note This option has no effect in run mode \ref SecModGeany.

Related run modi: \ref SecModDef, \ref SecModFile, \ref SecModList, \ref SecModSyntax



# Emitter Options  {#SecOptEmm}

Emitter options control the behaviour of a specific emitter. Find an
overview of the emitter options and the related emitters in section
\ref SubIntOptions.


## --asterix (-a)  {#SecOptAsterix}

This option makes \Proj to start a line in a multi line comment with an
asterix character (`*`). By default the emitter \ref SecEmmCSource
transforms only the comment markers for multi line comments (at the
start `/'*` gets `/*!` and at the end `'/` gets `*/`). The lines
between those markers get transfered unchanged.

Some backends (like gtk-doc) expect an asterix character in front of
each comment line. This character makes it difficult to format the
comment paragraphs, since the asterix character may get included in the
text when a line break gets executed. Using this option you can edit
clean documentation comments in the FB source code and add the asterix
only in the C like output for the backend.

Example:

The emitter transforms a FB source code documentational comment like

~~~{.txt}
/'* GooBar2dClass:

The #GooBar2dClass-struct struct contains private data only.

Since: 0.0
'/
~~~

by default to

~~~{.c}
/*! GooBar2dClass:

The #GooBar2dClass-struct struct contains private data only.

Since: 0.0
*/
~~~

and when this option is set it creates

~~~{.c}
/*! GooBar2dClass:
*
* The #GooBar2dClass-struct struct contains private data only.
*
* Since: 0.0
*/
~~~

Related emitter: \ref SecEmmCSource


## --cstyle (-c)  {#SecOptCStyle}

This option makes \Proj to transform FB source code to real C source
code. By default FB types get transformed to pseudo C types. Ie. the FB
type `ZSTRING PTR` gets transformed to the user defined C type
`ZSTRING_PTR`. When this option is set, the FB types get transformed to
real C types. In that case `ZSTRING PTR` gets `char*` in the output.

Examples:

|                   FB code | C code --cstyle      | C code default           |
| ------------------------: | :------------------- | :----------------------- |
|                   ANY PTR | void*                | ANY_PTR                  |
|  FUNCTION xyz() AS USHORT | unsigned short xyz{} | FUNCTION_AS_USHORT xyz{} |

The default output is easy to read in the documentation, since the
types are similar to the FB types. Instead setting this option makes
the output useful to get processed with a real C compiler, ie. when you
wrote a library in FB and you want to auto-generate a C header for that
library.

Related emitters: \ref SecEmmCSource, \ref SecEmmDoxy


## --doc-comments (-d)  {#SecOptDocom}

This option makes \Proj to export documentational comments in the
output of the emitter \ref SecEmmSyntax. This emitter follows the
Doxygen tag `STRIP_CODE_COMMENTS` (which defaults to `YES`) and strips
the documentational comments, since they are redundant (their content
was used to generate the documentation text). In the output, single
line documentational comments get dropped (they leave an empty line if
the line only contains the comment). And at the place of a multi line
documentational comment there's a gap in the line numbers. When this
option is set, the emitter ignores the `STRIP_CODE_COMMENTS` setting
and transforms all comments from the FB source code.

Related emitter: \ref SecEmmSyntax
