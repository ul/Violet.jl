type CircularBuffer{T}
  buffer::Array{T}
  size::Int
  read_cursor::Int
  write_cursor::Int
  pushed::Int
  pulled::Int
end

CircularBuffer(T, n) = CircularBuffer(zeros(T, n), n, 1, 1, 0, 0)

@inbounds function Base.getindex(cb::CircularBuffer, i)
  cb.buffer[mod1(i, cb.size)]
end

@inbounds function Base.setindex!(cb::CircularBuffer, x, i)
  cb.buffer[mod1(i, cb.size)] = x
end

@inbounds function Base.push!(cb::CircularBuffer, x)
  cb[cb.write_cursor] = x
  cb.write_cursor = mod1(cb.write_cursor+1, cb.size)
  cb.pushed += 1
  cb
end

function Base.append!(cb::CircularBuffer, xs)
  for i=1:length(xs)
    @inbounds cb[cb.write_cursor] = xs[i]
    cb.write_cursor = mod1(cb.write_cursor+1, cb.size)
  end
  cb.pushed += length(xs)
  cb
end

function Base.copy!(xs, cb::CircularBuffer, N)
  for i=1:N
    xs[i] = cb[cb.read_cursor]
    cb.read_cursor = mod1(cb.read_cursor+1, cb.size)
  end
  cb.pulled += N
  xs
end

function Base.unsafe_copy!(xs, cb::CircularBuffer, N)
  for i=1:N
    @inbounds xs[i] = cb[cb.read_cursor]
    cb.read_cursor = mod1(cb.read_cursor+1, cb.size)
  end
  cb.pulled += N
  xs
end
