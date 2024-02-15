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
    μ::Float = 1 + (N - 2) * (tanh(m.p.e0 * (v(m, h) / m.s[t].stats.p)))
    s::Float = (μ / N) * (N - μ) * (N * m.p.e1 - m.p.e1 + 1)
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
        h1 = s1.Hs[h.id]
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
                s.B.S += Δ
            end
            h.D -= it
            s.B.D += it
            s.B.B -= it
            s.G.B += it
            h.t -= it
            s.G.T += it
        end
        ψ = s.stats.ψ
        if h1.nc > 0
            p = ceil(Int, h1.nc / h1.rc * (1 + ψ))
        else
            p = ceil(Int, s.stats.p * (1 + m.p.τC) * (1 + ψ))
        end

        rcv_ = c((h.S + h.D) / p, m.p.av)

        if h.employer === nothing
            Ey = m.p.ϕ * max(wH(m, m.t, h1.EwF), h1.m)
        else
            Ey = wH(m, m.t, h1.EwF)
        end

        rcy_ = c(Ey / p, m.p.ay)
        h.rc_ = rcv_ + rcy_

        s_ = max(0, floor(Int, h.S + h.D + Ey - (1 + m.p.ρH) * p * h.rc_))
        Δs = max(min(s_ - h.S, h.D), -h.S)
        h.S += Δs
        s.B.S -= Δs
        h.D -= Δs
        s.B.D += Δs
    end
end