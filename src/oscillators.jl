export phasor, sine

sine(ν, θ=0.0) = (τ::Time, ι::AudioChannel) -> @fastmath Sample(sinpi(2.0*(θ + ν*τ)))
