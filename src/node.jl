type Node
  audio::Set{AudioSignal}
  precontrol::Set{Function}
  postcontrol::Set{Function}
  status::Symbol
  config::Config
  buffer::Array{Float64}
end

Node(config=CONFIG) =
  Node(Set{AudioSignal}(), Set{Function}(), Set{Function}(), :ok, config,
  zeros(Float64, (config.buffersize, config.outchannels)))

# currently will continue rendering even if afs are empty. need to have
# option to return nil when afs are empty, for the scenario of disk render.
# should add a *disk-render* flag to config and a default option here
# so that user can override behavior.
function Base.call(node::Node, frame₀::Int, Δframes=node.config.buffersize)
  fill!(node.buffer, 0.0)
  Δτ = 1/node.config.samplerate

  for ι=1:node.config.outchannels, frame=1:Δframes
    τ = (frame₀ + frame)*Δτ

    if ι == 1
      for f in node.precontrol
        if !(f(τ))
          delete!(node.precontrol, f)
        end
      end
    end

    for f in node.audio
      @inbounds node.buffer[frame, ι] += f(τ, ι)
    end

    if ι == 1
      for f in node.postcontrol
        if !(f(τ))
          delete!(node.postcontrol, f)
        end
      end
    end
  end
end

function Base.empty!(node::Node)
  node.audio = Set{AudioSignal}()
  node.precontrol = Set{Function}()
  node.postcontrol = Set{Function}()
end

Base.isempty(node::Node) = isempty(node.audio) && isempty(node.precontrol) && isempty(node.postcontrol)

"Create an instance of an audio function and adds to the node."
function fire_node_event(node::Node, event::Event)
  f = fire_event(event)
  # FIXME use nullable
  if isa(f, Function)
    push!(node.audio, f)
  end
end

function wrap_node_event(node::Node, event::Event)
  wrap_event(fire_node_event, [node], event)
end

"Takes a node and series of events, wrapping the events as node-events.
If single arg given, assumes it is a list of events."
function node_events(node::Node, args)
  map((event) -> wrap_node_event(node, event), args)
end
