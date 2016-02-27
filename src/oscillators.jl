using Reactive

export sine

sine(ν::Signal{Float64}, θ=Signal(Float64, 0)) =
  (τ::Time, ι::AudioChannel) -> @fastmath 2.0muladd(value(ν), τ, value(θ)) |> sinpi |> Sample

sine(ν, θ=0) = sine(Signal(Float64, ν), Signal(Float64, θ))
