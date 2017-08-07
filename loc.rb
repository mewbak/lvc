#!/usr/bin/ruby
require 'term/ansicolor'
require 'open3'
require 'io/console'
require 'csv'
require 'find'
require 'set'

include Term::ANSIColor

@width = IO.console.winsize[1]
@acc = Hash.new(0)
@total = Hash.new(0)

def loc(paths, exts=Set.new([".v"]))
  tloc = 0
  count = 0
	paths.each { |path|
    Find.find(*Dir.glob("#{path}")) do |path|
	    if exts.include?(File.extname(path)) then
		    loc, _ = `wc -l #{path}`.strip.split(" ")
				#print path, "\n"
  	    tloc += loc.to_i
  	    count += 1
				@acc[path] += 1
    	end
    end
	}
	return tloc, count
end

def rcol(width, text)
	  return "".ljust(width - uncolored(text).size) + text
end

def str(loc, count)
	return "#{rcol(6, "#{loc}")} loc in #{rcol(3, "#{count}")} files"
end

@texcmds = File.open("loc.tex", 'w')

def comp(name, paths, exts=Set.new([".v"]), silent=false)
  l, c = loc(paths, exts)
	@total["loc"] += l
	@total["count"] += c
	if not silent then print str(l,c), " ", name, "\n" end
  @texcmds.write("\\newcommand{\\#{name.gsub(/\s+/,"")}}{#{l}}\n");
end

comp("paco", ["paco/*"], [".v", ".ml4"], true)
comp("containers", ["ContainersPlugin/"], [".v", ".ml4"], true)
ext=@total
@total = Hash.new(0)
comp("Sets and Maps", ["theories/Constr"])
comp("Utilities and Tactics", ["theories/Infra"])
comp("Semantics", ["theories/IL", "theories/Isa"])
comp("Equivalence", ["theories/Equiv"])
comp("Coherence", ["theories/Coherence/Coherence.v", "theories/Coherence/Restrict.v", "theories/Coherence/Coherence_*.v"])
comp("Analyses", ["theories/Analysis", "theories/Liveness", "theories/Reachability"])
comp("Value Optimizations", ["theories/ValueOpts"])
comp("Dead Code Elimination", ["theories/DVE.v", "theories/UCE.v", "theories/DCVE.v", "theories/DCE.v"])
comp("Register Assignment", ["theories/Coherence/Allocation*", "theories/RegAssign.v", "theories/RenameApartToPart.v"])
comp("Spilling", ["theories/Spilling"])
comp("Lowering", ["theories/Lowering"])
comp("Alpha Equivalence", ["theories/Alpha"])
comp("SMT Translation Validation", ["theories/TransVal"])
comp("SSA Construction", ["theories/Coherence/AddParam.v", "theories/Coherence/Delocation*", "theories/Coherence/Invariance.v",
                          "theories/Coherence/AddParams.v", "theories/Coherence/AddAdd.v"])
comp("OCaml Integration", ["compiler/*.ml", "compiler/*.mll", "compiler/*.v", "compiler/*.mly", "theories/Compiler.v"], [".ml", ".v", ".mll", ",mly"])
comp("Coq Plugin", ["src/*.ml4"], [".ml4"])

print @total["loc"],  " loc in ", @total["count"], " files in LVC\n"
print ext["loc"],  " loc in ", ext["count"], " files in external dependencies\n"

Find.find("theories/") do |path|
  if File.extname(path) == ".v" then
		if @acc[path] == 0 then
			print "Unaccounted #{path}\n"
		elsif @acc[path] > 1 then
			print "Multiacc #{@acc[path]} #{path}\n"
		end
	end
end
