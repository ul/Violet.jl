type CircularBuffer{T}
  buffer::Array{T}
  size::Int
  write::Int
  read::Int
end

CircularBuffer(T, n) = CircularBuffer(zeros(T, n), n, 1, 1)

@inbounds function Base.getindex(cb::CircularBuffer, i)
  cb.buffer[mod1(i, cb.size)]
end

@inbounds function Base.setindex!(cb::CircularBuffer, x, i)
  cb.buffer[mod1(i, cb.size)] = x
end

@inbounds function Base.push!(cb::CircularBuffer, x)
  cb[cb.write] = x
  cb.write += 1
  cb
end

function Base.append!(cb::CircularBuffer, xs)
  for i=1:length(xs)
    @inbounds cb[cb.write] = xs[i]
    cb.write += 1
  end
  cb
end

function Base.copy!(xs, cb::CircularBuffer, N)
  for i=1:N
    xs[i] = cb[cb.read]
    cb.read += 1
  end
  xs
end

function Base.unsafe_copy!(xs, cb::CircularBuffer, N)
  for i=1:N
    @inbounds xs[i] = cb[cb.read]
    cb.read += 1
  end
  xs
end
