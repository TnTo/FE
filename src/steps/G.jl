function proposed_wage(m::Model, t::Int, f::ConsumptionFirm, g::CapitalGood)::Int
    s = m.s[t-1]
    return floor(Int, m.p.k * g.β * s.FCs[f.id].pF / (1 + s.FCs[f.id].μ))
end

function proposed_wage(m::Model, t::Int, f::CapitalFirm, g::CapitalGood)::Int
    s = m.s[t-1]
    return floor(Int, g.β * s.FKs[f.id].p / (1 + s.FKs[f.id].μ))
end

function proposed_wage(m::Model, t::Int, f::CapitalFirm, g::Researcher)::Int
    return avgwQF(m, t - 1, f)
end

function clean_operators!(f::ConsumptionFirm, h::Household)
    for k = f.K
        if k.operator == h.id
            k.operator = nothing
            break
        end
    end
end

function clean_operators!(f::CapitalFirm, h::Household)
    for k = f.K
        if k.operator == h.id
            k.operator = nothing
            break
        end
    end
    for q = f.Q
        if q.operator == h.id
            q.operator = nothing
            break
        end
    end
end

function stepG!(m::Model)
    @debug "G"
    s = m.s[m.t]
    vacancies = Vacancy[]
    for f = s.FCs
        ks = sort(f.K, by=k -> k.β, rev=true)
        ws = sort(map(id -> s.Hs[id], f.employees), by=h -> h.σ, rev=true)
        y = f.c_
        while length(ks) > 0 && length(ws) > 0 && y > 0
            h = popfirst!(ws)
            for (i, k) = enumerate(ks)
                if h.σ >= k.σ
                    k.operator = h.id
                    y -= k.β * m.p.k
                    deleteat!(ks, i)
                    break
                end
            end
        end
        while length(ks) > 0 && y > 0
            k = popfirst!(ks)
            push!(vacancies, Vacancy(f, k, proposed_wage(m, m.t, f, k)))
            y -= k.β * m.p.k
        end
    end
    for f = s.FKs
        f.Q = [Researcher(nothing) for _ = 1:f.q_]
        ks = sort(f.K, by=k -> k.β, rev=true)
        ws = sort(map(id -> s.Hs[id], f.employees), by=h -> h.σ, rev=true)
        y = f.k_
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
            push!(vacancies, Vacancy(f, k, proposed_wage(m, m.t, f, k)))
            y -= k.β
        end
        ws = filter(h -> h.σ > m.p.σ_, ws)
        if length(ws) > 0
            n = min(length(ws), length(f.Q))
            for i = 1:n
                f.Q[i].operator = ws[i].id
            end
        end
        qs = filter(r -> r.operator === nothing, f.Q)
        if length(qs) > 0
            for q = qs
                push!(vacancies, Vacancy(f, q, proposed_wage(m, m.t, f, q)))
            end
        end
    end

    vacancies = shuffle(vacancies)
    for v = vacancies
        hs = filter(h -> h.σ >= σ(m, v.g), s.Hs)
        if length(hs) == 0
            # println("Vacancy not filled: skill required too high")
            continue
        end
        if length(hs) > m.p.χH
            hs = sample(hs, m.p.χH, replace=false)
        end
        w = v.w
        hw = filter(h -> h.EwF < w, hs)
        if length(hw) >= 1
            h = sort(hw, by=h -> h.σ, rev=true)[1]
        else
            h = sort(hs, by=h -> h.EwF)[1]
            w = max(ceil(Int, h.EwF * m.p.ρW), m.p.p0)
        end
        h.employer_changed = (h.employer == v.f.id)
        if h.employer !== nothing
            oldf = f_by_id(m, m.t, h.employer)
            filter!(x -> x != h.id, oldf.employees)
            clean_operators!(oldf, h)
        end
        h.employer = v.f.id
        h.EwF = w
        push!(v.f.employees, h.id)
        v.g.operator = h.id
    end

    for f = s.FCs
        hs = sort(map(id -> s.Hs[id], f.employees), by=h -> h.σ, rev=true)
        w = mapsum(h -> h.EwF, hs)
        while w > f.D
            h = pop!(hs)
            w -= h.EwF
            fire!(h)
            filter!(i -> i != h.id, f.employees)
            clean_operators!(f, h)
        end
        for hid = f.employees
            h = s.Hs[hid]
            h.wF = h.EwF
            f.wF += h.EwF # inverse notation
            h.D += h.wF
            f.D -= h.wF
            tax = floor(Int, h.wF * max(0, m.p.τM * tanh(m.p.τF * (h.wF / s.stats.p - m.p.τT))))
            h.D -= tax
            s.B.D += tax
            s.B.B -= tax
            s.G.B += tax
            h.t -= tax
            s.G.T += tax
        end
    end

    for f = s.FKs
        hs = sort(map(id -> s.Hs[id], f.employees), by=h -> h.σ, rev=true)
        w = mapsum(h -> h.EwF, hs)
        while w > f.D
            # println("Firing a worker for liquidity constraint")
            h = pop!(hs)
            w -= h.EwF
            fire!(h)
            filter!(i -> i != h.id, f.employees)
            clean_operators!(f, h)
        end
        for hid = f.employees
            h = s.Hs[hid]
            h.wF = h.EwF
            f.wF += h.wF # inverse notation
            h.D += h.wF
            f.D -= h.wF
            tax = floor(Int, h.wF * max(0, m.p.τM * tanh(m.p.τF * (h.wF / s.stats.p - m.p.τT))))
            h.D -= tax
            s.B.D += tax
            s.B.B -= tax
            s.G.B += tax
            h.t -= tax
            s.G.T += tax
        end
    end
end