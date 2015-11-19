/'* \file fb-fb-doc_emit_gtk.bi
\brief Declarations for emitter for the gtk-doc template generator.

This file declares the emitter functions for the init function of the
gtk-doc template generator. It's the default emitter in mode
`--geany-mode`.

'/

#INCLUDE ONCE "fb-doc_emitters.bi"

DECLARE SUB gtk_init(BYVAL AS EmitterIF PTR)
