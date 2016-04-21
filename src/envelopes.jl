function adsr(attack::Time, decay::Time, sustain::Time, release::Time, sustain_amp::Amplitude)
  assert(0.0 <= sustain_amp <= 1.0)
  τ₀ = -1.0
  complement_sustain = 1.0 - sustain_amp
  function f(τ::Time, ι::AudioChannel)
    τ₀ < 0.0 && (τ₀ = τ)
    Δτ = τ - τ₀

    attack > 0.0 && Δτ <= attack && return Δτ/attack
    Δτ -= attack

    decay > 0.0 && Δτ <= decay && return 1.0 - complement_sustain*Δτ/decay
    Δτ -= decay

    Δτ <= sustain && return sustain_amp
    Δτ -= sustain

    release > 0.0 && Δτ <= release && return sustain_amp*(1.0 - Δτ/release)

    0.0
  end
  precompile(f, (Time, AudioChannel))
  f
end
