# Build / install the documentation.
#
# Note: this script needs an fb-doc version (0.4).

CMAKE_MINIMUM_REQUIRED(VERSION 2.8.3)

IF(NOT COMMAND FB_DOCUMENTATION)
  INCLUDE(UseFb-Doc)
ENDIF()

FB_DOCUMENTATION(
BAS_SRC
  ${BAS_SRC}
  ../src/bas/plugins/empty.bas
  ../src/bas/plugins/py_ctypes.bas
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
  ../src/doc/z_ChangeLog.md
  Doxyfile
  fb-doc.css
  fb-doc.xml
#NO_SYNTAX
  )
