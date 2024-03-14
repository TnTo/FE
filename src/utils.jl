mapmean(f, itr) = mean(map(f, itr))

yearly2monthly(r::Float)::Float = (1 + r)^(1 / 12) - 1
y2m = yearly2monthly

function quarterly(t::Int)::Bool
    return (t % 4 == 0)
end

function gini(x)
    n = length(x)
    sx = sort(x)
    2 * (sum(collect(1:n) .* sx)) / (n * sum(sx)) - 1
end