function compute_stats(m::Model)::Stats
    t1 = m.t - 1
    t0 = m.t - 4 # since last update
    # p
    pFs = map(t -> pF(m, t), t0:t1)
    p = floor(Int, mean(pFs))
    # ψ
    ψs = (ps[2:4] ./ ps[1:3]) .- 1
    ψ = mean(ψs)
    # u
    u = mean(map(t -> u(m, t), t0:t1))
    # ω
    ω = mean(map(t -> ω(m, t), t0:t1))
    # Y
    Ys = map(t -> Y(m, t), t0:t1)
    Y = mean(Ys)
    # g
    gs = (Ys[2:4] ./ Ys[1:3]) .- 1
    g = mean(gs)
    # Ewσ
    Ewσ = Ewσ(m, t1)
    return Stats(ψ, u, ω, p, g, Y, Ewσ)
end

function stepA!(m::Model)
    if quarterly(m.t)
        stats = compute_stats(m)
    else
        stats = m.s[m.t-1].stats
    end
    m.s[m.t].stats = stats
end