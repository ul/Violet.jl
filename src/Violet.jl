module Violet

using Reactive

include("types.jl")
include("utils.jl")

include("config.jl")

#include("ui.jl")

include("event.jl")
include("metro.jl")
#include("audio.jl")
include("signal.jl")
include("oscillators.jl")
include("table.jl")
include("engine.jl")
include("envelopes.jl")
include("instrument.jl")

include("exports.jl")

end # module
