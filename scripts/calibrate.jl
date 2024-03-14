using DrWatson
@quickactivate "DAS"

include(srcdir("DAS.jl"))

using Logging
global_logger(ConsoleLogger(stderr, Logging.Debug))

using BayesOpt
config = ConfigParameters()
config.random_seed = 8686

bounds = [
    0.0 20.0; # σ0 
    0.0 1.0; # δ0 
    0.0 20.0; # β0 
    0.0 100.0; # e0 
    0.0 1.0; # e1 
    1.0 10.0; # ρH 
    0.0 100.0; # ay 
    0.0 100.0; # av 
    1.0 10.0; # ρC 
    1.0 10.0; # ρK 
    1.0 10.0; # ρF 
    0.0 10.0; # Θ 
    1.0 100.0; # k 
    0.0 1.0; # ρΠ 
    0.0 10.0; # ρQ 
    0.0 10.0; # λ 
    0.0 1.0; # ν0 
    0.0 1.0; # ν1 
    0.0 10.0; # ν2 
    0.0 10.0; # ν3 
    0.0 10.0; # ν4 
    0.0 100.0; # τF 
    0.0 100.0; # τT 
    0.0 1.0; # ϵ0 
    0.0 100.0; # ϵ1 
    0.0 100.0; # ζ 
    0.0 10.0; # b0 
    0.0 10.0; # b1 
    0.0 10.0 # b2 
]

optimizer, optimum = bayes_optimization(DAS.run_or_load, bounds[:, 1], bounds[:, 2], config)

DrWatson.tagsave("optimization", Dict(:optimizer => optimizer, :optimum => optimum))