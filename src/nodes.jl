import Base.run

abstract Mixer <: Node

@inline function setport!(node::Mixer, port::Port, x::Sample)
  node.(port) += x
end

type MonoMixer <: Mixer
  in::Sample
  out::Sample
end

MonoMixer() = MonoMixer(0.0, 0.0)

type StereoMixer <: Mixer
  leftin::Sample
  rightin::Sample
  leftout::Sample
  rightout::Sample
end

StereoMixer() = StereoMixer(0.0, 0.0, 0.0, 0.0)

@inline function run(node::MonoMixer, τ::Time)
  node.out = node.in
  node.in = 0.0
end

@inline function run(node::StereoMixer, τ::Time)
  node.leftout = node.leftin
  node.rightout = node.rightin
  node.leftin = node.rightin = 0.0
end

type Constant{T} <: Node
  out::T
end

@inline function run(node::Constant, τ::Time)
end

type RSignal{T} <: Node
  signal::T
  out::T
  function RSignal(signal::Signal)
    new(signal, value(signal))
  end
end

@inline function run(node::RSignal, τ::Time)
  node.out = value(node.signal)
end

type Sine <: Node
  ν::Sample
  θ::Sample
  out::Sample
end

Sine(ν=0.0, θ=0.0) = Sine(ν, θ, 0.0)

@inline function run(node::Sine, τ::Time)
  node.out = sinpi(2.0muladd(node.ν, τ, node.θ))
end

type Saw <: Node
  ν::Sample
  θ::Sample
  out::Sample
end

Saw(ν=0.0, θ=0.0) = Saw(ν, θ, 0.0)

@inline function run(node::Saw, τ::Time)
  x = muladd(node.ν, τ, node.θ)
  node.out = 2.0(x - floor(x)) - 1.0
end

type Tri <: Node
  ν::Sample
  θ::Sample
  out::Sample
end

Tri(ν=0.0, θ=0.0) = Tri(ν, θ, 0.0)

@inline function run(node::Tri, τ::Time)
  x = 2.0muladd(node.ν, τ, node.θ)
  node.out = 4.0abs(x - floor(x + 0.5)) - 1.0
end

type Square <: Node
  ν::Sample
  θ::Sample
  out::Sample
end

Square(ν=0.0, θ=0.0) = Square(ν, θ, 0.0)

@inline function run(node::Square, τ::Time)
  x = node.ν*node.θ
  node.out = 2.0floor(x) - floor(2.0x) + 1.0
end

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
