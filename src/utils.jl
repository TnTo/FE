mapsum(f, itr) = mapreduce(f, +, itr, init=0)

yearly2monthly(r::Float)::Float = (1 + r)^(1 / 12) - 1
y2m = yearly2monthly

function quarterly(t::Int)::Bool
    return (t % 4 == 0)
end

function next_id!(m::Model)::Int
    id = m.id
    m.id += 1
    return id
end

###


