using DrWatson
using Logging
@quickactivate "FE"

include(srcdir("model.jl"))
include(srcdir("parameters.jl"))

Base.with_logger(Logging.ConsoleLogger(stderr, Logging.Debug)) do
    model = FE.create_model(params)
    FE.run_model(model, params[:T])
end