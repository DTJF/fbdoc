# TOP: create executable

CMAKE_MINIMUM_REQUIRED(VERSION 2.8.3)

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/Modules/")
PROJECT(fb-doc Fbc)

# constants
SET(PROJ_NAME "fb-doc"             CACHE STRING "project name" FORCE)
SET(PROJ_DESC "FreeBASIC documentation tool" CACHE STRING "project description" FORCE)
SET(PROJ_VERS "0.4.0"               CACHE STRING "project version" FORCE)
SET(PROJ_AUTH "DTJF"               CACHE STRING "project authors" FORCE)
SET(PROJ_MAIL "Thomas{ At ]Freiherr{ at }gmx[ dOt ]net"  CACHE STRING "project mail address" FORCE)
SET(PROJ_WEBS "http://github.com/DTJF/fb-doc" CACHE STRING "project website" FORCE)
SET(PROJ_LICE "GPLv3"              CACHE STRING "project licence" FORCE)
STRING(TIMESTAMP tmp "%Y" UTC)
SET(PROJ_YEAR "${tmp}"             CACHE STRING "project year" FORCE)

CONFIGURE_FILE(src/doc/_ReadMe.md.in ${CMAKE_SOURCE_DIR}/ReadMe.md @ONLY)

# the source folders
ADD_SUBDIRECTORY(src/bas)

# the plugin examples folders
ADD_SUBDIRECTORY(src/bas/plugins)

# the documentation construction folder
ADD_SUBDIRECTORY(doxy)

#SET(CPACK_GENERATOR "TBZ2")

# autogenerate dependency information
#SET(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
#SET(CPACK_GENERATOR "DEB")
#SET(CPACK_DEBIAN_PACKAGE_MAINTAINER "Thomas Freiherr") #required

#INCLUDE(CPack)
