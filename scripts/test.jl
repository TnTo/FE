using DrWatson
@quickactivate "DAS"

include(srcdir("DAS.jl"))

p = DAS.Parameters()

m = DAS.create_model(p)
try
    for _ = 1:m.p.T
        DAS.step!(m, print=false)
    end
catch e
    @warn e
end

scores = DAS.evaluate_model(m)

score = sum(scores) / (300 * 21)