# Synchronous flow-based programming engine.
# REVIEW ranking, it should be robust and compacting to enable future optimizations
# TODO run in parallel same-rank nodes
# TODO use GPU for number crunching nodes
# TODO tests

abstract Node
typealias NodeType{T<:Node} Type{T}

typealias Port Symbol
typealias ConnectedPorts Set{Port}
typealias PortConnections Dict{Port, ConnectedPorts}
typealias NodeConnections Dict{Node, PortConnections}
typealias Connections Dict{Node, NodeConnections}
typealias Ranks IntPriorityQueue{Any} # NodeType
typealias Cache Vector{Tuple{Node, Node, Port, Port}}

type Graph
  sinks::Connections
  sources::Connections
  ranks::Ranks
  cache::Cache
  eff::Vector{Node}
end

Graph() = Graph(Connections(), Connections(), Ranks(), Cache(), Node[])

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

function rebuild_cache(graph::Graph)
  empty!(graph.cache)
  empty!(graph.eff)
  for i in graph.ranks.index, source in graph.ranks.p[i]
    if !haskey(graph.sinks, source)
      push!(graph.eff, source)
      continue
    end
    for sink in keys(graph.sinks[source]),
        output in keys(graph.sinks[source][sink]),
        input in graph.sinks[source][sink][output]
      push!(graph.cache, (source, sink, output, input))
    end
  end
end

# FIXME batch ranking & cache building

function Base.push!(graph::Graph, source::Node, output::Port, sink::Node, input=:in)
  @assert fieldtype(typeof(source), output) <: fieldtype(typeof(sink), input)
  push!(graph.sinks, source, sink, output, input)
  push!(graph.sources, sink, source, input, output)
  !haskey(graph.ranks, source) && (graph.ranks[source] = 1)
  !haskey(graph.ranks, sink) && (graph.ranks[sink] = 2)
  update_ranks(graph, sink)
  rebuild_cache(graph)
  graph
end

Base.push!(graph::Graph, source::Node, sink::Node, input=:in) =
  push!(graph, source, :out, sink, input)

function clean_ranks(graph::Graph)
  for node in setdiff(keys(graph.ranks), union(keys(graph.sinks), keys(graph.sources)))
    delete!(graph.ranks, node)
  end
end

function Base.delete!(graph::Graph, source::Node, output::Port, sink::Node, input=:in)
  delete!(graph.sinks, source, sink, output, input)
  delete!(graph.sources, sink, source, input, output)
  if !haskey(graph.sources, sink) || !haskey(graph.sinks, source)
    clean_ranks(graph)
  end
  haskey(graph.ranks, sink) && update_ranks(graph, sink)
  rebuild_cache(graph)
  graph
end

Base.delete!(graph::Graph, source::Node, sink::Node, input=:in) =
  delete!(graph, source, :out, sink, input)

@inline function setport!(node::Node, port::Port, x)
  setfield!(node, port, x)
end

@inline function getport(node::Node, port::Port)
  getfield(node, port)
end

type Dummy <: Node
end

DUMMY = Dummy()

function Base.run(graph::Graph, τ::Time)
  src = DUMMY
  for (source, sink, output, input) in graph.cache
    if source !== src
      run(source, τ)
      src = source
    end
    setport!(sink, input, getport(source, output))
  end
  for eff in graph.eff
    run(eff, τ)
  end
  nothing
end
