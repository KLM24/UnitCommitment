###
# Profiling the adaptive Set
###
include("readGenerator.jl")
include("readLoads.jl")
include("nomsolver.jl")
include("robustsolver.jl")
include("UncSets.jl")
include("adaptivesolver.jl")

gens, scaling       = loadISO("../Data/AndysGenInstance", 1)
dts, vals           = readLoads("../Data/ISO-NE Load Data/PredTest.csv")
dts_true, vals_true = readLoads("../Data/ISO-NE Load Data/LoadTest.csv")
vals               *= scaling
vals_true          *= scaling
resids              = map(float, vals_true - vals);
kappa(eps)          = sqrt(1/eps - 1)
penalty             = 5e3
Gamma1              = .5 * scaling
Gamma2              = 4  * scaling * scaling
eps                 = .1
##################################
#solve the robust problem for a warmstart
# m = RobustModel(solver=GurobiSolver())
# alphas, uncs = createPolyUCS(m, resids, Gamma1, Gamma2, kappa(eps))
# rob = UCRob(m, gens, penalty, uncs)
# solve(rob, vals[int(ARGS[1]), :], report=true)

# w = WarmStartInfo()
# copyWarmStart(rob, w)

##################################
## a test function
#INDXSET = [72 88 107 160]
function testRun()
	rm2 = RobustModel(solver=GurobiSolver(MIPGap=1e-3, OutputFlag=1), cutsolver=GurobiSolver(OutputFlag=0))  #MIPGap=5e-3
	alphas, uncs = createPolyUCS(rm2, resids, Gamma1, Gamma2, kappa(eps));
	aff = UCAff(rm2, gens, penalty, uncs);
	aff.proj_fcn = eigenProjMatrixData(resids, 1)
	# aff.warmstart = w

	# read in the starting cuts
	if length(ARGS) >= 3
		println("Adding Old Cuts")
		samples = readdlm(open(ARGS[3], "r"), '\t')
		aff.sample_uncs = samples
	end
	solve(aff, vals[int(ARGS[1]), :], report=true, usebox=false, 
				prefer_cuts=true,  active_cuts=(ARGS[2]=="true")) 

	println( "Active Cuts:")
	ac = rm2.ext[:Robust].activecuts
	println(" Total: $(length(ac))")
	ac = unique(ac)
	println(" Unique: $(length(ac))")

	# # ofile = open(ARGS[3], "w")
	# # for ix = 1:length(ac)
	# # 	writedlm(ofile, transpose(ac[ix][1:HRS]) )  #this is a dangeorus hack
	# # end
	# close(ofile)
end


println( "\n Robust Solve Begins Here \n ")
println( @elapsed testRun() )


# ## Load it up again and resolve
# rm2 = RobustModel(solver=GurobiSolver(OutputFlag=0, MIPGap=1e-3), cutsolver=GurobiSolver(OutputFlag=0))  #MIPGap=5e-3
# alphas, uncs = createPolyUCS(rm2, resids, Gamma1, Gamma2, kappa(eps));
# aff = UCAff(rm2, gens, penalty, uncs);
# aff.proj_fcn = eigenProjMatrixData(resids, 1)

# #read in the starting cuts
# if length(ARGS) >= 3
# 	samples = readdlm(open(ARGS[3], "r"), '\t')
# 	aff.sample_uncs = samples
# end

# solve(aff, vals[int(ARGS[1]), :], report=true, usebox=false, 
# 			prefer_cuts=true,  active_cuts=(ARGS[2]=="true")) 



