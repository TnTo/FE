using Dates
function run_or_load(pvec)
    pdict = Dict(
        :σ0 => pvec[1],
        :δ0 => pvec[2],
        :β0 => pvec[3],
        :e0 => pvec[4],
        :e1 => pvec[5],
        :ρH => pvec[6],
        :ay => pvec[7],
        :av => pvec[8],
        :ρC => pvec[9],
        :ρK => pvec[10],
        :ρF => pvec[11],
        :Θ => pvec[12],
        :k => pvec[13],
        :ρΠ => pvec[14],
        :ρQ => pvec[15],
        :λ => pvec[16],
        :ν0 => pvec[17],
        :ν1 => pvec[18],
        :ν2 => pvec[19],
        :ν3 => pvec[20],
        :ν4 => pvec[21],
        :τF => pvec[22],
        :τT => pvec[23],
        :ϵ0 => pvec[24],
        :ϵ1 => pvec[25],
        :ζ => pvec[26],
        :b0 => pvec[27],
        :b1 => pvec[28],
        :b2 => pvec[29]
    )
    data, f = DrWatson.produce_or_load(pdict, "sims"; filename=hash) do pdict
        seeds = [8, 86, 868, 8686]
        ps = map(s -> Parameters(; seed=s, pdict...), seeds)
        ms = Vector{Model}(undef, 4)
        @debug Dates.format(now(), "HH:MM:SS")
        Threads.@threads for i = 1:4
            #for i = 1:4
            m = create_model(ps[i])
            try
                for t = 1:m.p.T
                    @debug t
                    step!(m, print=false)
                end
            catch e
            finally
                ms[i] = m
            end
        end
        scores = Vector{Matrix}(undef, 4)
        @debug Dates.format(now(), "HH:MM:SS")
        Threads.@threads for i = 1:4
            #for i = 1:4
            scores[i] = evaluate_model(ms[i])
        end
        score = sum(sum(scores))
        @debug Dates.format(now(), "HH:MM:SS")
        return Dict(
            "config" => pdict,
            "models" => ms,
            "scores" => scores,
            "score" => score
        )
    end
    return -data["score"] / (4 * 21 * 300)
end