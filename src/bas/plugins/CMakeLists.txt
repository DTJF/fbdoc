CMAKE_MINIMUM_REQUIRED(VERSION 2.8.3)

SET(bas
  empty
  py_ctypes
  )

FOREACH(tar ${bas})
  ADD_LIBRARY(${tar} SHARED ${tar}.bas)
  SET_TARGET_PROPERTIES(${tar} PROPERTIES
    COMPILE_FLAGS "-d __FB_DOC_PLUGIN__=-1 -Wc -fPIC"
    )
  ADD_Fbc_SRC_DEPS(${tar})
ENDFOREACH()

## compile and link the empty plugin
#ADD_LIBRARY(empty empty.bas)
#SET_TARGET_PROPERTIES(empty PROPERTIES
  #COMPILE_FLAGS "-Wc -fPIC"
  #)
#ADD_Fbc_SRC_DEPS(empty)

## compile and link the empty plugin
#ADD_LIBRARY(py_ctypes py_ctypes.bas)
#SET_TARGET_PROPERTIES(py_ctypes PROPERTIES
  #COMPILE_FLAGS "-Wc -fPIC"
  #)
#ADD_Fbc_SRC_DEPS(empty)

#ADD_FILE_DEPENDENCIES(${CMAKE_CURRENT_SOURCE_DIR}/fb-doc_main.bas ${fnam}.in)
#ADD_DEPENDENCIES(${PROJ_NAME} ${fnam})


