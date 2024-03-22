using DrWatson
@quickactivate "DAS"

include(srcdir("DAS.jl"))
using OffsetArrays

using Plots
using DataFrames

df = collect_results(datadir("sims"), white_list=["config", "score"])
df = first(sort(df, :score, rev=true))
pdict = load(df[:path])["config"]

seeds = [8, 86, 868, 8686]
ps = map(s -> DAS.Parameters(; seed=s, pdict...), seeds)
ms = Vector{DAS.Model}(undef, 4)
for i = 1:4
    m = DAS.create_model(ps[i])
    try
        for t = 1:m.p.T
            DAS.step!(m, print=false)
        end
    catch e
    finally
        ms[i] = m
    end
end
scores = Vector{Matrix}(undef, 4)
for i = 1:4
    scores[i] = DAS.evaluate_model(ms[i])
end

ms