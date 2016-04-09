type IntPriorityQueue{K} <: Associative{K,Int}
  p::Dict{Int, Set{K}}
  xs::Dict{K, Int}
  index::IntSet
  function IntPriorityQueue()
    new(Dict{Int, Set{K}}(), Dict{K, Int}(), IntSet())
  end
end

function Base.setindex!{T}(pq::IntPriorityQueue{T}, value::Int, key::T)
  if haskey(pq.xs, key)
    oldvalue = pq.xs[key]
    oldvalue == value && return value
    delete!(pq.p[oldvalue], key)
    if isempty(pq.p[oldvalue])
      delete!(pq.p, oldvalue)
      delete!(pq.index, oldvalue)
    end
  end
  pq.xs[key] = value
  if haskey(pq.p, value)
    push!(pq.p[value], key)
  else
    pq.p[value] = Set([key])
    push!(pq.index, value)
  end
  value
end

@inline function Base.getindex{T}(pq::IntPriorityQueue{T}, key::T)
  pq.xs[key]
end

@inline function Base.haskey{T}(pq::IntPriorityQueue{T}, key::T)
  haskey(pq.xs, key)
end

@inline function Base.keys(pq::IntPriorityQueue)
  keys(pq.xs)
end

function Base.delete!{T}(pq::IntPriorityQueue{T}, key::T)
  v = pq.xs[key]
  delete!(pq.xs, key)
  delete!(pq.p[v], key)
  if isempty(pq.p[v])
    delete!(pq.p, v)
    delete!(pq.index, v)
  end
  pq
end
