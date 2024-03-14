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

function pKK(m::Model, f::ConsumptionFirm)::Int
    return mapsum(k -> p(m, k), f.K)
end

function pKK(m::Model, f::CapitalFirm)::Int
    return mapsum(k -> p(m, k), f.K) + mapsum(k -> p(m, k), f.inv)
end

function avgwQF(m::Model, t::Int, f::CapitalFirm)::Int
    s = m.s[t]
    σempl = filter(hid -> s.Hs[hid].σ >= m.p.σ_, f.employees)
    if length(σempl) > 0
        avgwQF = mean(map(hid -> s.Hs[hid].wF, σempl))
    else
        avgwQF = Ewσ(m, t, m.p.σ_)
    end
    return ceil(Int, avgwQF)
end

function f_by_id(m::Model, t::Int, id::Int)
    if id <= m.p.NFK
        return m.s[t].FKs[id]
    else
        return m.s[t].FCs[id]
    end
end

# Net Worth

function v(m::Model, h::Household)::Int
    return h.D + h.S
end

function v(m::Model, f::Firm)::Int
    return f.D + L(f) + pKK(m, f)
end

function v(m::Model, b::Bank)::Int
    return b.D + b.S + b.L + b.B
end

function v(m::Model, g::Goverment)::Int
    return g.B
end

# Bank

function Γ(m::Model, t::Int)::Float
    return v(m, m.s[t].B) / m.s[t].B.L
end

# Stats

function pF(m::Model, t::Int)::Int
    N = mapsum(f -> f.s * f.pF, m.s[t].FCs)
    D = mapsum(f -> f.s, m.s[t].FCs)
    if D == 0
        return 0
    else
        return N ÷ D # Int Div
    end
end

function u(m::Model, t::Int)::Float
    s = m.s[t]
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
    s = m.s[t]
    N = count(h -> h.employer === nothing, s.Hs)
    return N / m.p.NH
end

function Y(m::Model, t::Int)::Int
    s = m.s[t]
    return mapsum(f -> f.s * f.pF, s.FCs) + mapsum(f -> f.y, s.FKs)
end

function Ewσ(m::Model, t::Int)::Vector{Int}
    s = m.s[t]
    σM = floor(Int, maximum(map(h -> h.σ, s.Hs)))
    Ewσ = ones(Int, σM)
    for i = 1:σM
        hi = filter(h -> i > h.σ >= (i - 1) && h.wF > 0, s.Hs)
        if length(hi) == 0
            if i == 1
                Ewσ[i] = m.p.p0
            else
                Ewσ[i] = Ewσ[i-1]
            end
        else
            Ewσ[i] = ceil(Int, mean(map(h -> h.wF, hi)))
        end
    end
    return Ewσ
end

function Ewσ(m::Model, t::Int, σ::Float)::Int
    σ = 1 + floor(Int, σ)
    Ew = m.s[t].stats.Ewσ
    if σ > length(Ew)
        return last(Ew)
    else
        return Ew[σ]
    end
end

# Household

function wH(m::Model, t::Int, w::Int)::Int
    z = ceil(Int, w * (1 - max(0, m.p.τM * tanh(m.p.τF * (w / m.s[t].stats.p - m.p.τT)))))
    return z
end

c(x, a) = ceil(Int, ((x + 1)^(1 - a) - 1) / (1 - a))

# Position
σ(m::Model, k::CapitalGood) = k.σ
σ(m::Model, r::Researcher) = m.p.σ_
