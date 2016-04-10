/'* \file fbdoc.bas
\brief An all-in-one source file to compile manually

This file includes all the submodules in to a single source code.

If you don't like the modular compiling by the CMake scripts, you can
instead compile this file with the FreeBASIC compiler in order to
create your fb-doc binary. Execute

~~~{.txt}
fbc -w all fbdoc.bas -x fb-doc
~~~

'/

#INCLUDE ONCE "fbdoc_options.bi"
#INCLUDE ONCE "fbdoc_version.bi"

#INCLUDE ONCE "fbdoc_emit_csource.bas"
#INCLUDE ONCE "fbdoc_emit_doxy.bas"
#INCLUDE ONCE "fbdoc_emit_gtk.bas"
#INCLUDE ONCE "fbdoc_emit_lfn.bas"
#INCLUDE ONCE "fbdoc_emit_syntax.bas"
#INCLUDE ONCE "fbdoc_options.bas"
#INCLUDE ONCE "fbdoc_parser.bas"
#INCLUDE ONCE "fbdoc_doxyfile.bas"
#INCLUDE ONCE "fbdoc_emitters.bas"
#INCLUDE ONCE "fbdoc_main.bas"
