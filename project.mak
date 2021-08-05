# This file is part of the Zarith library 
# http://forge.ocamlcore.org/projects/zarith .
# It is distributed under LGPL 2 licensing, with static linking exception.
# See the LICENSE file included in the distribution.
#   
# Copyright (c) 2010-2011 Antoine Miné, Abstraction project.
# Abstraction is part of the LIENS (Laboratoire d'Informatique de l'ENS),
# a joint laboratory by:
# CNRS (Centre national de la recherche scientifique, France),
# ENS (École normale supérieure, Paris, France),
# INRIA Rocquencourt (Institut national de recherche en informatique, France).

ifeq "$(shell $(OCAMLC) -config |grep ccomp_type)" "ccomp_type: msvc"
OBJSUFFIX    := obj
LIBSUFFIX    := lib
DLLSUFFIX    := dll
EXE          := .exe
else
OBJSUFFIX    := o
LIBSUFFIX    := a
ifeq "$(findstring mingw,$(shell $(OCAMLC) -config |grep system))" "mingw"
DLLSUFFIX    := dll
EXE          := .exe
else
DLLSUFFIX    := so
EXE          :=
endif
endif


# project files
###############

CSRC = caml_z.c
MLSRC = zarith_version.ml z.ml q.ml big_int_Z.ml
MLISRC = z.mli q.mli big_int_Z.mli

AUTOGEN = zarith_version.ml

CMIOBJ = $(MLISRC:%.mli=%.cmi)
CMXOBJ = $(MLISRC:%.mli=%.cmx)
CMIDOC = $(MLISRC:%.mli=%.cmti)

TOBUILD = zarith.cma libzarith.$(LIBSUFFIX) $(CMIOBJ) zarith_top.cma z.mli

TOINSTALL = $(TOBUILD) zarith.h q.mli big_int_Z.mli

ifeq ($(HASOCAMLOPT),yes)
TOBUILD += zarith.cmxa $(CMXOBJ)
TOINSTALL += zarith.$(LIBSUFFIX)
endif

OCAMLFLAGS = -I +compiler-libs
OCAMLOPTFLAGS = -I +compiler-libs

ifeq ($(HASDYNLINK),yes)
TOBUILD += zarith.cmxs
endif

ifeq ($(HASBINANNOT),yes)
TOINSTALL += $(CMIDOC)
OCAMLFLAGS += -bin-annot
endif

# build targets
###############

all: $(TOBUILD)

tests:
	make -C tests test

zarith.cma: $(MLSRC:%.ml=%.cmo)
	$(OCAMLMKLIB) -failsafe -o zarith $+ $(LIBS)

zarith.cmxa: $(MLSRC:%.ml=%.cmx)
	$(OCAMLMKLIB) -failsafe -o zarith $+ $(LIBS)

zarith.cmxs: zarith.cmxa libzarith.$(LIBSUFFIX)
	$(OCAMLOPT) -shared -o $@ -I . zarith.cmxa -linkall

libzarith.$(LIBSUFFIX): $(CSRC:%.c=%.$(OBJSUFFIX))
	$(OCAMLMKLIB) -failsafe -o zarith $+ $(LIBS)

gobzarith.cma: gobz_version.cmo gobz.cmo
	$(OCAMLMKLIB) -failsafe -o gobzarith $+ $(LIBS)

gobzarith.cmxa: gobz_version.cmx gobz.cmx
	$(OCAMLMKLIB) -failsafe -o gobzarith $+ $(LIBS)

gobzarith.cmxs: gobzarith.cmxa libgobzarith.$(LIBSUFFIX)
	$(OCAMLOPT) -shared -o $@ -I . gobzarith.cmxa -linkall

libgobzarith.$(LIBSUFFIX): caml_gobz.$(OBJSUFFIX)
	$(OCAMLMKLIB) -failsafe -o gobzarith $+ $(LIBS)

zarith_top.cma: zarith_top.cmo
	$(OCAMLC) -o $@ -a $<

doc: $(MLISRC)
	mkdir -p html
	$(OCAMLDOC) -html -d html -charset utf8 $+

zarith_version.ml: META
	(echo "let"; grep "version" META | head -1) > zarith_version.ml

# install targets
#################

ifeq ($(INSTMETH),install)
install:
	install -d $(INSTALLDIR) $(INSTALLDIR)/zarith $(INSTALLDIR)/stublibs
	for i in $(TOINSTALL); do \
		if test -f $$i; then $(INSTALL) -m 0644 $$i $(INSTALLDIR)/zarith/$$i; fi; \
	done
	if test -f dllzarith.$(DLLSUFFIX); then $(INSTALL) -m 0755 dllzarith.$(DLLSUFFIX) $(INSTALLDIR)/stublibs/dllzarith.$(DLLSUFFIX); fi

uninstall:
	for i in $(TOINSTALL); do \
		rm -f $(INSTALLDIR)/zarith/$$i; \
	done
	if test -f $(INSTALLDIR)/stublibs/dllzarith.$(DLLSUFFIX); then rm -f $(INSTALLDIR)/stublibs/dllzarith.$(DLLSUFFIX); fi
endif

ifeq ($(INSTMETH),findlib)
install:
	$(OCAMLFIND) install -destdir "$(INSTALLDIR)" zarith META $(TOINSTALL) -optional dllzarith.$(DLLSUFFIX)

uninstall:
	$(OCAMLFIND) remove -destdir "$(INSTALLDIR)" zarith
endif


# rules
#######

%.cmi: %.mli
	$(OCAMLC) $(OCAMLFLAGS) $(OCAMLINC) -c $<

%.cmo: %.ml %.cmi
	$(OCAMLC) $(OCAMLFLAGS) $(OCAMLINC) -c $<

%.cmx: %.ml %.cmi
	$(OCAMLOPT) $(OCAMLOPTFLAGS) $(OCAMLINC) -c $<

%.cmo: %.ml
	$(OCAMLC) $(OCAMLFLAGS) $(OCAMLINC) -c $<

%.cmx: %.ml
	$(OCAMLOPT) $(OCAMLOPTFLAGS) $(OCAMLINC) -c $<

%.$(OBJSUFFIX): %.c
	$(OCAMLC) -ccopt "$(CFLAGS)" -c $<

gobz.ml: z.ml
	cp $< $@
	sed -i 's/ml_z/ml_gobz/g' $@
	sed -i 's/Zarith_version/Gobz_version/g' $@

gobz_version.ml: zarith_version.ml
	cp $< $@

caml_gobz.c: caml_z.c
	cp $< $@
	sed -i 's/ml_z/ml_gobz/g' $@
	sed -i 's/"_z"/"_gobz"/g' $@

clean:
	/bin/rm -rf *.$(OBJSUFFIX) *.$(LIBSUFFIX) *.$(DLLSUFFIX) *.cmi *.cmo *.cmx *.cmxa *.cmxs *.cma  *.cmt *.cmti *~ \#* depend test $(AUTOGEN) tmp.c depend gobz.ml gobz_version.ml caml_gobz.c
	make -C tests clean

depend: $(AUTOGEN)
	$(OCAMLDEP) -native $(OCAMLINC) $(MLSRC) $(MLISRC) > depend

include depend

$(CSRC:%.c=%.$(OBJSUFFIX)): zarith.h

.PHONY: clean
.PHONY: tests
