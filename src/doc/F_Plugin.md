Plugin Development  {#PagPlugin}
==================
\tableofcontents

An external emitter (= plugin) is an extension for \Proj. It adds new
features. The developer of a plugin can use the \Proj file handling and
parsing capabilities, and just adds some code to generate the desired
output. Find details in section \ref SecEmmEx.

In order to use a plugin, the binary gets loaded by \Proj at program
start. Therefor the binary has to be previously compiled as a shared
library, located in the current directory.

In order to test this feature, \Proj ships with example source code in
folder `src/bas/plugins`:

- empty.bas: output the names of the function currently running (for
  learning purposes).

- py_ctypes.bas: output python source code to be used with ctypes (to
  create phyton language bindings from FreeBASIC source code for
  libraries).

The plugin binary usually gets created by the FB compiler by executing
(replace `SRC.BAS` by your file name)

    fbc -dylib SRC.BAS

Any other compiler, able to compile and link shared libraries, can be
used as well. It's beyond the scope of this document to cover all
posibilities.


# Execution # {#SecExecution}

The interaction between \Proj and a plugin passes several steps on
different levels:

-# \ref SubInit
 -# \ref SubPluginInit
 -# \ref SubProcessInit
-# \ref SubOperation
 -# \ref SubFileInit
 -# \ref SubFileParsing
 -# \ref SubFileExit
-# \ref SubExit

On the first level the plugin gets initialized, before it operates on
the files specified on the command line. Afterwards a closure function
gets called in order to finish pending operations. The file processing
step passes several substeps.


## Global init phase ## {#SubInit}

This steps at first level get executed once in the startup sequence.
They're designed to connect the plugin to the calling \Proj instance,
and also to pass remaining command line options (that \Proj doesn't
understand). Finally at this level global operations can get started,
ie. opening an output file.


### Plugin Init ### {#SubPluginInit}

The related slot in the emitter interface is EmitterInit().


### Process Init ### {#SubProcessInit}

The related slot in the emitter interface is EmitterIF::CTOR_().



## File Processing ## {#SubOperation}

This second level steps get executed multiple times, once for each file
the calling \Proj instance is processing. It contains three substeps

-# \ref SubFileInit
-# \ref SubFileParsing
-# \ref SubFileExit

The first and last get executed once for each new file. In the middle
step different functions are called in the module code, depending on
the context of the source code input parsed by the calling \Proj
instance.


### File Init ### {#SubFileInit}

The related slot in the emitter interface is EmitterIF::init_().


### File Parsing ### {#SubFileParsing}

There're several functions related to that step in the emitter interface

- EmitterIF::Decl_() to create output for a declaration
- EmitterIF::Func_() to create output for a function
- EmitterIF::Enum_() to create output for an ENUM block
- EmitterIF::Unio_() to create output for a UNION block
- EmitterIF::Clas_() to create output for a TYPE block
- EmitterIF::Defi_() to create output for a macro (#`DEFINE` / #`MACRO`)
- EmitterIF::Incl_() to create output for an #`INCLUDE` statement (must have for option \ref SecOptTree)
- EmitterIF::Error_() to create output for a error message
- EmitterIF::Empty_() to create output for an empty input line (from STDIN)


### File Exit ### {#SubFileExit}

The related slot in the emitter interface is EmitterIF::Exit_().


## Global exit phase ## {#SubExit}

The first level step gets executed once after the calling \Proj
instance processed all input files. It contains no substeps. A closure
function gets called in order to finish pending operation. Ie. this
function can output counter values or close files that collect
information from several input files.

The related slot in the emitter interface is EmitterIF::DTOR_().


# Source Code # {#SecSourceCode}

The main code to glue plugin code together with \Proj is in function
EmitterInit(). When the command line specifies that \Proj should use a
plugin, an Instance of an EmitterIF class gets created and its pointer
gets passed to this function. The plugin code fills the slots in the
interface by the related functions in the plugin source code, in order
to be called when files get processed.

\Proj parses the command line first, and removes the known command
syntax. The rest of the command line (unknown commands) gets passed to
the plugin code in the STRING parameter, so the user can pass command
line parameters to the plugin, in order to control its action.

Function EmitterInit() is the only must have in a plugin code, other
code is optional. Find details about the EmitterIF class in the related
section.

When you need some context in all function bodies, you can use global
vairiables (at module level), created by `DIM SHARED`. If you don't
like that idea, you can also pack all stuff in a structure (`UDT`) and
store its pointer in the member variable Parser::UserTok (see file
fbdoc_emit_syntax.bas as an example).


# Usage # {#SecUsage}

In order to use a plugin, just call its emitter by the command line
option \ref SecOptEmitter. \Proj checks the given name first against
the inbuild emitters. In case of no match, it tries to load a plugin
with the given name.

\note Specify the emitter name without file extension (ie. only
      *py_ctypes* instead of *py_ctypes.dll*).

\note The name of your plugin must not contain the beginning characters
      of any inbuild emitters.

Example:
