using Plots

function map_plot(m::Model, f, label::String)
    plot(map(f, m.states), label=label)
end

function map_plot(m::Model, fs::Vector{Function}, labels::Matrix{String})
    plot(map(f -> map(f, m.states), fs), label=labels)
end