function intergenerational_mobility(m::Model, s::State, s1::State)
    idx = (map(h -> h.age, s.Hs) .< map(h -> h.age, s1.Hs)) .& (map(h -> h.σ0, s1.Hs) .>= (m.p.σM / 2))
    if sum(idx) == 0
        return 1
    else
        if (sum(map(h -> h.σ0, s.Hs[idx]) .>= (m.p.σM / 2)) / sum(idx)) >= 0.7
            return 1
        else
            return 0
        end
    end
end

function degree_holders(m::Model, s::State)
    if 0.35 >= sum(map(h -> h.σ0, s.Hs) .>= (m.p.σM / 2)) / m.p.NH >= 0.2
        return 1
    else
        return 0
    end
end

function avg_propensity_consume_1st(s::State)
    yh = map(h -> h.wF + h.m + h.iS - h.t, s.Hs)
    idx = yh .<= StatsBase.quintile(yh, 0.2)
    if 1.0 >= mean(map(h -> h.nc, s.Hs[idx]) ./ yh[idx]) >= 0.9
        return 1
    else
        return 0
    end
end

function avg_propensity_consume_5th(s::State)
    yh = map(h -> h.wF + h.m + h.iS - h.t, s.Hs)
    idx = yh .>= StatsBase.quintile(yh, 0.8)
    if 0.5 >= mean(map(h -> h.nc, s.Hs[idx]) ./ yh[idx]) >= 0.4
        return 1
    else
        return 0
    end
end

function growth_rate(s::State)
    if 0.008 >= s.Stats.g >= 0.009
        return 1
    else
        return 0
    end
end

function inflation_rate(s::State)
    if 0.004 >= s.Stats.ψ >= 0.0008
        return 1
    else
        return 0
    end
end

function bank_capital_ratio(m::Model, s::State)
    if Γ(s.B) <= m.p.Γ_
        return 1
    else
        return 0
    end
end

function profit_share(s::State)
    if 0.45 >= (s.B.iS / mapsum(h -> h.wF + h.m + h.iS, s.Hs)) >= 0.3 # include taxes
        return 1
    else
        return 0
    end
end

function debt_interest_rate(s::State)
    if 0.05 >= s.G.rBy >= 0.0
        return 1
    else
        return 0
    end
end

function debt_gdp_rate(s::State)
    if 1.5 >= (s.B.B / (12 * s.Stats.Y)) >= 1.0
        return 1
    else
        return 0
    end
end

function firm_loan_rate(s::State)
    if 0.004 >= (
           mapsum(l -> l.principal * l.r, vcat(vcat(map(a -> a.L, s.FCs)...), vcat(map(a -> a.L, s.FKs)...))) / s.B.L
       ) >= 0
        return 1
    else
        return 0
    end
end

function tax_gdp_rate(s::State)
    if 0.5 >= (s.G.T / s.Stats.Y) >= 0.35
        return 1
    else
        return 0
    end
end

function no_tax_households(m::Model, s::State)
    if 0.25 >= count(h -> h.wF <= m.p.τT * s.stats.p) / m.p.NH >= 0.15
        return 1
    else
        return 0
    end
end

function unemployment_rate(s::State)
    if 0.1 >= s.stats.ω >= 0.0
        return 1
    else
        return 0
    end
end

function unemployment_by_skill(s::State)
    if StatsBase.cor(map(h -> h.σ, s.Hs), map(h -> (h.employer === nothing), s.Hs)) < 0.0
        return 1
    else
        return 0
    end
end

function wage_by_skill(s::State)
    if StatsBase.cor(map(h -> h.σ, s.Hs), map(h -> h.wF, s.Hs)) > 0.0
        return 1
    else
        return 0
    end
end

function firm_size(s::State)
    if StatsBase.kurtosis(map(f -> length(f.employees), vcat(s.FCs, s.FKs))) > 6.0
        return 1
    else
        return 0
    end
end

function income_kurtosis(s::State)
    if StatsBase.kurtosis(map(h -> h.m + h.iS + h.wF - h.t, s.Hs)) > 6.0
        return 1
    else
        return 0
    end
end

function wealth_kurtosis(m::Model, s::State)
    if StatsBase.kurtosis(map(h -> v(m, h))) > StatsBase.kurtosis(map(h -> h.m + h.iS + h.wF - h.t, s.Hs))
        return 1
    else
        return 0
    end
end

function gini_income(s::State)
    if 0.35 >= gini(map(h -> h.m + h.iS + h.wF - h.t, s.Hs)) >= 0.25
        return 1
    else
        return 0
    end
end

function gini_wealth(s::State)
    if gini(map(h -> v(m, h))) > gini(map(h -> h.m + h.iS + h.wF - h.t, s.Hs))
        return 1
    else
        return 0
    end
end

function goverment_spending(s::State)
    if 0.60 >= ((s.G.M + s.G.nC) / s.stats.Y) >= 0.45
        return 1
    else
        return 0
    end
end

function evaluate_state(m::Model, t::Int)

    try
        s = m.s[t]
        s1 = m.s[t-1]
        return [
            intergenerational_mobility(m, s, s1),
            degree_holders(m, s),
            avg_propensity_consume_1st(s),
            avg_propensity_consume_5th(s),
            growth_rate(s),
            inflation_rate(s),
            profit_share(s),
            debt_interest_rate(s),
            debt_gdp_rate(s),
            firm_loan_rate(s),
            tax_gdp_rate(s),
            no_tax_households(m, s),
            unemployment_rate(s),
            unemployment_by_skill(s),
            wage_by_skill(s),
            firm_size(s),
            income_kurtosis(s),
            wealth_kurtosis(m, s),
            gini_income(s),
            gini_wealth(s),
            goverment_spending(s)
        ]
    catch e
        # println(e)
        return zeros(Int, 21)
    end
end

function evaluate_model(m::Model)
    return hcat(map(t -> evaluate_state(m, t), 1:m.p.T)...)
end