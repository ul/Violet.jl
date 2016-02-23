export Node, run_audio, run_precontrol, run_postcontrol

"Nodes aggregate audio from other audio-rate functions. Nodes can contain other nodes. Each Node is wrapped in pink.util.shared so that the output of Node may be used by multiple other audio-functions within the same time period.
In general, users will first call create-node to create a node map. node-processor will be used as the audio-rate function to add to an Engine, Node, or other audio-function."
type Node
  functions::Set{Function}
  pending_adds::Set{Function}
  pending_removes::Set{Function}
  status::Symbol
  config::Config
  buffer::Array{Float64}
end

Node(config=CONFIG) =
  Node(Set{Function}(), Set{Function}(), Set{Function}(), :ok, config,
  zeros(Float64, (config.buffer_size, config.output_channels)))

function update_node_functions!(node::Node)
  union!(node.functions, node.pending_adds)
  setdiff!(node.functions, node.pending_removes)
end

function run_node_functions!(node::Node, frame₀::Int)
  fill!(node.buffer, 0.0)
  # REVIEW is automagic amplitude normalize worth to do?
  ampnorm = 1/length(node.functions)
  Δτ = 1/node.config.sample_rate
  for f in node.functions, ι=1:node.config.output_channels, frame=1:node.config.buffer_size
    τ = (frame₀ + frame)*Δτ
    x = f(τ, ι)
    if isnull(x)
      delete!(node.functions, f)
    else
      @inbounds node.buffer[frame, ι] += ampnorm*get(x)
    end
  end
end

function process_precontrol!(node::Node, frame₀::Int)
  τ = frame₀/node.config.sample_rate
  for f in node.functions
    if isnull(f(τ))
      delete!(node.functions, f)
    end
  end
end

function process_postcontrol!(node::Node, frame₀::Int)
  τ = (frame₀ + node.config.buffer_size)/node.config.sample_rate
  for f in node.functions
    if isnull(f(τ))
      delete!(node.functions, f)
    end
  end
end

# currently will continue rendering even if afs are empty. need to have
# option to return nil when afs are empty, for the scenario of disk render.
# should add a *disk-render* flag to config and a default option here
# so that user can override behavior.
"An audio-rate function that renders child funcs and returns the signals in an out-buffer."
function run_audio(node::Node, frame::Int)
  if node.status == :empty
    node.functions = Set{Function}()
    node.pending_adds = Set{Function}()
    node.pending_removes = Set{Function}()
    node.status = :ok
  else
    update_node_functions!(node)
    run_node_functions!(node, frame)
  end
  node.buffer
end

"Creates a control node processing functions that runs controls functions,
handling pending adds and removes, as well as filters out done functions."
function run_precontrol(node::Node, frame::Int)
  if node.status == :empty
    node.functions = Set{Function}()
    node.pending_adds = Set{Function}()
    node.pending_removes = Set{Function}()
    node.status = :ok
  else
    update_node_functions!(node)
    process_precontrol!(node, frame)
  end
  nothing
end

function run_postcontrol(node::Node, frame::Int)
  if node.status == :empty
    node.functions = Set{Function}()
    node.pending_adds = Set{Function}()
    node.pending_removes = Set{Function}()
    node.status = :ok
  else
    update_node_functions!(node)
    process_postcontrol!(node, frame)
  end
  nothing
end

"Adds an audio function to a node. Should not be called directly but rather be used via a message added to the node."
Base.push!(node::Node, f) = push!(node.pending_adds, f)
Base.delete!(node::Node, f) = push!(node.pending_removes, f)
Base.empty!() = (node.status = :empty)
Base.isempty(node::Node) = isempty(node.functions) && isempty(node.pending_adds)

"Create an instance of an audio function and adds to the node."
function fire_node_event(node::Node, event::Event)
  f = fire_event(event)
  # FIXME use nullable
  if f != nothing
    push!(node, f)
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
