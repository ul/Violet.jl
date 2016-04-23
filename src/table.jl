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
