# %%
#import juliapkg
#juliapkg.add("Distributions", "31c24e10-a181-5473-b8eb-7969acd0382f")
#juliapkg.add("DrWatson", "634d3b9d-ee7a-5ddf-bec9-22491ea816e1")
#juliapkg.add("NamedArrays", "86f7a689-2022-50b4-a561-43c23ac3c673")
#juliapkg.add("OffsetArrays", "6fe1bfb0-de20-5000-8ca7-80f57d26f881")
#juliapkg.add("StatsBase", "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91")
#juliapkg.resolve()

from juliacall import Main as jl
jl.Pkg.add(jl.convert(["Distributions", "StatsBase", "Random", "DrWatson", "OffsetArrays", "NamedArrays"]))
jl.seval("using DrWatson")
jl.seval("@quickactivate \"DAS\"")
jl.seval("include(srcdir(\"DAS.jl\"))")

# %%
from black_it.calibrator import Calibrator
from black_it.loss_functions.minkowski import MinkowskiLoss
from black_it.samplers.best_batch import BestBatchSampler
from black_it.samplers.halton import HaltonSampler
from black_it.samplers.random_forest import RandomForestSampler

import numpy

# %%
bounds = numpy.array([
    [0,5], # σ0 
    [0,1], # δ0 
    [0,5], # β0 
    [0,5], # e0 
    [0,1], # e1 
    [1,2], # ρH 
    [0,10], # ay 
    [0,10], # av 
    [1,2], # ρC 
    [1,2], # ρK 
    [1,2], # ρF 
    [0,5], # Θ 
    [1,10], # k 
    [0,1], # ρΠ 
    [0,1], # ρQ 
    [0,1], # λ 
    [0,1], # ν0 
    [0,1], # ν1 
    [0,1], # ν2 
    [0,1], # ν3 
    [0,1], # ν4 
    [0,10], # τF 
    [0,10], # τT 
    [0,1], # ϵ0 
    [0,5], # ϵ1 
    [0,5], # ζ 
    [0,5], # b0 
    [0,5], # b1 
    [0,5] # b2 
]).transpose()

batch_size = 8
halton_sampler = HaltonSampler(batch_size=batch_size)
random_forest_sampler = RandomForestSampler(batch_size=batch_size)
best_batch_sampler = BestBatchSampler(batch_size=batch_size)

# %%
def model(input_vec, output_size, seed):
    jl.seval("names(Main)")
    ret = jl.seval("DAS.run_or_load(input_vec)")
    return ret

calibrator = Calibrator(
    samplers=[halton_sampler, random_forest_sampler, best_batch_sampler],
    real_data=numpy.array([[-1]]),
    model=model,
    parameters_bounds=bounds,
    parameters_precision=numpy.ones(29) * 0.01,
    ensemble_size=3,
    loss_function=MinkowskiLoss(),
    random_state=8686,
)

#%%
params, losses = calibrator.calibrate(n_batches=5)

# %%
DrWatson.tagsave(DrWatson.datadir("optimization_bi.jld2"), {"params": params, "losses": losses}, safe=true)
# %%
