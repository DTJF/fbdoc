/'* \file fb-doc_doxyfile.bi
\brief Declarations for the \ref Doxyfile class

This file contains the declaration code for the Doxyfile class, used to
read parameters from a Doxyfile.

'/


/'* \brief enumerators for the tags in the Doxyfile

Enumerators used for the STRING array Tags() in UDT Doxyfile. They're
named after the tag names in the Doxyfile. Exeption: INPUT gets
INPUT_TAG (due to FB keyword collision).

'/
ENUM DoxyTags
  GENERATE_HTML       '*< the tag GENERATE_HTML
  SOURCE_BROWSER      '*< the tag SOURCE_BROWSER
  GENERATE_LATEX      '*< the tag GENERATE_LATEX
  LATEX_SOURCE_CODE   '*< the tag LATEX_SOURCE_CODE
  GENERATE_XML        '*< the tag GENERATE_XML
  XML_PROGRAMLISTING  '*< the tag XML_PROGRAMLISTING
  INPUT_TAG           '*< the tag INPUT
  RECURSIVE           '*< the tag RECURSIVE
  OUTPUT_DIRECTORY    '*< the tag OUTPUT_DIRECTORY
  HTML_OUTPUT         '*< the tag HTML_OUTPUT
  HTML_FILE_EXTENSION '*< the tag HTML_FILE_EXTENSION
  CREATE_SUBDIRS      '*< the tag CREATE_SUBDIRS
  LATEX_OUTPUT        '*< the tag LATEX_OUTPUT
  XML_OUTPUT          '*< the tag XML_OUTPUT
END ENUM

/'* \brief handle a Doxyfile

Load a Doxyfile and parse its coontext. In case of failure finding or
loading the file the Errr variable gets set in the constructor. Its
empty on success.

Currently only the first entry in a tags gets parsed (just the first
parameter of a lists).

'/
TYPE Doxyfile
  AS INTEGER Length   '*< the length of the buffer
  AS UBYTE PTR Buffer '*< the buffer data
  AS ZSTRING PTR _
    Doxy = @"empty"   '*< a pointer to interprete the data as STRING
  AS STRING _
    Errr _            '*< an error message (if any)
  , Tags(XML_OUTPUT)  '*< an array containing the tags context

  DECLARE CONSTRUCTOR(BYREF AS STRING)
  DECLARE DESTRUCTOR()
  DECLARE FUNCTION Search(BYREF AS STRING, BYREF AS INTEGER) AS STRING
  DECLARE PROPERTY Tag(BYVAL AS INTEGER) AS STRING
END TYPE
