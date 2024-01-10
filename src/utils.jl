mapsum(f, itr) = mapreduce(f, +, itr, init=0)

yearly2monthly(r::Float)::Float = (1 + r)^(1 / 12) - 1
y2m = yearly2monthly

function quarterly(t::Int)::Bool
    return (t % 4 == 0)
end

function next_id!(m::Model)::Int
    id = m.id
    m.id += 1
    return id
end

###

function skill_from_wealth(m::Model, rv::Int)::Float # rv = real net worth
    N::Int = m.p.σM
    μ::Float = 1 + (N - 1) * (tanh(m.p.e0 * (rv)))
    s::Float = (μ / N) * (N - μ + m.p.e1)
    A::Float = (μ * N - μ^2 - s) / (s * N - μ * N + μ^2)
    α::Float = A * μ
    β::Float = A * (N - μ)
    σ = 1 + rand(BetaBinomial(N - 1, α, β))
    return σ
end

function η(m::Model, rv::Int)::Float
    return (rv + 1)^(-m.p.α)
end

function net_wage(m::Model, state::State, w::Int)::Int
    z = ceil(Int, w * (1 - max(0, m.p.τM * tanh(m.p.τF * (w / state.stats.p - m.p.τT)))))
    return z
end



