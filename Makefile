#############################################################################
##  v      #                   The Coq Proof Assistant                     ##
## <O___,, #                INRIA - CNRS - LIX - LRI - PPS                 ##
##   \VV/  #                                                               ##
##    //   #  Makefile automagically generated by coq_makefile V8.4pl3     ##
#############################################################################

# WARNING
#
# This Makefile has been automagically generated
# Edit at your own risks !
#
# END OF WARNING

#
# This Makefile was generated by the command line :
# coq_makefile -R . Lvc extraction ./ILRaise.v ./Infra/AllInRel.v ./Infra/Option.v ./Infra/LengthEq.v ./Infra/EqDec.v ./Infra/Drop.v ./Infra/Relations.v ./Infra/CoreTactics.v ./Infra/Bootstrap.v ./Infra/DecidableTactics.v ./Infra/DecSolve.v ./Infra/Status.v ./Infra/Util.v ./Infra/Get.v ./Infra/Sublist.v ./Infra/MoreList.v ./Infra/AutoIndTac.v ./IL/IL.v ./IL/ParamsMatch.v ./IL/Var.v ./IL/Env.v ./IL/ILN.v ./IL/Sim.v ./LivenessAnalysis.v ./Compiler.v ./CoherenceAlgo.v ./Lattice.v ./AbsInt.v ./RegAllocAlgo.v ./Alpha.v ./Constr/MapAgreeSet.v ./Constr/Map.v ./Constr/InjectiveMapping.v ./Constr/MapComposition.v ./Constr/MapAgreement.v ./Constr/MapUpdateList.v ./Constr/MapLookup.v ./Constr/MapBasics.v ./Constr/MapUpdate.v ./Constr/MapLookupList.v ./Constr/MapInjectivity.v ./Constr/CSet.v ./Constr/MapInverse.v ./Liveness.v ./Isa/Val.v ./Isa/Exp.v ./ILIToILF.v ./EnvTy.v ./CopyPropagation.v ./Coherence.v ./ParallelMove.v ./Fresh.v ./RenameApart.v ./Restrict.v ./RegAlloc.v 
#

.DEFAULT_GOAL := all

# 
# This Makefile may take arguments passed as environment variables:
# COQBIN to specify the directory where Coq binaries resides;
# ZDEBUG/COQDEBUG to specify debug flags for ocamlc&ocamlopt/coqc;
# DSTROOT to specify a prefix to install path.

# Here is a hack to make $(eval $(shell works:
define donewline


endef
includecmdwithout@ = $(eval $(subst @,$(donewline),$(shell { $(1) | tr -d '\r' | tr '\n' '@'; })))
$(call includecmdwithout@,$(COQBIN)coqtop -config)

##########################
#                        #
# Libraries definitions. #
#                        #
##########################

COQLIBS?= -R . Lvc
COQDOCLIBS?=-R . Lvc

##########################
#                        #
# Variables definitions. #
#                        #
##########################


OPT?=
COQDEP?=$(COQBIN)coqdep -c
COQFLAGS?=-q $(OPT) $(COQLIBS) $(OTHERFLAGS) $(COQ_XML)
COQCHKFLAGS?=-silent -o
COQDOCFLAGS?=-interpolate -utf8
COQC?=$(COQBIN)coqc
GALLINA?=$(COQBIN)gallina
COQDOC?=$(COQBIN)coqdoc
COQCHK?=$(COQBIN)coqchk

##################
#                #
# Install Paths. #
#                #
##################

ifdef USERINSTALL
XDG_DATA_HOME?=$(HOME)/.local/share
COQLIBINSTALL=$(XDG_DATA_HOME)/coq
COQDOCINSTALL=$(XDG_DATA_HOME)/doc/coq
else
COQLIBINSTALL=${COQLIB}user-contrib
COQDOCINSTALL=${DOCDIR}user-contrib
endif

######################
#                    #
# Files dispatching. #
#                    #
######################

VFILES:=ILRaise.v\
  Infra/AllInRel.v\
  Infra/Option.v\
  Infra/LengthEq.v\
  Infra/EqDec.v\
  Infra/Drop.v\
  Infra/Relations.v\
  Infra/CoreTactics.v\
  Infra/Bootstrap.v\
  Infra/DecidableTactics.v\
  Infra/DecSolve.v\
  Infra/Status.v\
  Infra/Util.v\
  Infra/Get.v\
  Infra/Sublist.v\
  Infra/MoreList.v\
  Infra/AutoIndTac.v\
  IL/IL.v\
  IL/ParamsMatch.v\
  IL/Var.v\
  IL/Env.v\
  IL/ILN.v\
  IL/Sim.v\
  LivenessAnalysis.v\
  Compiler.v\
  CoherenceAlgo.v\
  Lattice.v\
  AbsInt.v\
  RegAllocAlgo.v\
  Alpha.v\
  Constr/MapAgreeSet.v\
  Constr/Map.v\
  Constr/InjectiveMapping.v\
  Constr/MapComposition.v\
  Constr/MapAgreement.v\
  Constr/MapUpdateList.v\
  Constr/MapLookup.v\
  Constr/MapBasics.v\
  Constr/MapUpdate.v\
  Constr/MapLookupList.v\
  Constr/MapInjectivity.v\
  Constr/CSet.v\
  Constr/MapInverse.v\
  Liveness.v\
  Isa/Val.v\
  Isa/Exp.v\
  ILIToILF.v\
  EnvTy.v\
  CopyPropagation.v\
  Coherence.v\
  ParallelMove.v\
  Fresh.v\
  RenameApart.v\
  Restrict.v\
  RegAlloc.v

-include $(addsuffix .d,$(VFILES))
.SECONDARY: $(addsuffix .d,$(VFILES))

VOFILES:=$(VFILES:.v=.vo)
GLOBFILES:=$(VFILES:.v=.glob)
VIFILES:=$(VFILES:.v=.vi)
GFILES:=$(VFILES:.v=.g)
HTMLFILES:=$(VFILES:.v=.html)
GHTMLFILES:=$(VFILES:.v=.g.html)
ifeq '$(HASNATDYNLINK)' 'true'
HASNATDYNLINK_OR_EMPTY := yes
else
HASNATDYNLINK_OR_EMPTY :=
endif

#######################################
#                                     #
# Definition of the toplevel targets. #
#                                     #
#######################################

all: $(VOFILES) ./extraction

spec: $(VIFILES)

gallina: $(GFILES)

html: $(GLOBFILES) $(VFILES)
	- mkdir -p html
	$(COQDOC) -toc $(COQDOCFLAGS) -html $(COQDOCLIBS) -d html $(VFILES)

gallinahtml: $(GLOBFILES) $(VFILES)
	- mkdir -p html
	$(COQDOC) -toc $(COQDOCFLAGS) -html -g $(COQDOCLIBS) -d html $(VFILES)

all.ps: $(VFILES)
	$(COQDOC) -toc $(COQDOCFLAGS) -ps $(COQDOCLIBS) -o $@ `$(COQDEP) -sort -suffix .v $^`

all-gal.ps: $(VFILES)
	$(COQDOC) -toc $(COQDOCFLAGS) -ps -g $(COQDOCLIBS) -o $@ `$(COQDEP) -sort -suffix .v $^`

all.pdf: $(VFILES)
	$(COQDOC) -toc $(COQDOCFLAGS) -pdf $(COQDOCLIBS) -o $@ `$(COQDEP) -sort -suffix .v $^`

all-gal.pdf: $(VFILES)
	$(COQDOC) -toc $(COQDOCFLAGS) -pdf -g $(COQDOCLIBS) -o $@ `$(COQDEP) -sort -suffix .v $^`

validate: $(VOFILES)
	$(COQCHK) $(COQCHKFLAGS) $(COQLIBS) $(notdir $(^:.vo=))

beautify: $(VFILES:=.beautified)
	for file in $^; do mv $${file%.beautified} $${file%beautified}old && mv $${file} $${file%.beautified}; done
	@echo 'Do not do "make clean" until you are sure that everything went well!'
	@echo 'If there were a problem, execute "for file in $$(find . -name \*.v.old -print); do mv $${file} $${file%.old}; done" in your shell/'

.PHONY: all opt byte archclean clean install userinstall depend html validate ./extraction

###################
#                 #
# Subdirectories. #
#                 #
###################

./extraction: Compiler.vo
	cd ./extraction ; $(MAKE) all

####################
#                  #
# Special targets. #
#                  #
####################

byte:
	$(MAKE) all "OPT:=-byte"

opt:
	$(MAKE) all "OPT:=-opt"

userinstall:
	+$(MAKE) USERINSTALL=true install

install:
	for i in $(VOFILES); do \
	 install -d `dirname $(DSTROOT)$(COQLIBINSTALL)/Lvc/$$i`; \
	 install -m 0644 $$i $(DSTROOT)$(COQLIBINSTALL)/Lvc/$$i; \
	done
	(cd ./extraction; $(MAKE) DSTROOT=$(DSTROOT) INSTALLDEFAULTROOT=$(INSTALLDEFAULTROOT)/./extraction install)

install-doc:
	install -d $(DSTROOT)$(COQDOCINSTALL)/Lvc/html
	for i in html/*; do \
	 install -m 0644 $$i $(DSTROOT)$(COQDOCINSTALL)/Lvc/$$i;\
	done

clean:
	rm -f $(VOFILES) $(VIFILES) $(GFILES) $(VFILES:.v=.v.d) $(VFILES:=.beautified) $(VFILES:=.old)
	rm -f all.ps all-gal.ps all.pdf all-gal.pdf all.glob $(VFILES:.v=.glob) $(VFILES:.v=.tex) $(VFILES:.v=.g.tex) all-mli.tex
	- rm -rf html mlihtml
	(cd ./extraction ; $(MAKE) clean)

archclean:
	rm -f *.cmx *.o
	(cd ./extraction ; $(MAKE) archclean)

printenv:
	@$(COQBIN)coqtop -config
	@echo CAMLC =	$(CAMLC)
	@echo CAMLOPTC =	$(CAMLOPTC)
	@echo PP =	$(PP)
	@echo COQFLAGS =	$(COQFLAGS)
	@echo COQLIBINSTALL =	$(COQLIBINSTALL)
	@echo COQDOCINSTALL =	$(COQDOCINSTALL)

###################
#                 #
# Implicit rules. #
#                 #
###################

%.vo %.glob: %.v
	$(COQC) $(COQDEBUG) $(COQFLAGS) $*

%.vi: %.v
	$(COQC) -i $(COQDEBUG) $(COQFLAGS) $*

%.g: %.v
	$(GALLINA) $<

%.tex: %.v
	$(COQDOC) $(COQDOCFLAGS) -latex $< -o $@

%.html: %.v %.glob
	$(COQDOC) $(COQDOCFLAGS) -html $< -o $@

%.g.tex: %.v
	$(COQDOC) $(COQDOCFLAGS) -latex -g $< -o $@

%.g.html: %.v %.glob
	$(COQDOC)$(COQDOCFLAGS)  -html -g $< -o $@

%.v.d: %.v
	$(COQDEP) -slash $(COQLIBS) "$<" > "$@" || ( RV=$$?; rm -f "$@"; exit $${RV} )

%.v.beautified:
	$(COQC) $(COQDEBUG) $(COQFLAGS) -beautify $*

# WARNING
#
# This Makefile has been automagically generated
# Edit at your own risks !
#
# END OF WARNING
