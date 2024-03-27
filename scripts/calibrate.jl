using DrWatson
@quickactivate "DAS"

include(srcdir("DAS.jl"))

using Distributions
using DataFrames
using Random
using StatsBase

Random.seed!(8686)

bounds = Dict(
    :σ0 => (0.0, 5.0),
    :δ0 => (0.0, 1.0),
    :β0 => (1.0, 5.0),
    :e0 => (0.0, 10.0),
    :e1 => (0.0, 1.0),
    :ay => (0.0, 50.0),
    :av => (0.0, 10.0),
    :Θ => (0.0, 10.0),
    :k => (1.0, 10.0),
    :ρQ => (0.0, 1.0),
    :λ => (0.0, 1.0),
    :ν2 => (0.0, 1.0),
    :τF => (0.0, 10.0),
    :τT => (0.0, 10.0),
    :ϵ0 => (0.0, 1.0),
    :ϵ1 => (0.0, 10.0),
    :ζ => (0.0, 5.0),
    :b0 => (0.0, 5.0),
    :b1 => (0.0, 5.0),
    :b2 => (0.0, 5.0)
)

min_score = 0.10
degree = 1
max_iter = 5000
eval_every = 10

mutable struct Optim
    res
    history
    bounds
    par
end

df = collect_results(datadir("sims"), white_list=["config", "score"])
df[!, "normalized_score"] = df[!, "score"] / (300 * 21 * 4)
df = df[df.normalized_score.>=min_score, :]

if nrow(df) < eval_every
    res = []
    while length(res) < eval_every
        par = Dict((p, rand(Uniform(bounds[p]...))) for p in names(bounds))
        if (score = DAS.run_or_load(par)) >= min_score
            push!(res, (config=par, normalized_score=score))
        end
        @show par
        @show score
    end
    global df = DataFrame(res)
end

df = hcat(df[!, ["normalized_score"]], DataFrame(Tables.dictrowtable(DrWatson.dict2ntuple.(df[!, :config])))[!, names(bounds)])

opt = Optim(
    [],
    df,
    bounds,
    Dict(
        p => mean_and_std(df[!, p], weights(df[!, :normalized_score] .* degree))
        for p = names(bounds)
    )
)
for _ = 1:max_iter
    if length(opt.res) == eval_every
        println("UPDATE DISTRIBUTIONS")
        data = DataFrame(res)
        data = hcat(data[!, ["normalized_score"]], DataFrame(Tables.dictrowtable(DrWatson.dict2ntuple.(data[!, :config])))[!, names(bounds)])
        opt.history = vcat(opt.history, data)
        opt.res = []
        opt.par = mean_and_std(opt.history[!, p], weights(opt.history[!, :normalized_score] .* degree))
    end
    par = Dict(
        (
            p,
            rand(TruncatedNormal(opt.par[p]..., opt.bounds[p]...))
        )
        for p in names(bounds)
    )
    if (score = DAS.run_or_load(par)) >= min_score
        push!(opt.res, (config=par, normalized_score=score))
    end
    @show par
    @show score
end

opt.par