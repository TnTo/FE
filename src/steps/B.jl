function stepB!(m::Model)
    # println("B")
    if quarterly(m.t) & m.t >= 12
        t0 = m.t - 12
        t1 = m.t - 1
        ψy = (m.s[t1].stats.pF / m.s[t0].stats.pF) - 1
        uy = mean(map(t -> m.s[t].stats.u, t0:t1))
        ωy = mean(map(t -> m.s[t].stats.ω, t0:t1))
        rBy_ = ψy + m.p.α1 * (ψy - m.p.ψ_) + m.p.α2 * (uy - m.p.u_) - m.p.α3 * (ωy - m.p.ω_)
        if abs(rBy_ - m.s[t1].stats.rBy) > 0.005
            rBy = m.s[t-1].stats.rBy + sign(rBy_) * 0.005
        else
            rBy = rBy_
        end
        rB = y2m(rBy)
    else
        rBy = m.s[m.t-1].G.rBy
        rB = m.s[m.t-1].G.rB
    end
    m.s[m.t].G.rBy = rBy
    m.s[m.t].G.rB = rB
end