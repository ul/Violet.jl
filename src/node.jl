type Node
  audio::Set{Function}
  precontrol::Set{Function}
  postcontrol::Set{Function}
  status::Symbol
  config::Config
  buffer::Array{Float64}
end

Node(config=CONFIG) =
  Node(Set{Function}(), Set{Function}(), Set{Function}(), :ok, config,
  zeros(Float64, (config.buffer_size, config.output_channels)))

# currently will continue rendering even if afs are empty. need to have
# option to return nil when afs are empty, for the scenario of disk render.
# should add a *disk-render* flag to config and a default option here
# so that user can override behavior.
function Base.call(node::Node, frame₀::Int, Δframes=node.config.buffer_size)
  fill!(node.buffer, 0.0)
  Δτ = 1/node.config.sample_rate

  for ι=1:node.config.output_channels, frame=1:Δframes
    τ = (frame₀ + frame)*Δτ

    if ι == 1
      for f in node.precontrol
        if !(f(τ))
          delete!(node.precontrol, f)
        end
      end
    end

    for f in node.audio
      x = f(τ, ι)
      if isnull(x)
        delete!(node.functions, f)
      else
        @inbounds node.buffer[frame, ι] += get(x)
      end
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
  node.audio = Set{Function}()
  node.precontrol = Set{Function}()
  node.postcontrol = Set{Function}()
end

Base.isempty(node::Node) = isempty(node.audio) && isempty(node.precontrol) && isempty(node.postcontrol)

"Create an instance of an audio function and adds to the node."
function fire_node_event(node::Node, event::Event)
  f = fire_event(event)
  # FIXME use nullable
  if f != nothing
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
