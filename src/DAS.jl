module DAS

using Distributions
using Random

Float = Float64

include("structs.jl")
include("utils.jl")
include("create.jl")
include("matrices.jl")
include("parameters.jl")
include("plots.jl")

function compute_u(m::Model, t::Int)::Float
    N = mapsum(f -> mapsum(g -> g.β, filter(k -> k.operator !== nothing, f.K)), values(m.states[t].FCs)) + mapsum(f -> mapsum(g -> g.β, filter(k -> k.operator !== nothing, f.K)), values(m.states[t].FKs))
    D = mapsum(f -> b(f), values(m.states[t].FCs)) + mapsum(f -> b(f), values(m.states[t].FKs))
    if D == 0
        return 1
    else
        return N / D
    end
end

function compute_stats(m::Model)::Stats
    t = m.t
    if t >= 12
        t0 = t - 12
    else
        t0 = 0
    end
    if any(map(t -> mapsum(f -> f.s, values(m.states[t].FCs)), t0:(t-1)) .== 0)
        p = mean(map(t -> mean(f -> f.p, values(m.states[t].FCs)), t0:(t-1)))
    else
        p = mean(map(t -> mapsum(f -> f.p * f.s, filter(f -> f.s != 0, collect(values(m.states[t].FCs)))) / mapsum(f -> f.s, filter(f -> f.s != 0, collect(values(m.states[t].FCs)))), t0:(t-1)))
    end
    p = floor(Int, p)
    ψ = (p - m.states[t0].stats.p) / m.states[t0].stats.p
    u = mean(map(t -> compute_u(m, t), t0:(t-1)))
    ω = mean(map(t -> (ws = count(h -> h.worker, collect(values(m.states[t].Hs)))) == 0 ? 0 : count(h -> h.w == 0 && h.worker, collect(values(m.states[t].Hs))) / ws, t0:(t-1)))
    Y = mapsum(t -> mapsum(f -> f.p * f.c, values(m.states[t].FCs)) + mapsum(f -> f.p * f.k, values(m.states[t].FKs)), t0:(t-1)) # I should subtract investments?
    if m.states[t0].stats.Y == 0
        if (Y - m.states[t0].stats.Y) == 0
            g = 0
        else
            g = 1
        end
    else
        g = (Y - m.states[t0].stats.Y) / m.states[t0].stats.Y
    end
    σM = floor(Int, maximum(map(h -> h.σ, values(m.states[m.t-1].Hs))))
    Ewσ = ones(Int, σM)
    for i = 1:σM
        hi = filter(h -> i >= h.σ > (i - 1) && h.w > 0, collect(values(m.states[m.t-1].Hs)))
        if length(hi) == 0
            if i == 1
                Ewσ[i] = m.p.p0
            else
                Ewσ[i] = Ewσ[i-1]
            end
        else
            Ewσ[i] = ceil(Int, mean(map(h -> h.w, hi)))
        end
    end
    return Stats(ψ, u, ω, p, g, Y, Ewσ)
end

function stepAlpha!(m::Model)::State
    # println("0")
    s1 = m.states[m.t]
    m.t += 1
    C = CentralBank(id=s1.C.id, B=s1.C.B, R=s1.C.R, rB=0)
    G = Goverment(id=s1.G.id, B=s1.G.B, R=s1.G.R, Ξ=0, rC=0, nC=0, M=0, T=0)
    B = Bank(id=s1.B.id, D=s1.B.D, S=s1.B.S, L=s1.B.L, B=s1.B.B, R=s1.B.R, rS=0, rL=0, l_=0, Π=0, iL=0)
    Hs = Dict(id => Household(id=id, D=h.D, S=h.S, σ=h.σ, age=h.age + 1, worker=h.worker, employer=h.employer, employer_changed=false, rc_=0, w=h.w, z=0, m=0, t=0, rc=0, nc=0) for (id, h) = s1.Hs)
    FCs = Dict(id => ConsumptionFirm(id=id, D=f.D, L=[Loan(l.value, l.r, l.age + 1, l.NPL) for l in f.L], K=[CapitalGood(k.p, k.age + 1, k.σ, k.β, nothing) for k = f.K], c_=0, Δb_=0, l_=0, c=0, s=0, Δb=0, i=0, w=0, il=0, μ=0, p=0, π=0, employees=copy(f.employees)) for (id, f) = s1.FCs)
    FKs = Dict(id => CapitalFirm(id=id, D=f.D, L=[Loan(l.value, l.r, l.age + 1, l.NPL) for l in f.L], K=[CapitalGood(k.p, k.age + 1, k.σ, k.β, nothing) for k = f.K], inv=[CapitalGood(k.p, k.age + 1, k.σ, k.β, nothing) for k = f.inv], Q=Researcher[], k_=0, Δb_=0, q_=0, l_=0, k=0, s=0, y=0, w=0, il=0, μ=0, p=0, π=0, σ=f.σ, β=f.β, employees=copy(f.employees)) for (id, f) = s1.FKs)
    stats = Stats(0, 0, 0, 0, 0, 0, Float[])
    state = State(Hs, FCs, FKs, B, G, C, stats)
    m.states[m.t] = state
    return state
end

function stepA!(state::State, state1::State, m::Model)
    # println("A")
    if quarterly(m.t)
        stats = compute_stats(m)
    else
        stats = state1.stats
    end
    state.stats = stats
end

function stepB!(state::State, state1::State, m::Model)
    # println("B")
    if quarterly(m.t)
        rB = state.stats.ψ + m.p.α1 * (state.stats.ψ - m.p.ψ_) + m.p.α2 * (state.stats.u - m.p.u_) - m.p.α3 * (state.stats.ω - m.p.ω_)
    else
        rB = state1.C.rB
    end
    rB = min(0.2, max(-0.05, rB))
    state.C.rB = rB
end

function stepCD!(state::State, state1::State, m::Model)
    # println("CD")
    Γ0 = Γ(state1)
    if v(state1.B) <= 0 # Really no meaning
        state.B.rS = max(0, state.C.rB) # yearly
        state.B.l_ = ceil(Int, state.stats.p / m.p.ν1) # Think it again, it has to be > 0
        state.B.rL = max(0, state.C.rB) # yearly
    elseif state1.B.L == 0
        state.B.rS = max(0, state.C.rB) # yearly
        state.B.l_ = max(0, floor(Int, v(state1.B) / (m.p.Γ_ * m.p.ν1 * (m.p.NFC + m.p.NFK))))
        state.B.rL = max(0, state.C.rB) # yearly
    else
        state.B.rS = max(0, state.C.rB + m.p.λ * (Γ0 - m.p.Γ_)) # yearly
        state.B.l_ = max(0, floor(Int, state1.B.L * (Γ0 / m.p.Γ_ - 1) / (m.p.ν1 * (m.p.NFC + m.p.NFK))))
        state.B.rL = max(0, state.C.rB + m.p.ν2 * (m.p.Γ_ - Γ0)) # yearly
    end
    ΔR = ceil(Int, state.B.D * m.p.Λ_) - state.B.R
    if ΔR > 0
        # increse res -> sell bonds
        ΔR = min(ΔR, state.B.B)
    else
        # decrease res -> buy_bonds
        ΔR = -min(-ΔR, state.C.B)
    end
    state.B.B -= ΔR
    state.C.B += ΔR
    state.B.R += ΔR
    state.C.R += ΔR
end

function stepE!(state::State, state1::State, m::Model)
    # println("E")
    if quarterly(m.t)
        t = m.t
        # those are monthly averages in the quarter?
        avgT = mean(map(i -> abs(m.states[t-i].G.T), 1:4))
        avgM = mean(map(i -> abs(m.states[t-i].G.M), 1:4))
        avgrC = mean(map(i -> abs(m.states[t-i].G.rC), 1:4))
        avgBB = mean(map(i -> abs(m.states[t-i].G.B), 1:4))
        avgBB_B = mean(map(i -> (GB = m.states[t-i].G.B) == 0 ? 0 : abs(m.states[t-i].B.B / GB), 1:4))
        # but the rates have to be corrected
        # those about macro-variables as composite interests
        # interests on bonds are paid as simple interests
        EG = (max(0, 1 + state.stats.ψ + state.stats.g))^(1 / 12) * avgT + (1 + state.stats.g)^(1 / 12) * (1 - state.C.rB / 12 * avgBB_B) * m.p.δ_ * state.stats.Y - state.C.rB / 12 * avgBB
        if avgrC == 0
            Ξ = state1.G.Ξ
        else
            Ξ = ceil(Int, state1.G.Ξ * (EG - avgM) / (avgrC * (1 + state.stats.ψ)^(1 / 12) * state.stats.p))
            # and there is the same ambiguity in the notes
            # TODO
        end
    else
        Ξ = state1.G.Ξ
    end
    state.G.Ξ = max(1, Ξ)
end

function get_f(f::ConsumptionFirm, s::State)::Union{Nothing,ConsumptionFirm}
    if haskey(s.FCs, f.id)
        return s.FCs[f.id]
    else
        return nothing
    end
end

function get_f(f::CapitalFirm, s::State)::Union{Nothing,CapitalFirm}
    if haskey(s.FKs, f.id)
        return s.FKs[f.id]
    else
        return nothing
    end
end

function get_f_by_id(id::Int, s::State)::Union{Nothing,Firm}
    if haskey(s.FCs, id)
        return s.FCs[id]
    elseif haskey(s.FKs, id)
        return s.FKs[id]
    else
        return nothing
    end
end


function fire!(h::Household)
    h.employer = nothing
    h.employer_changed = true
    h.w = 0
end

function replace!(f0::ConsumptionFirm, s::State, m::Model)
    f1 = ConsumptionFirm(id=next_id!(m), D=0, L=Loan[], K=f0.K, c_=0, Δb_=0, l_=0, c=0, s=0, Δb=0, i=0, w=0, il=0, μ=0.2, p=0, π=0, employees=Int[])
    s.FCs[f1.id] = f1
    delete!(s.FCs, f0.id)
    return f1
end

function replace!(f0::CapitalFirm, s::State, m::Model)
    f1 = CapitalFirm(id=next_id!(m), D=0, L=Loan[], K=f0.K, inv=f0.inv, Q=Researcher[], k_=0, Δb_=0, q_=0, l_=0, k=0, s=0, y=0, w=0, il=0, μ=0.2, p=0, π=0, σ=f0.σ, β=f0.β, employees=Int[])
    s.FKs[f1.id] = f1
    delete!(s.FKs, f0.id)
    return f1
end


function set_target!(f::ConsumptionFirm, f1::ConsumptionFirm, Es::Int, s::State, s1::State, m::Model)
    f.c_ = max(1, ceil(Int, m.p.ρC * Es))
    b0 = b(f)
    b_ = f.c_ / (m.p.u_ * m.p.ρC) + (b0 / m.p.NK)
    f.Δb_ = max(0, b_ - b0)
    if length(f.K) > 0 && length(f1.employees) > 0
        w_ = max(f1.w, m.p.p0, ceil(Int, f.c_ / mean(map(k -> k.β, f.K)) * (f1.w / length(f1.employees))))
    else
        w_ = max(f1.w, m.p.p0)
    end
    if length(f.K) > 0
        i_ = ceil(Int, (1 + s.stats.ψ)^(1 / 12) * mean(map(k -> ((k.p * m.p.NK / (m.p.NK - k.age + 1)) / k.β), f.K)) * f.Δb_)
    else
        fk1 = sample(collect(values(s1.FKs)))
        i_ = ceil(Int, (1 + s.stats.ψ)^(1 / 12) * fk1.p / fk1.β * f.Δb_) # Not in notes
    end
    Ep = ceil(Int, f1.p / f1.μ * (1 + f.μ))
    f.l_ = max(0, ceil(Int, m.p.ρF * w_ - f.D), ceil(Int, m.p.ρF * (w_ + i_) - (f.D + (Ep * Es))))
end


function wQ(f::CapitalFirm, s::State, s1::State, m::Model)::Float
    f1 = get_f_by_id(f.id, s1)
    if f1 === nothing
        return Ewσ(m.p.σ_, s)
    else
        eQ = filter(id -> s1.Hs[id].σ >= m.p.σ_, f1.employees)
        NeQ = length(eQ)
        if NeQ == 0
            return Ewσ(m.p.σ_, s)
        else
            wQ = mapsum(id -> s1.Hs[id].w, eQ)
            return ceil(Int, wQ / NeQ)
        end
    end
end

function set_target!(f::CapitalFirm, f1::CapitalFirm, Es::Int, s::State, s1::State, m::Model)
    b0 = b(f)
    b_ = max(1, Es / m.p.u_ + (b0 / m.p.NK))
    f.Δb_ = b_ - b0
    f.k_ = max(0, max(1, ceil(Int, m.p.ρC * Es + f.Δb_ / f1.β)) - length(f.inv))
    avg_wQ = wQ(f, s, s1, m)
    f.q_ = count(r -> r.operator !== nothing, f1.Q) + floor(Int, m.p.ρQ * (f1.p * f1.s - f1.w) / avg_wQ)
    if length(f.K) > 0 && length(f1.employees) > 0
        w_ = max(f1.w, m.p.p0, ceil(Int, f.k_ / mean(map(k -> k.β, f.K)) * (f1.w / length(f1.employees)) + f.q_ * avg_wQ))
    else
        w_ = max(f1.w, m.p.p0)
    end
    f.l_ = max(0, ceil(Int, m.p.ρF * w_ - f.D))
end

ry_(f::ConsumptionFirm) = f.c_
ry_(f::CapitalFirm) = f.k_

ry(f::ConsumptionFirm) = f.c
ry(f::CapitalFirm) = f.k

function stepF!(state::State, state1::State, m::Model)
    # println("F")
    for (id, f) = merge(state.FCs, state.FKs)
        f1 = get_f(f, state1)
        # F0
        if v(f) < 0
            state.B.L -= l(f)
            state.B.D -= f.D
            for id = f.employees
                fire!(state.Hs[id])
            end
            f = replace!(f, state, m)
        end
        # F1
        Es = ceil(Int, (max(1 + state.stats.g - state.stats.ψ, 0))^(1 / 12) * f1.s)
        set_target!(f, f1, Es, state, state1, m)
        if ry_(f1) > 0
            f.μ = f1.μ * (1 + m.p.Θ * (m.p.ρK * f1.s / ry_(f1) * m.p.ρC - 1))
        else
            f.μ = f1.μ
        end
        # F2
        lB_ = min(state.B.l_, floor(Int, m.p.ν0 * pkk(f) - l(f))) # in notes are t-1
        l0 = max(0, min(f.l_, lB_))
        if l0 > 0
            if l(f) == 0
                rL = state.B.rL
            elseif v(f) == 0
                rL = state.B.rL + m.p.ν3 - m.p.ν4 * f1.π / l(f)
            else
                rL = state.B.rL + m.p.ν3 * l(f) / v(f) - m.p.ν4 * f1.π / l(f)
            end
            push!(f.L, Loan(l0, max(0, rL), 0, false))
            state.B.L += l0
            f.D += l0
            state.B.D += l0
        end
    end
end


function resign!(h::Household, s::State)
    if h.employer !== nothing
        f = get_f_by_id(h.employer, s)
        filter!(x -> x != h.id, f.employees)
        h.employer = nothing
        h.employer_changed = true
        h.w = 0
    end
end

function B2G!(q::Int, state::State)
    if state.B.R < q
        # In the startup (first month) the bank needs reserves that are not available
        # Solution A (not pursued): Let government transferts money to Hs before ani B->G transaction
        # Solution B (pursued): Let ignore the lack of reserves and instead of creating advances using some ghost "negative bonds" instead
        # Solution C (not pursued): Let ignore everything and allows simply for negative interest-free reserves
        #Δ = q - state.B.R
        #if state.B.B > Δ
        state.B.B -= q
        state.C.B += q
        state.B.R += q
        state.C.R += q
        #else
        #    # println("Credit system has collapsed for lack of liquidity")
        #    throw(DomainError("Bank's Reserves will go negative"))
        #end
    end
    state.B.R -= q
    state.G.R += q

end

function stepG!(state::State, state1::State, m::Model)
    # println("G")
    for (id, h) = copy(state.Hs)
        h1 = state1.Hs[id]
        # G0
        if h.age == m.p.AM
            resign!(h, state)
            σ = skill_from_wealth(m, ceil(Int, v(h) / state.stats.p))
            age = m.p.A0 + floor(Int, 12 * σ)
            h0 = Household(id=next_id!(m), D=h.D, S=h.S, σ=σ, age=age, worker=true, employer=nothing, employer_changed=true, rc_=0, w=0, z=0, m=0, t=0, rc=0, nc=0)
            state.Hs[h0.id] = h0
            delete!(state.Hs, h.id)
            IT = floor(Int, m.p.τI * v(h0))
            if h0.D < IT
                Δ = IT - h0.D
                h0.D += Δ
                h0.S -= Δ
                state.B.D += Δ
                state.B.S -= Δ
            end
            h0.D -= IT
            state.B.D -= IT
            B2G!(IT, state)
            state.G.T += IT
            h0.t += IT
            h = h0
        end
        # G1
        rS = y2m(state.B.rS) * (1 - m.p.τS)
        rS1 = y2m(state1.B.rS) * (1 - m.p.τS)
        ΔrS = rS - rS1
        ψ = y2m(state.stats.ψ)
        if h1.nc > 0
            p = ceil(Int, h1.nc / h1.rc)
        else
            p = state.stats.p
        end
        D = ((1 + ψ) * p * η(m, ceil(Int, (h.D + h.S) / state.stats.p)) + (rS + ΔrS) * (1 + m.p.ρH))
        R = ψ * h1.rc / (1 + ψ)
        h.rc_ = ceil(Int, ((rS + ΔrS) * (h1.D + h1.z + m.p.ϕ * h1.m - (1 + m.p.ρH) * h1.nc) + ΔrS * h1.S) / D + h1.rc / (1 + ψ))
        if h.worker
            if (Δrc_ = ceil(Int, (-h1.z + (rS + ΔrS) * (h1.D + m.p.ϕ * h1.z - (1 + m.p.ρH) * h1.nc) + ΔrS * h1.S) / D - R)) > 0
                h.worker = false
                resign!(h, state)
                h.rc_ = Δrc_ + h1.rc
            end
        else
            Ez = net_wage(m, state, Ewσ(h.σ, state))
            A = ceil(Int, ((rS + ΔrS) * (h1.D + m.p.ϕ * h1.m - (1 + m.p.ρH) * h1.nc) + ΔrS * h1.S) / D - R)
            B = ceil(Int, (Ez + (rS + ΔrS) * (h1.D + Ez - (1 + m.p.ρH) * h1.nc) + ΔrS * h1.S) / D - R)
            if A < 0 && B >= 0
                h.worker = true
                h.rc_ = B + h1.rc
            end
        end
        h.rc_ = max(m.p.c0, h.rc_)
        nc_ = ceil(Int, h.rc_ * p * (1 + ψ))
        ΔS = max(0, min(floor(Int, h.D + h1.z + m.p.ϕ * h1.m - (1 + m.p.ρH) * nc_), h.D))
        h.S += ΔS
        h.D -= ΔS
        state.B.S += ΔS
        state.B.D -= ΔS
    end
end

σ(k::CapitalGood, m::Model) = k.σ
σ(r::Researcher, m::Model) = m.p.σ_

function open_research_vacancies!(vacancies::Vector{Vacancy}, f::ConsumptionFirm, uws::Vector{Household}, m::Model)
end

function open_research_vacancies!(vacancies::Vector{Vacancy}, f::CapitalFirm, uws::Vector{Household}, m::Model)
    ws = filter(h -> h.σ > m.p.σ_, uws)
    if length(ws) > 0
        n = min(length(ws), length(f.Q))
        for i = 1:n
            f.Q[i].operator = ws[i].id
        end
    end
    qs = filter(r -> r.operator === nothing, f.Q)
    if length(qs) > 0
        for q = qs
            push!(vacancies, Vacancy(f.id, q))
        end
    end
end

function open_vacancies!(vacancies::Vector{Vacancy}, f::Firm, state::State, m::Model)
    ks = sort(f.K, by=k -> k.β, rev=true)
    ws::Vector{Household} = sort(map(id -> state.Hs[id], f.employees), by=h -> h.σ, rev=true)
    y = ry_(f)
    while length(ks) > 0 && length(ws) > 0 && y > 0
        h = popfirst!(ws)
        for (i, k) = enumerate(ks)
            if h.σ >= k.σ
                k.operator = h.id
                y -= k.β
                deleteat!(ks, i)
                break
            end
        end
    end
    while length(ks) > 0 && y > 0
        k = popfirst!(ks)
        push!(vacancies, Vacancy(f.id, k))
        y -= k.β
    end
    open_research_vacancies!(vacancies, f, ws, m)
end

function remove_employee!(f::ConsumptionFirm, h::Household)
    filter!(x -> x != h.id, f.employees)
    for k = f.K
        if k.operator == h.id
            k.operator = nothing
        end
    end
end

function remove_employee!(f::CapitalFirm, h::Household)
    filter!(x -> x != h.id, f.employees)
    for k = f.K
        if k.operator == h.id
            k.operator = nothing
        end
    end
    for q = f.Q
        if q.operator == h.id
            q.operator = nothing
        end
    end
end


function fill_vacancy!(v::Vacancy, s::State, s1::State, m::Model)
    hs = filter(h -> h.worker && h.σ >= σ(v.g, m), collect(values(s.Hs)))
    if length(hs) == 0
        # println("Vacancy not filled: skill required too high")
        return
    end
    if length(hs) > m.p.χH
        hs = sample(hs, m.p.χH, replace=false)
    end
    w = Ewσ(σ(v.g, m), s)
    hw = filter(h -> h.w < w, hs)
    if length(hw) >= 1
        h = sort(hw, by=h -> h.σ, rev=true)[1]
    else
        h = sort(hs, by=h -> h.w)[1]
        w = max(ceil(Int, h.w * m.p.ρW), m.p.p0)
    end
    h.employer_changed = (h.employer == v.fid)
    if h.employer !== nothing
        f = get_f_by_id(h.employer, s)
        remove_employee!(f, h)
    end
    h.employer = v.fid
    h.w = w
    push!(get_f_by_id(v.fid, s).employees, h.id)
    v.g.operator = h.id
end

function free_g_by_operator_id!(id::Int, f::ConsumptionFirm)
    for k = f.K
        if k.operator == id
            k.operator = nothing
        end
    end
end

function free_g_by_operator_id!(id::Int, f::CapitalFirm)
    for k = f.K
        if k.operator == id
            k.operator = nothing
        end
    end
    for q = f.Q
        if q.operator == id
            q.operator = nothing
        end
    end
end

function stepH!(state::State, state1::State, m::Model)
    # println("H")
    for (id, f) = state.FKs
        f.Q = [Researcher(nothing) for _ = 1:f.q_]
    end
    vacancies = Vacancy[]
    for (id, f) = merge(state.FCs, state.FKs)
        open_vacancies!(vacancies, f, state, m)
    end
    vacancies = shuffle(vacancies)
    map(v -> fill_vacancy!(v, state, state1, m), vacancies)
    # println("$(length(filter(v->v.g.operator === nothing, vacancies))) vacancies not filled")
    for (id, f) = merge(state.FCs, state.FKs)
        hs = sort(map(id -> state.Hs[id], f.employees), by=h -> h.σ, rev=true)
        w = mapsum(h -> h.w, hs)
        while w > f.D
            # println("Firing a worker for liquidity constraint")
            h = pop!(hs)
            w -= h.w
            fire!(h)
            filter!(i -> i != h.id, f.employees)
            free_g_by_operator_id!(h.id, f)
        end
        for id = f.employees
            h = state.Hs[id]
            h.z = net_wage(m, state, h.w)
            h.D += h.z
            f.D -= h.w
            f.w += h.w
            IT = h.w - h.z
            state.B.D -= IT
            B2G!(IT, state)
            state.G.T += IT
            h.t += IT
        end
    end
end

function stepI!(state::State, state1::State, m::Model)
    # println("I")
    for (id, f) in state.FCs
        f.c = floor(Int, mapsum(k -> k.β, filter(k -> k.operator !== nothing, f.K)))
        if f.c == 0
            f1 = get_f_by_id(f.id, state1)
            if f1 === nothing
                f.p = state.stats.p
            else
                f.p = ceil(Int, f1.p * (1 + f.μ) / (1 + f1.μ))
            end
        else
            f.p = ceil(Int, (1 + m.p.τC) * (1 + f.μ) * f.w / f.c)
        end
    end
    for (id, f) in state.FKs
        f.k = floor(mapsum(k -> k.β, filter(k -> k.operator !== nothing, f.K)))
        if f.k == 0
            f1 = get_f_by_id(f.id, state1)
            if f1 === nothing
                f.p = ceil(Int, (1 + f.μ) * Ewσ(f.σ, state) / f.β)
            else
                f.p = ceil(Int, f1.p * (1 + f.μ) / (1 + f1.μ))
            end
        else
            f.p = ceil(Int, (1 + f.μ) * f.w / f.k)
        end
        ΔK = max(0, ceil(f.Δb_ / f.β))
        for _ = 1:ΔK
            push!(f.K, CapitalGood(f.p, 0, f.σ, f.β, nothing))
        end
        for _ = (ΔK+1):f.k
            push!(f.inv, CapitalGood(f.p, 0, f.σ, f.β, nothing))
        end
        if f.k < ΔK
            Δ = f.Δb_ - f.k * f.β
            while Δ > 0 && length(f.inv) > 0
                k = pop!(f.inv)
                push!(f.K, k)
                Δ -= k.β
            end
        end
    end
end

function G2B!(q::Int, state::State)
    if state.G.R < q
        Δ = q - state.G.R
        state.G.B += Δ
        state.C.B += Δ
        state.G.R += Δ
        state.C.R += Δ
    end
    state.B.R += q
    state.G.R -= q
end

function stepJ!(state::State, state1::State, m::Model)
    # println("J")
    for (id, h) in state.Hs
        if h.employer === nothing
            if haskey(state1.Hs, id)
                M = floor(Int, m.p.ϕ * max(state1.Hs[id].m, state1.Hs[id].z))
                h.m += M
                state.G.M += M
                h.D += M
                state.B.D += M
                G2B!(M, state)
            end
        end
    end
    fcs = filter(((id, f),) -> f.s < f.c, state.FCs)
    for h = shuffle(collect(values(state.Hs)))
        rv = ceil(Int, v(h) / state.stats.p) # Notes are in t-1
        rc_ = ceil(Int, state.G.Ξ * ((1 - m.p.ϵ0) + m.p.ϵ0 * exp(-m.p.ϵ1 * rv)))
        rc = 0
        while rc < rc_ && length(fcs) > 0
            id, f = rand(fcs)
            if (f.c - f.s) > (rc_ - rc)
                c = (rc_ - rc)
            else
                c = f.c - f.s
                delete!(fcs, id)
            end
            p = floor(Int, f.p / (1 + m.p.τC))
            rc += c
            state.G.rC += c
            f.s += c
            h.rc += c
            nc = p * c
            state.G.nC += nc
            f.D += nc
            state.B.D += nc
            G2B!(nc, state)
        end
    end
end

function stepK!(state::State, state1::State, m::Model)
    # println("K")
    hs = filter(((id, h),) -> h.rc < h.rc_, state.Hs)
    fcs = filter(((id, f),) -> f.s < f.c, state.FCs)
    while length(hs) > 0 && length(fcs) > 0
        hid, h = rand(hs)
        if h.D < minimum(map(f -> f.p, values(fcs)))
            delete!(hs, hid)
            continue
        end
        ffcs = filter(f -> f.p <= h.D, collect(values(fcs)))
        f = sort(sample(ffcs, min(length(ffcs), m.p.χC), replace=false), by=(f -> f.p))[1]
        rc = min(h.rc_ - h.rc, ceil(Int, h.rc_ / m.p.χC), floor(Int, h.D / f.p), f.c - f.s)
        nc = f.p * rc
        f.s += rc
        h.rc += rc
        h.nc += nc
        h.D -= nc
        f.D += ceil(Int, nc / (1 + m.p.τC))
        T = nc - ceil(Int, nc / (1 + m.p.τC))
        state.B.D -= T
        B2G!(T, state)
        state.G.T += T
        h.t += T
        if h.rc >= h.rc_
            delete!(hs, hid)
        end
        if f.s >= f.c
            delete!(fcs, f.id)
        end
    end
end

function depreciate_inv!(f::ConsumptionFirm, m::Model)
end

function depreciate_inv!(f::CapitalFirm, m::Model)
    filter!(k -> k.age != m.p.NK, f.inv)
    for k = f.inv
        k.p = floor(Int, (m.p.NK - k.age) / (m.p.NK - k.age + 1) * k.p)
    end
end

function depreciate_capital!(f::Firm, m::Model)
    filter!(k -> k.age != m.p.NK, f.K)
    for k = f.K
        k.p = floor(Int, (m.p.NK - k.age) / (m.p.NK - k.age + 1) * k.p)
    end
    depreciate_inv!(f, m)
end

function cheapest_k_p(FKs)
    min = Inf
    for fk = values(FKs)
        for k = fk.inv
            if k.p < min
                min = k.p
            end
        end
    end
    return min
end

function stepL!(state::State, state1::State, m::Model)
    # println("L")
    for (id, f) = merge(state.FCs, state.FKs)
        depreciate_capital!(f, m)
    end
    # println("L1")
    fcs = filter(((id, f),) -> f.Δb < f.Δb_, state.FCs)
    fks = filter(((id, f),) -> length(f.inv) > 0, state.FKs)
    while length(fcs) > 0 && length(fks) > 0
        fcid, fc = rand(fcs)
        ffks = filter(fk -> any(map(k -> k.p <= fc.D, fk.inv)), collect(values(fks))) # Feasible fks
        if length(ffks) == 0
            delete!(fcs, fcid)
            continue
        end
        fk = sort(sample(ffks, min(length(ffks), m.p.χK), replace=false), by=f -> f.β - Ewσ(f.σ, state) - f.p / m.p.NK)[1] # The promised β, σ, p/N are not necessary the ones sold !!!
        let nk_ = min(ceil(Int, fc.Δb_ - fc.Δb), ceil(Int, fc.Δb_ / m.p.χK), length(fk.inv))
            nk = 0
            i = 1
            while nk < nk_ && i <= length(fk.inv)
                if fk.inv[i].p <= fc.D
                    k = popat!(fk.inv, i)
                    push!(fc.K, k)
                    fc.Δb += k.β
                    fc.i += k.p
                    fk.s += 1
                    fk.y += k.p
                    fc.D -= k.p
                    fk.D += k.p
                    nk += 1
                else
                    i += 1
                end
            end
        end
        if fc.Δb_ <= fc.Δb
            delete!(fcs, fcid)
        end
        if length(fk.inv) == 0
            delete!(fks, fk.id)
        end
    end
end

function stepM!(state::State, state1::State, m::Model)
    # println("M")
    for (id, f) in state.FKs
        Q = count(r -> r.operator !== nothing, f.Q)
        if rand(Bernoulli(exp(-m.p.ζ * Q)))
            Δβ = rand(Beta(1, m.p.b0))
            Δσ = Δβ - m.p.b1 * rand(Beta(1, m.p.b2))
            f.β += Δβ
            f.σ = max(1, f.σ + Δσ)
        end
    end
end

function stepN!(state::State, state1::State, m::Model)
    # println("N")
    for (id, h) = state.Hs
        if h.employer === nothing
            h.σ = h.σ / (1 + m.p.Σ)
        elseif !h.employer_changed
            h.σ = h.σ * (1 + m.p.Σ)
        end

    end
end

function stepO!(state::State, state1::State, m::Model)
    # println("O")
    for (id, f) in merge(state.FCs, state.FKs)
        for l = f.L
            i = floor(Int, y2m(l.r) * l.value)
            Δv = ceil(Int, l.value / (m.p.NL - l.age))
            if f.D < (i + Δv)
                l.value += i
                l.age -= 1
                l.NPL = true
                state.B.L += i
            else
                f.D -= (i + Δv)
                state.B.D -= (i + Δv)
                f.il += i
                state.B.iL += i
                l.value -= Δv
                l.NPL = false
                state.B.L -= Δv
            end
        end
        filter!(l -> l.value > 0, f.L)
    end
end

function stepP!(state::State, state1::State, m::Model)
    # println("P")
    for (id, f) = merge(state.FCs, state.FKs)
        f.π = min(max(0, floor(Int, m.p.ρΠ * (f.p * f.s - f.w))), f.D)
        f.D -= f.π
        state.B.D -= f.π
        state.B.Π += f.π
    end
end

function stepQ!(state::State, state1::State, m::Model)
    # println("Q")
    for (id, h) in state.Hs
        i = floor(Int, y2m(state.B.rS) * h.S)
        t = floor(Int, m.p.τS * i)
        h.D += (i - t)
        state.B.D += (i - t)
        h.t += t
        state.G.T += t
        B2G!(t, state)
    end
end

function stepR!(state::State, state1::State, m::Model)
    # println("R")
    i = floor(Int, y2m(state.C.rB) * state.B.B) # If negative can lead to negative reserves
    if state.G.R < i
        Δ = i - state.G.R
        state.G.B += Δ
        state.C.B += Δ
        state.G.R += Δ
        state.C.R += Δ
    end
    state.G.R -= i
    state.B.R += i
end

function stepOmega!(state::State, state1::State, m::Model)
end

function step!(m)
    state1 = m.states[m.t]
    state = stepAlpha!(m)
    stepA!(state, state1, m)
    stepB!(state, state1, m)
    stepCD!(state, state1, m)
    stepE!(state, state1, m)
    stepF!(state, state1, m)
    stepG!(state, state1, m)
    stepH!(state, state1, m)
    stepI!(state, state1, m)
    stepJ!(state, state1, m)
    stepK!(state, state1, m)
    stepL!(state, state1, m)
    stepM!(state, state1, m)
    stepN!(state, state1, m)
    stepO!(state, state1, m)
    stepP!(state, state1, m)
    stepQ!(state, state1, m)
    stepR!(state, state1, m)
    stepOmega!(state, state1, m)
    # display_matrices(state, state1, m)
end

end