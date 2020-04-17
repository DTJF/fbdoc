# TOP: create executable

CMAKE_MINIMUM_REQUIRED(VERSION 2.8.3)

#SET(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake/Modules/")

# constants
SET(PROJ_NAME "fbdoc"              CACHE STRING "project name" FORCE)
SET(PROJ_DESC "FreeBASIC documentation tool" CACHE STRING "project description" FORCE)
SET(PROJ_VERS "1.0.1"              CACHE STRING "project version" FORCE) #!3-numbers!
SET(PROJ_AUTH "DTJF"               CACHE STRING "project authors" FORCE)
SET(PROJ_MAIL "Thomas{ At ]Freiherr{ at }gmx[ dOt ]net"  CACHE STRING "project mail address" FORCE)
SET(PROJ_WEBS "http://github.com/DTJF/fbdoc" CACHE STRING "project website" FORCE)
SET(PROJ_LICE "GPLv3"              CACHE STRING "project licence" FORCE)
#STRING(TIMESTAMP tmp "%Y" UTC)
#SET(PROJ_YEAR "${tmp}"             CACHE STRING "project year" FORCE)
SET(PROJ_YEAR "2020"             CACHE STRING "project year" FORCE)

FUNCTION(MSG_LOG Txt)
  FILE(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeOutput.log "${Txt}\n\n")
  MESSAGE(STATUS ${Txt})
ENDFUNCTION()

PROJECT(${PROJ_NAME} Fbc)

CONFIGURE_FILE(src/doc/_ReadMe.md.in ${CMAKE_SOURCE_DIR}/ReadMe.md @ONLY)

# the source folders
ADD_SUBDIRECTORY(src/bas)

# the plugin examples folders
ADD_SUBDIRECTORY(src/bas/plugins)

# the documentation construction folder
ADD_SUBDIRECTORY(doxy)

# the Debian package folder
IF(UNIX)
  ADD_SUBDIRECTORY(debian)
  IF(CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)             # in-source
    ADD_CUSTOM_TARGET(distclean make clean
      COMMAND rm -rf debian/${PROJ_NAME}
      COMMAND rm -rf debian/${PROJ_NAME}.*.*
      COMMAND rm -rf `find . -iname Makefile -print`
      COMMAND rm -rf `find . -name CMakeCache.txt -print`
      COMMAND rm -rf `find . -name CMakeFiles -print`
      COMMAND rm -rf `find . -name cmake_install.cmake -print`
      COMMAND rm -rf `find . -name install_manifest.txt -print`
      COMMAND rm -rf doxy/DoxyExtension doxy/HtmOut doxy/PdfOut doxy/fbdoc.lfn doxy/doxygen_sqlite3.db
      COMMAND rm -rf doxy/html/ doxy/latex/
      )
  ELSE()                                                 # out-of-source
    ADD_CUSTOM_TARGET(distclean rm -R *)
  ENDIF()
ENDIF()

#SET(CPACK_GENERATOR "TBZ2")

# autogenerate dependency information
#SET(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
#SET(CPACK_GENERATOR "DEB")
#SET(CPACK_DEBIAN_PACKAGE_MAINTAINER "Thomas Freiherr") #required

#INCLUDE(CPack)
