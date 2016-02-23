module Violet

include("PortAudio.jl")
using Violet.PortAudio

include("utils.jl")
include("config.jl")
include("control.jl")
include("event.jl")
include("node.jl")
include("engine.jl")
include("oscillators.jl")
include("envelopes.jl")

end # module
