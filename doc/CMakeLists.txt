# build rules to create the documentation

CMAKE_MINIMUM_REQUIRED(VERSION 2.8.3)

# check for Doxygen
INCLUDE(FindDoxygen)
IF(NOT DOXYGEN_FOUND)
  MESSAGE(STATUS "Doxygen not found ==> target doc not available!")
  FILE(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log
    "Determining if doxygen works failed\n\n")
  RETURN()
ENDIF()

# check for fbdoc tool (note: not fb-doc)
IF(NOT FBDOC_WORKS)
  EXECUTE_PROCESS(
    COMMAND fbdoc -v
    RESULT_VARIABLE result
	  ERROR_VARIABLE output
    OUTPUT_STRIP_TRAILING_WHITESPACE
    )

  IF(NOT (result EQUAL "0"))
    MESSAGE(FATAL_ERROR "fbdoc tool not found! (tried command fbdoc)")
    FILE(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log
      "Finding the fbdoc tool failed!")
    RETURN()
  ENDIF()

  STRING(REGEX MATCH "[0-9][.][0-9][.][0-9]" FBDOC_ID "${output}")
  STRING(COMPARE LESS "${FBDOC_ID}" "0.3.9" not_working)

  IF(not_working)
    MESSAGE(STATUS "fbdoc-${FBDOC_ID} found, but required is 0.3.9 ==> 'make doc' not available!")
    FILE(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log
      "Determining if the fbdoc tool works failed with "
      "the following output:\n${output}\n\n")
    RETURN()
  ENDIF()

  MESSAGE(STATUS "Check for working fbdoc tool OK ==> ${FBDOC_ID}")
  SET(FBDOC_WORKS "1" CACHE FILEPATH "fbdoc tool" FORCE)
  MARK_AS_ADVANCED(FBDOC_WORKS)
  FILE(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeOutput.log
    "Determining if the fbdoc tool works passed with "
    "the following output:\n${output}\n\n")
ENDIF()

# HTML and PDF build here, always from scratch and in source directory
SET(PDF_FILE ${CMAKE_CURRENT_BINARY_DIR}/latex/refman.pdf)
SET(HTM_FILE ${CMAKE_CURRENT_BINARY_DIR}/html/index.html)

SET(inp ${CMAKE_CURRENT_SOURCE_DIR}/Doxyfile)
SET(lfn ${CMAKE_CURRENT_SOURCE_DIR}/fb-doc.lfn)
SET(MD_SRC
    ../ReadMe.md
    ../src/doc/Development.md
    ../src/doc/Emitters.md
    ../src/doc/Examples.md
    ../src/doc/Extend.md
    ../src/doc/Files.md
    ../src/doc/Installation.md
    ../src/doc/Introduction.md
    ../src/doc/Options.md
    ../src/doc/Tables.md
    ../src/doc/Usage.md
  )

IF(CMAKE_CURRENT_BINARY_DIR STREQUAL
   CMAKE_CURRENT_SOURCE_DIR)
  SET(doxyconf ${CMAKE_BINARY_DIR}/CMakeFiles/Doxyfile)
ELSE()
  SET(doxyconf ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile)
ENDIF()

IF(UNIX)
SET(com cat)
ELSE()
SET(com type)
ENDIF()

CONFIGURE_FILE(DoxyExtension.in DoxyExtension @ONLY)

ADD_CUSTOM_COMMAND(OUTPUT ${lfn}
  COMMAND fbdoc -l
  #DEPENDS ../cmake_fb_deps/cmake_fb_deps.bas
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  )

ADD_CUSTOM_COMMAND(OUTPUT ${doxyconf}
  COMMAND ${CMAKE_COMMAND} -E copy ${inp} ${doxyconf}
  COMMAND ${com} DoxyExtension >> ${doxyconf}
  DEPENDS ${inp} ${CMAKE_CURRENT_SOURCE_DIR}/DoxyExtension.in
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
  )

ADD_CUSTOM_COMMAND(OUTPUT ${HTM_FILE}
  COMMAND ${DOXYGEN_EXECUTABLE} ${doxyconf}
  COMMAND fbdoc -s
  DEPENDS ${lfn} ${doxyconf} ${MD_SRC}
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  )
ADD_CUSTOM_COMMAND(OUTPUT ${PDF_FILE}
  COMMAND make
  DEPENDS ${HTM_FILE}
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/latex
  )

ADD_CUSTOM_TARGET(doc DEPENDS ${HTM_FILE} ${doxyconf})
ADD_CUSTOM_TARGET(doc_pdf DEPENDS ${PDF_FILE})

