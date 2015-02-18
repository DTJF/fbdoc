Options in Detail  {#pageOptionDetails}
=================
\tableofcontents

This page contains more detailed informations about the options.

fb-doc gets controlled by the command line, containing elements of this
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
with similar effects, fb-doc stops with and error message. Example
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


\section sectOptModes Mode Options

The standard mode is the Doxygen-Filter mode. fb-doc operates in this
mode when no other mode option is set. The only exeption is an empty
command line (no file specification). In this case fb-doc switches to
\ref subsectOptHelp.

\subsection sectoptDefaultMode Default Mode

|       _Summary_ | Standard Mode (Doxygen Filter)                        |
| --------------: | :---------------------------------------------------- |
|           Input | file (path and name)                                  |
|          Output | STDOUT (context depends on emitter)                   |
| Default Emitter | C_Source (in FB style)                                |
|       File Spec | FreeBasic source code (like *.bas;*.bi -- no default) |
| Further Options | -a -c -e -r -t (depends on emitter)                   |
| Ignored Options | -o

In standard mode fb-doc reads input from files and sends output to
STDOUT. The default emitter is `C_Source` in default mode. The file
specification may contain a single file name, a path and afile name, a
file pattern or a path and a file pattern. Several file specifications
can be used in any combination, separated by a white space character.
The emitter output for each file gets collected and send in a single
stream to STDOUT.

The standard mode is designed to be used as a filter for Doxygen. In
that case a single file name (including a path, if any) is passed at
the command line. fb-doc operates on this file and emits its output to
STDOUT pipe.

Furthermore this mode is helpful to test the fb-doc output (ie when
developing a new emitter). Just specify your emitter and an input file
like

~~~{.sh}
fb-doc --emitter "Plugin" fb-doc.bas
~~~

and fb-doc operates on the file fb-doc.bas and pipes the output of the
\em Plugin emitter to the terminal.

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
source code). Let fb-doc collect all relevant symbols by using the
`--tree` option as in the example above. Or extract symbols in a per
file basis, like

~~~{.sh}
fb-doc --emitter "DoxygenTemplates" MyFile_abc.bas > MyFile_abc.txt
~~~

Then edit all `FIXME` entries in MyFile_abc.txt and include the file in
to your Doxygen file tree.


\subsection subsectOptFileMode File Mode (-f)

|       _Summary_ | File Mode                                    |
| --------------: | :------------------------------------------- |
|           Input | file (path and name)                         |
|          Output | file (.bi -> .h, .bas -> .c)                 |
| Default Emitter | C_Source (in FB style)                       |
|       File Spec | FreeBasic source code (default: *.bas *.bi)  |
| Further Options | -a -c -e -o (defaults to ../doc/c_src) -r -t |
| Ignored Options | (depends on emitter)                         |

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

fb-doc creates a new folder if the output folder doesn't exist. Also
higher level directories get created if not existend. When an input
file comes from a subfolder, a similar subfolder gets created in the
output folder. When a subfolder is beyond the current path (ie like
`../../../src` form an \#`INCLUDE` statement in a source file) the ..
part(s) of the path get skipped and fb-doc creates subfolders for the
rest of the path.

\note fb-doc never writes above the output folder.

\note Existing files in the output folder get overriden without warning.

fb-doc uses the above mentioned default paths if option `--outpath` is
not used. To write in to the current directory use option `--outpath .`
(path name is a dot).

The most common use is to bridge to the gtk-doc back-end. Usually a set
of FB source files get translated in to similar C source files using
the C_Source emitter. gtk-doc then operates on that C files to generate
the desired output. So usually fb-doc gets executed in the source
folder like

~~~{.sh}
fb-doc --file-mode --asterix --cstyle --recursiv
~~~

to operate on all FB files (using default `*.bas` `*.bi`) in the
current folder and its subfolders to generate a similar source tree in
the default output folder <em>../doc/c_src</em>. Then switch to this
folder and start the gtk-doc tool chain there.

Furthermore you can add a file pattern (or multiple) to operate on
selected files (ie "??_view*.b*"). Or we use this run mode in a
Makefile to update a set of C sources like

~~~{.sh}
fb-doc --file-mode --asterix --cstyle $@
~~~

\note The renaming of the output files as in the above table
       is inbuild in fb-doc source code and cannot get adapted by
       command line settings.


\subsection subsectOptGeanyMode Geany Mode (-g)

|       _Summary_ |  Mode                               |
| --------------: | :---------------------------------- |
|           Input | STDIN                               |
|          Output | STDOUT                              |
| Default Emitter | GtkDocTemplates                     |
|       File Spec | none                                |
| Further Options | -e                                  |
| Ignored Options | -a -c -o -r -t (depends on emitter) |

The geany mode is designed to generate templates for the
documentational comments in the source code, see section \ref
sectInstallGeany for details. Usually a code section gets selected in
the editor and then sent to fb-doc via STDIN pipe. fb-doc extracts the
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
fb-doc. Or you can pipe an input stream to fb-doc at the command line.
The following example lists all function names from file test.bas in
the terminal

~~~{.sh}
fb-doc --geany "FunctionNames" < test.bas
~~~

\note The output may contain error messages from fb-doc. Those are send
       to STDERR and mixed in to the output by the terminal. That's
       different when directing the STDOUT stream to a file. In that
       case the error messages are shown in the terminal while the file
       contains pure fb-doc output.

Furthermore you can use this mode to collect output from several files
in to a single one. The following example collects the C-translations of
the declarations from two FB headers in the file C_Header.h

~~~{.sh}
fb-doc --geany "C_Source" --c-style < file1.bi > C_Header.h
fb-doc --geany "C_Source" --c-style < file2.bi >> C_Header.h
~~~


\subsection subsectOptListMode List Mode (-l)

|       _Summary_ |  Mode                                        |
| --------------: | :------------------------------------------- |
|           Input | file (path from Doxyfile, name = *.bas;*.bi) |
|          Output | fb-doc.lfn                                   |
| Default Emitter | ListOfFunction                               |
|       File Spec | Doxyfile (but also *.bas;*.bi)               |
| Further Options | -a -c -e -r -t                               |
| Ignored Options | -o (depends on emitter)                      |

The list mode is designed to generate a list of function names and
write this list to the file fb-doc.lfn, one function name per line.
Later, this file is used to generate pseudo function calls in the
function bodies by the C_Source emitter, making Doxygen being able to
generate caller / callee graphs.

Usually the mode is used in the `../doc` folder near the Doxyfile.
fb-doc reads the `INPUT` path from the Doxyfile and scans all FB
source files, to extract the function names in a single file
`fb-doc.lfn`, which gets written near the Doxyfile (where fb-doc can
find it later on when called by Doxygen as input filter). Example

~~~{.sh}
cd ../doc
fb-doc --list-mode
~~~

In this example no input file name is specified and fb-doc uses the
default name `Doxyfile`. Also it's possible to specify any outher file
name and a prepending path (ie like `../doc/fb-doc.Doxyfile`). But if
the file specification contains a pattern (characters `*` or `?`) or
the extension is one of `.bas` or `.bi`, then fb-doc skips the reading
of the Doxyfile and operates on the FB source file(s) directly.


\subsection subsectOptSyntaxMode Syntax Mode (-s)

|       _Summary_ | Syntax Mode                            |
| --------------: | :------------------------------------- |
|           Input | files (pathes and names from Doxyfile) |
|          Output | files                                  |
| Default Emitter | SyntaxHighLighting                     |
|       File Spec | Doxyfile                               |
| Further Options | -e -o                                  |
| Ignored Options | -a -c -r -t (depends on emitter)       |

In syntax mode fb-doc opens the specified Doxyfile and evaluates the
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
By default fb-doc read the file named "Doxyfile", but its possible
to specify (one or more) individual file name(s).

Since this mode operates on specific Doxygen output files, it makes no
sense to use it with an alternative emitter (but fb-doc doesn't block
this scenario).


\subsection subsectOptHelp Help (-h)

|       _Summary_ | Help Mode             |
| --------------: | :-------------------- |
|           Input | none                  |
|          Output | STDOUT (version text) |
| Default Emitter | none                  |
|       File Spec | none                  |
| Further Options | none                  |
| Ignored Options | none                  |

This option makes fb-doc to output the help text and stop. The help
text contains a brief summary of all available option and some examples
for usage. It should help experienced users to remember some
information. (It's not mentioned to be a complete documentation.)

\note In help mode all other options have no effect.


\subsection subsectOptVersion Version (-v)

|       _Summary_ | Version Mode         |
| --------------: | :------------------- |
|           Input | none                 |
|          Output | STDOUT (help text)   |
| Default Emitter | none                 |
|       File Spec | none                 |
| Further Options | none                 |
| Ignored Options | none                 |

This option makes fb-doc to output the version information and stop.
The version information contains the source code version number, the
date and time of compilation and the used operating system for the fbc
compiler.

\note In version mode all other options have no effect.


\section sectOptOperaOptions Operational Options

Operational options control the fb-doc operations or the output of an
emitter. In special cases they may have no effect, depending on the
used combination of run mode and emitter.

\subsection subsectOptAsterix Asterix (-a)

|            `-a` | `--asterix`          |
| --------------: | :------------------- |
|       Parameter | none                 |
|        Run Modi | all                  |
|        Emitters | `C_Source`           |

This options makes the emitter `C_Source` to output an asterix
character and a white space (like `"* "`) at the start of each line in
a special multi line comment block, see \ref subsectExaGtkdoc for
further examples.

This special format is used in gtk-doc (must have) and can also be used
in Doxygen (no advantage, slows down execution).

Editing and formating a special comment block with these line starts is
complicated and slow. The asterix character max get mixed up with the
text when using line wrapping functions. Therefor fb-doc offers this
feature to edit the documentation context in plain text and add the
special format only in the output for the back-end.


\subsection subsectOptCstyle CStyle (-c)

|            `-c` | `--cstyle`                     |
| --------------: | :----------------------------- |
|       Parameter | none                           |
|        Run Modi | all                            |
|        Emitters | `C_Source`, `DoxygenTemplates` |

This option makes fb-doc to emit real C types instead of the FB-like
mangled type names. It also infuences the translation of `TYPE` blocks
and \#`INCLUDE` lines, see \ref sectTabInterForm for examples.

The standard output of the `C_Source` emitter is optimized for best
matching documentation. Therefor the types in the source code get
fantasy names, similar to the FB keywords declaring them. Use this
option to switch form FB sytle to real C type names.


\subsection subsectOptEmitters Emitter (-e)

|            `-e` | `--emitter`          |
| --------------: | :------------------- |
|       Parameter | Emitter name         |
|        Run Modi | all                  |

This option makes fb-doc to use an alternative emitter and overrides
the run mode default emitter setting. A parameter must follow this
option (separated by a white space), specifying the emitter name. The
parameter may be surrounded by quotes (single or double), they get
removed befor further operation.

First, fb-doc searches in the list of internal emitter names (see \ref
sectTabEmitters). This search gets done non-case-sensitive and
partial-matching. Meaning you need not type the complete emitter name
nor use the right letter cases. Ie *d*, *Dox* or <em>"DOXY"</em> all
match the full emitter name *DoxygenTemplates*.

In case of no match in the internal emitter names fb-doc tries to load
an external emitter with the specified name. In this case the emitter
name must exactly match the base file name of the FB source code used
to build the plugin module. Ie when the plugin was compiled by

~~~{.sh}
fbc -dylib Plugin.bas
~~~

the parameter *emitter name* must be `Plugin` as in

~~~{.sh}
fbdoc -e "Plugin"
~~~

\note On UNIX-like systems file names are case-sensitive.
\note For external emitter plugins specify the base name of the source
       file (not the context of the string \ref EmitterIF::Nam).


\subsection subsectOptOutpath Outpath (-o)

|            `-o` | `--outpath`                  |
| --------------: | :--------------------------- |
|       Parameter | path to folder               |
|        Run Modi | `--file-mode`, `--list-mode` |
|        Emitters | all                          |

This option is used to specify the path for the fb-doc file output. It
works for the above mentioned run modi, wherein fb-doc generates new
file output (but not for `--syntax-mode` where fb-doc replaces files
generated by Doxygen).

The parameter may be either a relative path starting at the current
directory (where fb-doc is executed) or an absolute path (starting with
"/" on UNIX-like systems or with a drive letter and a colon an other
systems).

fb-doc writes the file output in the specified directory. The directory
gets created first, if it doesn't exist. Also all higher level
directories get created if not existing yet.

In `--list-mode` the file *fb-doc.lfn* gets created in that directory,
overriding an existed without warning (if any).

In `--file-mode` more than one file may get created, depending on the
specified input file(s) or pattern(s). In case of option `--recursiv`
or `--tree` also subdirectories may get created in the putpath
directory and its subfolder(s).

\note fb-doc writes files in to the outpath folder and may create
       subfolders in it. But fb-doc never performs any changes in
       directories above the outpath.


\subsection subsectOptRecursiv Recursiv (-r)

|            `-r` | `--recursiv`         |
| --------------: | :------------------- |
|       Parameter | none                 |
|        Run Modi | all                  |
|        Emitters | all                  |

This options makes fb-doc scanning for input files in the working
folder and in its subfolders. It takes only into effect when the input
file specification is a file pattern (or a list of patterns).

When the file pattern has no path, the current folder is the working
folder. Otherwise fb-doc scans the path specified before the pattern
and its subfolders.

In the following example the current folder is *doc* and fb-doc scans
the working folder *src* and its subfolders

~~~{.sh}
cd myProj/doc
fbdoc -r "../src/*.bas" "../src/*.bi"
~~~

\note The option has no effect when a single file name (or a list of
      names) is specified (it's only used for patterns).
\note When fb-doc operates on a Doxyfiles (*in* `--list-mode` *or*
      `--syntax-mode) the setting of its *RECURSIV* parameter
      overrides this option.
\note It has no effect when running in `--geany-mode`.
\note On LINUX systems usually the shell (bash) expands the file
      patterns and sends a list of single names to fb-doc, so this
      option has no effect until you enclose the file pattern by
      quotation marks (like in the example above).


\subsection subsectOptTree Tree (-t)

|            `-t` | `--tree`             |
| --------------: | :------------------- |
|       Parameter | none                 |
|        Run Modi | all                  |
|        Emitters | all                  |

This option makes fb-doc to follow the source code tree. That is, all
\#`INCLUDE` statements will be evaluated and fb-doc operates on this
files as if they were specified as input files on the command line.

\note This only works with files in the source code tree. Standard
      header files (ie like `"crt/string.bi"`) wont be found since
      fb-doc doesn't know the standard FreeBasic include path.
\note For this option to work the emitter must provide a handler for
      \ref EmitterIF::Incl_() in which the parsing of the new files
      get started. Not all emitters do support this.


\section sectOptFileSpec File Specifications

A file specification is used to determine one or more file(s) for
fb-doc file input (so not for `--geany-mode` where fb-doc gets input
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

Whereat the current directory is the folder fb-doc was executed in. And
the working folder is the directory specified by the path part of the
file specification. The later can either be a relative path (as in the
examples above) or an absolute path (starting with "/" on UNIX-like
systems or with a drive letter and a colon on other systems).

File specifications can be used in any combinations. Use white spaces to
separate them. When a path or a file name contains a white space it
must be enclused by (single or double) quotes. Generally it's
benefiting to enclose any file specification in qoutes, especially on
UNIX-like systems whereat unquoted pattern get expanded in the shell
and fb-doc receives a list of names instead of the pattern (option
`--recursiv` doesn't work in that case).

fb-doc uses default file specifications if none is set in the command
line. The default depends on the specified run mode:

|        Run Mode | Default File Specification |
| --------------: | :------------------------- |
|    default mode | `*.bas` `*.bi`             |
|   `--file-mode` | `*.bas` `*.bi`             |
|   `--list-mode` | `Doxyfile`                 |
| `--syntax-mode` | `Doxyfile`                 |
