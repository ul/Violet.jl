### Utils ###

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

function signal(x::Signal{Float64})
  function f(τ::Time, ι::AudioChannel)
    value(x)::Sample
  end
  f
end

function signal(x::Signal{Array{Float64}})
  function f(τ::Time, ι::AudioChannel)
    value(x[ι])::Sample
  end
  f
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

### Waves ###

@audiosignal function sine(fν::AudioSignal, fθ::AudioSignal, τ::Time, ι::AudioChannel)
  ν = fν(τ, ι)::Sample
  θ = fθ(τ, ι)::Sample
  sinpi(2.0muladd(ν, τ, θ))
end

sine(ν) = sine(ν, 0.0)

@audiosignal function saw(fν::AudioSignal, fθ::AudioSignal, τ::Time, ι::AudioChannel)
  ν = fν(τ, ι)::Sample
  θ = fθ(τ, ι)::Sample
  x = muladd(ν, τ, θ)
  2.0(x - floor(x)) - 1.0
end

saw(ν) = saw(ν, 0.0)

@audiosignal function tri(fν::AudioSignal, fθ::AudioSignal, τ::Time, ι::AudioChannel)
  ν = fν(τ, ι)::Sample
  θ = fθ(τ, ι)::Sample
  x = 2.0muladd(ν, τ, θ)
  4.0abs(x - floor(x + 0.5)) - 1.0
end

tri(ν) = tri(ν, 0.0)

@audiosignal function square(fν::AudioSignal, fθ::AudioSignal, τ::Time, ι::AudioChannel)
  ν = fν(τ, ι)::Sample
  θ = fθ(τ, ι)::Sample
  x = muladd(ν, τ, θ)
  2.0floor(x) - floor(2.0x) + 1.0
end

square(ν) = square(ν, 0.0)


function overtones(f::Function, amps::Vector{AudioControl}, ν::AudioControl, θ::AudioControl)
  fν = convert(AudioSignal, ν)
  fθ = convert(AudioSignal, θ)
  n = round(Int, length(amps)/2)
  mapreduce(+, enumerate(amps)) do ix
    k = ix[1] >= n ? ix[1] - n + 1.0 : 1.0 / (n - ix[1] + 1.0)
    ix[2]*f(k*fν, fθ)
  end
end

# bloody battle for performance
# sacrifice RAM, hail pure audiosignals!
# speed of light is our limit

"NOTE table has a channel number as an outer index
 REVIEW use this convention for buffers?"
function wavetable(table::Array{Sample}, samplerate=CONFIG.samplerate)
  function f(τ::Time, ι::AudioChannel)
    table[ι, mod1(round(Int, τ*samplerate) + 1, size(table, 2))]::Sample
  end
  f
end

cosine_distance(x, y) = 1 - dot(x, y)/(norm(x)*norm(y))

"NOTE table is flat here"
function match_periods(table::Vector{Sample}, periods=2, ϵ=1e-6)
  n = length(table)÷periods
  x = sub(table, 1:n)
  for i=1:periods - 1
    y = sub(table, i*n + (1:n))
    cosine_distance(x, y) > ϵ && return false
  end
  true
end

"NOTE `f` must be pure!
 `maxperiod` is in seconds,
    care about size of resulting table: 1 second is 44100*2*8 ~ 689 KiB
    table generation time is an issue too for long periods
 `periods` is how many periods to compare to be sure that we are not in a subperiod"
function gen_table(f::AudioSignal, maxperiod=1.0, periods=2, config=CONFIG)
  maxlength = maxperiod*config.samplerate*config.outchannels*periods
  table = Sample[]
  i = 0.0
  for j=1:2
    for k=1:periods
      for ι=1:config.outchannels
        push!(table, f(i/config.samplerate, ι))
      end
      i += 1.0
    end
  end
  while length(table) <= maxlength && !match_periods(table, periods)
    for k=1:periods
      for ι=1:config.outchannels
        push!(table, f(i/config.samplerate, ι))
      end
      i += 1.0
    end
  end
  n = length(table)÷periods
  reshape(table[1:n], (config.outchannels, n÷config.outchannels))
end

function snapshot(f::AudioSignal, maxperiod=1.0, periods=2, config=CONFIG)
  wavetable(gen_table(f::AudioSignal, maxperiod, periods, config))
end

# TODO optimize table generation
# TODO caching impure audiosignals!
