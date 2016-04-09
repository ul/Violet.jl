@inline function mixer_kernel(_::Time, x::Vector{Sample}, y::Vector{Sample})
  @inbounds copy!(y, x)
end

mixer(channels::Int) = Node(mixer_kernel, fill(Sample, channels), fill(Sample, channels))

@inline function stereo_kernel(_::Time, x::Vector{Sample}, y::Vector{Sample})
  @inbounds begin
    fill!(y, x[1])
  end
end

stereo(channels::Int) = Node(stereo_kernel, [Sample], fill(Sample, channels))

function constant{T}(x::T)
  @inline function constant_kernel(_::Time, __, y::Vector{T})
    @inbounds y[1] = x
  end
  Node(constant_kernel, [], [T])
end

function signal{T}(x::Signal{T})
  @inline function signal_kernel(_::Time, __, y::Vector{T})
    @inbounds y[1] = value(x)
  end
  Node(signal_kernel, [], [T])
end

@inline function sine_kernel(τ::Time, x::Vector{Sample}, y::Vector{Sample})
  @inbounds begin
    ν = x[1]
    θ = x[2]
    y[1] = sinpi(2.0muladd(ν, τ, θ))
  end
end

sine() = Node(sine_kernel, [Sample, Sample], [Sample])

@inline function saw_kernel(τ::Time, x::Vector{Sample}, y::Vector{Sample})
  @inbounds begin
    ν = x[1]
    θ = x[2]
    z = muladd(ν, τ, θ)
    y[1] = 2.0(z - floor(z)) - 1.0
  end
end

saw() = Node(saw_kernel, [Sample, Sample], [Sample])

@inline function tri_kernel(τ::Time, x::Vector{Sample}, y::Vector{Sample})
  @inbounds begin
    ν = x[1]
    θ = x[2]
    z = 2.0muladd(ν, τ, θ)
    y[1] = 4.0abs(z - floor(z + 0.5)) - 1.0
  end
end

tri() = Node(tri_kernel, [Sample, Sample], [Sample])

@inline function square_kernel(τ::Time, x::Vector{Sample}, y::Vector{Sample})
  @inbounds begin
    ν = x[1]
    θ = x[2]
    z = ν*τ
    y[1] = 2.0floor(z) - floor(2.0z) + 1.0
  end
end

square() = Node(square_kernel, [Sample, Sample], [Sample])

@inline function sum_kernel(τ::Time, x::Vector{Sample}, y::Vector{Sample})
  @inbounds y[1] = sum(x)
end

sum(channels::Int) = Node(sum_kernel, fill(Sample, channels), [Sample])

@inline function mul_kernel(τ::Time, x::Vector{Sample}, y::Vector{Sample})
  @inbounds y[1] = prod(x)
end

mul(channels::Int) = Node(mul_kernel, fill(Sample, channels), [Sample])

@inline function sub_kernel(τ::Time, x::Vector{Sample}, y::Vector{Sample})
  @inbounds y[1] = reduce(-, x)
end

sub(channels::Int) = Node(sub_kernel, fill(Sample, channels), [Sample])

@inline function div_kernel(τ::Time, x::Vector{Sample}, y::Vector{Sample})
  @inbounds y[1] = reduce(/, x)
end

div(channels::Int) = Node(div_kernel, fill(Sample, channels), [Sample])

@inline function pow_kernel(τ::Time, x::Vector{Sample}, y::Vector{Sample})
  @inbounds y[1] = reduce(^, x)
end

pow(channels::Int) = Node(pow_kernel, fill(Sample, channels), [Sample])


### FIXME not ported yet
#=
function overtones(n)
  function overtones_kernel(τ::Time, x::Vector{Sample}, y::Vector{Sample})

  end
end

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
function wavetable(table::Array{Sample}, sample_rate=CONFIG.sample_rate)
  function f(τ::Time, ι::AudioChannel)
    table[ι, mod1(round(Int, τ*sample_rate) + 1, size(table, 2))]::Sample
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

FFTW.set_num_threads(4)

using DSP

"NOTE `f` must be pure!
 `maxperiod` is in seconds,
    care about size of resulting table: 1 second is 44100*2*8 ~ 689 KiB
    table generation time is an issue too for long periods
 `periods` is how many periods to compare to be sure that we are not in a subperiod"
function gen_table(f::AudioSignal, ms=16, maxperiod=10.0, periods=2, config=CONFIG)
  maxlength = maxperiod*config.sample_rate*config.output_channels*periods
  matchstep = ms
  table = Sample[]
  i = 0.0
  for j=1:2
    for k=1:periods
      for ι=1:config.output_channels
        push!(table, f(i/config.sample_rate, ι))
      end
      i += 1.0
    end
  end
  z = 0
  while length(table) <= maxlength
    if (matchstep == 1 || i%(periods*matchstep) == 0)
      z += 1
      if match_periods(table, periods, exp10(matchstep)*1e-7)
        matchstep == 1 && break
        matchstep -= 1
      end
    end
    for k=1:periods
      for ι=1:config.output_channels
        push!(table, f(i/config.sample_rate, ι))
      end
      i += 1.0
    end
  end
  println(z)
  n = length(table)÷periods
  reshape(table[1:n], (config.output_channels, n÷config.output_channels))
end

function snapshot(f::AudioSignal, maxperiod=1.0, periods=2, config=CONFIG)
  wavetable(gen_table(f::AudioSignal, 1, maxperiod, periods, config))
end

# TODO optimize table generation
# TODO caching impure audiosignals!
=#
