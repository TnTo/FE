using NamedArrays

Base.displaysize() = (25, 80)

function compute_balance_sheet(s::State)::NamedArray{Int}
    balance = NamedArray(zeros(Int, 7, 7), ([:D, :S, :L, :B, :R, :K, :V], [:H, :FC, :FK, :B, :G, :C, :Tot]))
    balance[:D, :H] = mapsum(a -> a.D, values(s.Hs))
    balance[:D, :FC] = mapsum(a -> a.D, values(s.FCs))
    balance[:D, :FK] = mapsum(a -> a.D, values(s.FKs))
    balance[:D, :B] = -s.B.D
    balance[:D, :Tot] = sum(balance[:D, :])
    balance[:S, :H] = mapsum(a -> a.S, values(s.Hs))
    balance[:S, :B] = -s.B.S
    balance[:S, :Tot] = sum(balance[:S, :])
    balance[:L, :FC] = -mapsum(l -> l.value, vcat(map(a -> a.L, values(s.FCs))...))
    balance[:L, :FK] = -mapsum(l -> l.value, vcat(map(a -> a.L, values(s.FKs))...))
    balance[:L, :B] = s.B.L
    balance[:L, :Tot] = sum(balance[:L, :])
    balance[:B, :B] = s.B.B
    balance[:B, :G] = -s.G.B
    balance[:B, :C] = s.C.B
    balance[:B, :Tot] = sum(balance[:B, :])
    balance[:R, :B] = s.B.R
    balance[:R, :G] = s.G.R
    balance[:R, :C] = -s.C.R
    balance[:R, :Tot] = sum(balance[:R, :])
    balance[:K, :FC] = mapsum(k -> k.p, vcat(map(a -> a.K, values(s.FCs))...))
    balance[:K, :FK] = mapsum(k -> k.p, vcat(map(a -> a.K, values(s.FKs))..., map(a -> a.inv, values(s.FKs))...))
    balance[:K, :Tot] = sum(balance[:K, :])
    balance[:V, :H] = sum(balance[:, :H])
    balance[:V, :FC] = sum(balance[:, :FC])
    balance[:V, :FK] = sum(balance[:, :FK])
    balance[:V, :B] = sum(balance[:, :B])
    balance[:V, :G] = sum(balance[:, :G])
    balance[:V, :C] = sum(balance[:, :C])
    balance[:V, :Tot] = sum(balance[:V, :])
    return balance
end

function compute_flow_matrix(s::State, s1::State, m::Model)::NamedArray{Int}
    flow = NamedArray(zeros(Int, 17, 7), ([:C, :I, :W, :T, :M, :ΠF, :ΠC, :rS, :rL, :rB, :ΔD, :ΔS, :ΔL, :ΔB, :ΔR, :ΔK, :Tot], [:H, :FC, :FK, :B, :G, :C, :Tot]))
    flow[:C, :H] = -floor(Int, mapsum(a -> a.nc, values(s.Hs)) / (1 + m.p.τC))
    flow[:C, :FC] = floor(Int, mapsum(a -> a.s * a.p, values(s.FCs)) / (1 + m.p.τC))
    flow[:C, :G] = -s.G.nC
    flow[:C, :Tot] = sum(flow[:C, :])
    flow[:I, :FC] = -mapsum(a -> a.i, values(s.FCs))
    flow[:I, :FK] = mapsum(a -> a.y, values(s.FKs))
    flow[:I, :Tot] = sum(flow[:I, :])
    flow[:W, :H] = mapsum(a -> a.w, values(s.Hs))
    flow[:W, :FC] = -mapsum(a -> a.w, values(s.FCs))
    flow[:W, :FK] = -mapsum(a -> a.w, values(s.FKs))
    flow[:W, :Tot] = sum(flow[:W, :])
    flow[:T, :H] = -mapsum(a -> a.t, values(s.Hs))
    flow[:T, :G] = s.G.T
    flow[:T, :Tot] = sum(flow[:T, :])
    flow[:M, :H] = mapsum(a -> a.m, values(s.Hs))
    flow[:M, :G] = -s.G.M
    flow[:M, :Tot] = sum(flow[:M, :])
    flow[:ΠF, :FC] = -mapsum(a -> a.π, values(s.FCs))
    flow[:ΠF, :FK] = -mapsum(a -> a.π, values(s.FKs))
    flow[:ΠF, :B] = s.B.Π
    flow[:ΠF, :Tot] = sum(flow[:ΠF, :])
    flow[:ΠC, :G] = floor(Int, s.C.B * y2m(s.C.rB))
    flow[:ΠC, :C] = -floor(Int, s.C.B * y2m(s.C.rB))
    flow[:ΠC, :Tot] = sum(flow[:ΠC, :])
    flow[:rS, :H] = floor(Int, y2m(s.B.rS) * mapsum(a -> a.S, values(s.Hs)))
    flow[:rS, :B] = -floor(Int, y2m(s.B.rS) * s.B.S)
    flow[:rS, :Tot] = sum(flow[:rS, :])
    flow[:rL, :FC] = -mapsum(a -> a.il, values(s.FCs))
    flow[:rL, :FK] = -mapsum(a -> a.il, values(s.FKs))
    flow[:rL, :B] = s.B.iL
    flow[:rL, :Tot] = sum(flow[:rL, :])
    flow[:rB, :B] = floor(Int, s.B.B * y2m(s.C.rB))
    flow[:rB, :G] = -floor(Int, s.G.B * y2m(s.C.rB))
    flow[:rB, :C] = floor(Int, s.C.B * y2m(s.C.rB))
    flow[:rB, :Tot] = sum(flow[:rB, :])
    flow[:ΔD, :H] = mapsum(a -> a.D, values(s.Hs)) - mapsum(a -> a.D, values(s1.Hs))
    flow[:ΔD, :FC] = mapsum(a -> a.D, values(s.FCs)) - mapsum(a -> a.D, values(s1.FCs))
    flow[:ΔD, :FK] = mapsum(a -> a.D, values(s.FKs)) - mapsum(a -> a.D, values(s1.FKs))
    flow[:ΔD, :B] = -(s.B.D - s1.B.D)
    flow[:ΔD, :Tot] = sum(flow[:ΔD, :])
    flow[:ΔS, :H] = mapsum(a -> a.S, values(s.Hs)) - mapsum(a -> a.S, values(s1.Hs))
    flow[:ΔS, :B] = -(s.B.S - s1.B.S)
    flow[:ΔS, :Tot] = sum(flow[:ΔS, :])
    flow[:ΔL, :FC] = -(mapsum(a -> l(a), values(s.FCs)) - mapsum(a -> l(a), values(s1.FCs)))
    flow[:ΔL, :FK] = -(mapsum(a -> l(a), values(s.FKs)) - mapsum(a -> l(a), values(s1.FKs)))
    flow[:ΔL, :B] = s.B.L - s1.B.L
    flow[:ΔL, :Tot] = sum(flow[:ΔL, :])
    flow[:ΔB, :B] = s.B.B - s1.B.B
    flow[:ΔB, :G] = -(s.G.B - s1.G.B)
    flow[:ΔB, :C] = s.C.B - s1.C.B
    flow[:ΔB, :Tot] = sum(flow[:ΔB, :])
    flow[:ΔR, :B] = s.B.R - s1.B.R
    flow[:ΔR, :G] = s.G.R - s1.G.R
    flow[:ΔR, :C] = -(s.C.R - s1.C.R)
    flow[:ΔR, :Tot] = sum(flow[:ΔR, :])
    flow[:ΔK, :FC] = mapsum(a -> pkk(a), values(s.FCs)) - mapsum(a -> pkk(a), values(s1.FCs))
    flow[:ΔK, :FK] = mapsum(a -> pkk(a), values(s.FKs)) - mapsum(a -> pkk(a), values(s1.FKs))
    flow[:ΔK, :Tot] = sum(flow[:ΔK, :])
    flow[:Tot, :H] = sum(flow[[:ΔD, :ΔS, :ΔL, :ΔB, :ΔR, :ΔK], :H]) - sum(flow[[:C, :I, :W, :T, :M, :ΠF, :ΠC, :rS, :rL, :rB], :H])
    flow[:Tot, :FC] = sum(flow[[:ΔD, :ΔS, :ΔL, :ΔB, :ΔR, :ΔK], :FC]) - sum(flow[[:C, :I, :W, :T, :M, :ΠF, :ΠC, :rS, :rL, :rB], :FC])
    flow[:Tot, :FK] = sum(flow[[:ΔD, :ΔS, :ΔL, :ΔB, :ΔR, :ΔK], :FK]) - sum(flow[[:C, :I, :W, :T, :M, :ΠF, :ΠC, :rS, :rL, :rB], :FK])
    flow[:Tot, :B] = sum(flow[[:ΔD, :ΔS, :ΔL, :ΔB, :ΔR, :ΔK], :B]) - sum(flow[[:C, :I, :W, :T, :M, :ΠF, :ΠC, :rS, :rL, :rB], :B])
    flow[:Tot, :G] = sum(flow[[:ΔD, :ΔS, :ΔL, :ΔB, :ΔR, :ΔK], :G]) - sum(flow[[:C, :I, :W, :T, :M, :ΠF, :ΠC, :rS, :rL, :rB], :G])
    flow[:Tot, :C] = sum(flow[[:ΔD, :ΔS, :ΔL, :ΔB, :ΔR, :ΔK], :C]) - sum(flow[[:C, :I, :W, :T, :M, :ΠF, :ΠC, :rS, :rL, :rB], :C])
    flow[:Tot, :Tot] = sum(flow[[:ΔD, :ΔS, :ΔL, :ΔB, :ΔR, :ΔK], :Tot]) - sum(flow[[:C, :I, :W, :T, :M, :ΠF, :ΠC, :rS, :rL, :rB], :Tot])
    return flow
end

function display_matrices(state::State, state1::State, m::Model)
    display(compute_balance_sheet(state))
    display(compute_flow_matrix(state, state1, m))
    flush(stdout)
end