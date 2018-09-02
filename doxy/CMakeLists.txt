# Build / install the documentation.
#
# Note: this script needs an fbdoc version (0.4.4).

CMAKE_MINIMUM_REQUIRED(VERSION 2.8.3)

IF(NOT COMMAND FB_DOCUMENTATION)
  INCLUDE(UseFbDoc)
  IF(NOT COMMAND FB_DOCUMENTATION)
    MSG_LOG("!! no targets <doc...> (UseFbDoc.cmake failed)")
    RETURN()
  ENDIF()
ENDIF()
MSG_LOG(">> targets <doc...> OK")

FB_DOCUMENTATION(
BAS_SRC
  ${BAS_SRC}
  ${EXT_SRC}
DEPENDS
  ../CMakeLists.txt
  ../ReadMe.md
  ../src/doc/1_Introduction.md
  ../src/doc/2_Preparation.md
  #../src/doc/3_Usage.md
  ../src/doc/4_Examples.md
  #../src/doc/5_Tables.md
  #../src/doc/6_RunModi.md
  ../src/doc/7_Options.md
  ../src/doc/8_Emitters.md
  #../src/doc/9_Extend.md
  ../src/doc/A_Files.md
  ../src/doc/B_TipsTricks.md
  ../src/doc/F_Plugin.md
  ../src/doc/z_ChangeLog.md
  Doxyfile
  fbdoc.css
  fbdoc.xml
#NO_SYNTAX
  )
