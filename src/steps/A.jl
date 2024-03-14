function compute_stats(m::Model)::Stats
    t1 = m.t - 1
    t0 = m.t - 4 # since last update
    # p
    pFs = map(t -> pF(m, t), t0:t1)
    p = floor(Int, mean(pFs))
    # ψ
    ψs = (pFs[2:4] ./ pFs[1:3]) .- 1
    ψ = mean(ψs)
    # u
    ut = mean(map(t -> u(m, t), t0:t1))
    # ω
    ωt = mean(map(t -> ω(m, t), t0:t1))
    # Y
    Ys = map(t -> Y(m, t), t0:t1)
    Yt = round(Int, mean(Ys))
    # g
    gs = (Ys[2:4] ./ Ys[1:3]) .- 1
    g = mean(gs)
    # Ewσ
    Ewσt = Ewσ(m, t1)
    return Stats(ψ, ut, ωt, p, g, Yt, Ewσt)
end

function stepA!(m::Model)
    @debug "A"
    if quarterly(m.t)
        stats = compute_stats(m)
    else
        stats = m.s[m.t-1].stats
    end
    m.s[m.t].stats = stats
end