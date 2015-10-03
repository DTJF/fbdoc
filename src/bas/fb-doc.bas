/'* \file fb-doc.bas
\brief An all-in-one source file to compile

This file includes all the submodules in to a single source code.

If you don't like the modular compiling by the CMake scripts, instead
you can compile this file with the FreeBASIC compiler in order to
create your fb-doc binary. Execute

~~~{.sh}
fbc -w all fb-doc.bas
~~~

'/

#INCLUDE ONCE "fb-doc_emitters.bi"
#INCLUDE ONCE "fb-doc_parser.bi"
#INCLUDE ONCE "fb-doc_options.bi"
#INCLUDE ONCE "fb-doc_version.bi"
#INCLUDE ONCE "fb-doc.bi"

#INCLUDE ONCE "fb-doc_emit_syntax.bas"
#INCLUDE ONCE "fb-doc_emit_callees.bas"
#INCLUDE ONCE "fb-doc_emit_gtk.bas"
#INCLUDE ONCE "fb-doc_emit_doxy.bas"
#INCLUDE ONCE "fb-doc_parser.bas"
#INCLUDE ONCE "fb-doc_doxyfile.bas"
#INCLUDE ONCE "fb-doc_emitters.bas"
#INCLUDE ONCE "fb-doc_options.bas"
#INCLUDE ONCE "fb-doc_main.bas"
