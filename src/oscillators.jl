export sine

function sine(ν::Signal{Float64}, θ=Signal(Float64, 0))
  function sine(τ::Time, ι::AudioChannel)
    @fastmath 2.0muladd(value(ν), τ, value(θ)) |> sinpi |> Sample
  end
  precompile(sine, (Time, AudioChannel))
  sine
end

sine(ν, θ=0.0) = sine(Signal(Float64, ν), Signal(Float64, θ))
