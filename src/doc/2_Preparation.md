Preparation  {#PagInstall}
===========
\tableofcontents

In order to install and make use of the \Proj package, first, you've to

-# [install some programming tools](#SecTools) before you
-# [get the package](#SecGet) and
-# [compile your executable](#SecBuild).


# Programming tools  {#SecTools}

The following table lists all dependencies for \Proj and their types.
At least, you have to install the FreeBASIC compiler on your system to
build your \Proj executable. (Of course, later you'll need it for your
projects as well.) Beside this mandatory (M) tool, the others are
optional. Some are recommended (R) in order to make use of all package
features. Some are helpful for testing (T) purposes. LINUX users find
some packages in their distrubution management system (D).

|                                       Name  | Type |  Function                                                      |
| ------------------------------------------: | :--: | :------------------------------------------------------------- |
| [fbc](http://www.freebasic.net)             | M    | FreeBASIC compiler to compile the source code                  |
| [GIT](http://git-scm.com/)                  | R  D | version control system to organize the files                   |
| [CMake](http://www.cmake.org)               | R  D | build management system to build executables and documentation |
| [cmakefbc](http://github.com/DTJF/cmakefbc) | R    | FreeBASIC extension for CMake                                  |
| [Doxygen](http://www.doxygen.org/)          | R  D | documentation generator (ie. for this text)                    |
| [Graphviz](http://www.graphviz.org/)        | R  D | Graph Visualization Software (caller/callee graphs)            |
| [Geany](http://www.geany.org/)              | T  D | Integrated development environment (ie. to test templates)     |
| [gtk-doc](http://www.gtk.org/gtk-doc/)      | T  D | A further documentation generator (ie. for testing purposes)   |

It's beyond the scope of this guide to describe the installation for
those programming tools. Find detailed installation instructions on the
related websides, linked by the name in the first column.

-# First, install the distributed (D) packages of your choise.

-# Make the FB compiler working. If you aren't confident about
   the task you can find a few notes on the [Installing
   FreeBASIC](http://www.freebasic.net/wiki/wikka.php?wakka=CompilerInstalling)
   wiki page.

-# Install cmakefbc, if wanted. That's easy, when you have GIT and CMake.
   Execute the commands
   ~~~{.sh}
   git clone https://github.com/DTJF/cmakefbc
   cd cmakefbc
   mkdir build
   cd build
   cmake ..
   make
   sudo make install
   ~~~
   \note Omit `sudo` in case of non-LINUX systems.


# Get Package  {#SecGet}

Depending on whether you installed the optional GIT package, there're
two ways to get the \Proj package.

## GIT  {#SubSecGit}

Using GIT is the prefered way to download the \Proj package (since it
helps users to get involved in to the development process). Get your
copy and change to the source tree by executing

~~~{.sh}
git clone https://github.com/DTJF/fb-doc
cd fb-doc
~~~

## ZIP  {#SubSecZip}

As an alternative you can download a Zip archive by clicking the
[Download ZIP](https://github.com/DTJF/fb-doc/archive/master.zip)
button on the \Proj website, and use your local Zip software to unpack
the archive. Then change to the newly created folder.


# Build Executable  {#SecBuild}

Depending on whether you installed the optional CMake package, there're
two ways to build the \Proj executable.

## CMake Build System  {#SubSecCMake}

The prefered way to build the executable and the documentation files is
to use the scripts for the CMake build system. If you don't want to
install or to use CMake, then skip this section and continue at \ref
SubSecManual.

The CMake scripts check your system and through warnings if anything is
missing. Otherwise you can either perform an in-source or an
out-of-source build. The later should be your prefered choise.


### In-Source-Build  {#SubSubSecISB}

The following command triple will compile the executable in the source
tree and install it on your system:

~~~{.sh}
cmake .
make
sudo make install
~~~

\note Omit `sudo` in case of non-LINUX systems.

\note In-Source-Builds polute the source tree by newly created files.


### Out-Of-Source-Build  {#SubSubSecISB}

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


### Documentation-Build  {#SubSubSecDocB}

In order to build the documentation, all recommended packages listed in
section \ref SecTools have to get installed. The following command will
build the documentation in form of an HTML file tree and in form of a
PDF file (either in-source or out-of-source):

~~~{.sh}
make doc
~~~

\note Find the HTML start file at `doxy/html/index.html`.
\note Find the PDF file at `doxy/fb-doc.pdf`.

Both targets can get build separately by executing

~~~{.sh}
make doc_htm
make doc_pdf
~~~


## Manual Build  {#SubSecManual}

Manual builds are laborious. They're necessary when you don't have the
recommended tools installed. Find the source code in folder src/bas.
Beside the module files this folder contains a file named fb-doc.bas,
which collects all modules in to a single source tree, in order to
compile all-in-one by executing

~~~{.sh}
cd src/bas
fbc -w all fb-doc.bas
~~~

This creates an executable binary named

- *fb-doc* (on UNIX-like systems) or
- *fb-doc.exe* (on other systems).

That's all you need to get started. Now you can use \Proj and check
its features, ie. translate FB code to intermediate C format or generate
templates.

Therefor you don't need a complex installation. Just place the compiled
binary in any of your source folders and execute it there (see \ref
PagUsage for details). Or you test your \Proj executable on its own
source, find some examples in \ref SecExaCli.

To generate a real documentation &mdash; as mentioned in the
Introduction, \Proj is not a complete documentation generator &mdash;
you have to install an additional back-end for C source, like

- [gtk-doc](http://developer.gnome.org/gtk-doc-manual/stable/index.html)
- [Doxygen](http://www.doxygen.org/)

Download one of these packages for your operating system and follow the
installation instruction. Both can get extended by using further tools.
Consider to install them too. (Ie. the package
[GraphViz](http://www.graphviz.org/) is used to generate the
caller / callee graphs in this documentation.)

The first back-end is a good choise if you like to document a library
API in the GNOME documentation style. In all other cases &mdash;
especially when you have to document a program or application &mdash;
the later is the better choise. Doxygen is a more modern tool, it's
easier to handle, comes with a GUI front-end and has more features.

When you intend to use \Proj in a regular basis and call it from
different folders for several projects, it's best to install \Proj on
your system, as specified in one of the two following sections.








build your personal binary of \Proj.
It gets shipped as a FreeBASIC source tree. Find the code in the
folder *src* in your *fb-doc.zip* archive. To create your binary you
need to install the [FreeBASIC compiler
fbc](http://www.freebasic.net/get) for your operating system. Then just
extract the \Proj folder to any place on your hard disk, change to
the folder *src* and compile the main file *fb-doc.bas*. Ie. load the
file in to Geany IDE and choose menu <em>Build -> Compile</em>. Or call
the FreeBASIC compiler at the command line (in the extracted
folder *src*)


UNIX Installation  {#SubSecInsLin}
-----------------

It's recommended to create a link to the executable and move this link
to a folder in the system `PATH`. Using a link allows

- recompiling of the source (ie. for a new release) and also
- using the fresh executable from any directory.

This can be done by executing in a terminal
~~~{.sh}
cd .../fb-doc/src
cp -l fb-doc ~/bin/fb-doc
~~~

Assuming that the folder `~/bin` is in your PATH you can now execute
\Proj in each folder by calling the link. Try

\code{.sh}
cd ~
fb-doc --version
\endcode

and you should see the version information text in the terminal. This
solution works on your personal user account. When you need a system
wide installation that allows all users to access \Proj, then you need
admin privileges to place the link in a similar system folder, ie. in like
~~~{.sh}
cd .../fb-doc/src
sudo cp -l fb-doc /usr/bin/fb-doc
~~~

\note Replace `.../` by a proper path on your system.


DOS / windows Installation  {#SubSecInsWoe}
--------------------------

DOS doesn't support links and on the other system links don't work at
the terminal (AFAIK). So it's best to use a batch file to call the
\Proj executable.

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
fb-doc --version
~~~

and you should see the version information text in the terminal.

\note Replace `C:\YOUR\PATH\TO` by a proper path on your system.


Geany IDE Installation  {#SecInsGeany}
======================

\Proj can be used as a filter (= custom command) for Geany IDE. Using
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
fb-doc --geany-mode
~~~

to use the default emitter for gtk-doc templates or select the emitter
for Doxygen templates by

~~~{.txt}
fb-doc --geany-mode "DoxygenTemplates"
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
\note This setting only works when \Proj is installed in your system
       `PATH` (see previous sections for details). If you don't want to
       install \Proj, you have to use the full path and the original
       name of the executable (ie. like `/home/me/proj/fb-doc/src/fb-doc
       -g Doxy`).


Uninstall  {#SecUninstall}
=========

In order to uninstall the package, remove the files listed in the
file(s) `install_manifest.txt`. Ie. on Debian LINUX (or Ubuntu) execute

~~~{.sh}
sudo xargs rm < install_manifest.txt
~~~
