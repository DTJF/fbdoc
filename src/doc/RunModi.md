Run Modi  {#PagRunModi}
========
\tableofcontents

Run modi control the data flow in \Proj. They determine where to get
input from and where to send output to. See table \ref SecTabRunModi
for details.


Information Modes  {#SecInformationModes}
=================

Informational modi don't get any input. They output internal
information to the STDOUT stream, which is console output by default.

--help  {#SubSecModHelp}
------

The help run mode outputs a information on how to use \Proj. It lists all options with a brief description.


--version  {#SubSecModVersion}
---------

The version run mode outputs information on the \Proj binary, its version, build date and the target operating system.


Operation Modes  {#SecOperationModes}
===============

Operational modi are used in the daily \Proj workflow. They determine
the input and the output stream (see
table \ref SecTabRunModi). And they specify a default emitter, which can get overridden by option \ref
SubSecOptEmitter.

Default  {#SubSecModDefault}
-------

In default run mode \Proj acts as a Doxygen filter. It reads input from a single FB source code file

--file-mode  {#SubSecModFile}
-----------



--geany-mode  {#SubSecModGeany}
------------



--list-mode  {#SubSecModList}
-----------



--syntax-mode  {#SubSecModSyntax}
-------------

