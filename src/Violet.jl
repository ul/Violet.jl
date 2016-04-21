module Violet

using Reactive

include("types.jl")
include("utils.jl")

include("config.jl")

#include("ui.jl")

include("event.jl")
#include("audio.jl")
include("oscillators.jl")
include("engine.jl")
include("envelopes.jl")

include("exports.jl")

end # module
