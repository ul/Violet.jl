module Violet

using Reactive

include("types.jl")
include("utils.jl")

include("config.jl")

#include("ui.jl")

include("event.jl")
include("node.jl")
#include("audio.jl")
include("engine.jl")
include("oscillators.jl")
include("envelopes.jl")
include("swapper.jl")

include("exports.jl")

end # module
