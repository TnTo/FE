using DrWatson
@quickactivate "DAS"

include(srcdir("DAS.jl"))

using Logging
using BayesOpt
using Dates

# global_logger(ConsoleLogger(stderr, Logging.Debug))

config = ConfigParameters()
config.random_seed = 8686
config.n_iterations = 500
config.n_iter_relearn = 50
config.l_type = L_MCMC
set_criteria!(config, "cEIa")
config.epsilon = 0.1
# config.verbose_level = 4
# set_log_file!(config, datadir("bayesopt_$(Dates.now()).log"))
config.load_save_flag = 2
set_save_file!(config, datadir("bayesopt_$(Dates.now()).dat"))

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

optimizer, optimum = bayes_optimization(DAS.run_or_load, bounds[:, 1], bounds[:, 2], config)

DrWatson.tagsave(datadir("optimization.jld2"), Dict("optimizer" => optimizer, "optimum" => optimum), safe=true)