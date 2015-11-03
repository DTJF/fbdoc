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


## --version (-v)  {#SubSecOptVersion}

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


# Operational Options  {#SecOptOperations}

Operational options control the \Proj operations or the output of an
emitter. In special cases they may have no effect, depending on the
used combination of run mode and emitter.


## --asterix (-a)  {#SecOptAsterix}

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


## --cstyle (-c)  {#SecOptCStyle}

|            `-c` | `--cstyle`                     |
| --------------: | :----------------------------- |
|       Parameter | none                           |
|        Run Modi | all                            |
|        Emitters | `C_Source`, `DoxygenTemplates` |

This option makes \Proj to emit real C types instead of the FB-like
mangled type names. It also infuences the translation of `TYPE` blocks
and #`INCLUDE` lines, see \ref SecTabInterForm for examples.

The standard output of the `C_Source` emitter is optimized for best
matching documentation. Therefor the types in the source code get
fantasy names, similar to the FB keywords declaring them. Use this
option to switch form FB sytle to real C type names.


## --doc-comments (-d)  {#SecOptDocom}

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


## --emitter (-e)  {#SecOptEmitter}

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


## --outpath (-o)  {#SecOptPath}

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


## --recursiv (-r)  {#SecOptRecursiv}

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


## --tree (-t)  {#SecOptTree}

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


# File Specifications  {#SecOptFileSpec}

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
| `../doxy/Doxyfile` | the file named `Doxyfile` in the working folder `../doxy`            |
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
