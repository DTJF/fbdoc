Run Modi  {#PagRunModi}
========
\tableofcontents

Run modi control the data flow in \Proj. They determine where to get
input from and where to send output to. See table \ref SecTabRunModi
for details.


# Information Modi  {#SecModInfo}

Informational modi don't get any input. They output internal
information to the STDOUT stream, which is console output by default.

## --help  {#SecModHelp}

The help run mode outputs a information on how to use \Proj. It lists all options with a brief description.


## --version  {#SecModVersion}

The version run mode outputs information on the \Proj binary, its version, build date and the target operating system.


# Operational Modi  {#SecModOperation}

Operational modi are used in the daily \Proj workflow. They determine
the input and the output stream (see
table \ref SecTabRunModi). And they specify a default emitter, which can get overridden by option \ref
SubSecOptEmitter.

## Default  {#SecModDefault}

In default run mode \Proj acts as a Doxygen filter. It reads input from a single FB source code file


## --file-mode  {#SecModFile}



## --geany-mode  {#SecModGeany}



## --list-mode  {#SecModList}



## --syntax-mode  {#SecModSyntax}


Mode Options  {#SecOptModes}
============

The standard mode is the Doxygen-Filter mode. \Proj operates in this
mode when no other mode option is set. The only exeption is an empty
command line (no file specification). In this case \Proj switches to
\ref SubSecOptHelp.


Default Mode  {#SecOptDefault}
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
`../../../src` form an #`INCLUDE` statement in a source file) the ..
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
the default output folder `../doc/c_src`. Then switch to this
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


