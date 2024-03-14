module DAS

using Distributions
using Random
using StatsBase
using DrWatson

Float = Float64

include("parameters.jl")
include("structs.jl")
include("utils.jl")
include("getters.jl")
include("create.jl")
include("matrices.jl")
include("steps.jl")
include("plots.jl")

include("evaluate.jl")
include("calibrate.jl")

end