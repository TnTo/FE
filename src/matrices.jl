using NamedArrays

Base.displaysize() = (25, 80)

function compute_balance_sheet(m::Model, t::Int)::NamedArray{Int}
    s = m.s[t]
    balance = NamedArray(zeros(Int, 6, 6), ([:D, :S, :L, :B, :K, :V], [:H, :FC, :FK, :B, :G, :Tot]))
    balance[:D, :H] = mapsum(a -> a.D, s.Hs)
    balance[:D, :FC] = mapsum(a -> a.D, s.FCs)
    balance[:D, :FK] = mapsum(a -> a.D, s.FKs)
    balance[:D, :B] = s.B.D
    balance[:D, :Tot] = sum(balance[:D, :])
    balance[:S, :H] = mapsum(a -> a.S, s.Hs)
    balance[:S, :B] = s.B.S
    balance[:S, :Tot] = sum(balance[:S, :])
    balance[:L, :FC] = -mapsum(l -> l.principal, vcat(map(a -> a.L, s.FCs)...))
    balance[:L, :FK] = -mapsum(l -> l.principal, vcat(map(a -> a.L, s.FKs)...))
    balance[:L, :B] = s.B.L
    balance[:L, :Tot] = sum(balance[:L, :])
    balance[:B, :B] = s.B.B
    balance[:B, :G] = s.G.B
    balance[:B, :Tot] = sum(balance[:B, :])
    balance[:K, :FC] = mapsum(a -> pKK(m, a), s.FCs)
    balance[:K, :FK] = mapsum(a -> pKK(m, a), s.FKs)
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
    flow[:C, :H] = -mapsum(a -> a.nc, s.Hs)
    flow[:C, :FC] = mapsum(a -> a.s * a.pF, s.FCs)
    flow[:C, :G] = -s.G.nC
    flow[:C, :Tot] = sum(flow[:C, :])
    flow[:I, :FC] = mapsum(a -> a.i, s.FCs)
    flow[:I, :FK] = mapsum(a -> a.y, s.FKs)
    flow[:I, :Tot] = sum(flow[:I, :])
    flow[:W, :H] = mapsum(a -> a.wF, s.Hs)
    flow[:W, :FC] = -mapsum(a -> a.wF, s.FCs)
    flow[:W, :FK] = -mapsum(a -> a.wF, s.FKs)
    flow[:W, :Tot] = sum(flow[:W, :])
    flow[:T, :H] = mapsum(a -> a.t, s.Hs)
    flow[:T, :G] = s.G.T
    flow[:T, :Tot] = sum(flow[:T, :])
    flow[:M, :H] = mapsum(a -> a.m, s.Hs)
    flow[:M, :G] = s.G.M
    flow[:M, :Tot] = sum(flow[:M, :])
    flow[:ΠF, :FC] = -mapsum(a -> a.π, s.FCs)
    flow[:ΠF, :FK] = -mapsum(a -> a.π, s.FKs)
    flow[:ΠF, :B] = s.B.Π
    flow[:ΠF, :Tot] = sum(flow[:ΠF, :])
    flow[:rS, :H] = mapsum(a -> a.iS, s.Hs)
    flow[:rS, :B] = s.B.iS
    flow[:rS, :Tot] = sum(flow[:rS, :])
    flow[:rL, :FC] = mapsum(a -> a.iL, s.FCs)
    flow[:rL, :FK] = mapsum(a -> a.iL, s.FKs)
    flow[:rL, :B] = s.B.iL
    flow[:rL, :Tot] = sum(flow[:rL, :])
    flow[:rB, :B] = floor(Int, s.B.B * s.G.rB)
    flow[:rB, :G] = floor(Int, s.G.B * s.G.rB)
    flow[:rB, :Tot] = sum(flow[:rB, :])
    flow[:ΔD, :H] = -(mapsum(a -> a.D, s.Hs) - mapsum(a -> a.D, s1.Hs))
    flow[:ΔD, :FC] = -(mapsum(a -> a.D, s.FCs) - mapsum(a -> a.D, s1.FCs))
    flow[:ΔD, :FK] = -(mapsum(a -> a.D, s.FKs) - mapsum(a -> a.D, s1.FKs))
    flow[:ΔD, :B] = -(s.B.D - s1.B.D)
    flow[:ΔD, :Tot] = sum(flow[:ΔD, :])
    flow[:ΔS, :H] = -(mapsum(a -> a.S, s.Hs) - mapsum(a -> a.S, s1.Hs))
    flow[:ΔS, :B] = -(s.B.S - s1.B.S)
    flow[:ΔS, :Tot] = sum(flow[:ΔS, :])
    flow[:ΔL, :FC] = -(mapsum(a -> L(a), s.FCs) - mapsum(a -> L(a), s1.FCs))
    flow[:ΔL, :FK] = -(mapsum(a -> L(a), s.FKs) - mapsum(a -> L(a), s1.FKs))
    flow[:ΔL, :B] = -(s.B.L - s1.B.L)
    flow[:ΔL, :Tot] = sum(flow[:ΔL, :])
    flow[:ΔB, :B] = -(s.B.B - s1.B.B)
    flow[:ΔB, :G] = -(s.G.B - s1.G.B)
    flow[:ΔB, :Tot] = sum(flow[:ΔB, :])
    flow[:ΔK, :FC] = -(mapsum(a -> pKK(m, a), s.FCs) - mapsum(a -> pKK(m, a), s1.FCs))
    flow[:ΔK, :FK] = -(mapsum(a -> pKK(m, a), s.FKs) - mapsum(a -> pKK(m, a), s1.FKs))
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