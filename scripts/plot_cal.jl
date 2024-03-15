using DrWatson
@quickactivate "DAS"

include(srcdir("DAS.jl"))
using OffsetArrays

using JSON
using Plots
using DataFrames
using StatsBase
using Distributions
using StatsPlots

df = collect_results(datadir("sims"), white_list=["config", "score"])
df[!, "normalized_score"] = df[!, "score"] / (300 * 21 * 4)
transform!(
    df,
    (
        :config => ByRow(DrWatson.dict2ntuple) => AsTable
    )
)

df2 = select(df, Not(:scores, :score, :path, :config))

for p = filter(c -> c != "normalized_score", names(df2))
    npar = mean_and_std(df2[!, p], weights(df2[!, :normalized_score]))
    scatter(df2[!, p], df2[!, :normalized_score], label=false, title=p)
    plot!(Normal(npar...), label=false)
    display(hline!([0.10], label=false))
end

