function stepN!(m::Model)
    @debug "N"
    s = m.s[m.t]
    for f = s.FCs
        for l = f.L
            i = floor(Int, l.r * l.principal)
            Δv = ceil(Int, l.principal / (m.p.NL - l.age))
            if f.D < (i + Δv)
                l.principal += i
                l.age -= 1
                l.NPL = true
                s.B.L += i
            else
                f.D -= (i + Δv)
                s.B.D += (i + Δv)
                f.iL -= i
                s.B.iL += i
                l.principal -= Δv
                l.NPL = false
                s.B.L -= Δv
            end
        end
        filter!(l -> l.principal > 0, f.L)
    end
    for f = s.FKs
        for l = f.L
            i = floor(Int, l.r * l.principal)
            Δv = ceil(Int, l.principal / (m.p.NL - l.age))
            if f.D < (i + Δv)
                l.principal += i
                l.age -= 1
                l.NPL = true
                s.B.L += i
            else
                f.D -= (i + Δv)
                s.B.D += (i + Δv)
                f.iL -= i
                s.B.iL += i
                l.principal -= Δv
                l.NPL = false
                s.B.L -= Δv
            end
        end
        filter!(l -> l.principal > 0, f.L)
    end
end
