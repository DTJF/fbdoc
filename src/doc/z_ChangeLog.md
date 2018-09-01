Changelog & Credits {#PagChangeLog}
===================
\tableofcontents


# Further Development # {#SecToDo}

In combination with Doxygen \Proj is a powerful documentation system
for FreeBASIC source code. This Doxygen support for FreeBASIC is much
better than for any other BASIC dialect (ie. like VB6). But there's
still some room for optimization, for further Doxygen functions as well
as for other features, like:

- additional emitters to support further documentation systems or other tools
- extended SUB / FUNCTION detection for caller / callee graph when using operators `.` or `->`
- implementation of NAMESPACE, SCOPE
- a hash table for callees to speed up the execution
- currently \Proj only works with clean FB code. When standard keywords get #`UNDEF`ined, grazy things may happen.
- ...

Either report your ideas, bug reports, wishes or patches, to the
project page at

- \Webs

or to the

- [forum page](http://www.freebasic.net/forum/viewtopic.php?f=8&t=19810)

or feel free to send your ideas directly to the author (\Mail).


# fb-doc-0.4.4 # {#SecV-0-4-4}

New:

-

Changes:

- plugin py_ctypes option -py???

Bugfixes:

- small fixes in the documentation

Released on 2018 August.


# fb-doc-0.4.2 # {#SecV-0-4-2}

New:

- option -L (supports out-of source builds)
- evaluation of Doxygen tag `STRIP_CODE_COMMENTS`

Changes:

- adapted CMake scripts (folder cmake)
- advanced docu (plugin, syntaxemitter, ...)

Bugfixes:

- parsing of Doxyfile flags no more case sensitive (YES = Yes = yes == True == Y)

Released on 2016 December.


# fb-doc-0.4.0 # {#SecV-0-4-0}

New:

- GIT repository
- CMake build scripts, modular compiling (in-source / out-of-source)
- separate doc building: doc_htm, doc_pdf
- Doxyfile parsing supports `@INCLUDE` tag now
- source listings: documentational comments get removed now by default (as in Doxygen listings)
- source listings: new option --doc-comments (-d) to force inclusion of documentational comments
- plugin example py_ctypes to create language bindings for python
- support for inherritance (`EXTENDS`)
- support for `DIM` and `REDIM` in `TYPE` and `UNION` blocks
- init process (EmitterIF reviewed)
- command line options transfer to plugins

Changes:

- folder src/plugins moved to src/bas/plugins for easily compiling / testing
- new CMake macros (EXTENSION_MAPPING)
- Doxyfile adapted for Doxygen > 1.8.6
- better references in the docu

Bugfixes:

- parser.bas: rest of line issue fixed in case of no Emit->Decl_() function
- --file-mode: correct suffix for `.c` files now
- --geany-mode: works now with default emitter (without specifying an emitter name)
- --syntax-mode: `*.bas`/`*.bi` files/patterns working now
- files renamed: fb-doc -> fbdoc for better PDF (pdflatex mishandles '-' characters in hyperlinks)
- syntax highlighter: finds FB source files in subfolders now (TEX, XML)
- syntax highlighter: suppressed #`INCLUDE` statements fixed (HTM, TEX, XML)
- syntax highlighter: suppressed code before multi line comment fixed
- plugin example empty.bas fixed and improved
- parsing problem `REDIM PRESERVE "..."` fixed
- parsing problem `EXTERN "..."` fixed
- parsing problem `DECLARE ...` after bitfields fixed
- better caller / callee graphs (with manual interaction in case of `WITH` blocks)

Released on 2015 October, ??.


# fb-doc-0.2 # {#SecV-0-2}

New:

- completely renewed code base
- help and version information
- complete translation of all blocks (TYPE / UNION)
- support for non-case-sensitive FB keywords
- operating on files or pipes (input and output)
- walking through FB source trees
- variable target path
- recursiv scanning of subfolders
- fully Doxygen support, inclusive syntac highlighting in listings
- Geany mode for generating customized templates
- four inbuild emitters (C source, Templates for gtk-doc or Doxygen, Function names)
- interface for external emitter plugins
- self-hosted documentation and tutorial (including caller / callee graphs)

Released on 2013 June, 1.


# fb-doc-0.0 # {#SecV-0-0}

Initial release on 2012 April, 29.



# Credits # {#SecCredits}

Thanks go to:

- The FreeBASIC developer team for creating a great compiler.

- Bill Hoffman, Ken Martin, Brad King, Dave Cole, Alexander Neundorf,
  Clinton Stimpson for developing the CMake tool and publishing it
  under an open licence (the documentation has optimization
  potential).

- Dimitri van Heesch for creating the Doxygen tool, which is used to
  generate this documentation.

- Chris Lyttle, Dan Mueth, Stefan Kost (authors of gtk-doc).

- Arend Lammertink for providing Debian packages for armhf architecture
  and hosting them on his server.

- AGS (from http://www.freebasic.net/forum) for testing and bug reporting.

- All others I forgot to mention.

