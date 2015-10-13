Options in Detail  {#PagOptionDetails}
=================
\tableofcontents

This page contains more detailed informations about the options.

\Proj gets controlled by the command line, containing elements of this
types (may be none, one or more than one)

- options (starting with '`-`' or '`--`')
  -# mode options
  -# operational options
  -# option parameters (separated by white space)
- file specifications (in any combination of)
  -# a single file name
  -# a list of single file names (separated by white spaces)
  -# a file pattern
  -# a list of file patterns (separated by white spaces)

\note An empty command line defaults to option `--help`.

The options get evaluated in the given order. When two options are used
with similar effects, \Proj stops with and error message. Example
(both options are contrary run mode options).

~~~{.sh}
prompt$ fb-doc --list-mode --geany-mode
fb-doc: Invalid command line (multiple run modes)
~~~

The options `--help` and `--version` are dominat. They stop further
command line parsing and get executed immediately.

Since a mode option sets its standard emitter (and overrides any
previous emitter settings), it's best practise to set options in the
following order

~~~{.sh}
fb-doc [mode options] [operational options] <file specifications>
~~~

\note The options information in the following summary tables belong to
       the standard emitters. ???


Mode Options  {#SecOptModes}
============

The standard mode is the Doxygen-Filter mode. \Proj operates in this
mode when no other mode option is set. The only exeption is an empty
command line (no file specification). In this case \Proj switches to
\ref SubSecOptHelp.


Default Mode  {#SubSecOptDefault}
------------

This mode is active when none of the other modes is specified.

|            none | none (= standard Mode = Doxygen Filter)               |
| --------------: | :---------------------------------------------------- |
|           Input | file (path and name)                                  |
|          Output | STDOUT (context depends on emitter)                   |
| Default Emitter | C_Source (in FB style)                                |
|       File Spec | FreeBASIC source code (like *.bas;*.bi -- no default) |
| Further Options | -a -c -e -r -t (depends on emitter)                   |
| Ignored Options | -d -o                                                 |

In standard mode \Proj reads input from files and sends output to
STDOUT. The default emitter is `C_Source`. The file specification may
contain a single file name, a path and a file name, a file pattern or a
path and a file pattern. Several file specifications can be used in any
combination, separated by a white space character. The emitter output
for each file gets collected and send in a single stream to STDOUT.

The standard mode is designed to be used as a filter for Doxygen. In
that case a single file name (including a path, if any) is passed at
the command line. \Proj operates on this file and emits its output to
STDOUT pipe.

Furthermore this mode is helpful to test the \Proj output (ie. when
developing a new emitter). Just specify your emitter and an input file
like

~~~{.sh}
fb-doc --emitter "empty" fb-doc.bas
~~~

and \Proj operates on the file fb-doc.bas and pipes the output of the
\em empty emitter to the terminal.

Or you can use this mode to generate a C-header for a library,
collecting the context of several FB headers in one C header. While it
has some advantages to use several header files during the development,
further users of the library may prefer to have only one file. This can
be done by scanning the source files and piping STDOUT to a file

~~~{.sh}
fb-doc --emitter C_Source --c_style *.bi > MyLib_SingleHeader.h
~~~

When your headers need a certain order you may use the option `--tree`
and specify the start files instead of the pattern.

Or you can generate a file for external documentation (outside the
source code). Let \Proj collect all relevant symbols by using the
`--tree` option as in the example above. Or extract symbols in a per
file basis, like

~~~{.sh}
fb-doc --emitter "DoxygenTemplates" MyFile_abc.bas > MyFile_abc.txt
~~~

Then edit all `FIXME` entries in MyFile_abc.txt and include the file in
to your Doxygen file tree.


--file-mode (-f)  {#SubSecOptFile}
----------------

|            `-f` | `--file-mode`                                |
| --------------: | :------------------------------------------- |
|           Input | file (path and name)                         |
|          Output | file (.bi -> .h, .bas -> .c)                 |
| Default Emitter | C_Source (in FB style)                       |
|       File Spec | FreeBASIC source code (default: *.bas *.bi)  |
| Further Options | -a -c -e -o (defaults to ../doc/c_src) -r -t |
| Ignored Options | -d (depends on emitter)                      |

The file mode is designed to read input from certain files and to write
output to certain files. For each input file an output file gets
created in the output folder specified by option `--outpath`. The type
of the output file depends on the emitter in use:

|            Emitter | `*.bas` Type   | `*.bi` Type   | default path   |
| -----------------: | :------------- | :------------ | :------------- |
|           C_Source | --> *.c        | --> *.h       | ../doc/c_src   |
| SyntaxHighLighting | --> *.bas.html | --> *.bi.html | ../doc/fb_html |
|    GtkDocTemplates | --> *.bas.gtmp | --> *.bi.gtmp | ../doc/src     |
|   DoxygenTemplates | --> *.bas.dtmp | --> *.bi.dtmp | ../doc/src     |
|      FunctionNames | --> *.bas.lfn  | --> *.bi.lfn  | ../doc/src     |
|    external plugin | --> *.bas.ext  | --> *.bi.ext  | ../doc/src     |

\Proj creates a new folder if the output folder doesn't exist. Also
higher level directories get created if not existend. When an input
file comes from a subfolder, a similar subfolder gets created in the
output folder. When a subfolder is beyond the current path (ie. like
`../../../src` form an \#`INCLUDE` statement in a source file) the ..
part(s) of the path get skipped and \Proj creates subfolders for the
rest of the path.

\note \Proj never writes above the output folder.

\note Existing files in the output folder get overriden without warning.

\Proj uses the above mentioned default paths if option `--outpath` is
not used. To write in to the current directory use option `--outpath .`
(path name is a dot).

The most common use is to bridge to the gtk-doc back-end. Usually a set
of FB source files get translated in to similar C source files using
the C_Source emitter. gtk-doc then operates on that C files to generate
the desired output. So usually \Proj gets executed in the source
folder like

~~~{.sh}
fb-doc --file-mode --asterix --cstyle --recursiv
~~~

to operate on all FB files (using default `*.bas` `*.bi`) in the
current folder and its subfolders to generate a similar source tree in
the default output folder <em>../doc/c_src</em>. Then switch to this
folder and start the gtk-doc tool chain there.

Furthermore you can add a file pattern (or multiple) to operate on
selected files (ie. "??_view*.b*"). Or we use this run mode in a
Makefile to update a set of C sources like

~~~{.sh}
fb-doc --file-mode --asterix --cstyle $@
~~~

\note The renaming of the output files as in the above table
       is inbuild in \Proj source code and cannot get adapted by
       command line settings.


--geany-mode (-g)  {#SubSecOptGeany}
-----------------

|            `-g` | `--geany-mode`                         |
| --------------: | :------------------------------------- |
|           Input | STDIN                                  |
|          Output | STDOUT                                 |
| Default Emitter | GtkDocTemplates                        |
|       File Spec | none                                   |
| Further Options | -e                                     |
| Ignored Options | -a -c -d -o -r -t (depends on emitter) |

The geany mode is designed to generate templates for the
documentational comments in the source code, see section \ref
SecInsGeany for details. Usually a code section gets selected in
the editor and then sent to \Proj via STDIN pipe. \Proj extracts the
relevant symbols and generates a matching comment block for this piece
of code. Both, the comment block and the original code block, get
returned to geany and replaces the previously selected block.

From a geany user point of view it looks like adding a block in to the
source, but this block contains individual informations related to the
previously selected block.

Geany mode is also usefull for testing purposes because the output to
STDOUT doesn't change any files in your source tree. Just edit the
custom command in Geany settings to change to the desired emitter. This
option allows to specify an emitter name directly after the option
(since geany mode doesn't need any file specifications) but you can
also use option `--emitter` in this mode. The output can either be
tested in the geany editor, where you can easy select the stuff for
\Proj. Or you can pipe an input stream to \Proj at the command line.
The following example lists all function names from file test.bas in
the terminal

~~~{.sh}
fb-doc --geany-mode "FunctionNames" < test.bas
~~~

\note The output may contain error messages from \Proj. Those are send
       to STDERR and mixed in to the output by the terminal. That's
       different when directing the STDOUT stream to a file. In that
       case the error messages are shown in the terminal while the file
       contains pure \Proj output.

Furthermore you can use this mode to collect output from several files
in to a single one. The following example collects the C-translations of
the declarations from two FB headers in the file C_Header.h

~~~{.sh}
fb-doc --geany-mode "C_Source" --c-style < file1.bi > C_Header.h
fb-doc --geany-mode "C_Source" --c-style < file2.bi >> C_Header.h
~~~


--list-mode (-l)  {#SubSecOptList}
----------------

|            `-l` | `--list-mode`                                |
| --------------: | :------------------------------------------- |
|           Input | file (path from Doxyfile, name = *.bas;*.bi) |
|          Output | fb-doc.lfn                                   |
| Default Emitter | ListOfFunction                               |
|       File Spec | Doxyfile (but also *.bas;*.bi)               |
| Further Options | -a -c -e -r -t                               |
| Ignored Options | -d -o (depends on emitter)                   |

The list mode is designed to generate a list of function names and
write this list to the file fb-doc.lfn, one function name per line.
Later, this file is used to generate pseudo function calls in the
function bodies by the C_Source emitter, making Doxygen being able to
generate caller / callee graphs.

Usually the mode is used in the `../doc` folder near the Doxyfile.
\Proj reads the `INPUT` path from the Doxyfile and scans all FB
source files, to extract the function names in a single file
`fb-doc.lfn`, which gets written near the Doxyfile (where \Proj can
find it later on when called by Doxygen as input filter). Example

~~~{.sh}
cd ../doc
fb-doc --list-mode
~~~

In this example no input file name is specified and \Proj uses the
default name `Doxyfile`. Also it's possible to specify any outher file
name and a prepending path (ie. like `../doc/fb-doc.Doxyfile`). But if
the file specification contains a pattern (characters `*` or `?`) or
the extension is one of `.bas` or `.bi`, then \Proj skips the reading
of the Doxyfile and operates on the FB source file(s) directly.


--syntax-mode (-s)  {#SubSecOptSyntax}
------------------

|            `-s` | `--syntax-mode`                        |
| --------------: | :------------------------------------- |
|           Input | files (pathes and names from Doxyfile) |
|          Output | files                                  |
| Default Emitter | SyntaxHighLighting                     |
|       File Spec | Doxyfile                               |
| Further Options | -d -e -o                               |
| Ignored Options | -a -c -r -t (depends on emitter)       |

In syntax mode \Proj opens the specified Doxyfile and evaluates the
path to the FB source and the output types and their folders. Then
it scans the output folders for files containing listings, operating
on Html, LaTeX and XML output.

These listing files get replaced by a version with the original
header and footer and inbetween a newly created listing section with
appropriate FB syntax highlighting. All links found in the original
files get transfered to the new file.

The syntax mode is designed to correct syntax highlighting in the
Doxygen output files. Since the paths get evaluated from the
Doxyfile, no options (additional to `--syntax-mode`) are neccessary.
By default \Proj read the file named "Doxyfile", but its possible
to specify (one or more) individual file name(s).

Since this mode operates on specific Doxygen output files, it makes no
sense to use it with an alternative emitter (but \Proj doesn't block
this scenario).


--help (-h)  {#SubSecOptHelp}
-----------

|            `-h` | `help`                |
| --------------: | :-------------------- |
|           Input | none                  |
|          Output | STDOUT (version text) |
| Default Emitter | none                  |
|       File Spec | none                  |
| Further Options | none                  |
| Ignored Options | all                   |

This option makes \Proj to output the help text and stop. The help
text contains a brief summary of all available option and some examples
for usage. It should help experienced users to remember some
information. (It's not mentioned to be a complete documentation.)

\note In help mode all other options have no effect.


--version (-v)  {#SubSecOptVersion}
--------------

|            `-v` | `--version`          |
| --------------: | :------------------- |
|           Input | none                 |
|          Output | STDOUT (help text)   |
| Default Emitter | none                 |
|       File Spec | none                 |
| Further Options | none                 |
| Ignored Options | all                  |

This option makes \Proj to output the version information and stop.
The version information contains the source code version number, the
date and time of compilation and the used operating system for the fbc
compiler.

\note In version mode all other options have no effect.


Operational Options  {#SecOptOperations}
===================

Operational options control the \Proj operations or the output of an
emitter. In special cases they may have no effect, depending on the
used combination of run mode and emitter.


--asterix (-a)  {#SubSecOptAsterix}
--------------

|            `-a` | `--asterix`          |
| --------------: | :------------------- |
|       Parameter | none                 |
|        Run Modi | all                  |
|        Emitters | `C_Source`           |

This options makes the emitter `C_Source` to output an asterix
character and a white space (like `"* "`) at the start of each line in
a special multi line comment block, see \ref SubSecExaGtkdoc for
further examples.

This special format is used in gtk-doc (must have) and can also be used
in Doxygen (no advantage, slows down execution).

Editing and formating a special comment block with these line starts is
complicated and slow. The asterix character may get mixed up with the
text when using line wrapping functions. Therefor \Proj offers this
feature to edit the documentation context in plain text and add the
special format only in the output for the back-end.


--cstyle (-c)  {#SubSecOptCStyle}
-------------

|            `-c` | `--cstyle`                     |
| --------------: | :----------------------------- |
|       Parameter | none                           |
|        Run Modi | all                            |
|        Emitters | `C_Source`, `DoxygenTemplates` |

This option makes \Proj to emit real C types instead of the FB-like
mangled type names. It also infuences the translation of `TYPE` blocks
and \#`INCLUDE` lines, see \ref SecTabInterForm for examples.

The standard output of the `C_Source` emitter is optimized for best
matching documentation. Therefor the types in the source code get
fantasy names, similar to the FB keywords declaring them. Use this
option to switch form FB sytle to real C type names.


--doc-comments (-d)  {#SubSecOptDocom}
-------------------

|            `-d` | `--doc-comments`     |
| --------------: | :------------------- |
|       Parameter | none                 |
|        Run Modi | syntax-mode          |
|        Emitters | `SyntaxHighLighting` |

This options makes the emitter `SyntaxHighLighting` to output all
documentational comments in the source code, so that the listing looks
like the original file.

By default documentational comments get removed. The listing has gaps
in the line numbers at the place of the original documentational
comments (as in Doxygen listings).

\note Documentational comments are redundant informations, since their
      context was already used to generate the output.


--emitter (-e)  {#SubSecOptEmitter}
--------------

|            `-e` | `--emitter`          |
| --------------: | :------------------- |
|       Parameter | Emitter name         |
|        Run Modi | all                  |

This option makes \Proj to use an alternative emitter and overrides
the run mode default emitter setting. A parameter must follow this
option (separated by a white space), specifying the emitter name. The
parameter may be surrounded by quotes (single or double), they get
removed befor further operation.

First, \Proj searches in the list of internal emitter names (see \ref
SecTabEmitter). This search gets done non-case-sensitive and
partial-matching. Meaning you need not type the complete emitter name
nor use the right letter cases. Ie. *d*, *Dox* or <em>"DOXY"</em> all
match the full emitter name *DoxygenTemplates*.

In case of no match in the internal emitter names \Proj tries to load
an external emitter with the specified name. In this case the emitter
name must exactly match the base file name of the FB source code used
to build the plugin module. Ie. when the plugin was compiled by

~~~{.sh}
fbc -dylib empty.bas
~~~

the parameter *emitter name* must be `empty` as in

~~~{.sh}
fb-doc -e "empty"
~~~

\note On UNIX-like systems file names are case-sensitive.
\note For external emitter plugins specify the base name of the source
       file (not the context of the string \ref EmitterIF::Nam).


--outpath (-o)  {#SubSecOptPath}
--------------

|            `-o` | `--outpath`                  |
| --------------: | :--------------------------- |
|       Parameter | path to folder               |
|        Run Modi | `--file-mode`, `--list-mode` |
|        Emitters | all                          |

This option is used to specify the path for the \Proj file output. It
works for the above mentioned run modi, wherein \Proj generates new
file output (but not for `--syntax-mode` where \Proj replaces files
generated by Doxygen).

The parameter may be either a relative path starting at the current
directory (where \Proj is executed) or an absolute path (starting with
"/" on UNIX-like systems or with a drive letter and a colon an other
systems).

\Proj writes the file output in the specified directory. The directory
gets created first, if it doesn't exist. Also all higher level
directories get created if not existing yet.

In `--list-mode` the file *fb-doc.lfn* gets created in that directory,
overriding an existed without warning (if any).

In `--file-mode` more than one file may get created, depending on the
specified input file(s) or pattern(s). In case of option `--recursiv`
or `--tree` also subdirectories may get created in the putpath
directory and its subfolder(s).

\note \Proj writes files in to the outpath folder and may create
      subfolders in it. But \Proj never performs any changes in
      directories above the outpath.


--recursiv (-r)  {#SubSecOptRecursiv}
---------------

|            `-r` | `--recursiv`         |
| --------------: | :------------------- |
|       Parameter | none                 |
|        Run Modi | all                  |
|        Emitters | all                  |

This options makes \Proj scanning for input files in the working
folder and in its subfolders. It takes only into effect when the input
file specification is a file pattern (or a list of patterns).

When the file pattern has no path, the current folder is the working
folder. Otherwise \Proj scans the path specified before the pattern
and its subfolders.

In the following example the current folder is *doc* and \Proj scans
the working folder *src* and its subfolders

~~~{.sh}
cd myProj/doc
fb-doc -r "../src/*.bas" "../src/*.bi"
~~~

\note The option has no effect when a single file name (or a list of
      names) is specified (it's only used for patterns).
\note When \Proj operates on a Doxyfiles (*in* `--list-mode` *or*
      `--syntax-mode) the setting of its *RECURSIV* parameter
      overrides this option.
\note It has no effect when running in `--geany-mode`.
\note On LINUX systems usually the shell (bash) expands the file
      patterns and sends a list of single names to \Proj, so this
      option has no effect until you enclose the file pattern by
      quotation marks (like in the example above).


--tree (-t)  {#SubSecOptTree}
-----------

|            `-t` | `--tree`             |
| --------------: | :------------------- |
|       Parameter | none                 |
|        Run Modi | all                  |
|        Emitters | all                  |

This option makes \Proj to follow the source code tree. That is, all
\#`INCLUDE` statements will be evaluated and \Proj operates on this
files as if they were specified as input files on the command line.

\note This only works with files in the source code tree. Standard
      header files (ie. like `"crt/string.bi"`) wont be found since
      \Proj doesn't know the standard FreeBASIC include path.
\note For this option to work the emitter must provide a handler for
      \ref EmitterIF::Incl_() in which the parsing of the new files
      get started. Not all emitters do support this.


File Specifications  {#SecOptFileSpec}
===================

A file specification is used to determine one or more file(s) for
\Proj file input (so not for `--geany-mode` where \Proj gets input
from STDIN). Each entry at the command line that is neither an option
nor an option parameter gets recognized as file specification and added
to the list \ref Options::InFiles for further operation.

A file specification contains an (optional) path to the working
directory and either a concrete file name or a file pattern. Examples

| File Specification | Description                                                          |
| -----------------: | :------------------------------------------------------------------- |
|          `abc.bas` | the file `abc.bas` in the current directory                          |
|  `../doc/Doxyfile` | the file named `Doxyfile` in the working folder `../doc`             |
|            `*.bas` | all files matching the pattern `*.bas` in the current folder         |
|      `../src/*.bi` | all files matching the pattern `*.bi` in the working folder `../src` |

Whereat the current directory is the folder \Proj was executed in. And
the working folder is the directory specified by the path part of the
file specification. The later can either be a relative path (as in the
examples above) or an absolute path (starting with "/" on UNIX-like
systems or with a drive letter and a colon on other systems).

File specifications can be used in any combinations. Use white spaces to
separate them. When a path or a file name contains a white space it
must be enclused by (single or double) quotes. Generally it's
benefiting to enclose any file specification in qoutes, especially on
UNIX-like systems whereat unquoted pattern get expanded in the shell
and \Proj receives a list of names instead of the pattern (option
`--recursiv` doesn't work in that case).

\Proj uses default file specifications if none is set in the command
line. The default depends on the specified run mode:

|        Run Mode | Default File Specification |
| --------------: | :------------------------- |
|    default mode | `*.bas` `*.bi`             |
|   `--file-mode` | `*.bas` `*.bi`             |
|   `--list-mode` | `Doxyfile`                 |
| `--syntax-mode` | `Doxyfile`                 |
