using DrWatson
using Plots
@quickactivate "FE"

include(srcdir("model.jl"))

model = FE.create_model()

histogram(map(h -> h.skill, model.Households))