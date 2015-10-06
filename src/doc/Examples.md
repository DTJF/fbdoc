Examples  {#PagExamples}
========
\tableofcontents

This chapter contains some examples on how to use \Proj and its
features.


Command Line Interface  {#SecExaCli}
======================

As a first step this section contains some exercises to learn how
\Proj works. All operations get executed in the package folder.

We execute \Proj with several command line and use its own source code
in folder *src* as input to learn about its usage. Therefor extract the
archive *fb-doc.zip* to any folder, change to the source folder and
compile.

~~~{.sh}
cd fb-doc/src/bas
fbc -w all fb-doc.bas
~~~

Then you can test the binary by executing in that folder.

\note The following examples are for UNIX like systems. Omit the
       leading `./` when you're on other systems.

-# To output the version information or help text, execute in a terminal
   ~~~{.sh}
   ./fb-doc --version
   ./fb-doc --help
   ~~~
-# To output the intermediate format for a certain file execute
   ~~~{.sh}
   ./fb-doc fb-doc.bas
   ~~~
-# Instead of watching the output in the terminal you can write it to a
   file by
   ~~~{.sh}
   ./fb-doc fb-doc.bas > fb-doc.c
   ~~~
   and compare the input and the output files. The file *fb-doc.c*
   contains just a part of the original code (variable declarations,
   some special comments, \#`INCLUDE`s and an empty function `main()`).
   Each content is at the same line number.
-# To test the output of the emitter `SyntaxHighLighting` execute
   ~~~{.sh}
   ./fb-doc --emitter "SyntaxHighLighting" fb-doc.bas > fb-doc.html
   ~~~
   and the new file *fb-doc.html* contains Html code with highlighting
   tags for that FB source file. (You won't see highlighted code when
   you load this document in to a browser, because the class
   declaratinons for the highlighting tags are missing.)
-# Instead of option `--emitter` you can use the short form `-e`. And
   instead of a single file name you can use a file pattern. Here we
   test the emitter `FunctionNames` with terminal output
   ~~~{.sh}
   ./fb-doc -e "FunctionNames" "*.bi"
   ~~~
   and get the name `null_emitter` as single output line, which is the
   only function declared in the code files matching this pattern.
-# When we use `"fb-doc.bas"` as file specification we'll get empty
   output since this file contains no function declaration. But when we
   add option `--tree` \Proj follows each \#`INCLUDE` statement in the
   source tree and generates a list of all function names.
   ~~~{.sh}
   ./fb-doc -e "FunctionNames" --tree "fb-doc.bas"
   ~~~
   The list in the terminal output also contains some messages about
   the files scanned during the tree run.
-# When you pipe the output to a file, the messages will be
   shown in the terminal and the file contains the names list only.
   ~~~{.sh}
   ./fb-doc -e "FunctionNames" -t "fb-doc.bas" > fb-doc.lfn
   ~~~
   This list includes the function names of the \Proj source tree.
-# To generate a list of all function names you can specify several
   file patterns and collect the function names of all source files in
   in a single file, like
   ~~~{.sh}
   ./fb-doc -e "FunctionNames"  "*.bas" "*.bi" > fb-doc.lfn
   ~~~
   Option `--recursiv` will make \Proj searching in subfolders also.

-# Since this list is often needed to generate caller / callee graphs
   in Doxygen output, \Proj has the special run mode \ref
   SubSecOptList to create it. Use this option and execute \Proj near
   the Doxyfile to get the file at the right place
   ~~~{.sh}
   cd ../doc
   ./src/fb-doc -l
   ~~~
   \Proj scans the configuration file *Doxyfile* for the `INPUT` path
   (first entry only). In this path it scans depending on the
   `RECURSIV` setting the patterns `"*.bas;*.bi"` to scan for input
   files, generates the list of function names and writes the output to
   the file *fb-doc.lfn* in the current folder (overriding an existing,
   if any, without warning)
-# When you installed [Doxygen](http://www.doxygen.org/) and
   [GraphViz](http://www.graphviz.org/) you're ready to generate your
   first documentation from FB source. Just execute in the folder *doc*
   ~~~{.sh}
   doxygen
   ./src/fb-doc -s
   ~~~
   The first command generates a lot of Doxygen messages (depending on
   the settings in *Doxyfile*). It should end with message '`***
   Doxygen has finished`'. The second command makes \Proj run in \ref
   SubSecOptSyntax and repair the listing sections in the Doxygen
   output files. After all you should have a new folder *html* (in the
   folder *doc*) containing your personal version of this
   documentation. Test it by loading `..doc/html/index.html` in to your
   browser.

As a summary steps 1. to 8. are informal examples. You need steps 9.
and 10. for your personal projects.


Comments (in general)  {#SecExaComments}
=====================

The C back-ends work on an intermediate format. This format contains
comments exported from the FB source. \Proj doesn't export all
comments, since the programmer may want to have private comments as
well (ie ToDo marks). On the other hand \Proj provides a way to export
context directly to the intermediate format, to do tricky things with
the back-end in use.

To export a comment to the intermediate format it needs to be marked as
a special comment by starting its context with a magic character

- `*` for comments (exported as C comment)
- `&` for direct exports (exported as C source)

\note In these examples the ends of the FreeBASIC multi line comments
       are fakes, because the straight single quote mark cannot be used
       in the source (Geany lexer gets confused). Instead an acute
       accent is used. Correct them when you intend to copy / paste the
       code.

-# A line end comment in the FB source like
   ~~~{.bas}
   '* a line end comment
   ~~~
   gets emitted as
   ~~~{.c}
   / /! a line end comment
   ~~~
-# And a multi line comment in FB source like
   ~~~{.bas}
   /'*
   Some
   lines of
   comment '/
   ~~~
   gets emitted as
   ~~~{.c}
   /**
   Some
   lines of
   comment * /
   ~~~
   or &mdash; when option `--asterix` is set &mdash; as
   ~~~{.c}
   /**
   * Some
   * lines of
   * comment * /
   ~~~
-# Direct exports are only available for line end comments like
   ~~~{.bas}
   '&/ / a line end comment in C syntax

   '&/*
   '&Some
   '&lines of
   '&C comment
   '&* /
   ~~~
   get emitted as
   ~~~{.c}
   / / a line end comment in C syntax

   /*
   Some
   lines of
   C comment
   * /
   ~~~
-# Normal FreeBASIC comments (without magic character) wont be emitted.
   ~~~{.bas}
   ' a line end comment

   /'
   A block
   of
   comment
   '/
   ~~~
   They're only visible in the FB source. The intermediate format
   contains empty lines in that case.


Variables Declaration  {#SecExaDim}
=====================

A varible declaration in a FreeBASIC source code is in human readable
words (making it easy to understand the code) and may look like

~~~{.bas}
CONST VarName AS ZSTRING PTR
~~~

This couldn't get parsed by the C back-end, since this expects the
short C syntax like

~~~{.c}
const char* VarName;
~~~

where

- `const` is a C keyword,
- `char` is the name of an inbuild C type and the
- `*` is similar to the FB keyword `PTR`.

The type declaration `char*` can get replaced by any other type. Rather
than checking each type declaration, the parsers in the back-ends just
scan the type names and use them to build the documentation.

\Proj makes use of this flexibility. It creates new C types named
similar to the FB syntax (without any declaration). As new type name
all FB keywords get mangled in to a single word, separated by
underscore characters. The C back-end interpretes this word as a type
name and generates documentation output similar to the FB source code.
The above example gets in the intermediate (C-like) format

~~~{.c}
CONST_ZSTRING_PTR VarName;
~~~

and will be used as *CONST_ZSTRING_PTR VarName* in the documentation as
well. In this syntax the FB user can identify the type as an FB
declaration and easily understand the documentation. See \ref
SecTabInterForm for more examples.

\note The type name is allways in front of the symbol name, this order
       cannot get swapped as in FB syntax.

\Proj can also generate real C types. In this case the above example
gets

~~~{.c}
const char* VarName;
~~~

and this syntax can be used directly by a C compiler. This can be
useful to auto-generate C headers from FB source, ie to bind a library
written in FB in to a C project.


Templates  {#SecExaTemplates}
=========

In an early stage of the project development you'll start to add
documentation comments to your source code. When targeting the Doxygen
back-end this is an easy task. Just write the comment before or behind
the relevant statement in the source code.

It's different for gtk-doc. Each and every documentation comment needs
a list of the symbols the comment referes to. It's a boring job to copy
the symbol names from the source code to the documentation comment.
\Proj can support this process.

\note The source code in this section contains verbatim blocks instead
       of code blocks, because Doxygen miss-interpretes the \\ \p brief
       as keyword (allthough it's inside the code block).


Gtk-doc  {#SubSecExaGtkdoc}
-------

\note This example is based on a system wide installation of \Proj
       and a setting as Geany custom command with option
       `--geany-mode`. (See \ref SecInsGeany for details.)

This example is about documenting a function and its parameter list.
We load our source code in to Geany IDE, select the function
declaration (the code in the following box) and send it to the
\Proj custom command:

\verbatim
FUNCTION goo_axis_new CDECL( _
  BYVAL Parent AS GooCanvasItem PTR, _
  BYVAL Back AS GooCanvasItem PTR, _
  BYVAL Text AS gchar PTR, _
  BYVAL Modus AS GooAxisType, _
  ...) AS GooAxis PTR
\endverbatim

\Proj extracts the names of the function and its parameters,
generates a matching template and returns the customized template
and the original code. The entries for the individual documentation
texts are marked with the text `FIXME`:

\verbatim
/'*
goo_axis_new:
@Parent: FIXME
@Back: FIXME
@Text: FIXME
@Modus: FIXME
@...: FIXME

FIXME

Returns: FIXME
'/
FUNCTION goo_axis_new CDECL( _
  BYVAL Parent AS GooCanvasItem PTR, _
  BYVAL Back AS GooCanvasItem PTR, _
  BYVAL Text AS gchar PTR, _
  BYVAL Modus AS GooAxisType, _
  ...) AS GooAxis PTR
\endverbatim

Now we complete the documentation comment by filling the entries
marked by the `FIXME`s, and we end-up with something like:

\verbatim
/'*
goo_axis_new:
@Parent: the parent item, or %NULL. If a parent is specified, it
         will assume ownership of the item, and the item will
         automatically be freed when it is removed from the
         parent. Otherwise call g_object_unref() to free it.
  @Back: the background box to connect the axis to (a
         #GooCanvasRect, #GooCanvasImage, #GooCanvasGroup, ...).
         Note: to set the axis position and size, the properties
         #GooCanvasItemSimple:x, #GooCanvasItemSimple:y,
         #GooCanvasItemSimple:width and
         #GooCanvasItemSimple:height will be red (and therefore
         must be set in the background box item).
  @Text: the label text for the axis
 @Modus: the position and type (like %GOO_AXIS_SOUTH or
         %GOO_GRIDAXIS_SOUTH, ...)
   @...: optional pairs of property names and values, and a
         terminating %NULL.

Creates a new axis item.

Returns: (transfer full): a new axis item.
'/
FUNCTION goo_axis_new CDECL( _
  BYVAL Parent AS GooCanvasItem PTR, _
  BYVAL Back AS GooCanvasItem PTR, _
  BYVAL Text AS gchar PTR, _
  BYVAL Modus AS GooAxisType, _
  ...) AS GooAxis PTR
\endverbatim

Finally we translate all FB sources to C source using (defaults: output
path = `../doc/c_src`, file specification = `"*.bas" "*.bi"`)

~~~{.sh}
fb-doc --file-mode --asterix
~~~

The corresponding <em>.c</em> file looks like

\verbatim
/**
* goo_axis_new:
* @Parent: the parent item, or %NULL. If a parent is specified, it
*          will assume ownership of the item, and the item will
*          automatically be freed when it is removed from the
*          parent. Otherwise call g_object_unref() to free it.
*   @Back: the background box to connect the axis to (a
*          #GooCanvasRect, #GooCanvasImage, #GooCanvasGroup, ...).
*          Note: to set the axis position and size, the properties
*          #GooCanvasItemSimple:x, #GooCanvasItemSimple:y,
*          #GooCanvasItemSimple:width and
*          #GooCanvasItemSimple:height will be red (and therefore
*          must be set in the background box item).
*   @Text: the label text for the axis
*  @Modus: the position and type (like %GOO_AXIS_SOUTH or
*          %GOO_GRIDAXIS_SOUTH, ...)
*    @...: optional pairs of property names and values, and a
*          terminating %NULL.
*
* Creates a new axis item.
*
* Returns: (transfer full): a new axis item.
* */
FUNCTION_CDECL_AS_GooAxis_PTR goo_axis_new (
BYVAL_AS_GooCanvasItem_PTR Parent,
BYVAL_AS_GooCanvasItem_PTR Back,
BYVAL_AS_gchar_PTR Text,
BYVAL_AS_GooAxisType Modus,
...) {

};
\endverbatim

This C-like output can be used as input for the gtk-doc tool-chain to
generate the desired documentation output. Execute the tools on the
files in the <em>../doc/c_src</em> folder.

Or you use option `--cstyle` to generate output with types in real C syntax

~~~{.sh}
fb-doc --file-mode --asterix --cstyle
~~~
and the corresponding <em>.c</em> file looks like

\verbatim
/**
* goo_axis_new:
* @Parent: the parent item, or %NULL. If a parent is specified, it
*          will assume ownership of the item, and the item will
*          automatically be freed when it is removed from the
*          parent. Otherwise call g_object_unref() to free it.
*   @Back: the background box to connect the axis to (a
*          #GooCanvasRect, #GooCanvasImage, #GooCanvasGroup, ...).
*          Note: to set the axis position and size, the properties
*          #GooCanvasItemSimple:x, #GooCanvasItemSimple:y,
*          #GooCanvasItemSimple:width and
*          #GooCanvasItemSimple:height will be red (and therefore
*          must be set in the background box item).
*   @Text: the label text for the axis
*  @Modus: the position and type (like %GOO_AXIS_SOUTH or
*          %GOO_GRIDAXIS_SOUTH, ...)
*    @...: optional pairs of property names and values, and a
*          terminating %NULL.
*
* Creates a new axis item.
*
* Returns: (transfer full): a new axis item.
* */
GooAxis* goo_axis_new (
GooCanvasItem* Parent,
GooCanvasItem* Back,
gchar* Text,
GooAxisType Modus,
...) {

};
\endverbatim


Doxygen  {#SubSecExaDoxy}
-------

\note This example is based on a system wide installation of \Proj
       and a setting as Geany custom command with option `--geany-mode
       "DoxygenTemplates"`. (See \ref PagInstall for details.)

This example is about documenting a function and its parameter list,
similar to the previous one. We load our code in to Geany IDE, select
some source like the following code and send it to the \Proj custom
command:

\verbatim
FUNCTION goo_axis_new CDECL( _
  BYVAL Parent AS GooCanvasItem PTR, _
  BYVAL Back AS GooCanvasItem PTR, _
  BYVAL Text AS gchar PTR, _
  BYVAL Modus AS GooAxisType, _
  ...) AS GooAxis PTR
\endverbatim

\Proj extracts the names and returns the customized template, followed
by the original code:

\verbatim
/'* \fn FUNCTION_CDECL_AS_GooAxis_PTR goo_axis_new (BYVAL_AS_GooCanvasItem_PTR Parent, BYVAL_AS_GooCanvasItem_PTR Back, BYVAL_AS_gchar_PTR Text, BYVAL_AS_GooAxisType Modus, ...)
\param Parent FIXME
\param Back FIXME
\param Text FIXME
\param Modus FIXME
\param ... FIXME

\brief FIXME

\returns FIXME

FIXME

'/
FUNCTION goo_axis_new CDECL( _
  BYVAL Parent AS GooCanvasItem PTR, _
  BYVAL Back AS GooCanvasItem PTR, _
  BYVAL Text AS gchar PTR, _
  BYVAL Modus AS GooAxisType, _
  ...) AS GooAxis PTR
\endverbatim

The first line is the declaration of our function in C syntax &mdash;
without the character ; at the end and prepended by the keyword \\`fn`.
This line enables Doxygen to read the documentation comment anywhere in
its input, so the documentations comment needs not to be in front of
the matching function. Since we don't wonna move this block (it's
advantageous to place the documentation text near to the source code)
we can remove this line and then complete the documentation comment by
filling the `FIXME` entries. We end-up with something like:

\verbatim
/'* \brief Creates a new axis item.
\param Parent the parent item, or %NULL. If a parent is specified, it
         will assume ownership of the item, and the item will
         automatically be freed when it is removed from the
         parent. Otherwise call g_object_unref() to free it.
\param Back the background box to connect the axis to (a
         #GooCanvasRect, #GooCanvasImage, #GooCanvasGroup, ...).
         Note: to set the axis position and size, the properties
         #GooCanvasItemSimple:x, #GooCanvasItemSimple:y,
         #GooCanvasItemSimple:width and
         #GooCanvasItemSimple:height will be red (and therefore
         must be set in the background box item).
\param Text the label text for the axis
\param Modus the position and type (like %GOO_AXIS_SOUTH or
         %GOO_GRIDAXIS_SOUTH, ...)
\param ... optional pairs of property names and values, and a
         terminating %NULL.

\returns a new axis item.

A detailed desription of the function may follow here ...

'/
FUNCTION goo_axis_new CDECL( _
  BYVAL Parent AS GooCanvasItem PTR, _
  BYVAL Back AS GooCanvasItem PTR, _
  BYVAL Text AS gchar PTR, _
  BYVAL Modus AS GooAxisType, _
  ...) AS GooAxis PTR

' ...
END FUNCTION
\endverbatim

Using Doxygen we don't need to generate intermediate C source code in
files. Instead this code gets directly piped by \Proj acting as a
filter, so we usually don't see it. Being curious we may execute in a
terminal `fb-doc XYZ.bas` (replace XYZ by your file name) and we'll
see output (which is the Doxygen input) like

\verbatim
/**
\param Parent the parent item, or %NULL. If a parent is specified, it
         will assume ownership of the item, and the item will
         automatically be freed when it is removed from the
         parent. Otherwise call g_object_unref() to free it.
\param Back the background box to connect the axis to (a
         #GooCanvasRect, #GooCanvasImage, #GooCanvasGroup, ...).
         Note: to set the axis position and size, the properties
         #GooCanvasItemSimple:x, #GooCanvasItemSimple:y,
         #GooCanvasItemSimple:width and
         #GooCanvasItemSimple:height will be red (and therefore
         must be set in the background box item).
\param Text the label text for the axis
\param Modus the position and type (like %GOO_AXIS_SOUTH or
         %GOO_GRIDAXIS_SOUTH, ...)
\param ... optional pairs of property names and values, and a
         terminating %NULL.

\brief Creates a new axis item.

\returns: a new axis item.

The detailed desription of the function follows here ...

*/
FUNCTION_CDECL_AS_GooAxis_PTR goo_axis_new (
BYVAL_AS_GooCanvasItem_PTR Parent,
BYVAL_AS_GooCanvasItem_PTR Back,
BYVAL_AS_gchar_PTR Text,
BYVAL_AS_GooAxisType Modus,
...) {

};
\endverbatim

\note This output is also visible in the source code browser before the
       listings get repaired by executing `fb-doc -s` in the folder *doc*.









 They should have

- well prepared FB source files (supported by `--geany-mode "DoxygenTemplates"`) and
- a matching Doxyfile (using \Proj as input filter)

to auto-generate the documentation by executing

~~~{.sh}
cd ../doc
fb-doc -l
doxygen
fb-doc -s
~~~

\note This conclusion assumes a complete installation of *fb-doc*, *Doxygen* and *GraphViz*.
