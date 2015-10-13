How To Use  {#PagUsage}
==========
\tableofcontents

This is a brief introduction in auto-generating documentation extracted
from the source code. Therefor you'll need well written source code in
correct syntax for the compiler (FB syntax), but also comments matching
the syntax of the back-end in use.

So to test \Proj and to learn about its usage and features you'll need

-# source code to work on (ie. the \Proj code in the `src` folder)
-# an executable of \Proj (ie. compiled by `fbc fb-doc.bas`)
-# a documentation back-end (\Proj comments are formated for Doxygen)
-# optional a GUI frontend (ie. Doxywizard)
-# optional further tools (ie. *GraphViz* (graphs), *LaTeX* (pdf), ...)







both, an installation of a C tool-chain and some source code with
documentation comments in the tool-chain's syntax.

The easiest way to get started is to use Doxygen and the \Proj
sourc code. In that case you can skip the next section.


Generating Templates  {#SecUseTemplates}
====================

For Doxygen back-end there's no need for generating templates. It's
best practise to write the documenting comment right in front of or
just behind the relevant construct. The only exeption is a
documenting comment for a function. It contains the names of the
variables in the parameter list.

Its different when using gtk-doc tool-chain. Here the documentation
context is collected in blocks. Such a block contains the name of
the relevant construct (ie. a ENUM block) and the names of all its
members, followed by its decription. (Doxygen can handle such blocks
as well, but it isn't well supported.)

Generating such a comment block is a reasonable amount of word. Each
name has to get copied from the source in to the block. \Proj can
do this for us.

When we use Geany IDE, we can use a convenient method by installing
\Proj as Geany custom command (see \ref SecInsGeany) and choose
the emitter for the tool-chain in use (\em GtkDocTemplates or \em
DoxygenTemplates). After loading the source, we select a block of
code, send it to \Proj and we receive the original block, prepended
by a customized documentation block. We just need to edit the
entries (marked by the text `FIXME`). See \ref SubSecExaGtkdoc and
\ref SubSecExaDoxy for examples.

We can select a single construct and generate the comment blocks
one-by-one. Or we select a bunch of statements and \Proj inserts
the templates inbetween the constructs. In case of a block
construct (ENUM / UNION / TYPE) it's advantageous to select the
complete block up to the END ... statement, to get all members
listed in the documentation block. In case of a function
decalaration the selection need not include the function body, but
should contain the complete decalaration.

It's a bit less convenient to auto-generate templates when an other
IDE is in use. In that case the documentation blocks can get
generated for a complete file, by piping its context to \Proj. See
\ref SecUsePipe for details.


Gtk-doc  {#SecUseGtk}
=======

When using gtk-doc as back-end the documentation comment blocks are
placed before a structure, union, function ... and the names of the
members or parameters are listed in the comment block, prepended by
a \@ character and appended by a colon. See the manual
http://developer.gnome.org/gtk-doc-manual/stable/index.html for
details. Find an example for a gtk-doc documentation comment in \ref
SubSecExaGtkdoc.

\Proj helps us by creating such documentation comment blocks (=
template). We select a piece of code in Geany and send it to the
\Proj filter. \Proj creates a template, evaluates the names from
our source code and includes them in the template, followed by the
text `FIXME`. We just replace this text by the proper description.
To use this feature we have to install \Proj as Geany filter, see
\ref SecInsGeany for details.

When our documentation texts are done, we create a pseudo C source
tree in a separate folder and use the gtk-doc tool chain on this C
files. Therefor we start a command line interpreter (shell) and
switch to the folder where our FB source is placed. Then, we execute

~~~{.sh}
fb-doc --asterix --file-mode
~~~

This makes \Proj creating a new folder <em>../doc/c_src</em> (if
not present) and write pseudo C files similar to our FB source
(overriding existing files). *.\em bas files get translated to *.\em
c and *.\em bi files get translated to *.\em h. Our documentation
comments get transfered to this files and some of our FB code gets
translated to C syntax. Then we start the gtk-doc tool-chain in the
<em>../doc/c_src</em> folder as descibed in the above mentioned
manual (\em gtkdoc-scan, ...).

gtk-doc works well to document a library API. Especially when it's
related to GLib, GTK+ or gnome software. One of the unique features
is auto-extracting the properties from the source code (I'll publish
an FB tool soon). But it's not the best choise when we want to
document a program like \Proj. In that case we better use Doxygen.


Doxygen Back-End  {#SecUseDoxy}
================

For Doxygen we can either use separate comment blocks, similar to
the gtk-doc blocks. Doxygen blocks use a different syntax and they
don't need to be placed in front of the related construct. \Proj
also supports Doxygen templates, but this way of documenting isn't
very common and not well supported yet.

The other case is &mdash; a more commen way &mdash; to place the
documentation directly in front of (or behind the) related construct.
Rather than documenting a complete block at once, just the class
name or just one member gets documented in one comment. This way is
more convenient, we need not extract the names from our source code.
We just place the documentation beside the construct and Doxygen
picks the names from the source. For that way of documenting there's
no need to generate templates. The only execption is a parameter
list, where the parameter names have to be listed in the
documentation block. See

 - the manual
   http://www.stack.nl/~dimitri/doxygen/manual.html for details.
 - \ref SubSecExaDoxy for an example for a function comment block
 - all \Proj source code as further examples.

For Doxygen we can also create the pseudo C files in the
<em>../doc/c_src</em> folder, as described in the previous section.
But it's more convenient to send the pseudo C code directly to
Doxygen without creating intermediate files. This can be done by
using \Proj as a Doxygen filter. (We use Doxygen as if we were
working on C source code, \Proj translates on-the-fly when Doxygen
reads the input.)

Doxygen gets controlled by a configuration file. This file contains
all options. Here we can specify the \Proj filter by adapting the
following:

First we have to tell Doxygen that it should load FB source files:

\verbatim
FILE_PATTERNS          = *.bi \
                         *.bas
\endverbatim

and second we need to set \Proj as the filter for these files

\verbatim
FILTER_PATTERNS        = *.bas=fb-doc \
                         *.bi=fb-doc
\endverbatim

\note Doxygen doesn't allow to send additional options directly to
       a filter. So if we need further options we can set the name
       of a batch file here and call \Proj from the batch file
       passing further options.

That's it. When we now start doxygen with proper settings for the
paths and output format, we get our first auto-created
documentation. (Try it with the \Proj source code.)

To get caller and callees graphs (as in this document) it gets a
little tricky. Doxygen needs the function calls inside the function
bodies (in the C source). But when \Proj acts as a Doxygen filter
it gets restarted on each file. So it doesn't know a function
declaration in file B when working on file A. The names of all the
functions must be known to evaluate their calls in a function body
and to generate proper pseudo C source. That's why \Proj reads the
names from a file called <em>fb-doc.lfn</em> in the current folder.

We needn't generate this file manually, \Proj can do this for us by
executing the command

~~~{.sh}
fb-doc --list-mode
~~~

in our source folder. This writes a new (or overrides an existing) file
<em>fb-doc.lfn</em> in the current folder. When we don't start Doxygen
in our source folder, we have to move the file to the folder where
we execute the \em doxygen command. When we use Doxywizzard (the GUI
frontend for Doxygen) this is the folder specified under

\verbatim
Step1: Specify the working directory from which doxygen will run
\endverbatim

And we have to specify \Proj as filter for source files and enable
source file filtering

\verbatim
FILTER_SOURCE_FILES    = YES

FILTER_SOURCE_PATTERNS = *.bas=fb-doc \
                         *.bi=fb-doc
\endverbatim

In the next run Doxygen should be able to generate caller and callee
graphs in the documentation (if the settings are correct and all
tools are available).

But this has a downside: when we want the source files in the
documentation (as in this document) the C-like code is used. To get
the FB code we have to run Doxygen twice:

 -# without source filtering to get the \em html files with FB source

 -# with source filtering to get the graphs

Before the second run we save the \em html source files in a
separate folder by executing in the Doxygen html output folder
something like (example for LINUX OS)

~~~{.sh}
mkdir bas
mv *bas_source.html bas
mv *bi_source.html bas
~~~

and after the second run we restore the FB source files

~~~{.sh}
rm *bas_source.html
rm *bi_source.html
cd bas
mv * ..
cd ..
rmdir bas
~~~


C Headers  {#SecUseCHeader}
=========

Since \Proj needs to generate C-like code for the back-end parsers, it
can also be useful to create a set of C headers for a library written
in FreeBASIC (= FB). By default the FB types get mangled in to one word
(for documentation purposes). Ie. a FB parameter <em>byref Nam as const
short</em> gets the pseudo C code <em>byref_as_const_short Nam</em>.
This mangling can get suppressed by option `--cstyle` and \Proj emitts
real C types. In that case the example gets <em>const short* Nam</em>
and this code can be used by a C compiler.

So when we need C headers for our FB library we just execute

~~~{.sh}
fb-doc --file-mode --cstyle "*.bi"
~~~

in our source folder and get a set of C translations in *.\em h
files in the target folder (<em>../doc/c_src</em> by default).

\note \Proj doesn't handle initializers. You have to check them
       manually.


Piping  {#SecUsePipe}
======

By default \Proj reads its input for (one or more) files and sends
its output to STDOUT. We can switch to STDIN input by option \em
--geany-mode and then use the operating system commands to control the
data flow in and from \Proj.

Ie. this is useful when we don't use Geany IDE or when we want to get
templates for a complete file or a bunch of files at once. We can
pipe the files context to the \Proj STDIN channel and the fb-doc
output to a file.

To get templates for all constructs in an existing file, first we
create a copy the file (example for LINUX OS)

~~~{.sh}
cp filename.bas filename.txt
~~~

Then we pipe the copy to \Proj in geany mode (using emitter \em
DoxygenTemplates here). The output gets piped to the original file
(omit <em>>filename.bas</em> to see the output in the console)

~~~{.sh}
fb-doc --geany-mode doxy < filename.txt > filename.bas
~~~

Finally we may want to delete the intermediate file

~~~{.sh}
rm filename.txt
~~~

To insert templates in all files of an existing project we write a
batch file (or FB program) that does these three steps for all our
source files.
f
