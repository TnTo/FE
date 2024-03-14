using NamedArrays

Base.displaysize() = (25, 80)

function compute_balance_sheet(m::Model, t::Int)::NamedArray{Int}
    s = m.s[t]
    balance = NamedArray(zeros(Int, 6, 6), ([:D, :S, :L, :B, :K, :V], [:H, :FC, :FK, :B, :G, :Tot]))
    balance[:D, :H] = sum(a -> a.D, s.Hs)
    balance[:D, :FC] = sum(a -> a.D, s.FCs)
    balance[:D, :FK] = sum(a -> a.D, s.FKs)
    balance[:D, :B] = s.B.D
    balance[:D, :Tot] = sum(balance[:D, :])
    balance[:S, :H] = sum(a -> a.S, s.Hs)
    balance[:S, :B] = s.B.S
    balance[:S, :Tot] = sum(balance[:S, :])
    balance[:L, :FC] = -sum(l -> l.principal, vcat(map(a -> a.L, s.FCs)...))
    balance[:L, :FK] = -sum(l -> l.principal, vcat(map(a -> a.L, s.FKs)...))
    balance[:L, :B] = s.B.L
    balance[:L, :Tot] = sum(balance[:L, :])
    balance[:B, :B] = s.B.B
    balance[:B, :G] = s.G.B
    balance[:B, :Tot] = sum(balance[:B, :])
    balance[:K, :FC] = sum(a -> pKK(m, a), s.FCs)
    balance[:K, :FK] = sum(a -> pKK(m, a), s.FKs)
    balance[:K, :Tot] = sum(balance[:K, :])
    balance[:V, :H] = sum(balance[:, :H])
    balance[:V, :FC] = sum(balance[:, :FC])
    balance[:V, :FK] = sum(balance[:, :FK])
    balance[:V, :B] = sum(balance[:, :B])
    balance[:V, :G] = sum(balance[:, :G])
    balance[:V, :Tot] = sum(balance[:V, :])
    return balance
end

function compute_flow_matrix(m::Model, t::Int)::NamedArray{Int}
    s = m.s[t]
    s1 = m.s[t-1]
    flow = NamedArray(zeros(Int, 15, 6), ([:C, :I, :W, :T, :M, :ΠF, :rS, :rL, :rB, :ΔD, :ΔS, :ΔL, :ΔB, :ΔK, :Tot], [:H, :FC, :FK, :B, :G, :Tot]))
    flow[:C, :H] = -sum(a -> a.nc, s.Hs)
    flow[:C, :FC] = sum(a -> a.s * a.pF, s.FCs)
    flow[:C, :G] = -s.G.nC
    flow[:C, :Tot] = sum(flow[:C, :])
    flow[:I, :FC] = sum(a -> a.i, s.FCs)
    flow[:I, :FK] = sum(a -> a.y, s.FKs)
    flow[:I, :Tot] = sum(flow[:I, :])
    flow[:W, :H] = sum(a -> a.wF, s.Hs)
    flow[:W, :FC] = -sum(a -> a.wF, s.FCs)
    flow[:W, :FK] = -sum(a -> a.wF, s.FKs)
    flow[:W, :Tot] = sum(flow[:W, :])
    flow[:T, :H] = sum(a -> a.t, s.Hs)
    flow[:T, :G] = s.G.T
    flow[:T, :Tot] = sum(flow[:T, :])
    flow[:M, :H] = sum(a -> a.m, s.Hs)
    flow[:M, :G] = s.G.M
    flow[:M, :Tot] = sum(flow[:M, :])
    flow[:ΠF, :FC] = -sum(a -> a.π, s.FCs)
    flow[:ΠF, :FK] = -sum(a -> a.π, s.FKs)
    flow[:ΠF, :B] = s.B.Π
    flow[:ΠF, :Tot] = sum(flow[:ΠF, :])
    flow[:rS, :H] = sum(a -> a.iS, s.Hs)
    flow[:rS, :B] = s.B.iS
    flow[:rS, :Tot] = sum(flow[:rS, :])
    flow[:rL, :FC] = sum(a -> a.iL, s.FCs)
    flow[:rL, :FK] = sum(a -> a.iL, s.FKs)
    flow[:rL, :B] = s.B.iL
    flow[:rL, :Tot] = sum(flow[:rL, :])
    flow[:rB, :B] = floor(Int, s.B.B * s.G.rB)
    flow[:rB, :G] = floor(Int, s.G.B * s.G.rB)
    flow[:rB, :Tot] = sum(flow[:rB, :])
    flow[:ΔD, :H] = -(sum(a -> a.D, s.Hs) - sum(a -> a.D, s1.Hs))
    flow[:ΔD, :FC] = -(sum(a -> a.D, s.FCs) - sum(a -> a.D, s1.FCs))
    flow[:ΔD, :FK] = -(sum(a -> a.D, s.FKs) - sum(a -> a.D, s1.FKs))
    flow[:ΔD, :B] = -(s.B.D - s1.B.D)
    flow[:ΔD, :Tot] = sum(flow[:ΔD, :])
    flow[:ΔS, :H] = -(sum(a -> a.S, s.Hs) - sum(a -> a.S, s1.Hs))
    flow[:ΔS, :B] = -(s.B.S - s1.B.S)
    flow[:ΔS, :Tot] = sum(flow[:ΔS, :])
    flow[:ΔL, :FC] = -(sum(a -> L(a), s.FCs) - sum(a -> L(a), s1.FCs))
    flow[:ΔL, :FK] = -(sum(a -> L(a), s.FKs) - sum(a -> L(a), s1.FKs))
    flow[:ΔL, :B] = -(s.B.L - s1.B.L)
    flow[:ΔL, :Tot] = sum(flow[:ΔL, :])
    flow[:ΔB, :B] = -(s.B.B - s1.B.B)
    flow[:ΔB, :G] = -(s.G.B - s1.G.B)
    flow[:ΔB, :Tot] = sum(flow[:ΔB, :])
    flow[:ΔK, :FC] = -(sum(a -> pKK(m, a), s.FCs) - sum(a -> pKK(m, a), s1.FCs))
    flow[:ΔK, :FK] = -(sum(a -> pKK(m, a), s.FKs) - sum(a -> pKK(m, a), s1.FKs))
    flow[:ΔK, :Tot] = sum(flow[:ΔK, :])
    flow[:Tot, :H] = sum(flow[[:ΔD, :ΔS, :ΔL, :ΔB, :ΔK], :H]) + sum(flow[[:C, :I, :W, :T, :M, :ΠF, :rS, :rL, :rB], :H])
    flow[:Tot, :FC] = sum(flow[[:ΔD, :ΔS, :ΔL, :ΔB, :ΔK], :FC]) + sum(flow[[:C, :I, :W, :T, :M, :ΠF, :rS, :rL, :rB], :FC])
    flow[:Tot, :FK] = sum(flow[[:ΔD, :ΔS, :ΔL, :ΔB, :ΔK], :FK]) + sum(flow[[:C, :I, :W, :T, :M, :ΠF, :rS, :rL, :rB], :FK])
    flow[:Tot, :B] = sum(flow[[:ΔD, :ΔS, :ΔL, :ΔB, :ΔK], :B]) + sum(flow[[:C, :I, :W, :T, :M, :ΠF, :rS, :rL, :rB], :B])
    flow[:Tot, :G] = sum(flow[[:ΔD, :ΔS, :ΔL, :ΔB, :ΔK], :G]) + sum(flow[[:C, :I, :W, :T, :M, :ΠF, :rS, :rL, :rB], :G])
    flow[:Tot, :Tot] = sum(flow[[:ΔD, :ΔS, :ΔL, :ΔB, :ΔK], :Tot]) + sum(flow[[:C, :I, :W, :T, :M, :ΠF, :rS, :rL, :rB], :Tot])
    return flow
end

function display_matrices(m::Model, t::Int)
    display(compute_balance_sheet(m, t))
    display(compute_flow_matrix(m, t))
    flush(stdout)
    println()
end