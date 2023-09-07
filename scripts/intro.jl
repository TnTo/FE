using DrWatson
@quickactivate "DAS"

using ProgressBars
using Plots
using Statistics

include(srcdir("DAS.jl"))

p = DAS.get_default_parameters()
p.T = 10 * 12
p.p0 = 100
p.α1 = 0.2
p.α2 = 0.1
p.α3 = 0.1
p.ρC = 1.2
p.ρK = 1.2
p.ρF = 1.2
p.ρH = 2.0
p.ν0 = 2.0
p.ν1 = 0.7
p.NK = 5 * 12
p.NL = 5 * 12
p.b0 = 5
p.b1 = 1
p.b2 = 10
p.μ0 = 1.0
p.K0 = 5


m = DAS.create_model(p)
try
    for t = ProgressBar(1:m.p.T)
        # println("STEP $(t)")
        DAS.step!(m)
    end
finally
end
DAS.display_matrices(m.states[end], m.states[end-1], m)
plot(
    DAS.map_plot(m, [s -> DAS.mapsum(f -> f.k_, values(s.FKs)), s -> DAS.mapsum(f -> f.k, values(s.FKs)), s -> DAS.mapsum(f -> f.s, values(s.FKs)), s -> DAS.mapsum(f -> floor(Int, DAS.mapsum(k -> k.β, f.K)), values(s.FKs)), s -> DAS.mapsum(f -> length(f.inv), values(s.FKs))], ["k_" "k" "s" "b" "inv"]),
    DAS.map_plot(m, [s -> DAS.mapsum(f -> f.c_, values(s.FCs)), s -> DAS.mapsum(f -> f.c, values(s.FCs)), s -> DAS.mapsum(f -> f.s, values(s.FCs)), s -> DAS.mapsum(f -> floor(Int, DAS.mapsum(k -> k.β, f.K)), values(s.FCs)), s -> DAS.mapsum(f -> f.Δb, values(s.FCs)), s -> DAS.mapsum(f -> f.Δb_, values(s.FCs))], ["c_" "c" "s" "b" "Δb" "Δb_"]),
    #DAS.map_plot(m, [s -> s.B.l_, s -> mean(map(f -> f.l_, values(s.FCs))), s -> mean(map(f -> floor(Int, m.p.ν0 * DAS.pkk(f) - DAS.l(f)), values(merge(s.FKs, s.FCs)))), s -> mean(map(f -> f.D, values(s.FCs)))], ["BL_" "FCL_" "PKKL_" "FCD"]),
    #DAS.map_plot(m, [s -> min(s.B.l_, mean(map(f -> floor(Int, m.p.ν0 * DAS.pkk(f) - DAS.l(f)), values(merge(s.FKs, s.FCs))))), s -> mean(map(f -> f.l_, values(s.FCs))), s -> mean(map(f -> f.D, values(s.FCs)))], ["min BL_ PKKL_" "FCL_" "FCD"]),
    DAS.map_plot(m, [s -> s.stats.ψ, s -> s.stats.u, s -> s.stats.ω, s -> s.C.rB], ["ψ" "u" "ω" "rB"]),
    DAS.map_plot(m, [s -> DAS.mapsum(f -> f.c_, values(s.FCs)), s -> DAS.mapsum(f -> f.c, values(s.FCs)), s -> DAS.mapsum(h -> h.rc_, values(s.Hs)), s -> DAS.mapsum(h -> h.rc, values(s.Hs)), s -> s.G.rC], ["c_" "c" "Hc_" "Hc" "Gc"]),
    DAS.map_plot(m, [s -> mean(map(f -> f.p, values(s.FCs))), s -> mean(map(f -> f.p, values(s.FKs)))], ["pC" "pK"]),
    DAS.map_plot(m, [s -> s.stats.Y / 12, s -> DAS.mapsum(h -> h.w, values(s.Hs))], ["Y" "w"]),
    DAS.map_plot(m, [s -> mean(map(f -> f.β, values(s.FKs))), s -> mean(map(f -> f.σ, values(s.FKs)))], ["β" "σ"]),
    DAS.map_plot(m, [s -> DAS.Γ(s), s -> s.B.R / s.B.D], ["Γ" "Λ"]),
    layout=(8, 1),
    size=(900, 1600)
)

t = 100

plot(
    histogram(map(h -> h.S + h.D, values(m.states[t].Hs)), title="v"),
    histogram(map(h -> h.z, values(m.states[t].Hs)), title="z"),
    histogram(map(h -> h.z + h.S * m.states[t].B.rS, values(m.states[t].Hs)), title="y"),
    layout=(1, 3),
    size=(900, 300)
)

using StatsBase

(
    kurtosis(map(h -> h.S + h.D, values(m.states[t].Hs))),
    kurtosis(map(h -> h.z + h.S * m.states[t].B.rS + h.m, values(m.states[t].Hs)))
)

scatter(map(h -> h.σ, valfilter(h -> h.w > 0, collect(values(m.states[t].Hs)))ues(m.states[t].Hs)), map(h -> h.z, values(m.states[t].Hs)),)