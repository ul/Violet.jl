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
    pq.p[value] = Set{T}([key])
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

Base.start(pq::IntPriorityQueue) = (start(pq.index), 0, 0)

Base.done(pq::IntPriorityQueue, s) =
  done(pq.index, s[1]) && (s[2] === 0 || done(pq.p[s[2]], s[3]))

function Base.next(pq::IntPriorityQueue, s)
  index, p, set = s
  if set === 0 || done(pq.p[p], set)
    p, index = next(pq.index, index)
    set = start(pq.p[p])
  end
  x, set = next(pq.p[p], set)
  x, (index, p, set)
end

@inline function Base.length(pq::IntPriorityQueue)
  length(pq.xs)
end
