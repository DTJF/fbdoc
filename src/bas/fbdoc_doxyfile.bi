/'* \file fbdoc_doxyfile.bi
\brief Declarations for the DoxyUDT class

This file contains the declaration code for the DoxyUDT class, used to
read parameters from a Doxygen configuration file.

'/


/'* \brief Enumerators for the tags in the Doxyfile

Enumerators used for the STRING array Tags() in DoxyUDT. They're
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


'&typedef DoxyUDT* DoxyUDT_PTR; //!< Doxygen internal (ignore this).
/'* \brief Class to handle a Doxyfile

Load a Doxygen configuration file and parse its contents. In case of a
failure in finding or loading the file, the variable DoxyUDT.Errr gets
set in the constructor. It points to `NULL` (is empty) on success.

Currently only the first entry in a multi line tag gets parsed (just
the first parameter of a lists).

'/
TYPE DoxyUDT
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
