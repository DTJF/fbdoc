/'* \file fb-doc_doxyfile.bas
\brief The source code for the \ref Doxyfile class

This file contains the source code for a class used to read parameters
from a Doxyfile, a file that contain settings to control the operations
of Doxygen. fb-doc reads this files to operate on the same folders and
files as Doxygen.

This is used in modes `--list-mode` and `--syntax-mode`.

'/

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
  AS STRING Errr

  DECLARE CONSTRUCTOR(BYREF AS STRING)
  DECLARE DESTRUCTOR()
  DECLARE FUNCTION Tag(BYREF AS STRING) AS STRING
END TYPE


/'* \brief construct reading a Doxyfile
\param Fnam The (path and) file name

The constructor tries to find and read the Doxyfile. In case of
errors the variable Errr contains an error message. Its empty
otherwise and the context can get parsed by the function \ref Tag().

'/
CONSTRUCTOR Doxyfile(BYREF Fnam AS STRING)
  VAR fnr = FREEFILE
  IF OPEN(Fnam FOR INPUT AS fnr) THEN errr = "error (couldn't open)" : EXIT CONSTRUCTOR

  Length = LOF(fnr)
  Buffer = ALLOCATE(Length + 1)
  IF 0 = Buffer THEN errr = "error (out of memory)" : CLOSE #fnr : Length = 0 : EXIT CONSTRUCTOR

  VAR bytes_red = 0
  GET #fnr, 1, *Buffer, Length, bytes_red
  IF Length <> bytes_red THEN _
    errr = "read error (red " & bytes_red & " of " & Length & " bytes)" : Length = 0 : EXIT CONSTRUCTOR
  Buffer[bytes_red] = 0
  Doxy = CAST(ZSTRING PTR, Buffer)
  CLOSE #fnr
END CONSTRUCTOR

/'* \brief destructor freeing the memory used

The destructor frees the memory allocated in the constructor, if any.

'/
DESTRUCTOR Doxyfile()
  IF Buffer THEN DEALLOCATE(Buffer)
END DESTRUCTOR

/'* \brief find a single line tag in the Doxyfile and return its value
\param Su the tag to search for
\returns the tags value (if any))

This function is designed to find a value of an Doxyfile tag. It
return the tags context or an empty string if the tag has no value
or cannot be found.

'/
FUNCTION Doxyfile.Tag(BYREF Su AS STRING) AS STRING
  VAR p1 = INSTR(*Doxy, !"\n" & Su & " ") : IF 0 = p1 THEN RETURN ""
  VAR p2 = INSTR(p1 + LEN(Su), *Doxy, "="), _
      p3 = INSTR(p2 + 1, *Doxy, !"\n") - 1
  RETURN TRIM(MID(*Doxy, p2 + 1, p3 - p2), ANY !" \t\v\\")
END FUNCTION

