function fire!(h::Household)
    h.employer = nothing
    h.employer_changed = true
    # h.wF = 0
end

function stepE!(m::Model)
    s = m.s[m.t]
    # println("E")
    for f = s.FCs
        f1 = m.s[m.t-1].FCs[f.id]
        if v(f) < 0 # bankrupt
            s.B.L += L(f)
            f.L = []
            s.B.D += f.D
            f.D = 0
            for id = f.employees
                fire!(state.Hs[id])
            end
            f.employees = []
        end
        Es = (1 + s.stats.g - s.stats.ψ) * f1.s
        f.c_ = max(1, ceil(Int, m.p.ρC * Es))
        f.Δb_ = max(0, f.c_ / m.p.u_ - (1 - m.p.γ) * b(m, f))
        if length(f.K) > 0
            Ei = (1 + s.stats.ψ) * mean(k -> k.p0 / βF(m, f, k), f.K) * f.Δb_
            if length(f.employees) > 0
                EwF = max(f1.wF, f.c_ / mean(k -> βF(m, f, k), f.K) * mean(hid -> m.s[m.t-1].Hs[hid].wF, f.employees))
            else
                EwF = max(f.wF, f.c_ / mean(k -> βF(m, f, k), f.K) * mean(k -> Ewσ(m, t, k.σ), f.K))
            end
        else
            fk1 = sample(collect(values(s1.FKs)))
            effβ = m.p.k * fk1.β
            Ei = (1 + s.stats.ψ) * fk1.pF / effβ * f.Δb_
            if length(f.employees) > 0
                EwF = max(f.wF, f.c_ / effβ * mean(hid -> m.s[m.t-1].Hs[hid].wF, f.employees))
            else
                EwF = max(f.wF, f.c_ / effβ * Ewσ(m, t, fk1.σ))
            end
        end
        f.μ = f1.μ * (1 + m.p.Θ * (m.p.ρC * f1.s / f1.c_ - 1))
        f.l_ = ceil(Int, max(m.p.ρF * EwF - f.D, m.p.ρF * (EwF + Ei) - (f.D + ((1 + μ) * f1.wF / f1.c) * Es)))

        l = max(0, floor(Int, min(f.l_, s.B.l_, m.p.ν0 * pKK(f) + L(f))))
        if l > 0
            if L(f) != 0
                if v(f) != 0
                    rL = s.B.rL - m.p.ν3 * L(f) / v(f) + m.p.ν4 * f1.π / L(f)
                else
                    rL = s.B.rL + m.p.ν3 + m.p.ν4 * f1.π / L(f)
                end
            else
                rL = s.B.rL - m.p.ν4
            end
            push!(f.L, Loan(l, max(0, rL), 0, false))
            s.B.L += l
            f.D += l
            s.B.D -= l
        end
    end

    for f = state.FKs
        f1 = m.s[m.t-1].FKs[f.id]
        if v(f) < 0 # bankrupt
            s.B.L += L(f)
            f.L = []
            s.B.D += f.D
            f.D = 0
            for id = f.employees
                fire!(state.Hs[id])
            end
            f.employees = []
        end
        Es = (1 + s.stats.g - s.stats.ψ) * f1.s
        f.Δb_ = max(1, Es / m.p.u_ - m.p.γ * b(m, f)) - b(m, f)
        f.k_ = max(0, ceil(Int, m.p.ρK * Es + f.Δb_ / f.β - lenght(f.inv)))
        f.μ = f1.μ * (1 + m.p.Θ * (m.p.ρK * f1.s / f.k_ - 1))
        σempl = filter(hid -> s.Hs[hid].σ >= m.p.σ_, f.employees)
        if length(σempl) > 0
            avgwQF = mean(map(hid -> s.Hs[hid].wF, σempl))
        else
            avgwQF = Ewσ(m, t, m.p.σ_)
        end
        f.q_ = count(r -> r.operator !== nothing, f1.Q) + floor(Int, m.p.ρQ * (f1.pF * f1.s - f1.wF) / avgwQF)
        if length(f.K) > 0
            if length(f.employees) > 0
                EwF = max(f1.wF, f.k_ / mean(k -> βF(m, f, k), f.K) * mean(hid -> m.s[m.t-1].Hs[hid].wF, f.employees) + f.q_ * avgwQF)
            else
                EwF = max(f1.wF, f.k_ / mean(k -> βF(m, f, k), f.K) * mean(k -> Ewσ(m, t, k.σ), f.K) + f.q_ * avgwQF)
            end
        else
            if length(f.employees) > 0
                EwF = max(f1.wF, f.k_ / f.β * mean(hid -> m.s[m.t-1].Hs[hid].wF, f.employees) + q_ * avgwQF)
            else
                EwF = max(f1.wF, f.k_ / f.β * Ewσ(m, t, f.σ) + q_ * avgwQF)
            end
        end
        f.l_ = ceil(Int, max(m.p.ρF * EwF, 0))

        l = max(0, floor(Int, min(f.l_, s.B.l_, m.p.ν0 * pKK(f) + L(f))))
        if l > 0
            if L(f) != 0
                if v(f) != 0
                    rL = s.B.rL - m.p.ν3 * L(f) / v(f) + m.p.ν4 * f1.π / L(f)
                else
                    rL = s.B.rL + m.p.ν3 + m.p.ν4 * f1.π / L(f)
                end
            else
                rL = s.B.rL - m.p.ν4
            end
            push!(f.L, Loan(l, max(0, rL), 0, false))
            s.B.L += l
            f.D += l
            s.B.D -= l
        end
    end
end