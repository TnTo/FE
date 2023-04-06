using Base
using StaticArrays

# Globals
const YEAR = 12
const BONDT = 5 * YEAR

include("agents.jl")
include("assets.jl")
include("functions.jl")
include("model.jl")
include("steps.jl")
include("stock.jl")