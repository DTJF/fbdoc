/'* \file fbdoc_emit_lfn.bi
\brief Declarations for emitter for the file generator `fb-doc.lfn`.

This file declares the emitter functions for the \ref EmitterIF to
generate the file `fb-doc.lfn` for the Doxygen Back-end. It's the
default emitter in mode `--list-mode`.

'/

#INCLUDE ONCE "fbdoc_emitters.bi"

CONST _
  LFN_FILE = "fb-doc.lfn" _ '*< File name for list of function names (caller / callees graphs)
 , LFN_SEP = !"\n"          '*< Separator for entries in file `fb-doc.lfn` (one character!).

DECLARE FUNCTION startLFN(BYREF AS STRING) AS INTEGER
