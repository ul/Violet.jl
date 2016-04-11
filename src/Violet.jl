module Violet

using Reactive

include("types.jl")
include("utils.jl")
include("ipq.jl")

include("config.jl")

include("PortAudio.jl")
using Violet.PortAudio

Violet.PortAudio.initialize()
atexit(Violet.PortAudio.terminate)

#include("ui.jl")

include("event.jl")
include("flow.jl")
include("audio.jl")
include("nodes.jl")
include("engine.jl")
include("envelopes.jl")
include("swapper.jl")

include("exports.jl")

end # module
