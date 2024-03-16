using DrWatson
@quickactivate "DAS"

include(srcdir("DAS.jl"))

using BayesianOptimization, GaussianProcesses, Distributions

model = ElasticGPE(
    29,
    mean=MeanConst(1.0),
    kernel=SEArd(zeros(29), 5.0),
    logNoise=0.0,
    capacity=300
)
set_priors!(model.mean, [Normal(1, 2)])

kbl = -1 * ones(30)
kbl[end] = 0
kbu = 4 * ones(30)
kbu[end] = 10

modeloptimizer = MAPGPOptimizer(
    every=50,
    oisebounds=[-4, 3],
    kernbounds=[kbl, kbu],  # bounds of the 3 parameters GaussianProcesses.get_param_names(model.kernel)
    maxeval=40
)

bounds = [
    0.0 5.0; # σ0 
    0.0 1.0; # δ0 
    0.0 5.0; # β0 
    0.0 5.0; # e0 
    0.0 1.0; # e1 
    1.0 2.0; # ρH 
    0.0 10.0; # ay 
    0.0 10.0; # av 
    1.0 2.0; # ρC 
    1.0 2.0; # ρK 
    1.0 2.0; # ρF 
    0.0 5.0; # Θ 
    1.0 10.0; # k 
    0.0 1.0; # ρΠ 
    0.0 1.0; # ρQ 
    0.0 1.0; # λ 
    0.0 1.0; # ν0 
    0.0 1.0; # ν1 
    0.0 1.0; # ν2 
    0.0 1.0; # ν3 
    0.0 1.0; # ν4 
    0.0 10.0; # τF 
    0.0 10.0; # τT 
    0.0 1.0; # ϵ0 
    0.0 5.0; # ϵ1 
    0.0 5.0; # ζ 
    0.0 5.0; # b0 
    0.0 5.0; # b1 
    0.0 5.0 # b2 
]

opt = BOpt(
    DAS.run_or_load,
    model,
    UpperConfidenceBound(),                   # type of acquisition
    modeloptimizer,
    bounds[:, 1],
    bounds[:, 2],
    repetitions=1,
    maxiterations=200,
    sense=Min,
    acquisitionoptions=(
        method=:LD_LBFGS,
        restarts=5,
        maxtime=0.1,
        maxeval=1000
    ),
    verbosity=Progress
)

result = boptimize!(opt)

DrWatson.tagsave(datadir("optimization2.jld2"), Dict("result" => result), safe=true)