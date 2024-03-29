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

for m = ms
    t = count(i -> isassigned(m.s, i), 1:m.p.T)
    DAS.display_matrices(m, t)
    m.s = m.s[1:t]
    DAS.map_plot(m,
        [
            s -> DAS.mapsum(h -> h.rc_, s.Hs),
            s -> DAS.mapsum(h -> h.rc, s.Hs),
            s -> s.G.rC,
            s -> DAS.mapsum(f -> f.c_, s.FCs),
            s -> DAS.mapsum(f -> f.c, s.FCs),
            s -> DAS.mapsum(f -> DAS.b(m, f), s.FCs),
            s -> DAS.mapsum(f -> length(f.employees), s.FCs)
        ],
        ["H rc_" "H rc" "G rc" "F c_" "F c" "F b" "emp"]
    )

    DAS.map_plot(m,
        [
            s -> DAS.mapsum(f -> length(f.inv), s.FKs),
            s -> DAS.mapsum(f -> f.Δb_, s.FCs),
            s -> DAS.mapsum(f -> f.Δb, s.FCs),
            s -> DAS.mapsum(f -> f.Δb_, s.FKs),
            s -> DAS.mapsum(f -> f.k_ * f.β * m.p.k, s.FKs),
            s -> DAS.mapsum(f -> f.k * f.β * m.p.k, s.FKs),
            s -> DAS.mapsum(f -> DAS.b(m, f), s.FKs),
            s -> DAS.mapsum(f -> length(f.employees), s.FKs),
            s -> DAS.mapsum(f -> f.s, s.FKs),
        ],
        ["inv" "Δb_ FC" "Δb FC" "Δb_ FK" "k_" "k" "b FK" "empl FK" "s"]
    )

    DAS.map_plot(m,
        [
            s -> count(h -> h.employer !== nothing, s.Hs),
            s -> count(h -> h.employer === nothing, s.Hs)
        ],
        ["empl" "unempl"]
    )

    DAS.map_plot(m, [s -> s.B.rS, s -> s.G.rB], ["rS" "rB"])

    DAS.map_plot(m,
        [
            s -> DAS.mapsum(f -> length(f.inv), s.FKs),
            s -> DAS.mapsum(f -> length(f.employees), s.FKs),
            s -> DAS.mapsum(f -> f.s, s.FKs),
            s -> DAS.mapsum(f -> f.k, s.FKs),
            s -> DAS.mapsum(f -> DAS.b(m, f), s.FKs),
            s -> DAS.mapsum(f -> length(f.K), s.FKs),
            s -> DAS.mapsum(f -> f.k_, s.FKs),
        ],
        ["inv" "empl FK" "s FK" "k FK" "b FK" "K FK" "k_ FK"]
    )

    DAS.map_plot(m,
        [
            s -> DAS.mapsum(f -> length(f.Q), s.FKs),
            s -> DAS.mapsum(f -> f.q_, s.FKs),
        ],
        ["Q" "q_"]
    )

    DAS.map_plot(m,
        [
            s -> DAS.mapmean(f -> f.p, s.FKs),
            s -> DAS.mapmean(f -> f.pF, s.FCs),
            s -> DAS.mapmean(h -> h.wF, filter(h -> h.employer !== nothing, s.Hs)),
            s -> 0,
            s -> s.stats.p,
            s -> DAS.mapmean(h -> h.D, s.Hs)
        ],
        ["pK" "pC" "w" "0" "<p>" "DH"]
    )

    DAS.map_plot(m,
        [
            s -> DAS.mapmean(f -> f.μ, s.FKs),
            s -> DAS.mapmean(f -> f.μ, s.FCs),
        ],
        ["μK" "μC"]
    )

    scatter(map(h -> h.σ, m.s[end].Hs), map(h -> h.wF, m.s[end].Hs))
end