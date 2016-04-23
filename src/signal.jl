function fop(op, f₁::AudioControl, f₂::AudioControl)
  isa(f₁, Float64) && isa(f₂, Float64) && return op(f₁, f₂)
  g₁ = convert(AudioSignal, f₁)
  g₂ = convert(AudioSignal, f₂)
  function f(τ::Time, ι::AudioChannel)
    x₁ = g₁(τ, ι)::Sample
    x₂ = g₂(τ, ι)::Sample
    op(x₁, x₂)::Sample
  end
  f
end

Base.(:+)(f₁::AudioControl, f₂::AudioControl) = fop(+, f₁, f₂)
Base.(:-)(f₁::AudioControl, f₂::AudioControl) = fop(-, f₁, f₂)
Base.(:*)(f₁::AudioControl, f₂::AudioControl) = fop(*, f₁, f₂)
Base.(:/)(f₁::AudioControl, f₂::AudioControl) = fop(/, f₁, f₂)
Base.(:^)(f₁::AudioControl, f₂::AudioControl) = fop(^, f₁, f₂)

function constantly(x::Sample)
  function f(τ::Time, ι::AudioChannel)
    x::Sample
  end
  f
end

function constantly(x::Vector{Sample})
  function f(τ::Time, ι::AudioChannel)
    x[ι]::Sample
  end
  f
end

silence = constantly(0.0)

function signal(x::Signal{Sample})
  function f(τ::Time, ι::AudioChannel)
    value(x)::Sample
  end
  f
end

function signal(x::Signal{Vector{Sample}})
  function f(τ::Time, ι::AudioChannel)
    value(x[ι])::Sample
  end
  f
end

Base.convert(::Type{AudioSignal}, x::Signal{Sample}) = signal(x)
Base.convert(::Type{AudioSignal}, x::Signal{Vector{Sample}}) = signal(x)
Base.convert(::Type{AudioSignal}, x::Vector{Sample}) = constantly(x)
Base.convert(::Type{AudioSignal}, x::Sample) = constantly(x)

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
      function f($τ, $ι)
        $body
      end
      precompile(f, (Time, AudioChannel))
      f
    end

    precompile($name, $types)
  end

  esc(wrapper)
end
