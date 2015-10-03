# build rules to create the documentation

CMAKE_MINIMUM_REQUIRED(VERSION 2.8.3)

# check for fb-doc tool
INCLUDE(FindFb-Doc)
IF(NOT FbDoc_WORKS)
  MESSAGE(STATUS "fb-doc tool not found ==> targets doc, doc_htm and doc_pdf not available!")
  FILE(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log
    "Determining if fb-doc tool works failed\n\n")
  RETURN()
ENDIF()

# check for Doxygen
INCLUDE(FindDoxygen)
IF(NOT DOXYGEN_FOUND)
  MESSAGE(STATUS "Doxygen not found ==> target doc not available!")
  FILE(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log
    "Determining if doxygen works failed\n\n")
  RETURN()
ENDIF()


# HTML and PDF build here, always from scratch and in source directory
SET(PDF_FILE ${CMAKE_CURRENT_BINARY_DIR}/latex/refman.pdf)
SET(HTM_FILE ${CMAKE_CURRENT_BINARY_DIR}/html/index.html)

SET(htmcon ${CMAKE_CURRENT_BINARY_DIR}/HtmlDoc)
SET(pdfcon ${CMAKE_CURRENT_BINARY_DIR}/PdfDoc)
SET(lfn ${CMAKE_CURRENT_SOURCE_DIR}/fb-doc.lfn)
SET(MD_SRC
    ../ReadMe.md
    ../src/doc/ChangeLog.md
    ../src/doc/Emitters.md
    ../src/doc/Examples.md
    ../src/doc/Extend.md
    ../src/doc/Files.md
    ../src/doc/Introduction.md
    ../src/doc/Options.md
    ../src/doc/Preparation.md
    ../src/doc/RunModi.md
    ../src/doc/Tables.md
    ../src/doc/Usage.md
  )

CONFIGURE_FILE(${CMAKE_CURRENT_SOURCE_DIR}/DoxyExtension.in ${CMAKE_CURRENT_BINARY_DIR}/DoxyExtension @ONLY)
CONFIGURE_FILE(${CMAKE_CURRENT_SOURCE_DIR}/HtmlDoc.in ${htmcon} @ONLY)
CONFIGURE_FILE(${CMAKE_CURRENT_SOURCE_DIR}/PdfDoc.in  ${pdfcon} @ONLY)

ADD_CUSTOM_COMMAND(OUTPUT ${lfn}
  COMMAND ${FbDoc_EXECUTABLE} -l
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  )

ADD_CUSTOM_COMMAND(OUTPUT ${HTM_FILE}
  COMMAND ${DOXYGEN_EXECUTABLE} ${htmcon}
  #COMMAND echo 'HIER ---> ${DOXYGEN_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/HtmlDoc'
  COMMAND ${FbDoc_EXECUTABLE} -s ${htmcon}
  #COMMAND echo 'HIER ---> ${FbDoc_EXECUTABLE} -s  ${CMAKE_CURRENT_BINARY_DIR}/HtmlDoc'
  DEPENDS
    ${lfn}
    #${doxyconf}
    ${MD_SRC}
    ${BAS_SRC}
    ../_ReadMe.md.in
    ${CMAKE_CURRENT_SOURCE_DIR}/fb-doc.css
    ${CMAKE_CURRENT_SOURCE_DIR}/fb-doc.xml
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  )

ADD_CUSTOM_COMMAND(OUTPUT ${PDF_FILE}
  COMMAND ${DOXYGEN_EXECUTABLE} ${pdfcon}
  COMMAND ${FbDoc_EXECUTABLE} -s ${pdfcon}
  #COMMAND cd ${CMAKE_CURRENT_BINARY_DIR}/latex & make
  COMMAND cd ${CMAKE_CURRENT_BINARY_DIR}/latex
  COMMAND make
  COMMAND echo 'HIER ---> cd ${CMAKE_CURRENT_BINARY_DIR}/latex & make'
  #COMMAND ${CMAKE_CURRENT_BINARY_DIR}/latex/make
  #COMMAND latex/make
  DEPENDS
    ${lfn}
    ${MD_SRC}
    ${BAS_SRC}
    ../_ReadMe.md.in
    ${CMAKE_CURRENT_SOURCE_DIR}/fb-doc.css
    ${CMAKE_CURRENT_SOURCE_DIR}/fb-doc.xml
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  VERBATIM
  )

ADD_CUSTOM_TARGET(doc_htm DEPENDS ${HTM_FILE})
ADD_CUSTOM_TARGET(doc_pdf DEPENDS ${PDF_FILE})
ADD_CUSTOM_TARGET(doc)
ADD_DEPENDENCIES(doc DEPENDS doc_htm doc_pdf)
