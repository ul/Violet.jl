export sine

sine(ν, θ=0.0) =
  (τ::Time, ι::AudioChannel) -> @fastmath 2.0muladd(ν, τ, θ) |> sinpi |> Sample
