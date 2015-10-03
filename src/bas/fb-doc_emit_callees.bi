/'* \file fb-doc_emit_callees.bi
\brief Declarations for emitter for the file \em fb-doc.lfn.

This file declares the emitter functions for the \ref EmitterIF to
generate the file \em fb-doc.lfn for the Doxygen Back-end. It's the
default emitter in mode `--list-mode`.

'/

DECLARE FUNCTION writeLFN(BYREF AS STRING) AS INTEGER
