type Engine
  config::Config
  status::Symbol
  empty::Bool
  root::Node
  eventlist::EventList
  port::Int
  frame::Int
end

function Engine(port=31337, config=CONFIG)
  Engine(
    config,
    :stopped,
    false,
    Node(config),
    EventList(config),
    port,
    0)
end

function Base.run(engine::Engine)
  if engine.status == :running
    return
  end
  engine.status = :running
  stream = convert(IO, connect(31337))
  buffer = Array{Float32}(engine.config.buffersize, engine.config.outchannels)
  Δframes = engine.config.buffersize
  sr = engine.config.samplerate
  δτ = 0.0
  τ₀ = time()
  @async while true
    if engine.status == :running
      endframe = engine.frame + Δframes
      engine.eventlist(endframe)
      engine.root(engine.frame, Δframes)
      @inbounds copy!(buffer, engine.root.buffer)
      if engine.empty
        empty!(engine.root)
        empty!(engine.eventlist)
        engine.empty = false
      end
      Δτ = time() - τ₀
      δτ = engine.frame/sr - Δτ - 1e-3
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

function fire_audio_event(engine::Engine, event::Event)
  afunc = fire_event(event)
  if afunc # FIXME nullable
    push!(engine.root.audio, afunc)
  end
end

wrap_audio_event(engine::Engine, event::Event) = wrap_event(fire_audio_event, [engine], event)

audio_events(engine::Engine, events) = map((event) -> wrap_audio_event(engine, event), events)
audio_events(engine::Engine, events...) = map((event) -> wrap_audio_event(engine, event), events)
