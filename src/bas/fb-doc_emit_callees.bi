/'* \file fb-doc_emit_callees.bi
\brief Declarations for emitter for the file generator \em fb-doc.lfn.

This file declares the emitter functions for the \ref EmitterIF to
generate the file \em fb-doc.lfn for the Doxygen Back-end. It's the
default emitter in mode `--list-mode`.

'/

#INCLUDE ONCE "fb-doc_emitters.bi"

DECLARE FUNCTION startLFN(BYREF AS STRING) AS INTEGER
DECLARE SUB callees_init(BYVAL AS EmitterIF PTR)
