export Engine

type Engine
  config::Config
  status::Symbol
  empty::Bool
  root::Node
  eventlist::EventList
  #stream::IO
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
    #convert(IO, connect(port)),
    port,
    0)
end

"Main realtime engine running function. Called within a thread from engine-start."
function Base.run(engine::Engine)
  if engine.status == :running
    return
  end
  engine.status = :running
  stream = convert(IO, connect(engine.port))
  buffer = Array{Float32}(engine.config.buffer_size, engine.config.output_channels)
  Δτ = engine.config.buffer_size/engine.config.sample_rate
  timer = Timer(0, Δτ)
  @async while true
    if engine.status == :running
      eventlist_tick!(engine.eventlist)
      engine.root(engine.frame)
      @inbounds copy!(buffer, engine.root.buffer)
      if engine.empty
        empty!(engine.root)
        empty!(engine.eventlist)
        engine.empty = false
      end
      wait(timer)
      serialize(stream, buffer)
      flush(stream)
      engine.frame += engine.config.buffer_size
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
