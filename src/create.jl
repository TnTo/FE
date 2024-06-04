function create_household(m::Model, id::Int)::Household
    age = rand(DiscreteUniform(m.p.A0, m.p.AR - 1))
    σ0 = rand(Binomial(m.p.σM, 0.5))
    σ = σ0 + m.p.Σ * rand(Binomial(age - m.p.A0, m.p.δ0))
    return Household(id=id, D=0, S=0, σ=σ, σ0=σ0, age=age, employer=nothing, employer_changed=false, rc_=0, wF=0, EwF=0, m=0, t=0, rc=0, nc=0, iS=0)
end

function create_consumption_firm(m::Model, id::Int)
    return ConsumptionFirm(id=id, D=0, L=Loan[], K=[CapitalGood(m.p.p0, rand(DiscreteUniform(0, m.p.NK - 1)), m.p.σ0, m.p.β0, nothing) for _ = 1:floor(Int, m.p.k0)], c_=1, Δb_=0, l_=0, c=1, s=1, Δb=0, i=0, wF=0, iL=0, μ=1, pF=ceil(Int, m.p.p0 / m.p.k), π=0, employees=Int[])
end

function create_capital_firm(m::Model, id::Int)
    return CapitalFirm(id=id, D=0, L=Loan[], K=[CapitalGood(m.p.p0, rand(DiscreteUniform(0, m.p.NK - 1)), m.p.σ0, m.p.β0, nothing)], inv=CapitalGood[], Q=Researcher[], k_=1, Δb_=0, q_=0, l_=0, k=1, s=1, y=0, wF=0, iL=0, μ=1, p=m.p.p0, π=0, σ=m.p.σ0, β=m.p.β0, employees=Int[])
end

function create_model(p::Parameters)::Model
    Random.seed!(p.seed)
    m = Model(p, OffsetArray{State}(undef, 0:p.T), 0)
    G = Goverment(B=0, rB=0, rBy=0, Ξ=1, rC=0, nC=0, M=0, T=0)
    B = Bank(D=0, S=0, L=0, B=0, rS=0, rL=0, l_=0, Π=0, iL=0, iS=0)
    Hs = OffsetArray([create_household(m, id) for id = (m.p.NFK+m.p.NFC+1):(m.p.NFK+m.p.NFC+m.p.NH)], m.p.NFK + m.p.NFC)
    FCs = OffsetArray([create_consumption_firm(m, id) for id = (m.p.NFK+1):(m.p.NFK+m.p.NFC)], m.p.NFK)
    FKs = OffsetArray([create_capital_firm(m, id) for id = 1:m.p.NFK], 0)
    stats = Stats(ψ=m.p.ψ_, u=m.p.u_, ω=m.p.ω_, p=ceil(Int, 2 * m.p.p0), g=0, Y=m.p.p0, Ewσ=[ceil(Int, m.p.p0 * m.p.β0 / 2)])
    m.s[0] = State(Hs, FCs, FKs, B, G, stats)
    return m
end