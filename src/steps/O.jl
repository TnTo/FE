
function stepO!(m::Model)
    # println("O")
    s = m.s[m.t]
    for f = s.FCs
        f.π = min(max(0, floor(Int, m.p.ρΠ * (f.pF * f.s - f.wF))), f.D)
        f.D -= f.π
        state.B.D += f.π
        state.B.Π += f.π
    end
    for f = s.FKs
        f.π = min(max(0, floor(Int, m.p.ρΠ * (f.p * f.s - f.wF))), f.D)
        f.D -= f.π
        state.B.D += f.π
        state.B.Π += f.π
    end
end
