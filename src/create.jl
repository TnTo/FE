function create_household(m::Model, id::Int, rv::Int)::Household  # rv = real net worth
    σ::Float = skill_from_wealth(m, rv)
    age = m.p.A0 + floor(Int, 12 * σ)
    return Household(id=id, D=0, S=0, σ=σ, age=age, worker=true, employer=nothing, employer_changed=false, rc_=0, w=0, z=0, m=0, t=0, rc=0, nc=0)
end

function create_consumption_firm(m::Model, id::Int, K::Vector{CapitalGood})
    return ConsumptionFirm(id=id, D=0, L=Loan[], K=K, c_=1, Δb_=0, l_=0, c=0, s=0, Δb=0, i=0, w=0, il=0, μ=m.p.μ0, p=m.p.p0, π=0, employees=Int[])
end

function create_capital_firm(m::Model, id::Int, K::Vector{CapitalGood}, inv::Vector{CapitalGood})
    return CapitalFirm(id=id, D=0, L=Loan[], K=K, inv=inv, Q=Researcher[], k_=1, Δb_=0, q_=0, l_=0, k=0, s=0, y=0, w=0, il=0, μ=m.p.μ0, p=m.p.p0, π=0, σ=1, β=1, employees=Int[])
end

function create_bank(m::Model, id::Int)
    return Bank(id=id, D=0, S=0, L=0, B=0, R=0, rS=0, rL=0, l_=0, Π=0, iL=0)
end

function create_government(m::Model, id::Int)
    return Goverment(id=id, B=0, R=0, Ξ=1, rC=0, nC=0, M=0, T=0)
end

function create_centralbank(m::Model, id::Int)
    return CentralBank(id=id, B=0, R=0, rB=0)
end

function age_household!(m::Model, h::Household)
    age = rand(DiscreteUniform(h.age + 1, m.p.AM - 1))
    δ_ = rand(Binomial(age - h.age, m.p.δ0))
    σ = h.σ * (1 + m.p.Σ)^δ_
    h.σ = σ
    h.age = age
end

function create_capital_good(p::Parameters)::CapitalGood
    age = rand(DiscreteUniform(0, p.NK - 1))
    price = floor(Int, p.p0 / p.NK * (p.NK - age))
    return CapitalGood(price, age, 1, 1, nothing)
end

function create_model(p::Parameters)::Model
    Random.seed!(p.seed)
    m = Model(p, OffsetArray{State}(undef, 0:p.T), 0, 0)
    C = create_centralbank(m, next_id!(m))
    G = create_government(m, next_id!(m))
    B = create_bank(m, next_id!(m))
    Hs = Dict(id => create_household(m, id, rv) for (id, rv) = [(next_id!(m), rv) for rv = rand(Geometric(1 / m.p.v0), m.p.NH)])
    map(h -> age_household!(m, h), values(Hs))
    FCs = Dict(id => create_consumption_firm(m, id, [create_capital_good(p) for _ = 1:m.p.K0]) for id = [next_id!(m) for _ = 1:m.p.NFC])
    FKs = Dict(id => create_capital_firm(m, id, [create_capital_good(p)], CapitalGood[]) for id = [next_id!(m) for _ = 1:m.p.NFK])
    stats = Stats(ψ=m.p.ψ_, u=m.p.u_, ω=m.p.ω_, p=ceil(Int, (1 + m.p.μ0) * m.p.p0), g=0, Y=m.p.p0, Ewσ=[m.p.p0])
    m.states[0] = State(Hs, FCs, FKs, B, G, C, stats)
    return m
end