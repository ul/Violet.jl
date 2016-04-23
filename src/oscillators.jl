### Waves ###

@audiosignal function sine(fν::AudioSignal, fθ::AudioSignal, τ::Time, ι::AudioChannel)
  ν = fν(τ, ι)::Sample
  θ = fθ(τ, ι)::Sample
  sinpi(2.0muladd(ν, τ, θ))
end

sine(ν) = sine(ν, 0.0)

@audiosignal function saw(fν::AudioSignal, fθ::AudioSignal, τ::Time, ι::AudioChannel)
  ν = fν(τ, ι)::Sample
  θ = fθ(τ, ι)::Sample
  x = muladd(ν, τ, θ)
  2.0(x - floor(x)) - 1.0
end

saw(ν) = saw(ν, 0.0)

@audiosignal function tri(fν::AudioSignal, fθ::AudioSignal, τ::Time, ι::AudioChannel)
  ν = fν(τ, ι)::Sample
  θ = fθ(τ, ι)::Sample
  x = 2.0muladd(ν, τ, θ)
  4.0abs(x - floor(x + 0.5)) - 1.0
end

tri(ν) = tri(ν, 0.0)

@audiosignal function square(fν::AudioSignal, fθ::AudioSignal, τ::Time, ι::AudioChannel)
  ν = fν(τ, ι)::Sample
  θ = fθ(τ, ι)::Sample
  x = muladd(ν, τ, θ)
  2.0floor(x) - floor(2.0x) + 1.0
end

square(ν) = square(ν, 0.0)


function overtones(f::AudioSignal, amps::Vector{AudioControl}, ν::AudioControl, θ::AudioControl)
  fν = convert(AudioSignal, ν)
  fθ = convert(AudioSignal, θ)
  n = round(Int, length(amps)/2)
  mapreduce(+, enumerate(amps)) do ix
    k = ix[1] >= n ? ix[1] - n + 1.0 : 1.0 / (n - ix[1] + 1.0)
    ix[2]*f(k*fν, fθ)
  end
end
