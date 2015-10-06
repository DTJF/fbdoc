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


--version  {#SubSecModVersion}
---------



Operation Modes  {#SecOperationModes}
===============

Operational modi are used in the daily \Proj workflow. They determine
the input and the output stream. And they specify a default emitter (see
table \ref SecTabRunModi), which can get overridden by option \ref
SubSecOptEmitter.

Default  {#SubSecModDefault}
-------



--file-mode  {#SubSecModFile}
-----------



--geany-mode  {#SubSecModGeany}
------------



--list-mode  {#SubSecModList}
-----------



--syntax-mode  {#SubSecModSyntax}
-------------

