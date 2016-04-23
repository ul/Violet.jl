type Mixer
  sources::Set
end

Mixer() = Mixer(Set())

Base.push!(m::Mixer, f::AudioSignal) = push!(m.sources, f)
Base.delete!(m::Mixer, f::AudioSignal) = delete!(m.sources, f)
Base.empty!(m::Mixer) = empty!(m.sources)

function Base.call(m::Mixer, τ::Time, ι::AudioChannel)
  a = 0.0
  for f in m.sources
    a += f(τ, ι)
  end
  a
end
