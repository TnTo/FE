using DrWatson
@quickactivate "DAS"

using Hyperopt

include(srcdir("DAS.jl"))

N = 5

function run_model(p::DAS.Parameters)
    try
        m = DAS.create_model(p)
        for t = 1:m.p.T
            DAS.step!(m)
        end
        return m
    catch e
    end
end

function evaluate_model(m)
    if m === nothing
        return 1000
    end
    try
        m.states[end]
    catch e
        if isa(e, BoundsError)
            return 1000
        else
            rethrow(e)
        end
    end
    return 0
end

ho = @thyperopt for i = N, sampler = LHSampler(), # Hyperband(R=50, η=3, inner=BOHB(dims=[Hyperopt.Continuous() for _ = 1:35])),
    # Hs
    e0 = exp10.(LinRange(-5, 2, N)),
    e1 = exp10.(LinRange(-2, 2, N)),
    Σ = LinRange(0, 1, N),
    τF = exp10.(LinRange(-2, 2, N)),
    τT = (x -> floor(Int, x)).(LinRange(0, 10^6, N)),
    ρH = LinRange(1, 2, N),
    α = exp10.(LinRange(-2, 2, N)),
    # Fs
    ρC = LinRange(1, 2, N),
    Θ = LinRange(0, 1, N),
    ρF = LinRange(1, 2, N),
    ρK = LinRange(1, 2, N),
    ρQ = LinRange(0, 1, N),
    ρΠ = LinRange(0, 1, N),
    # B
    λ = LinRange(0, 1, N),
    ν0 = LinRange(0, 5, N),
    ν1 = LinRange(0, 1, N),
    ν2 = LinRange(0, 1, N),
    ν3 = LinRange(0, 1, N),
    ν4 = LinRange(0, 1, N),
    # G
    ϵ0 = LinRange(0, 1, N),
    ϵ1 = exp10.(LinRange(-2, 2, N)),
    # Markets
    χH = exp10.(LinRange(-2, 0, N)),
    χC = exp10.(LinRange(-2, 0, N)),
    χK = exp10.(LinRange(-2, 0, N)),
    ρW = LinRange(1, 2, N),
    # Innovation
    ζ = exp10.(LinRange(-2, 2, N)),
    b0 = exp10.(LinRange(0, 2, N)),
    b1 = LinRange(0, 1, N),
    b2 = exp10.(LinRange(0, 2, N)),
    # Initialization
    c0 = (x -> floor(Int, x)).(exp10.(LinRange(-1, 2, N))),
    μ0 = exp10.(LinRange(-2, 0, N)),
    v0 = (x -> ceil(Int, x)).(LinRange(0, 10^3, N)),
    δ0 = LinRange(0, 1, N),
    p0 = (x -> floor(Int, x)).(LinRange(0, 10^3, N)),
    K0 = (x -> floor(Int, x)).(LinRange(0, 10^2, N))

    p = DAS.get_default_parameters()
    p.e0 = e0
    p.e1 = e1
    p.Σ = Σ
    p.τF = τF
    p.τT = τT
    p.ρH = ρH
    p.α = α
    p.ρC = ρC
    p.Θ = Θ
    p.ρF = ρF
    p.ρK = ρK
    p.ρQ = ρQ
    p.ρΠ = ρΠ
    p.λ = λ
    p.ν0 = ν0
    p.ν1 = ν1
    p.ν2 = ν2
    p.ν3 = ν3
    p.ν4 = ν4
    p.ϵ0 = ϵ0
    p.ϵ1 = ϵ1
    p.χH = ceil(Int, χH * p.NH)
    p.χC = ceil(Int, χC * p.NFC)
    p.χK = ceil(Int, χK * p.NFK)
    p.ρW = ρW
    p.ζ = ζ
    p.b0 = b0
    p.b1 = b1
    p.b2 = b2
    p.c0 = c0
    p.μ0 = μ0
    p.v0 = v0
    p.δ0 = δ0
    p.p0 = p0
    p.K0 = K0

    m = run_model(p)
    res = evaluate_model(m)
end