using Plots

function map_plot(m::Model, f, label::String)
    plot(map(f, m.s), label=label, legend=:outerright, gridalpha=0.3, show=true)
end

function map_plot(m::Model, fs::Vector{Function}, labels::Matrix{String})
    plot(map(f -> map(f, m.s), fs), label=labels, legend=:outerright, gridalpha=0.3, show=true)
end