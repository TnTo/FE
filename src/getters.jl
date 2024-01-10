# Firms

βK(m::Model, k::CapitalGood)::Float = k.β
βC(m::Model, k::CapitalGood)::Float = k.β * m.p.k

βF(m::Model, f::CapitalFirm, k::CapitalGood) = βK(m, k)
βF(m::Model, f::ConsumptionFirm, k::CapitalGood) = βC(m, k)

function p(m::Model, k::CapitalGood)
    return floor(Int, k.p0 * (1 - (k.age / m.p.NK)))
end

function b(m::Model, f::Firm)::Float
    return mapsum(k -> βF(m, f, k), f.K)
end

function L(f::Firm)::Int
    return -mapsum(l -> l.principal, f.L)
end

function q(f::CapitalFirm)::Int
    return count(r -> r.operator !== nothing, f.Q)
end

function pKK(f::ConsumptionFirm)::Int
    return mapsum(k -> p(m, k), f.K)
end

function pKK(f::CapitalFirm)::Int
    return mapsum(k -> p(m, k), f.K) + mapsum(k -> p(m, k), f.inv)
end

# Net Worth

function v(h::Household)::Int
    return h.D + h.S
end

function v(f::Firm)::Int
    return f.D + L(f) + pKK(f)
end

function v(b::Bank)::Int
    return b.D + b.S + b.L + b.B
end

function v(g::Goverment)::Int
    return g.B
end

# Bank

function Γ(m::Model, t::Int)::Float
    return v(m.s[t].B) / m.s[t].B.L
end

# Stats

function pF(m::Model, t::Int)::Int
    N = mapsum(f -> f.s * f.p, m.s[t].FCs)
    D = mapsum(f -> f.s, m.s[t].FCs)
    if D == 0
        return 0
    else
        return N ÷ D # Int Div
    end
end

function u(m::Model, t::Int)::Float
    s = st(m, t)
    N = mapsum(f -> mapsum(g -> βC(m, g), filter(k -> k.operator !== nothing, f.K)), values(s.FCs)) +
        mapsum(f -> mapsum(g -> βK(m, g), filter(k -> k.operator !== nothing, f.K)), values(s.FKs))
    D = mapsum(f -> b(m, f), values(s.FCs)) + mapsum(f -> b(m, f), values(s.FKs))
    if D == 0
        return 1
    else
        return N / D
    end
end

function ω(m::Model, t::Int)::Float
    s = st(m, t)
    N = count(h -> h.worker & (h.employer === nothing), collect(values(s.Hs)))
    D = count(h -> h.worker, collect(values(s.Hs)))
    if D == 0
        return 0
    else
        return N / D
    end
end

function Y(m::Model, t::Int)::Int
    s = st(m, t)
    return mapsum(f -> f.s * f.pF, values(s.FCs)) + mapsum(f -> f.y, values(s.FKs))
end

function Ewσ(m::Model, t::Int)::Vector{Int}
    s = st(m, t)
    σM = floor(Int, maximum(map(h -> h.σ, values(s.Hs))))
    Ewσ = ones(Int, σM)
    for i = 1:σM
        hi = filter(h -> i >= h.σ > (i - 1) && h.w > 0, collect(values(s.Hs)))
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
end

function Ewσ(m::Model, t::Int, σ::Float)::Int
    σ = ceil(Int, σ)
    Ew = st(m, t).stats.Ewσ
    if σ > length(Ew)
        return last(Ew)
    else
        return Ew[σ]
    end
end