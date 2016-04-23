type Engine
  config::Config
  status::Symbol
  empty::Bool
  dsp #::AudioSignal
  events::EventQueue
  frame::Int
end

function Engine(config=CONFIG)
  Engine(
    config,
    :stopped,
    false,
    silence,
    EventQueue(),
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
  sr = config.samplerate
  engine.frame = 0
  empty!(engine.events)
  τ₀ = time()
  @async while true
    if engine.status == :running
      endframe = engine.frame + Δframes
      engine.events(endframe/sr)
      for ι=1:config.outchannels, frame=1:Δframes
        τ = (engine.frame + frame)/sr
        @inbounds buffer[frame, ι] = engine.dsp(τ, ι)
      end
      if engine.empty
        engine.dsp = silence
        empty!(engine.events)
        engine.empty = false
      end
      δτ = τ₀ + now(engine) - time() - 1e-3
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

Base.now(engine::Engine) = engine.frame/engine.config.samplerate

schedule₀(engine::Engine, start::Time, f::Function, args...) =
  schedule(engine.events, start, f, args...)

Base.schedule(engine::Engine, start::Time, f::Function, args...) =
  schedule₀(engine, now(engine) + start, f, args...)
