export phasor, sine

function sine(ν, θ=0.0)
  ν *= 2.0
  θ *= 2.0
  (τ::Time, ι::AudioChannel) -> @fastmath Sample(sinpi(muladd(ν, τ, θ)))
end
