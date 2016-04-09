# Synchronous flow-based programming engine.
# REVIEW ranking, it should be robust and compacting to enable future optimizations
# TODO run in parallel same-rank nodes
# TODO use GPU for number crunching nodes
# TODO tests

typealias Port Int

type Node
  f::Function # (τ::Time, y::Vector, x...)
  Tx::Vector{Type}
  Ty::Vector{Type}
  x::Vector
  y::Vector
  x₀::Vector
  function Node(f, Tx, Ty)
    x₀ = map(zero, Tx)
    y = map(zero, Ty)
    new(f, Tx, Ty, copy(x₀), y, x₀)
  end
end

function Base.call(node::Node, τ::Time)
  node.f(τ, node.x, node.y)
  copy!(node.x, node.x₀)
end

typealias ConnectedPorts Set{Port}
typealias PortConnections Dict{Port, ConnectedPorts}
typealias NodeConnections Dict{Node, PortConnections}
typealias Connections Dict{Node, NodeConnections}

typealias Ranks IntPriorityQueue{Node}

type Graph
  sinks::Connections
  sources::Connections
  ranks::Ranks
end

Graph() = Graph(Connections(), Connections(), Ranks())

function update_ranks(graph::Graph, node::Node)
  rank = 0
  haskey(graph.sources, node) &&
    for source in keys(graph.sources[node])
      rank = max(rank, graph.ranks[source])
    end
  rank += 1
  graph.ranks[node] === rank && return
  graph.ranks[node] = rank
  !haskey(graph.sinks, node) && return
  for sink in keys(graph.sinks[node])
    update_ranks(graph, sink)
  end
end

function Base.push!(c::Connections, src::Node, dest::Node, from::Port, to::Port)
  !haskey(c, src) && (c[src] = NodeConnections())
  !haskey(c[src], dest) && (c[src][dest] = PortConnections())
  !haskey(c[src][dest], from) && (c[src][dest][from] = ConnectedPorts())
  push!(c[src][dest][from], to)
end

function Base.delete!(c::Connections, src::Node, dest::Node, from::Port, to::Port)
  delete!(c[src][dest][from], to)
  !isempty(c[src][dest][from]) && return c
  delete!(c[src][dest], from)
  !isempty(c[src][dest]) && return c
  delete!(c[src], dest)
  !isempty(c[src]) && return c
  delete!(c, src)
  c
end

function Base.push!(graph::Graph, source::Node, output::Port, sink::Node, input::Port)
  @assert source.Ty[output] <: sink.Tx[input]
  push!(graph.sinks, source, sink, output, input)
  push!(graph.sources, sink, source, input, output)
  !haskey(graph.ranks, source) && (graph.ranks[source] = 1)
  !haskey(graph.ranks, sink) && (graph.ranks[sink] = 2)
  update_ranks(graph, sink)
  graph
end

function clean_ranks(graph::Graph)
  for node in setdiff(keys(graph.ranks), union(keys(graph.sinks), keys(graph.sources)))
    delete!(graph.ranks, node)
  end
end

function Base.delete!(graph::Graph, source::Node, output::Port, sink::Node, input::Port)
  delete!(graph.sinks, source, sink, output, input)
  delete!(graph.sources, sink, source, input, output)
  if !haskey(graph.sources, sink) || !haskey(graph.sinks, source)
    clean_ranks(graph)
  end
  haskey(graph.ranks, sink) && update_ranks(graph, sink)
  graph
end

function Base.run(graph::Graph, τ::Time)
  ks = graph.ranks.index
  for k in ks, source in graph.ranks.p[k]
    source(τ)
    !haskey(graph.sinks, source) && continue
    @inbounds for sink in keys(graph.sinks[source]),
        output in keys(graph.sinks[source][sink]),
        input in graph.sinks[source][sink][output]
      sink.x[input] += source.y[output]
    end
  end
end
