# ADSR envelope
# FIXME: enable arbitrary interpolation
@audiosignal function adsr(
  τ₀::AudioSignal, duration::AudioSignal,
  attack::AudioSignal, decay::AudioSignal, sustain::AudioSignal, release::AudioSignal,
  τ::Time, ι::AudioChannel)

  Δτ = τ - τ₀(τ, ι)
  Δτ < 0.0 && return 0.0

  a = attack(τ, ι)
  a > 0.0 && Δτ <= a && return Δτ/a
  Δτ -= a

  amp = sustain(τ, ι)

  d = decay(τ, ι)
  d > 0.0 && Δτ <= d && return 1.0 - (1.0 - amp)Δτ/d
  Δτ -= d

  s = duration(τ, ι)
  Δτ <= s && return amp
  Δτ -= s

  r = release(τ, ι)
  r > 0.0 && Δτ <= r && return (1.0 - Δτ/r)amp

  0.0
end
