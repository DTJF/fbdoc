Preparation  {#PagInstall}
===========
\tableofcontents

First, you've to

-# [install some programming tools](#SecTools) to
-# [get the package](#SecGit) and
-# [compile your executable](#SecBuild).


Programming tools  {#SecTools}
=================

Before you can use (or install) the \Proj package you have to have a
working installation of some tools, the first is mandatory and others
are optional.

|                                       Name  |    Typ    |  Function                                                          |
| ------------------------------------------: | :-------: | :----------------------------------------------------------------- |
| [fbc](http://www.freebasic.net)             | mandatory | The FreeBASIC compiler to compile the source code                  |
| [GIT](http://git-scm.com/)                  | optional  | The version control system to organize the files                   |
| [CMake](http://www.cmake.org)               | optional  | The build management system to build executables and documentation |
| [cmakefbc](http://github.com/DTJF/cmakefbc) | optional  | The FreeBASIC extension for CMake                                  |
| [Doxygen](http://www.doxygen.org/)          | optional  | The documentation generator (ie. for this text)                    |
| [Graphviz](http://www.graphviz.org/)        | optional  | The Graph Visualization Software (caller/callee graphs)            |
| [gtk-doc](http://developer.gnome.org/gtk-doc-manual/) | optional  | A further documentation generator (ie. for testing purposes)  |


\note It's beyond the scope of this guide to describe the installation
      for those programming tools. Follow the installation instructions
      in the above links (The name in the first column is linked to the
      related websites.)



Get Package  {#SecGit}
===========

Use GIT to get your copy of the package and change to the source tree

~~~{.sh}
git clone https://github.com/DTJF/fb-doc
cd fb-doc
~~~

(As an alternative you can click the [Download
ZIP](https://github.com/DTJF/cmakefbc/archive/master.zip) button on the
\Proj website, unpack the archive and change to the new folder.)


CMake Build System  {#SecCMake}
==================

The prefered way to build the executable and the documentation files is
to use the scripts for the CMake build system. If you don't want to
install or to use CMake, then skip this section and continue at \ref
SecManual.

The CMake scripts check your system and through warnings if anything is
missing. Otherwise you can either perform an in-source or an
out-of-source build. The later should be your prefered choise.


In-Source-Build  {#SubSecInS}
---------------

The following command triple will compile the executable in the source
tree and install it on your system:

~~~{.sh}
cmake .
make
sudo make install
~~~

\note Omit `sudo` in case of non-LINUX systems.

\note In-Source-Builds polute the source tree by newly created files.

Out-Of-Source-Build  {#SubSecOoS}
-------------------

The following command quintuple will create a new *build* folder,
change to that folder, compile the executable and install it on your
system:

~~~{.sh}
mkdir build
cd build
cmake ..
make
sudo make install
~~~

\note Omit `sudo` in case of non-LINUX systems.


Documentation-Build  {#SubSecMakeDoc}
-------------------

The following command will build the documentation in form of an HTML
file tree (either in-source or out-of-source):

~~~{.sh}
make doc
~~~

\note Find the start file at *doc/html/index.html*.


Manual Compiling  {#SecManual}
================



build your personal binary of fb-doc.
It gets shipped as a FreeBasic source tree. Find the code in the
folder *src* in your *fb-doc.zip* archive. To create your binary you
need to install the [FreeBasic compiler
fbc](http://www.freebasic.net/get) for your operating system. Then just
extract the *fb-doc* folder to any place on your hard disk, change to
the folder *src* and compile the main file *fb-doc.bas*. Ie load the
file in to Geany IDE and choose menu <em>Build -> Compile</em>. Or call
the Freebasic compiler at the command line (in the extracted
folder *src*)
~~~{.sh}
cd src/bas
fbc -w all fb-doc.bas
~~~

This creates an executable binary named

- *fb-doc* (on UNIX-like systems) or
- *fb-doc.exe* (on other systems).

That's all you need to get started. Now you can use fb-doc and check
its features, ie translate FB code to intermediate C format or generate
templates.

Therefor you don't need a complex installation. Just place the compiled
binary in any of your source folders and execute it there (see \ref
PagUsage for details). Or you test your fb-doc executable on its own
source, find some examples in \ref SecExaCli.

To generate a real documentation &mdash; as mentioned in the
Introduction, fb-doc is not a complete documentation generator &mdash;
you have to install an additional back-end for C source, like

- [gtk-doc](http://developer.gnome.org/gtk-doc-manual/stable/index.html)
- [Doxygen](http://www.doxygen.org/)

Download one of these packages for your operating system and follow the
installation instruction. Both can get extended by using further tools.
Consider to install them too. (Ie the package
[GraphViz](http://www.graphviz.org/) is used to generate the
caller / callee graphs in this documentation.)

The first back-end is a good choise if you like to document a library
API in the GNOME documentation style. In all other cases &mdash;
especially when you have to document a program or application &mdash;
the later is the better choise. Doxygen is a more modern tool, it's
easier to handle, comes with a GUI front-end and has more features.

When you intend to use fb-doc in a regular basis and call it from
different folders for several projects, it's best to install fb-doc on
your system, as specified in one of the two following sections.


UNIX Installation  {#SubSecInsLin}
-----------------

It's recommended to create a link to the executable and move this link
to a folder in the system `PATH`. Using a link allows

- recompiling of the source (ie for a new release) and also
- using the fresh executable from any directory.

This can be done by executing in a terminal
~~~{.sh}
cd .../fb-doc/src
cp -l fb-doc ~/bin/fbdoc
~~~

Assuming that the folder `~/bin` is in your PATH you can now execute
fb-doc in each folder by calling the link. Try

\code{.sh}
cd ~
fbdoc --version
\endcode

and you should see the version information text in the terminal. This
solution works on your personal user account. When you need a system
wide installation that allows all users to access fb-doc, then you need
admin privileges to place the link in a similar system folder, ie in like
~~~{.sh}
cd .../fb-doc/src
sudo cp -l fb-doc /usr/bin/fbdoc
~~~

\note Replace `.../` by a proper path on your system.


DOS / windows Installation  {#SubSecInsWoe}
--------------------------

DOS doesn't support links and on the other system links don't work at
the terminal (AFAIK). So it's best to use a batch file to call the
fb-doc executable.

Here's the recommended way

-# create a folder `C:\bin` (or use an existing folder for batch files in you `PATH`)
-# ensure that this folder is in the system `PATH`
-# create a file named `fbdoc.bat` in this path with the following context

~~~{.bat}
C:\YOUR\PATH\TO\fb-doc\src\fb-doc.exe %*
~~~

Then test the installation by executing
~~~{.bat}
cd \
fbdoc --version
~~~

and you should see the version information text in the terminal.

\note Replace `C:\YOUR\PATH\TO` by a proper path on your system.


Geany IDE Installation  {#SecInsGeany}
======================

fb-doc can be used as a filter (= custom command) for Geany IDE. Using
this feature, we can send the current selection (a text fragment) to
the filter and receive the filtered output as replacement for the
selected text. From a user point of view it looks like paste a new text
block in to a previously selected section. Ie. the user can select a
function declaration, send it to \Proj and receive the original
context, prepended by the ducumentation for the function parameters.

To get this running, start Geany and choose menu item
*Edit->Format->Send Selection to->Set Custom Commands* and click on
*Add* to get a new item. Then type

~~~{.sh}
fbdoc --geany-mode
~~~

to use the default emitter for gtk-doc templates or select the emitter
for Doxygen templates by

~~~{.txt}
fbdoc --geany-mode "DoxygenTemplates"
~~~

To test the installation open a new editor window. Now right-click on
an empty line and choose menu item *Format->Send Selection
to->YOUR_NEW_COMMAND_ITEM*. The following text should appear (assuming
you're using the DoxygenTemplates setting)

\code{.txt}
/'* \file FIXME
\brief FIXME

FIXME

`/
\endcode

This is the output from the function \ref EmitterIF::Empty_() of the
`DoxygenTemplates` emitter. Such a comment block is used to start any
Doxygen input file.

If you don't get this text nor any other message in the editor then
check the *status* message tab (in the notebook window at the bottom)
to get a hint for solving the problem.

\note Instead of the right-click menu try also keybindings &mdash;
       `<Crtl>-[1 | 2 | 3]` is default. Find further details in [Geany
       documentation](http://www.geany.org/manual/current/index.html#sending-text-through-custom-commands").
\note This setting only works when fb-doc is installed in your system
       `PATH` (see previous sections for details). If you don't want to
       install fb-doc, you have to use the full path and the original
       name of the executable (ie like `/home/me/proj/fb-doc/src/fb-doc
       -g Doxy`).


Uninstall  {#SecUninstall}
=========

In order to uninstall the package, remove the files listed in the
file(s) `install_manifest.txt`. Ie. on Debian LINUX (or Ubuntu) execute

~~~{.sh}
sudo xargs rm < install_manifest.txt
~~~
