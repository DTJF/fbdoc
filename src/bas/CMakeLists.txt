CMAKE_MINIMUM_REQUIRED(VERSION 2.8.3)

# transfer constants to FB source
SET(fnam ${CMAKE_CURRENT_SOURCE_DIR}/fb-doc_version.bi)
CONFIGURE_FILE(${fnam}.in ${fnam} @ONLY)

SET(BAS_SRC
  "${CMAKE_CURRENT_SOURCE_DIR}/fb-doc_doxyfile.bas"
  "${CMAKE_CURRENT_SOURCE_DIR}/fb-doc_emit_csource.bas"
  "${CMAKE_CURRENT_SOURCE_DIR}/fb-doc_emit_doxy.bas"
  "${CMAKE_CURRENT_SOURCE_DIR}/fb-doc_emit_gtk.bas"
  "${CMAKE_CURRENT_SOURCE_DIR}/fb-doc_emit_lfn.bas"
  "${CMAKE_CURRENT_SOURCE_DIR}/fb-doc_emit_syntax.bas"
  "${CMAKE_CURRENT_SOURCE_DIR}/fb-doc_emitters.bas"
  "${CMAKE_CURRENT_SOURCE_DIR}/fb-doc_options.bas"
  "${CMAKE_CURRENT_SOURCE_DIR}/fb-doc_parser.bas"
  "${CMAKE_CURRENT_SOURCE_DIR}/fb-doc_main.bas"
  CACHE FILEPATH "BAS files" FORCE
  )
#SET(BAS_SRC
  #fb-doc_doxyfile.bas
  #fb-doc_emit_lfn.bas
  #fb-doc_emit_doxy.bas
  #fb-doc_emit_gtk.bas
  #fb-doc_emit_syntax.bas
  #fb-doc_emitters.bas
  #fb-doc_options.bas
  #fb-doc_parser.bas
  #fb-doc_main.bas
  #CACHE FILEPATH "BAS files" FORCE
  #)

# fb-doc[.exe]: compile and link the final executable
ADD_EXECUTABLE(${PROJ_NAME} ${BAS_SRC})
SET_TARGET_PROPERTIES(${PROJ_NAME} PROPERTIES
  COMPILE_FLAGS "-m fb-doc_main"
  LINK_FLAGS "-export"
  )
ADD_Fbc_SRC_DEPS(${PROJ_NAME})
#ADD_FILE_DEPENDENCIES(${CMAKE_CURRENT_SOURCE_DIR}/fb-doc_main.bas ${fnam}.in)
#ADD_DEPENDENCIES(${PROJ_NAME} ${fnam})

INSTALL(TARGETS ${PROJ_NAME}
  DESTINATION bin
  )

