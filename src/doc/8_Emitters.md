Emitters  {#PagEmitters}
========
\tableofcontents

Emitters generate the output of \Proj, which gets either written to the
stream `STDOUT` or to files, depending on the choosen run mode. An
emitter provides a set of functions of type EmitFunc, specified in the
class EmitterIF. When the parser evaluates the input and finds a
documentation related construct, it calls the emitter function for that
type of code. The emitter function transforms the FB source code to the
desired output format, either by using variables provided by the parser
or by evaluating the source code directly. Documentation relevant
constructs are

|            Construct | Keywords                                           |
| -------------------: | :------------------------------------------------- |
|            variables | `VAR  DIM  REDIM  CONST  COMMON  EXTERN  STATIC`   |
|               blocks | `ENUN  UNION  TYPE  CLASS`                         |
| forward declarations | `DECLARE  TYPE  TYPE alias`                        |
|            functions | `SUB  FUNCTION  PORPERTY  CONSTRUCTOR  DESTRUCTOR` |
|               macros | #`DEFINE`  #`MACRO`                                |
|             includes | #`INCLUDE`                                         |

\Proj gets shipped with inbuild emitters for the standard tasks, which
are described in this chapter. It also contains an interface for
external emitters (= plugins) to extend its features. See \ref
SecEmmEx for details.



# Inbuild emitters  {#SecEmmIn}


## C_Source  {#SecEmmCSource}


## GtkDocTemplates  {#SecEmmGtk}


## DoxygenTemplates  {#SecEmmDoxy}


## FunctionNames  {#SecEmmLfn}


## SyntaxHighlighting  {#SecEmmSyntax}


# External emitters  {#SecEmmEx}
