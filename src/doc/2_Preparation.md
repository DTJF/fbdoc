Preparation  {#PagInstall}
===========
\tableofcontents

As mentioned, this package ships the source code of \Proj. It has to
get compiled and linked to an executable binary first. Therefor at
least the FB compiler has to be installed on the users system. Other
tools are used by the author, here's how to get all components working.


# Tools  {#SecTools}

The following table lists all dependencies for \Proj and their
category. The FreeBASIC compiler is mandatory (M), the others are
optional. Some are recommended (R) in order to make use of all package
features. Some are helpful for testing (T) purposes. LINUX users may
find some packages in their distrubution management system (D).

|                                       Name  | Type |  Function                                                      |
| ------------------------------------------: | :--: | :------------------------------------------------------------- |
| [fbc](http://www.freebasic.net)             | M    | FreeBASIC compiler to compile the source code                  |
| [GIT](http://git-scm.com/)                  | R  D | version control system to organize the files                   |
| [CMake](http://www.cmake.org)               | R  D | build management system to build executables and documentation |
| [cmakefbc](http://github.com/DTJF/cmakefbc) | R    | FreeBASIC extension for CMake                                  |
| [Doxygen](http://www.doxygen.org/)          | R  D | documentation generator (ie. for this text)                    |
| [Graphviz](http://www.graphviz.org/)        | R  D | Graph Visualization Software (caller/callee graphs)            |
| [LaTeX](https://latex-project.org/ftp.html) | R  D | A document preparation system (PDF output)                     |
| [Geany](http://www.geany.org/)              | T  D | Integrated development environment (ie. to test templates)     |
| [gtk-doc](http://www.gtk.org/gtk-doc/)      | T  D | A further documentation generator (ie. for testing purposes)   |

It's beyond the scope of this guide to describe the installation for
those programming tools. Find detailed installation instructions on the
related websides, linked by the name in the first column.

-# First, install the distributed (D) packages of your choise. Ie. on
   Debian LINUX execute
   ~~~{.txt}
   sudo apt-get install git cmake doxygen graphviz texlive geany doxygen-latex
   ~~~

-# Make the FB compiler working. If you aren't confident about
   the task you can find a few notes on the [Installing
   FreeBASIC](http://www.freebasic.net/wiki/wikka.php?wakka=CompilerInstalling)
   wiki page.

-# Install cmakefbc, if wanted. That's easy, when you have GIT and CMake.
   Execute the commands
   ~~~{.txt}
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

## GIT  {#SubGit}

Using GIT is the prefered way to download the \Proj package (since it
helps users to get involved in to the development process). Get your
copy and change to the source tree by executing

~~~{.txt}
git clone https://github.com/DTJF/fb-doc
cd fb-doc
~~~

## ZIP  {#SubZip}

As an alternative you can download a Zip archive by clicking the
[Download ZIP](https://github.com/DTJF/fb-doc/archive/master.zip)
button on the \Proj website, and use your local Zip software to unpack
the archive. Then change to the newly created folder.


# Build  {#SecBuild}

Depending on whether the optional CMake package is installed
(recommended), the \Proj executable can either get compiled by the
build management scripts or has to get compiled manually.

## CMake Build  {#SubCMake}

The prefered way to build the executable and the documentation files is
to use the scripts for the CMake build system. The CMake scripts check
your system and through warnings if anything is missing. Depending on
the missing part this may end up by

- no build system (ie. when fbc is missing or too old)
- a partial build system (ie. no doc targets when Doxygen is missing)
- a full configured build system

Anyway, the first run will complain about the missing \Proj executable.
This executable has to get built and installed before the doc target
can get configured and used.


### Executable  {#SubCmakeExe}

Either  in-source or out-of-source builds are supported. The later
should be the prefered choise. Execute the following commands starting
at the root directory of the package.

#### In-Source-Build  {#SubCmakeISB}

The following command triple will compile the executable in the source
tree and install it on the system:

~~~{.txt}
cmake .
make
sudo make install
~~~

\note Omit `sudo` in case of non-LINUX systems.

\note In-Source-Builds polute the source tree by newly created files
      and folders.


#### Out-Of-Source-Build  {#SubCmakeOSB}

The following command quintuple will create a new *build* folder,
change to that folder, compile the executable and install it on the
system:

~~~{.txt}
mkdir build
cd build
cmake ..
make
sudo make install
~~~

\note Omit `sudo` in case of non-LINUX systems.


### Documentation-Build  {#SubCmakeDoc}

In order to build the documentation, all recommended packages listed in
section \ref SecTools have to get installed. This also means that the
\Proj executable has to get compiled and installed first.

The following command will build the documentation in form of an HTML
file tree and in form of a PDF file (either in-source or
out-of-source):

~~~{.txt}
make doc
~~~

\note Find the HTML start file at `doxy/html/index.html`.
\note Find the PDF file at `doxy/fb-doc.pdf`.

Both targets can get build separately by executing

~~~{.txt}
make doc_htm
make doc_pdf
~~~


### Uninstall  {#SubCmakeUninstall}

In order to uninstall the package, remove the files listed in the
file `install_manifest.txt`. Ie. on Debian LINUX (or Ubuntu) execute

~~~{.txt}
sudo xargs rm < install_manifest.txt
~~~


## Manual Build  {#SubManual}

Manual builds are laborious. They're necessary when the recommended
tools aren't installed.


### Executable  {#SubManExe}

The source code is located in folder `src/bas`.
Beside the module files this folder also contains a file named
`fb-doc.bas`, which collects all modules files in to a single source
tree, in order to compile all-in-one by executing

~~~{.txt}
cd src/bas
fbc -w all fbdoc.bas -x fb-doc
~~~

This creates an executable binary named

- `fb-doc` (on UNIX-like systems) or
- `fb-doc.exe` (on other systems).

That's all you need to get started. Now you can use \Proj and check
its features, see \ref SecExaTut for examples.


### Install  {#SubManInstall}

To install the program just copy the executable in to a directory of
your system `PATH`. Ie. on Debian LINUX execute

~~~{.txt}
cp src/bas/fb-doc /usr/local/bin
~~~


### Documentation  {#SubManDoc}

In order to build the documentation, all recommended packages listed in
section \ref SecTools have to get installed, exept CMake and cmakefbc.
This also means that the \Proj executable has to get compiled and
installed first.

The following command quadruple will build the documentation in form of
an HTML file tree and in form of a PDF file (either in-source or
out-of-source). Privious to the Doxygen run the list of function names
get updated and after the run the syntax highlighting of the source
code listings gets fixed.

~~~{.txt}
cd doxy
fb-doc -l
doxygen
fb-doc -s
~~~

\note Find the HTML start file at `doxy/html/index.html`. This does not
      create a PDF file by default. In order to get this format, you've
      to adapt the output settings in configuration file Doxyfile.

\note The original documentation gets build by the CMake scripts. They
      update some configuration in the Doxyfile. For manual builds you
      have to update this file manually.


### Uninstall  {#SubManUninstall}

In order to uninstall just remove the executable. Ie. on Debian LINUX
execute

~~~{.txt}
sudo rm /usr/local/bin/fb-doc
~~~


# Geany IDE Installation  {#SecGeanyInstall}

\Proj can be used as a filter (= custom command) for Geany IDE. Using
this feature, the current selection (a text fragment) can get sent to
the \Proj filter and Geany replaces the former selection by the
received filter output. From the user point of view it looks like paste
a new text block in to a previously selected section.

To get this working, Geany has to get started and the menu item `Edit
-> Format -> Send Selection to -> Set Custom Commands` needs to get
selected. In the newly opened dialog a click on `Add` creates a new
item with an entry box, which get filled by

~~~{.txt}
fb-doc --geany-mode "DoxygenTemplates"
~~~

to use the emitter for Doxygen templates. In order to use the default
emitter for gtk-doc templates just omit the quoted emitter name

~~~{.txt}
fb-doc --geany-mode
~~~

\note This assumes that \Proj is installed in any system `PATH`.
      Otherwise the complete path to the executable has to get
      prepended to the command.

To test the installation

-# open a new editor window,
-# right-click on an empty line and
-# choose menu item `Format -> Send Selection to -> YOUR_NEW_COMMAND_ITEM`.

The following text should appear (assuming you're using the
DoxygenTemplates setting)

\code{.txt}
/'* \file FIXME
\brief FIXME

FIXME

\since FIXME
'/
\endcode

If you don't get this text nor any other message in the editor window,
then check the `status` message tab (in the notebook window at the
bottom) to get a hint for solving the problem.

\note Instead of the right-click menu try also keybindings &mdash;
      `<Crtl>-[1|2|3]` is default. Find further details in [Geany
      documentation](http://www.geany.org/manual/current/index.html#sending-text-through-custom-commands").
