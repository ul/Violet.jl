#=type Swapper
  engine::Engine
  f::AudioSignal
end

function Base.call(s::Swapper, f::AudioSignal)
  delete!(s.engine.root.audio, s.f)
  s.f = f
  push!(s.engine.root.audio, s.f)
end

function Base.run(s::Swapper)
  push!(s.engine.root.audio, s.f)
end

function Base.kill(s::Swapper)
  delete!(s.engine.root.audio, s.f)
end=#
