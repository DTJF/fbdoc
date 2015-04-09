# TOP: create executable

CMAKE_MINIMUM_REQUIRED(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/Modules/")
PROJECT(fb-doc Fbc)

# constants
SET(PROJ_NAME "fb-doc"             CACHE STRING "project name" FORCE)
SET(PROJ_DESC "FreeBASIC documentation tool" CACHE STRING "project description" FORCE)
SET(PROJ_VERS "0.4.0"              CACHE STRING "project version" FORCE)
SET(PROJ_AUTH "TJF"                CACHE STRING "project authors" FORCE)
SET(PROJ_MAIL "Thomas{ At ]Freiherr{ at }gmx[ dOt ]net"  CACHE STRING "project mail address" FORCE)
SET(PROJ_WEBS "http://github.com/DTJF/fb-doc" CACHE STRING "project website" FORCE)
SET(PROJ_LICE "GPLv3"              CACHE STRING "project licence" FORCE)
STRING(TIMESTAMP tmp "%Y" UTC)
SET(PROJ_YEAR "${tmp}"             CACHE STRING "project year" FORCE)

# transfer constants to FB source
SET(fnam ${CMAKE_CURRENT_SOURCE_DIR}/src/bas/version.bas)
CONFIGURE_FILE(${fnam}.in  ${fnam} @ONLY)

# the documentation construction folder
ADD_SUBDIRECTORY(doc)

# the source folders
#ADD_SUBDIRECTORY(src)

# fbdbg[.exe]: link the final executable
ADD_EXECUTABLE(${PROJ_NAME} src/bas/fb-doc.bas)
#SET_TARGET_PROPERTIES(fbdbg PROPERTIES
  #LINK_FLAGS "-export"
  #)

# installation
#INSTALL(FILES ${UI_FILES}
   #DESTINATION bin
   #)
#INSTALL(DIRECTORY src/dat src/img src/locale
  #DESTINATION bin
  #)
INSTALL(TARGETS ${PROJ_NAME}
  DESTINATION bin
  )

#SET(CPACK_GENERATOR "TBZ2")

# autogenerate dependency information
#SET(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
#SET(CPACK_GENERATOR "DEB")
#SET(CPACK_DEBIAN_PACKAGE_MAINTAINER "Thomas Freiherr") #required

#INCLUDE(CPack)
