### Utils ###

macro sample(ex)
  ex.head != :(=) &&
    error("@sample works only with `x = f(τ, ι)` form, got ", ex)
  x = gensym()
  wrapper = quote
    $x = $(ex.args[2])
    isnull($x) && return Sample()
    $(ex.args[1]) = get($x)
  end
  esc(wrapper)
end

function fop(op, f₁::AudioControl, f₂::AudioControl)
  isa(f₁, Float64) && isa(f₂, Float64) && return op(f₁, f₂)
  g₁ = convert(Function, f₁)
  g₂ = convert(Function, f₂)
  function (τ::Time, ι::AudioChannel)
    @sample x₁ = g₁(τ, ι)
    @sample x₂ = g₂(τ, ι)
    op(x₁, x₂) |> Sample
  end
end

Base.(:+)(f₁::AudioControl, f₂::AudioControl) = fop(+, f₁, f₂)
Base.(:-)(f₁::AudioControl, f₂::AudioControl) = fop(-, f₁, f₂)
Base.(:*)(f₁::AudioControl, f₂::AudioControl) = fop(*, f₁, f₂)
Base.(:/)(f₁::AudioControl, f₂::AudioControl) = fop(/, f₁, f₂)

function constantly(x)
  s = Sample(x)
  (τ::Time, ι::AudioChannel) -> s
end

signal(x::Signal{Float64}) =
  (τ::Time, ι::AudioChannel) -> x |> value |> Sample

signal(x::Signal{Array{Float64}}) =
  (τ::Time, ι::AudioChannel) -> @inbounds x[ι] |> value |> Sample

Base.convert(::Type{Function}, x::Signal{Float64}) = signal(x)
Base.convert(::Type{Function}, x::Signal{Array{Float64}}) = signal(x)
Base.convert(::Type{Function}, x::Float64) = constantly(x)

macro audiosignal(ex)
  ex.head != :function &&
    error("@audiosignal works only with `function myfunc(...)` form, got ", ex)

  signature = ex.args[1].args
  name = signature[1]
  body = ex.args[2]

  τ = signature[end - 1] # τ::Time
  ι = signature[end]     # ι::AudioChannel

  # e.g. Function, Function, Time, AudioChannel
  _types = map((x) -> x.args[2], signature[2:end])
  types = Expr(:tuple, _types...)

  # e.g. fν::Function, fθ::Function
  bindargs = signature[2:end-2]

  # e.g. fν::AudioControl, fθ::AudioControl
  wrapperargs = map(bindargs) do arg
    Expr(arg.head, arg.args[1], :AudioControl)
  end

  conversions = map(bindargs) do arg
    # e.g. convert(Function, fν)
    x = arg.args[1]
    :($x = convert(Function, $x))
  end

  wrapper = quote
    $ex

    function $name($(wrapperargs...))
      $(conversions...)
      ($τ, $ι) -> $body
    end

    precompile($name, $types)
  end

  esc(wrapper)
end

### Waves ###

@audiosignal function sine(fν::Function, fθ::Function, τ::Time, ι::AudioChannel)
  @sample ν = fν(τ, ι)
  @sample θ = fθ(τ, ι)
  2.0muladd(ν, τ, θ) |> sinpi |> Sample
end

sine(ν) = sine(ν, 0.0)

@audiosignal function saw(fν::Function, fθ::Function, τ::Time, ι::AudioChannel)
  @sample ν = fν(τ, ι)
  @sample θ = fθ(τ, ι)
  x = muladd(ν, τ, θ)
  2(x - floor(x)) - 1 |> Sample
end

saw(ν) = saw(ν, 0.0)

@audiosignal function tri(fν::Function, fθ::Function, τ::Time, ι::AudioChannel)
  @sample ν = fν(τ, ι)
  @sample θ = fθ(τ, ι)
  x = 2.0muladd(ν, τ, θ)
  4abs(x - floor(x + 0.5)) - 1 |> Sample
end

tri(ν) = tri(ν, 0.0)
