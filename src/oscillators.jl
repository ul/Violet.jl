export sine, constantly, signal

function constantly(x)
  s = Sample(x)
  (τ::Time, ι::AudioChannel) -> s
end

signal(x::Signal{Float64}) =
  (τ::Time, ι::AudioChannel) -> x |> value |> Sample

signal(x::Signal{Array{Float64}}) =
  (τ::Time, ι::AudioChannel) -> @inbounds x[ι] |> value |> Sample

function sine(fν::Function, fθ::Function)
  function sine(τ::Time, ι::AudioChannel)
    ν = fν(τ, ι)
    isnull(ν) && return Sample()
    θ = fθ(τ, ι)
    isnull(θ) && return Sample()
    2.0muladd(get(ν), τ, get(θ)) |> sinpi |> Sample
  end
  precompile(sine, (Time, AudioChannel))
  sine
end

function sine(ν::Signal{Float64}, θ=Signal(Float64, 0.0))
  sine(signal(ν), signal(θ))
end

function sine(ν::Signal{Float64}, θ::Function)
  sine(signal(ν), θ)
end

sine(ν, θ=0.0) = sine(constantly(ν), constantly(θ))
sine(ν::Function, θ=0.0) = sine(ν, constantly(θ))
