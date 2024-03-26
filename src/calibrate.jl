using Dates
function run_or_load(pdict)
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
    return data["score"] / (4 * 21 * 300)
end