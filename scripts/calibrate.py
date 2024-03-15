# %%
import os
import pathlib
os.environ["JULIA_PROJECT"] = str(pathlib.Path(__file__).parent.parent.resolve())
from julia.api import Julia
jl = Julia(compiled_modules=False)

# %%
from julia import DrWatson
jl.eval("DrWatson.@quickactivate \"DAS\"")
jl.eval("include(DrWatson.srcdir(\"DAS.jl\"))")

# %%
from black_it.calibrator import Calibrator
from black_it.loss_functions.msm import MethodOfMomentsLoss
from black_it.samplers.best_batch import BestBatchSampler
from black_it.samplers.halton import HaltonSampler
from black_it.samplers.random_forest import RandomForestSampler

import numpy

# %%
from julia.Main import DAS

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

calibrator = Calibrator(
    samplers=[halton_sampler, random_forest_sampler, best_batch_sampler],
    real_data=numpy.array([[-1]]),
    model=DAS.run_or_load,
    parameters_bounds=bounds,
    parameters_precision=numpy.ones(29) * 0.01,
    ensemble_size=3,
    loss_function=MethodOfMomentsLoss(),
    random_state=8686,
)

#%%
params, losses = calibrator.calibrate(n_batches=15)

DrWatson.tagsave(DrWatson.datadir("optimization_bi.jld2"), {"params": params, "losses": losses}, safe=true)
# %%
