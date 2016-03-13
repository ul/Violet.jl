function constantly(x)
  s = Sample(x)
  (τ::Time, ι::AudioChannel) -> s
end

signal(x::Signal{Float64}) =
  (τ::Time, ι::AudioChannel) -> x |> value |> Sample

signal(x::Signal{Array{Float64}}) =
  (τ::Time, ι::AudioChannel) -> @inbounds x[ι] |> value |> Sample

function sine(fν::Function, fθ::Function, τ::Time, ι::AudioChannel)
  ν = fν(τ, ι)
  isnull(ν) && return Sample()
  θ = fθ(τ, ι)
  isnull(θ) && return Sample()
  2.0muladd(get(ν), τ, get(θ)) |> sinpi |> Sample
end

precompile(sine, (Function, Function, Time, AudioChannel))

sine(fν::Function, fθ::Function) =
  (τ::Time, ι::AudioChannel) -> sine(fν, fθ, τ, ι)

sine(ν::Signal{Float64}, θ=Signal(Float64, 0.0)) = sine(signal(ν), signal(θ))
sine(ν::Signal{Float64}, θ::Function) = sine(signal(ν), θ)
sine(ν::Float64, θ=0.0) = sine(constantly(ν), constantly(θ))
sine(ν::Function, θ=0.0) = sine(ν, constantly(θ))

function saw(fν::Function, τ::Time, ι::AudioChannel)
  ν = fν(τ, ι)
  isnull(ν) && return Sample()
  x = get(ν)*τ
  2(x - floor(x)) - 1 |> Sample
end

precompile(saw, (Function, Time, AudioChannel))

saw(fν::Function) = (τ::Time, ι::AudioChannel) -> saw(fν, τ, ι)
saw(ν) = saw(constantly(ν))

function tri(fν::Function, τ::Time, ι::AudioChannel)
  ν = fν(τ, ι)
  isnull(ν) && return Sample()
  x = 2get(ν)*τ
  4abs(x - floor(x + 0.5)) - 1 |> Sample
end

precompile(tri, (Function, Time, AudioChannel))

tri(fν::Function) = (τ::Time, ι::AudioChannel) -> tri(fν, τ, ι)
tri(ν) = tri(constantly(ν))
