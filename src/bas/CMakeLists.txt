CMAKE_MINIMUM_REQUIRED(VERSION 2.8.3)

# transfer constants to FB source
SET(fnam ${CMAKE_CURRENT_SOURCE_DIR}/fbdoc_version.bi)
CONFIGURE_FILE(${fnam}.in ${fnam} @ONLY)

SET(BAS_SRC
  "${CMAKE_CURRENT_SOURCE_DIR}/fbdoc_doxyfile.bas"
  "${CMAKE_CURRENT_SOURCE_DIR}/fbdoc_emit_csource.bas"
  "${CMAKE_CURRENT_SOURCE_DIR}/fbdoc_emit_doxy.bas"
  "${CMAKE_CURRENT_SOURCE_DIR}/fbdoc_emit_gtk.bas"
  "${CMAKE_CURRENT_SOURCE_DIR}/fbdoc_emit_lfn.bas"
  "${CMAKE_CURRENT_SOURCE_DIR}/fbdoc_emit_syntax.bas"
  "${CMAKE_CURRENT_SOURCE_DIR}/fbdoc_emitters.bas"
  "${CMAKE_CURRENT_SOURCE_DIR}/fbdoc_options.bas"
  "${CMAKE_CURRENT_SOURCE_DIR}/fbdoc_parser.bas"
  "${CMAKE_CURRENT_SOURCE_DIR}/fbdoc_main.bas"
  CACHE FILEPATH "BAS files" FORCE
  )
SET(EXT_SRC
  "${CMAKE_CURRENT_SOURCE_DIR}/plugins/empty.bas"
  "${CMAKE_CURRENT_SOURCE_DIR}/plugins/py_ctypes.bas"
  CACHE FILEPATH "Plugin source files" FORCE
  )

# fbdoc[.exe]: compile and link the final executable
ADD_EXECUTABLE(${PROJ_NAME} ${BAS_SRC})
SET(CMAKE_EXE_LINKER_FLAGS "-Wl -z,relro") # must override global flags
SET_TARGET_PROPERTIES(${PROJ_NAME} PROPERTIES
  COMPILE_FLAGS "-m fbdoc_main"
  LINK_FLAGS "-export"
  )

ADD_Fbc_SRC_DEPS(${PROJ_NAME})
#ADD_FILE_DEPENDENCIES(${CMAKE_CURRENT_SOURCE_DIR}/fbdoc_main.bas ${fnam}.in)
#ADD_DEPENDENCIES(${PROJ_NAME} ${fnam})

INSTALL(TARGETS ${PROJ_NAME}
  DESTINATION bin
  )

