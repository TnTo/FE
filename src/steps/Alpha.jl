function age(h::Household)
    return Household(
        id=h.id,
        D=h.D,
        S=h.S,
        σ=h.σ,
        age=h.age + 1,
        worker=h.worker,
        employer=h.employer,
        employer_changed=false,
        rc_=0, # F
        wF=0,
        EwF=h.wF,
        m=0,
        t=0,
        rc=0,
        nc=0,
        iS=0
    )
end

function age(f::ConsumptionFirm)
    return ConsumptionFirm(
        id=f.d,
        D=f.D,
        L=[
            Loan(l.value, l.r, l.age + 1, l.NPL)
            for l in f.L
        ],
        K=[
            CapitalGood(k.p0, k.age + 1, k.σ, k.β, nothing)
            for k = f.K
        ],
        c_=0, # E
        Δb_=0.0, # E
        l_=0, # E
        c=0,
        s=0,
        Δb=0.0,
        i=0,
        wF=0,
        iL=0,
        μ=0.0, # E
        pF=0, #
        π=0,
        employees=copy(f.employees)
    )
end

function age(f::CapitalFirm)
    return CapitalFirm(
        id=f.id,
        D=f.D,
        L=[
            Loan(l.value, l.r, l.age + 1, l.NPL)
            for l in f.L
        ],
        K=[
            CapitalGood(k.p0, k.age + 1, k.σ, k.β, nothing)
            for k = f.K
        ],
        inv=[
            CapitalGood(k.p0, k.age + 1, k.σ, k.β, nothing)
            for k = f.inv
        ],
        Q=Researcher[],
        k_=0, # E
        Δb_=0.0, # E
        q_=0, # E
        l_=0, # E
        k=0,
        s=0,
        y=0,
        wF=0,
        iL=0,
        μ=0.0, # E
        p=0, #
        π=0,
        σ=f.σ,
        β=f.β,
        employees=copy(f.employees)
    )
end

function stepAlpha!(m::Model)::State
    m.t += 1
    s1 = m.s[m.t-1]
    G = Goverment(
        B=s1.G.B,
        rB=0.0, # B
        rBy=0.0, # B
        Ξ=0.0, # D
        rC=0,
        nC=0,
        M=0,
        T=0
    )
    B = Bank(
        D=s1.B.D,
        S=s1.B.S,
        L=s1.B.L,
        B=s1.B.B,
        rS=0.0, # C
        rL=0.0, # C
        l_=0, # C
        Π=0,
        iL=0,
        iS=0
    )
    Hs = OffsetArray([age(m.s[m.t-1].Hs[id]) for id = (m.p.NFK+m.p.NFC+1):(m.p.NFK+m.p.NFC+m.p.NH)], m.p.NFK + m.p.NFC)
    FCs = OffsetArray([age(m.s[m.t-1].FCs[id]) for id = (m.p.NFK+1):(m.p.NFK+m.p.NFC)], m.p.NFK)
    FKs = OffsetArray([age(m.s[m.t-1].FKs[id]) for id = 1:m.p.NFK], 0)
    stats = Stats(0, 0, 0, 0, 0, 0, Float[]) # A
    state = State(Hs, FCs, FKs, B, G, stats)
    m.s[m.t] = state
    return state
end