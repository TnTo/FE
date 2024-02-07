mapsum(f, itr) = mapreduce(f, +, itr, init=0)
mapmean(f, itr) = mean(map(f, itr))

yearly2monthly(r::Float)::Float = (1 + r)^(1 / 12) - 1
y2m = yearly2monthly

function quarterly(t::Int)::Bool
    return (t % 4 == 0)
end