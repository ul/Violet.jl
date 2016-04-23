"ADSR envelope
FIXME: enable arbitrary interpolation"
function adsr(start::AudioControl, duration::AudioControl,
              attack::Time, decay::Time, sustain::Amplitude, release::Time)
  @assert 0.0 <= sustain <= 1.0
  τ₀ = convert(AudioSignal, start)
  dur = convert(AudioSignal, duration)
  complement_sustain = 1.0 - sustain
  function f(τ::Time, ι::AudioChannel)
    Δτ = τ - τ₀(τ, ι)
    Δτ < 0.0 && return 0.0

    attack > 0.0 && Δτ <= attack && return Δτ/attack
    Δτ -= attack

    decay > 0.0 && Δτ <= decay && return 1.0 - complement_sustain*Δτ/decay
    Δτ -= decay

    s = dur(τ, ι)
    Δτ <= s && return sustain
    Δτ -= s

    release > 0.0 && Δτ <= release && return (1.0 - Δτ/release)sustain

    0.0
  end
  precompile(f, (Time, AudioChannel))
  f
end
