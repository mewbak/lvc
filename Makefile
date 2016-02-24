#############################################################################
##  v      #                   The Coq Proof Assistant                     ##
## <O___,, #                INRIA - CNRS - LIX - LRI - PPS                 ##
##   \VV/  #                                                               ##
##    //   #  Makefile automagically generated by coq_makefile V8.5        ##
#############################################################################

# WARNING
#
# This Makefile has been automagically generated
# Edit at your own risks !
#
# END OF WARNING

#
# This Makefile was generated by the command line :
# coq_makefile -R . Lvc extraction Infra/AllInRel.v Infra/Option.v Infra/LengthEq.v Infra/EqDec.v Infra/Drop.v Infra/Relations.v Infra/CoreTactics.v Infra/Bootstrap.v Infra/Computable.v Infra/DecSolve.v Infra/Indexwise.v Infra/Relations2.v Infra/Status.v Infra/Util.v Infra/Get.v Infra/Sublist.v Infra/Pos.v Infra/MoreList.v Infra/AutoIndTac.v Infra/OptionMap.v sumabo/Size.v sumabo/lib.v Containers/Generate.v Containers/BagFacts.v Containers/MapPatricia.v Containers/MapList.v Containers/SetDecide.v Containers/BagInterface.v Containers/Sets.v Containers/SetListInstance.v Containers/MapNotations.v Containers/Tactics.v Containers/SetEqProperties.v Containers/SetAVLInstance.v Containers/CMapPositiveInstance.v Containers/Maps.v Containers/CMapPositive.v Containers/OrderedTypeEx.v Containers/OrderedType.v Containers/MapAVL.v Containers/MapAVLInstance.v Containers/MapListInstance.v Containers/SetAVL.v Containers/MapInterface.v Containers/MapPatriciaInstance.v Containers/SetInterface.v Containers/SetPatricia.v Containers/BagMap.v Containers/MapPositive.v Containers/SetConstructs.v Containers/Bridge.v Containers/SetFacts.v Containers/MapFacts.v Containers/SetList.v Containers/BagInstance.v Containers/SetPatriciaInstance.v Containers/MapPositiveInstance.v Containers/SetProperties.v LivenessValidators.v paco/paco6.v paco/paco13.v paco/paco2.v paco/paco14.v paco/paco1.v paco/paco12.v paco/paco15.v paco/paco.v paco/paco4.v paco/hpattern.v paco/tutorial.v paco/paco11.v paco/pacotacuser.v paco/paco8.v paco/paco10.v paco/paco3.v paco/paco5.v paco/paco0.v paco/pacotac.v paco/paco9.v paco/paconotation.v paco/pacodef.v paco/paco7.v Libs/PartialOrder.v Filter.v IL/ILDB.v IL/Annotation.v IL/LabelsDefined.v IL/IL.v IL/Var.v IL/StateType.v IL/Events.v IL/Patterns.v IL/Env.v IL/Rename.v IL/ILN.v IL/EventsActivated.v Eqn.v LivenessAnalysis.v Compiler.v Lattice.v Equiv/CtxEq.v Equiv/Bisim.v Equiv/TraceEquiv.v Equiv/Equiv.v Equiv/Sim.v ConstantPropagation.v Alpha.v Constr/CSetGet.v Constr/SetOperations.v Constr/CSetDisjoint.v Constr/MapAgreeSet.v Constr/Map.v Constr/CSetBasic.v Constr/CSetTac.v Constr/CSetComputable.v Constr/MapComposition.v Constr/MapAgreement.v Constr/MapUpdateList.v Constr/CSetNotation.v Constr/MapLookup.v Constr/MapBasics.v Constr/CSetCases.v Constr/MapUpdate.v Constr/MapLookupList.v Constr/MapInjectivity.v Constr/CSet.v Constr/CMap.v Constr/MapInverse.v Liveness.v Isa/Val.v Isa/MoreExp.v Isa/Exp.v GVN.v EnvTy.v DVE.v CopyPropagation.v Analysis.v ShadowingFree.v RenamedApart.v Coherence/AllocationAlgo.v Coherence/Allocation.v Coherence/Coherence.v Coherence/Delocation.v Coherence/DelocationValidator.v Coherence/DelocationAlgo.v Coherence/Restrict.v ConstantPropagationAnalysis.v ParallelMove.v EAE.v Sawtooth.v Fresh.v InRel.v RenameApart.v ValueOpts.v TrueLiveness.v RenamedApart_Liveness.v Alpha_RenamedApart.v 
#

.DEFAULT_GOAL := all

# This Makefile may take arguments passed as environment variables:
# COQBIN to specify the directory where Coq binaries resides;
# TIMECMD set a command to log .v compilation time;
# TIMED if non empty, use the default time command as TIMECMD;
# ZDEBUG/COQDEBUG to specify debug flags for ocamlc&ocamlopt/coqc;
# DSTROOT to specify a prefix to install path.

# Here is a hack to make $(eval $(shell works:
define donewline


endef
includecmdwithout@ = $(eval $(subst @,$(donewline),$(shell { $(1) | tr -d '\r' | tr '\n' '@'; })))
$(call includecmdwithout@,$(COQBIN)coqtop -config)

TIMED=
TIMECMD=
STDTIME?=/usr/bin/time -f "$* (user: %U mem: %M ko)"
TIMER=$(if $(TIMED), $(STDTIME), $(TIMECMD))

vo_to_obj = $(addsuffix .o,\
  $(filter-out Warning: Error:,\
  $(shell $(COQBIN)coqtop -q -noinit -batch -quiet -print-mod-uid $(1))))

##########################
#                        #
# Libraries definitions. #
#                        #
##########################

COQLIBS?=\
  -R "." Lvc
COQDOCLIBS?=\
  -R "." Lvc

##########################
#                        #
# Variables definitions. #
#                        #
##########################


OPT?=
COQDEP?="$(COQBIN)coqdep" -c
COQFLAGS?=-q $(OPT) $(COQLIBS) $(OTHERFLAGS) $(COQ_XML)
COQCHKFLAGS?=-silent -o
COQDOCFLAGS?=--interpolate --utf8 --external "http://www.lix.polytechnique.fr/coq/pylons/contribs/files/Containers/v8.4/" Containers --toc --toc-depth 3 --index indexpage --no-lib-name
COQC?=$(TIMER) "$(COQBIN)coqc"
GALLINA?="$(COQBIN)gallina"
COQDOC?="$(COQBIN)coqdoc"
COQCHK?="$(COQBIN)coqchk"
COQMKTOP?="$(COQBIN)coqmktop"

##################
#                #
# Install Paths. #
#                #
##################

ifdef USERINSTALL
XDG_DATA_HOME?="$(HOME)/.local/share"
COQLIBINSTALL=$(XDG_DATA_HOME)/coq
COQDOCINSTALL=$(XDG_DATA_HOME)/doc/coq
else
COQLIBINSTALL="${COQLIB}user-contrib"
COQDOCINSTALL="${DOCDIR}user-contrib"
COQTOPINSTALL="${COQLIB}toploop"
endif

######################
#                    #
# Files dispatching. #
#                    #
######################

VFILES:=Infra/AllInRel.v\
  Infra/Option.v\
  Infra/LengthEq.v\
  Infra/EqDec.v\
  Infra/Drop.v\
  Infra/Relations.v\
  Infra/CoreTactics.v\
  Infra/Bootstrap.v\
  Infra/Computable.v\
  Infra/DecSolve.v\
  Infra/Indexwise.v\
  Infra/Relations2.v\
  Infra/Status.v\
  Infra/Util.v\
  Infra/Get.v\
  Infra/Sublist.v\
  Infra/Pos.v\
  Infra/MoreList.v\
  Infra/AutoIndTac.v\
  Infra/OptionMap.v\
  sumabo/Size.v\
  sumabo/lib.v\
  Containers/Generate.v\
  Containers/BagFacts.v\
  Containers/MapPatricia.v\
  Containers/MapList.v\
  Containers/SetDecide.v\
  Containers/BagInterface.v\
  Containers/Sets.v\
  Containers/SetListInstance.v\
  Containers/MapNotations.v\
  Containers/Tactics.v\
  Containers/SetEqProperties.v\
  Containers/SetAVLInstance.v\
  Containers/CMapPositiveInstance.v\
  Containers/Maps.v\
  Containers/CMapPositive.v\
  Containers/OrderedTypeEx.v\
  Containers/OrderedType.v\
  Containers/MapAVL.v\
  Containers/MapAVLInstance.v\
  Containers/MapListInstance.v\
  Containers/SetAVL.v\
  Containers/MapInterface.v\
  Containers/MapPatriciaInstance.v\
  Containers/SetInterface.v\
  Containers/SetPatricia.v\
  Containers/BagMap.v\
  Containers/MapPositive.v\
  Containers/SetConstructs.v\
  Containers/Bridge.v\
  Containers/SetFacts.v\
  Containers/MapFacts.v\
  Containers/SetList.v\
  Containers/BagInstance.v\
  Containers/SetPatriciaInstance.v\
  Containers/MapPositiveInstance.v\
  Containers/SetProperties.v\
  LivenessValidators.v\
  paco/paco6.v\
  paco/paco13.v\
  paco/paco2.v\
  paco/paco14.v\
  paco/paco1.v\
  paco/paco12.v\
  paco/paco15.v\
  paco/paco.v\
  paco/paco4.v\
  paco/hpattern.v\
  paco/tutorial.v\
  paco/paco11.v\
  paco/pacotacuser.v\
  paco/paco8.v\
  paco/paco10.v\
  paco/paco3.v\
  paco/paco5.v\
  paco/paco0.v\
  paco/pacotac.v\
  paco/paco9.v\
  paco/paconotation.v\
  paco/pacodef.v\
  paco/paco7.v\
  Libs/PartialOrder.v\
  Filter.v\
  IL/ILDB.v\
  IL/Annotation.v\
  IL/LabelsDefined.v\
  IL/IL.v\
  IL/Var.v\
  IL/StateType.v\
  IL/Events.v\
  IL/Patterns.v\
  IL/Env.v\
  IL/Rename.v\
  IL/ILN.v\
  IL/EventsActivated.v\
  Eqn.v\
  LivenessAnalysis.v\
  Compiler.v\
  Lattice.v\
  Equiv/CtxEq.v\
  Equiv/Bisim.v\
  Equiv/TraceEquiv.v\
  Equiv/Equiv.v\
  Equiv/Sim.v\
  ConstantPropagation.v\
  Alpha.v\
  Constr/CSetGet.v\
  Constr/SetOperations.v\
  Constr/CSetDisjoint.v\
  Constr/MapAgreeSet.v\
  Constr/Map.v\
  Constr/CSetBasic.v\
  Constr/CSetTac.v\
  Constr/CSetComputable.v\
  Constr/MapComposition.v\
  Constr/MapAgreement.v\
  Constr/MapUpdateList.v\
  Constr/CSetNotation.v\
  Constr/MapLookup.v\
  Constr/MapBasics.v\
  Constr/CSetCases.v\
  Constr/MapUpdate.v\
  Constr/MapLookupList.v\
  Constr/MapInjectivity.v\
  Constr/CSet.v\
  Constr/CMap.v\
  Constr/MapInverse.v\
  Liveness.v\
  Isa/Val.v\
  Isa/MoreExp.v\
  Isa/Exp.v\
  GVN.v\
  EnvTy.v\
  DVE.v\
  CopyPropagation.v\
  Analysis.v\
  ShadowingFree.v\
  RenamedApart.v\
  Coherence/AllocationAlgo.v\
  Coherence/Allocation.v\
  Coherence/Coherence.v\
  Coherence/Delocation.v\
  Coherence/DelocationValidator.v\
  Coherence/DelocationAlgo.v\
  Coherence/Restrict.v\
  ConstantPropagationAnalysis.v\
  ParallelMove.v\
  EAE.v\
  Sawtooth.v\
  Fresh.v\
  InRel.v\
  RenameApart.v\
  ValueOpts.v\
  TrueLiveness.v\
  RenamedApart_Liveness.v\
  Alpha_RenamedApart.v

ifneq ($(filter-out archclean clean cleanall printenv,$(MAKECMDGOALS)),)
-include $(addsuffix .d,$(VFILES))
else
ifeq ($(MAKECMDGOALS),)
-include $(addsuffix .d,$(VFILES))
endif
endif

.SECONDARY: $(addsuffix .d,$(VFILES))

VO=vo
VOFILES:=$(VFILES:.v=.$(VO))
GLOBFILES:=$(VFILES:.v=.glob)
GFILES:=$(VFILES:.v=.g)
HTMLFILES:=$(VFILES:.v=.html)
GHTMLFILES:=$(VFILES:.v=.g.html)
OBJFILES=$(call vo_to_obj,$(VOFILES))
ALLNATIVEFILES=$(OBJFILES:.o=.cmi) $(OBJFILES:.o=.cmo) $(OBJFILES:.o=.cmx) $(OBJFILES:.o=.cmxs)
NATIVEFILES=$(foreach f, $(ALLNATIVEFILES), $(wildcard $f))
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

quick: $(VOFILES:.vo=.vio)

vio2vo:
	$(COQC) $(COQDEBUG) $(COQFLAGS) -schedule-vio2vo $(J) $(VOFILES:%.vo=%.vio)
checkproofs:
	$(COQC) $(COQDEBUG) $(COQFLAGS) -schedule-vio-checking $(J) $(VOFILES:%.vo=%.vio)
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

.PHONY: all archclean beautify byte clean cleanall gallina gallinahtml html install install-doc install-natdynlink install-toploop opt printenv quick uninstall userinstall validate vio2vo ./extraction

###################
#                 #
# Subdirectories. #
#                 #
###################

./extraction: Compiler.vo
	+cd "./extraction" && $(MAKE) all

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
	cd "." && for i in $(VOFILES) $(VFILES) $(GLOBFILES) $(NATIVEFILES) $(CMOFILES) $(CMIFILES) $(CMAFILES); do \
	 install -d "`dirname "$(DSTROOT)"$(COQLIBINSTALL)/Lvc/$$i`"; \
	 install -m 0644 $$i "$(DSTROOT)"$(COQLIBINSTALL)/Lvc/$$i; \
	done
	+cd ./extraction && $(MAKE) DSTROOT="$(DSTROOT)" INSTALLDEFAULTROOT="$(INSTALLDEFAULTROOT)/./extraction" install

install-doc:
	install -d "$(DSTROOT)"$(COQDOCINSTALL)/Lvc/html
	for i in html/*; do \
	 install -m 0644 $$i "$(DSTROOT)"$(COQDOCINSTALL)/Lvc/$$i;\
	done

uninstall_me.sh: Makefile
	echo '#!/bin/sh' > $@
	printf 'cd "$${DSTROOT}"$(COQLIBINSTALL)/Lvc && rm -f $(VOFILES) $(VFILES) $(GLOBFILES) $(NATIVEFILES) $(CMOFILES) $(CMIFILES) $(CMAFILES) && find . -type d -and -empty -delete\ncd "$${DSTROOT}"$(COQLIBINSTALL) && find "Lvc" -maxdepth 0 -and -empty -exec rmdir -p \{\} \;\n' >> "$@"
	printf 'cd "$${DSTROOT}"$(COQDOCINSTALL)/Lvc \\\n' >> "$@"
	printf '&& rm -f $(shell find "html" -maxdepth 1 -and -type f -print)\n' >> "$@"
	printf 'cd "$${DSTROOT}"$(COQDOCINSTALL) && find Lvc/html -maxdepth 0 -and -empty -exec rmdir -p \{\} \;\n' >> "$@"
	chmod +x $@

uninstall: uninstall_me.sh
	sh $<

clean::
	rm -f $(OBJFILES) $(OBJFILES:.o=.native) $(NATIVEFILES)
	find . -name .coq-native -type d -empty -delete
	rm -f $(VOFILES) $(VOFILES:.vo=.vio) $(GFILES) $(VFILES:.v=.v.d) $(VFILES:=.beautified) $(VFILES:=.old)
	rm -f all.ps all-gal.ps all.pdf all-gal.pdf all.glob $(VFILES:.v=.glob) $(VFILES:.v=.tex) $(VFILES:.v=.g.tex) all-mli.tex
	- rm -rf html mlihtml uninstall_me.sh
	+cd ./extraction && $(MAKE) clean

cleanall:: clean
	rm -f $(patsubst %.v,.%.aux,$(VFILES))

archclean::
	rm -f *.cmx *.o
	+cd ./extraction && $(MAKE) archclean

printenv:
	@"$(COQBIN)coqtop" -config
	@echo 'CAMLC =	$(CAMLC)'
	@echo 'CAMLOPTC =	$(CAMLOPTC)'
	@echo 'PP =	$(PP)'
	@echo 'COQFLAGS =	$(COQFLAGS)'
	@echo 'COQLIBINSTALL =	$(COQLIBINSTALL)'
	@echo 'COQDOCINSTALL =	$(COQDOCINSTALL)'

###################
#                 #
# Implicit rules. #
#                 #
###################

$(VOFILES): %.vo: %.v
	$(COQC) $(COQDEBUG) $(COQFLAGS) $*

$(GLOBFILES): %.glob: %.v
	$(COQC) $(COQDEBUG) $(COQFLAGS) $*

$(VFILES:.v=.vio): %.vio: %.v
	$(COQC) -quick $(COQDEBUG) $(COQFLAGS) $*

$(GFILES): %.g: %.v
	$(GALLINA) $<

$(VFILES:.v=.tex): %.tex: %.v
	$(COQDOC) $(COQDOCFLAGS) -latex $< -o $@

$(HTMLFILES): %.html: %.v %.glob
	$(COQDOC) $(COQDOCFLAGS) -html $< -o $@

$(VFILES:.v=.g.tex): %.g.tex: %.v
	$(COQDOC) $(COQDOCFLAGS) -latex -g $< -o $@

$(GHTMLFILES): %.g.html: %.v %.glob
	$(COQDOC) $(COQDOCFLAGS)  -html -g $< -o $@

$(addsuffix .d,$(VFILES)): %.v.d: %.v
	$(COQDEP) $(COQLIBS) "$<" > "$@" || ( RV=$$?; rm -f "$@"; exit $${RV} )

$(addsuffix .beautified,$(VFILES)): %.v.beautified:
	$(COQC) $(COQDEBUG) $(COQFLAGS) -beautify $*

# WARNING
#
# This Makefile has been automagically generated
# Edit at your own risks !
#
# END OF WARNING

