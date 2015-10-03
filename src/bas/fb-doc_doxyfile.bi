/'* \file fb-doc_doxyfile.bi
\brief The source code for the \ref Doxyfile class

This file contains the declaration code for a class used to read
parameters from a Doxyfile, a file that contain settings to control the
operations of Doxygen. fb-doc reads this files to operate on the same
folders and files as Doxygen.

This is used in modes `--list-mode` and `--syntax-mode`.

'/


/'* \brief enumerators for the tags in the Doxyfile

Enumerators used for the STRING array Tags() in UDT Doxyfile. They're
named after the tag names in the Doxyfile. Exeption: INPUT gets
INPUT_TAG.

'/
ENUM
  GENERATE_HTML
  SOURCE_BROWSER
  GENERATE_LATEX
  LATEX_SOURCE_CODE
  GENERATE_XML
  XML_PROGRAMLISTING
  INPUT_TAG
  RECURSIVE
  OUTPUT_DIRECTORY
  HTML_OUTPUT
  HTML_FILE_EXTENSION
  CREATE_SUBDIRS
  LATEX_OUTPUT
  XML_OUTPUT
END ENUM

/'* \brief handle a Doxyfile

Read a Doxyfile and parse its coontext. In case of errors finding or
loading the file the Errr variable gets set in the constructor. Its
empty on success. Currently only single line tags are supported (no
lists).

'/
TYPE Doxyfile
  AS INTEGER Length
  AS UBYTE PTR Buffer
  AS ZSTRING PTR Doxy = @"empty"
  AS STRING Errr _
  , Tags(XML_OUTPUT)

  DECLARE CONSTRUCTOR(BYREF AS STRING)
  DECLARE DESTRUCTOR()
  DECLARE FUNCTION Search(BYREF AS STRING, BYREF AS INTEGER) AS STRING
  DECLARE PROPERTY Tag(BYVAL AS INTEGER) AS STRING
END TYPE
