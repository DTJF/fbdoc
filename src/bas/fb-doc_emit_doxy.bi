/'* \file fb-fb-doc_emit_doxy.bi
\brief Declarations for emitter for the Doxygen template generator.

This file declares the emitter function for the init function of the
Doxygen template generator. It isn't defined as the default emitter in
any mode.

'/

#INCLUDE ONCE "fb-doc_emitters.bi"

DECLARE SUB doxy_init(BYVAL AS EmitterIF PTR)
