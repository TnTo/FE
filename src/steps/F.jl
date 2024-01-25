function resign!(m::Model, h::Household)
    if h.employer !== nothing
        filter!(x -> x != h.id, f_by_id(m, m.t, h.employer).employees)
        h.employer = nothing
        h.employer_changed = true
        h.EwF = 0
    end
end

function skill_from_wealth(m::Model, t::Int, h::Household)::Float
    N::Int = m.p.σM
    μ::Float = 1 + (N - 1) * (tanh(m.p.e0 * (v(m, h) / m.s[t].stats.p)))
    s::Float = (μ / N) * (N - μ + m.p.e1)
    A::Float = (μ * N - μ^2 - s) / (s * N - μ * N + μ^2)
    α::Float = A * μ
    β::Float = A * (N - μ)
    σ = 1 + rand(BetaBinomial(N - 1, α, β))
    return σ
end

function stepF!(m::Model)
    s = m.s[m.t]
    s1 = m.s[m.t-1]
    # println("F")
    for h = s.Hs
        h1 = s.Hs[h.id]
        if h.age == m.p.AR # retirement
            resign!(m, h)
            h.σ = skill_from_wealth(m, m.t, h)
            h.age = m.p.A0 + floor(Int, 12 * h.σ)
            it = floor(Int, m.p.τI * v(m, h1))
            if h.D < it
                Δ = it - h.D
                h.D += Δ
                h.S -= Δ
                s.B.D -= Δ
                s.B.D += Δ
            end
            h.D -= it
            s.B.D += it
            s.B.B -= it
            s.G.B += it
            h.t += it
        end
        rS = s.B.rS * (1 - m.p.τS)
        rS1 = s1.B.rS * (1 - m.p.τS)
        ΔrS = rS - rS1
        ψ = s.stats.ψ
        if h1.nc > 0
            p = ceil(Int, h1.nc / h1.rc)
        else
            p = ceil(Int, s.stats.p * (1 + m.p.τC))
        end
        D = ((1 + ψ) * p * η(m, m.t, h) + (rS + ΔrS) * (1 + m.p.ρH))
        A = (ΔrS * h.S + (rS + ΔrS) * (h.D - (1 + m.p.ρH) * h1.nc)) / D - ψ * h1.rc / (1 + ψ)
        if h.worker == true
            if (A + (-wH(m, m.t, h.EwF) + (rS + ΔrS) * (m.p.ϕ * max(h1.m, wH(m, m.t, h.EwF)))) / D) > 0
                resign!(m, h)
                h.worker = false
            end
        else
            if ((A + ((rS + ΔrS) * (m.p.ϕ * h1.m)) / D) > 0) && ((A + (Ewσ(m, m.t, h.σ) + (rS + ΔrS) * Ewσ(m, m.t, h.σ)) / D) > 0)
                h.worker = true
            end
        end
        if h.employer === nothing
            h.rc_ = ceil(Int, h1.rc + A + ((rS + ΔrS) * (m.p.ϕ * max(h1.m, wH(m, m.t, h.EwF)))) / D)
            s_ = max(0, floor(Int, h.S + h.D + (m.p.ϕ * max(h1.m, wH(m, m.t, h.EwF))) - (1 + m.p.ρH) * (1 + s.stats.ψ) * p * h.rc_))
        else
            h.rc_ = ceil(Int, h1.rc + A + ((rS + ΔrS) * wH(m, m.t, h.EwF)) / D)
            s_ = max(0, floor(Int, h.S + h.D + wH(m, m.t, h.EwF) - (1 + m.p.ρH) * (1 + s.stats.ψ) * p * h.rc_))
        end
        Δs = min(s_ - h.S, h.D)
        h.S += Δs
        s.B.S -= Δs
        h.D -= Δs
        s.B.D += Δs
    end
end