include ../../Makefile.config

LIBS     := -I private ${addprefix -package ,${CLIENT_PACKAGE} ${CLIENT_SYNTAX}}
OCAMLC   := $(OCAMLFIND) ocamlc${BYTEDBG}
OCAMLOPT := $(OCAMLFIND) ocamlopt ${OPTDBG}
OCAMLDOC := $(OCAMLFIND) ocamldoc
OCAMLDEP := $(OCAMLFIND) ocamldep

all: eliom_client.cma eliom_client_main.cmo

### Common files ###

COMMON_FILES  := $(notdir $(wildcard ../common/*.mli) $(wildcard ../common/*.ml))
COMMON_PFILES := $(addprefix private/, \
		     $(notdir $(wildcard ../common/private/*.mli) \
	                      $(wildcard ../common/private/*.ml)))

PREDEP := ${COMMON_FILES} ${COMMON_PFILES}

${COMMON_FILES}:
	ln -s ../common/$@ $@
${COMMON_PFILES}:
	ln -s ../../common/$@ $@

### Library ###

FILES := eliom_pervasives.ml \
	 eliom_client_unwrap.ml \
	 eliom_common_base.ml eliom_common.ml \
         private/eliommod_cookies.ml \
	 eliom_types_base.ml eliom_types.ml \
	 eliom_common_base.ml eliom_common.ml \
	 eliom_process.ml \
	 eliom_config.ml \
	 eliom_request_info.ml \
	 eliom_state.ml \
	 eliom_parameters_base.ml eliom_parameters.ml \
	 eliom_services_base.ml eliom_services.ml \
	 eliom_uri.ml \
	 eliom_request.ml \
	 eliommod_cli.ml \
	 eliom_client.ml \
	 eliom_comet_base.ml eliom_comet.ml \
         private/eliommod_mkforms.ml \
	 eliom_mkforms.ml \
	 eliom_output_base.ml eliom_output.ml \
	 eliom_output.ml \
	 eliom_bus.ml \
	 eliom_react.ml \

eliom_client.cma: eliom_client_stubs.o ${FILES:.ml=.cmo}
	${OCAMLMKLIB} -o ${@:.cma=} $^

##########

%.cmi: %.mli
	$(OCAMLC) -syntax camlp4o ${LIBS} -c $<
%.cmo: %.ml
	$(OCAMLC) -syntax camlp4o ${LIBS} -c $<
%.cmx: %.ml
	$(OCAMLOPT) -syntax camlp4o ${LIBS} -c $<
%.cmxs: %.cmx
	$(OCAMLOPT) -shared -linkall -o $@ $<
%.o: %.c
	$(OCAMLC) -c $<

## .mli to be compiled without camlp4
eliom_output.cmi eliom_pervasives.cmi: \
%.cmi: %.mli
	$(OCAMLC) ${LIBS} -c $<

## INSTALL ##

include Makefile.filelist

install:
	${INSTALL} -m 755 -d ${CLIENTDIR}
	${INSTALL} -m 644 ${INTF} ${IMPL} ${STUBS} ${DOC} ${CLIENTDIR}

uninstall:
	-rm -fr ${CLIENTDIR}

#####

## Clean up

clean:
	-rm -f *.cm[ioax] *.cmxa *.cmxs *.o *.a *.annot
	-cd private && rm -f *.cm[ioax] *.cmxa *.cmxs *.o *.a *.annot
	-rm -f ${PREDEP}

distclean: clean
	-rm -f *~ \#* .\#*

## Dependencies

depend: ${PREDEP}
	ls *.ml *.mli private/*.ml private/*.mli | \
	  grep -v eliom_output.mli | \
	  grep -v eliom_pervasives.mli | \
	  xargs $(OCAMLDEP) -syntax camlp4o ${LIBS} > .depend
	${OCAMLDEP} ${LIBS} eliom_output.mli >> .depend
	${OCAMLDEP} ${LIBS} eliom_pervasives.mli >> .depend

FORCE:
-include .depend