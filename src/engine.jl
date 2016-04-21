type Engine
  config::Config
  status::Symbol
  empty::Bool
  dsp::AudioSignal
  eventlist::EventList
  frame::Int
end

function Engine(config=CONFIG)
  Engine(
    config,
    :stopped,
    false,
    silence,
    EventList(config.tempo),
    0)
end

function Base.run(engine::Engine)
  if engine.status == :running
    return
  end
  engine.status = :running
  config = engine.config
  stream = convert(IO, connect(config.port))
  buffer = Array{Float32}(config.buffersize, config.outchannels)
  Δframes = config.buffersize
  Δτ = 1.0/config.samplerate
  τ₀ = time()
  @async while true
    if engine.status == :running
      endframe = engine.frame + Δframes
      engine.eventlist(endframe*Δτ)
      for ι=1:config.outchannels, frame=1:Δframes
        τ = (engine.frame + frame)*Δτ
        @inbounds buffer[frame, ι] = engine.dsp(τ, ι)
      end
      if engine.empty
        engine.dsp = silence
        empty!(engine.eventlist)
        engine.empty = false
      end
      δτ = τ₀ + engine.frame*Δτ - time() - 1e-3
      δτ > 1e-3 && sleep(δτ)
      serialize(stream, buffer)
      flush(stream)
      engine.frame = endframe
    else
      close(stream)
      break
    end
  end
end

function Base.kill(engine::Engine)
  engine.status = :stopped
end

function Base.empty!(engine::Engine)
  if engine.status == :running
    engine.empty = true
  end
end
