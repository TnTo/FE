module DAS

using Distributions
using Random

Float = Float64

include("parameters.jl")
include("structs.jl")
include("utils.jl")
include("getters.jl")
include("create.jl")
include("matrices.jl")
include("steps.jl")
include("plots.jl")

end