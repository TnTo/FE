using DrWatson
using Logging
@quickactivate "FE"

include(srcdir("DAS.jl"))
#include(srcdir("parameters.jl"))

Base.with_logger(Logging.ConsoleLogger(stderr, Logging.Debug)) do
    model = DAS.Model(DAS.Parameters(8686))
    #FE.run_model(model, params[:T])
end