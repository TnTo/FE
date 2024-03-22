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
        :ρK => pvec[9],
        :ρF => pvec[10],
        :Θ => pvec[11],
        :k => pvec[12],
        :ρΠ => pvec[13],
        :ρQ => pvec[14],
        :λ => pvec[15],
        :ν2 => pvec[16],
        :τF => pvec[17],
        :τT => pvec[18],
        :ϵ0 => pvec[19],
        :ϵ1 => pvec[20],
        :ζ => pvec[21],
        :b0 => pvec[22],
        :b1 => pvec[23],
        :b2 => pvec[24]
    )
    data, f = DrWatson.produce_or_load(pdict, datadir("sims"); filename=hash) do pdict
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
            # "models" => ms,
            # "scores" => scores,
            "score" => score
        )
    end
    return -data["score"] / (4 * 21 * 300)
end