CMAKE_MINIMUM_REQUIRED(VERSION 2.8.3)

SET(bas
  empty
  py_ctypes
  )

SET(CMAKE_SHARED_LINKER_FLAGS "-Wl -z,relro") # must override global flags

# compile and link the plugins
FOREACH(tar ${bas})
  ADD_LIBRARY(${tar} SHARED ${tar}.bas)
  SET_TARGET_PROPERTIES(${tar} PROPERTIES
    COMPILE_FLAGS "-d __FB_DOC_PLUGIN__=-1 -Wc -fPIC"
    )
  ADD_Fbc_SRC_DEPS(${tar})
ENDFOREACH()
