using DrWatson
@quickactivate "DAS"

include(srcdir("DAS.jl"))

using BayesianOptimization, GaussianProcesses, Distributions
using DataFrames

history = hcat(
    [
        [config[:σ0], config[:δ0], config[:β0], config[:e0], config[:e1], config[:ρH], config[:ay], config[:av], config[:ρC], config[:ρK], config[:ρF], config[:Θ], config[:k], config[:ρΠ], config[:ρQ], config[:λ], config[:ν0], config[:ν1], config[:ν2], config[:ν3], config[:ν4], config[:τF], config[:τT], config[:ϵ0], config[:ϵ1], config[:ζ], config[:b0], config[:b1], config[:b2], score] for (config, score) = Tuple.(
            eachrow(
                first(
                    sort(
                        select(
                            collect_results(
                                datadir("sims"),
                                white_list=["config", "score"]
                            ),
                            Not(:path)
                        ),
                        "score",
                        rev=true
                    ),
                    300
                )
            )
        )
    ]...
)

model = ElasticGPE(
    29,
    capacity=300
)

modeloptimizer = MAPGPOptimizer()

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
    UpperConfidenceBound(),
    modeloptimizer,
    bounds[:, 1],
    bounds[:, 2],
    repetitions=1,
    maxiterations=200,
    sense=Min,
    acquisitionoptions=(
        method=:LD_LBFGS,
        restarts=5,
        maxtime=1.0,
        maxeval=5000
    ),
    initializer_iterations=10,
    verbosity=Progress
)

BayesianOptimization.update!(opt.model, history[1:29, :], -history[30, :] ./ (21 * 300 * 4))

result = boptimize!(opt)

DrWatson.tagsave(datadir("optimization2.jld2"), Dict("result" => result, "optimizer" => opt), safe=true)