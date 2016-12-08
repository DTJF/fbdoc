Plugin Development  {#PagPlugin}
==================
\tableofcontents

An external emitter (= plugin) is an extension for \Proj. It adds new
features. The developer of a plugin can use the \Proj file handling and
parsing capabilities, and just adds some code to generate the desired
output.

Proj loads a plugin at run-time. Therefor it needs a binary, compiled
as shared library. The binary has to be located in the current
directory. ???

In order to test this feature, \Proj ships with example source code in
folder `src/bas/plugins`:

- empty.bas: output the names of the function currently running (for
  learning purposes).

- py_ctypes.bas: output a python source to be used with ctypes (to
  create language bindings for libraries).

The binary usually gets created by the FB compiler by executing
(replace `SRC.BAS` by your file name)

    fbc -dylib SRC.BAS

Any other compiler, able to compile and link shared libraries, can be
used as well. It's beyond the scope of this document to cover all
posibilities.


# Execution  {#SecExecution}

The interaction between \Proj and a plugin passes several steps on
different levels

-# Init
-# File Processing
 -# File init
 -# File parsing
 -# File exit
-# Exit

On the first level the plugin gets initialized, before it operates on
the files specified on the command line. Afterwards a closure function
gets called in order to finish pending operations. The file processing
step passes several substeps.


## Init  {#SubInit}

This first level step gets executed once in the startup sequence. It's
designed to connect the plugin to the calling \Proj instance. It also
gets remaining command line options (that \Proj doesn't understand).
Finally in this step global operations can get started, ie. opening an
output file.


### Plugin Init  {#SubPluginInit}

The related function in the emitter interface is EmitterIF::CTOR().


### Process Init  {#SubProcessInit}


## File Processing  {#SubOperation}

This first level step gets executed multiple times, once for each file
to calling \Proj instance is processing. It contains three substeps

-# File init
-# File parsing
-# File exit

The first and last get executed once for each new file. In the middle
step different functions are called in the module code, depending on
the context of the source code inout parsed by the calling \Proj
instance.


### File Init  {#SubFileInit}

The related function in the emitter interface is EmitterIF::init().


### File Parsing  {#SubFileParsing}

There're several functions related to that step in the emitter interface

- EmitterTF::Decl() to create output for a declaration
- EmitterTF::Func() to create output for a function
- EmitterTF::Enum() to create output for an ENUM block
- EmitterTF::Unio() to create output for a UNION block
- EmitterTF::Clas() to create output for a TYPE block
- EmitterTF::Defi() to create output for a macro (#DEFINE / #MACRO)
- EmitterTF::Incl() to create output for an #INCLUDE statement
- EmitterTF::Error() to create output for a error message
- EmitterTF::Empty() to create output for an empty input line (from STDIN)


### File Exit  {#SubFileExit}

The related function in the emitter interface is EmitterIF::exit().


## Exit  {#SubExit}

The first level step gets executed once after the calling \Proj
instance processed all input files. It contains no substeps. A closure
function gets called in order to finish pending operation. Ie. this
function can output counter values or close files that collect
information from several input files.

The related function in the emitter interface is EmitterIF::DTOR().


# Source Code  {#SecSourceCode}


# Usage  {#SecUsage}
