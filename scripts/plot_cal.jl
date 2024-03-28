using DrWatson
@quickactivate "DAS"

include(srcdir("DAS.jl"))
using OffsetArrays

using Plots
using DataFrames
using StatsBase
using Distributions
using StatsPlots

df = collect_results(datadir("sims"), white_list=["config", "score"])
df[!, "normalized_score"] = df[!, "score"] / (300 * 21 * 4)

df = hcat(df, DataFrame(Tables.dictrowtable(DrWatson.dict2ntuple.(df[!, :config]))))
df = select(df, Not(:score, :path, :config))
df2 = df[df.normalized_score.>=0.15, :]

D = 1

for p = filter(c -> c != "normalized_score", names(df2))
    idx = .!(ismissing.(df2[!, p]))
    npar = mean_and_std(disallowmissing(df2[idx, p]), weights(df2[idx, :normalized_score] .* D))
    scatter(df2[!, p], df2[!, :normalized_score], label=false, title=p)
    plot!(Normal(npar...), label=false)
    idx = .!(ismissing.(df[!, p]))
    npar = mean_and_std(disallowmissing(df[idx, p]), weights(df[idx, :normalized_score] .* D))
    plot!(Normal(npar...), label=false, linestyle=:dash)
    display(hline!([0.10], label=false))
end

