# - This module looks for fb-doc tool to generate documentation by the
#   Doxygen generator.  Please see
# http://github.com/DTJF/fb-doc
#
# This modules defines the following variables:
#
#   FbDoc_EXECUTABLE     = The path to the fb-doc command.
#   FbDoc_WORKS          = Was fb-doc found or not?
#   FbDoc_VERSION        = The version reported by fb-doc --version
#

#=============================================================================
# Copyright (C) 2014-2015, Thomas{ dOt ]Freiherr[ aT ]gmx[ DoT }net
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file Copyright.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================
# (To distribute this file outside of CMake, substitute the full
#  License text for the above reference.)

IF(NOT FbDoc_WORKS)
  SET(fbdoc "fb-doc")
  SET(minvers "0.4.0")

  FIND_PROGRAM(FbDoc_EXECUTABLE
    NAMES ${fbdoc}
    DOC "${fbdoc} documentation generation tool (http://github.com/DTJF/fb-doc)"
  )

  IF(FbDoc_EXECUTABLE EQUAL "")
    MESSAGE(FATAL_ERROR "${fbdoc} tool not found! (tried command ${fbdoc})")
    FILE(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log
      "Finding the ${fbdoc} tool failed!")
    RETURN()
  ENDIF()

  EXECUTE_PROCESS(
    COMMAND ${FbDoc_EXECUTABLE} -v
    RESULT_VARIABLE result
    ERROR_VARIABLE output
    OUTPUT_STRIP_TRAILING_WHITESPACE
    )

  IF(NOT (result EQUAL "0"))
    MESSAGE(FATAL_ERROR "${fbdoc} tool not executable! (tried command ${fbdoc})")
    FILE(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log
      "Executing the ${fbdoc} tool failed!")
    RETURN()
  ENDIF()

  STRING(REGEX MATCH "[0-9][.][0-9][.][0-9]" FbDoc_VERSION "${output}")
  STRING(COMPARE LESS "${FbDoc_VERSION}" "${minvers}" not_working)

  IF(not_working)
    MESSAGE(STATUS "${fbdoc}-${FbDoc_VERSION} found, but required is ${minvers} ==> 'make doc' not available!")
    FILE(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log
      "Determining if the ${fbdoc} tool works failed with "
      "the following output:\n${output}\n\n")
    RETURN()
  ENDIF()

  MESSAGE(STATUS "Check for working ${fbdoc} tool OK ==> ${FbDoc_EXECUTABLE} (${FbDoc_VERSION})")
  SET(FbDoc_EXECUTABLE "${FbDoc_EXECUTABLE}" CACHE FILEPATH "${fbdoc} tool" FORCE)
  SET(FbDoc_VERSION "${FbDoc_VERSION}" CACHE STRING "${fbdoc} version" FORCE)
  SET(FbDoc_WORKS "1" CACHE FILEPATH "${fbdoc} tool" FORCE)
  MARK_AS_ADVANCED(
    FbDoc_EXECUTABLE
    FbDoc_WORKS
    FbDoc_VERSION
    )
  FILE(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeOutput.log
    "Determining if the ${fbdoc} tool works passed with "
    "the following output:\n${output}\n\n")
ENDIF()
