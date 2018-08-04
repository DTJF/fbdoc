CMAKE_MINIMUM_REQUIRED(VERSION 2.8.3)

SET(bas
  empty
  py_ctypes
  )

# compile and link the plugins
FOREACH(tar ${bas})
  ADD_LIBRARY(${tar} SHARED ${tar}.bas)
  SET_TARGET_PROPERTIES(${tar} PROPERTIES
    COMPILE_FLAGS "-d __FB_DOC_PLUGIN__=-1 -Wc -fPIC"
    )
  ADD_Fbc_SRC_DEPS(${tar})
ENDFOREACH()
