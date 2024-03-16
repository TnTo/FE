using DrWatson
@quickactivate "DAS"

include(srcdir("DAS.jl"))

using PythonCall
Calibrator, MinkowskiLoss, BestBatchSampler, HaltonSampler, RandomForestSampler = pyimport(
    "black_it.calibrator" => "Calibrator",
    "black_it.loss_functions.minkowski" => "MinkowskiLoss",
    "black_it.samplers.best_batch" => "BestBatchSampler",
    "black_it.samplers.halton" => "HaltonSampler",
    "black_it.samplers.random_forest" => "RandomForestSampler"
)
pyimport("dill")

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

batch_size = 8
halton_sampler = HaltonSampler(batch_size=batch_size)
random_forest_sampler = RandomForestSampler(batch_size=batch_size)
best_batch_sampler = BestBatchSampler(batch_size=batch_size)

function model(input_vec, output_size, seed)
    return DAS.run_or_load(input_vec)
end

calibrator = Calibrator(
    samplers=[halton_sampler, random_forest_sampler, best_batch_sampler],
    real_data=-ones((1, 1)),
    model=model,
    parameters_bounds=Py(transpose(bounds)).to_numpy(),
    parameters_precision=ones(29) * 0.01,
    ensemble_size=3,
    loss_function=MinkowskiLoss(),
    random_state=8686,
)

params, losses = calibrator.calibrate(n_batches=5)

DrWatson.tagsave(DrWatson.datadir("optimization_bi.jld2"), {"params":params, "losses":losses}, safe=true)