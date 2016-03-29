### Utils ###

function fop(op, f₁::AudioControl, f₂::AudioControl)
  isa(f₁, Float64) && isa(f₂, Float64) && return op(f₁, f₂)
  g₁ = convert(AudioSignal, f₁)
  g₂ = convert(AudioSignal, f₂)
  @inline function (τ::Time, ι::AudioChannel)
    x₁ = g₁(τ, ι)
    x₂ = g₂(τ, ι)
    op(x₁, x₂)
  end
end

Base.(:+)(f₁::AudioControl, f₂::AudioControl) = fop(+, f₁, f₂)
Base.(:-)(f₁::AudioControl, f₂::AudioControl) = fop(-, f₁, f₂)
Base.(:*)(f₁::AudioControl, f₂::AudioControl) = fop(*, f₁, f₂)
Base.(:/)(f₁::AudioControl, f₂::AudioControl) = fop(/, f₁, f₂)
Base.(:^)(f₁::AudioControl, f₂::AudioControl) = fop(^, f₁, f₂)

function constantly(x)
  @inline function (τ::Time, ι::AudioChannel)
    x
  end
end

function signal(x::Signal{Float64})
  @inline function (τ::Time, ι::AudioChannel)
    value(x)
  end
end

function signal(x::Signal{Array{Float64}})
  @inline function (τ::Time, ι::AudioChannel)
    @inbounds value(x[ι])
  end
end

Base.convert(::Type{AudioSignal}, x::Signal{Float64}) = signal(x)
Base.convert(::Type{AudioSignal}, x::Signal{Array{Float64}}) = signal(x)
Base.convert(::Type{AudioSignal}, x::Float64) = constantly(x)

macro audiosignal(ex)
  ex.head != :function &&
    error("@audiosignal works only with `function myfunc(...)` form, got ", ex)

  signature = ex.args[1].args
  name = signature[1]
  body = ex.args[2]

  τ = signature[end - 1] # τ::Time
  ι = signature[end]     # ι::AudioChannel

  # e.g. AudioSignal, AudioSignal, Time, AudioChannel
  _types = map((x) -> x.args[2], signature[2:end])
  types = Expr(:tuple, _types...)

  # e.g. fν::AudioSignal, fθ::AudioSignal
  bindargs = signature[2:end-2]

  # e.g. fν::AudioControl, fθ::AudioControl
  wrapperargs = map(bindargs) do arg
    Expr(arg.head, arg.args[1], :AudioControl)
  end

  conversions = map(bindargs) do arg
    # e.g. convert(AudioSignal, fν)
    x = arg.args[1]
    :($x = convert(AudioSignal, $x))
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

@audiosignal function sine(fν::AudioSignal, fθ::AudioSignal, τ::Time, ι::AudioChannel)
  ν = fν(τ, ι)
  θ = fθ(τ, ι)
  sinpi(2.0muladd(ν, τ, θ))
end

sine(ν) = sine(ν, 0.0)

@audiosignal function saw(fν::AudioSignal, fθ::AudioSignal, τ::Time, ι::AudioChannel)
  ν = fν(τ, ι)
  θ = fθ(τ, ι)
  x = muladd(ν, τ, θ)
  2.0(x - floor(x)) - 1.0
end

saw(ν) = saw(ν, 0.0)

@audiosignal function tri(fν::AudioSignal, fθ::AudioSignal, τ::Time, ι::AudioChannel)
  ν = fν(τ, ι)
  θ = fθ(τ, ι)
  x = 2.0muladd(ν, τ, θ)
  4.0abs(x - floor(x + 0.5)) - 1.0
end

tri(ν) = tri(ν, 0.0)

OVERTONE_STEP = sqrt(2)

function overtones(f::Function, amps::Vector{AudioControl}, ν::AudioControl, θ::AudioControl)
  fν = convert(AudioSignal, ν)
  fθ = convert(AudioSignal, θ)
  n = 0.5length(amps) |> ceil
  mapreduce(+, enumerate(amps)) do ix
    ix[2]*f(fν*OVERTONE_STEP^(ix[1] - n), fθ)
  end
end
