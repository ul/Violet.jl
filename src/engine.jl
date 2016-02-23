export Engine

type Engine
  config::Config
  status::Symbol
  empty::Bool
  root::Node
  eventlist::EventList
  stream::IO
  tick::Int
end

function Engine(address=31337, config=CONFIG)
  Engine(
    config,
    :stopped,
    false,
    Node(config),
    EventList(config),
    convert(IO, connect(address)),
    0)
end

"Main realtime engine running function. Called within a thread from engine-start."
function run(engine::Engine)
  buffer = Array{Float32}(engine.config.buffer_size, engine.config.output_channels)
  #timer = Timer() # FIXME
  tic()
  while true
    if engine.status == :running
      eventlist_tick!(engine.eventlist)
      frame = engine.tick*engine.config.buffer_size
      run(engine.root, frame)
      @inbounds copy!(buffer, engine.root.buffer)
      if engine.empty
        empty!(engine.root)
        empty!(engine.eventlist)
        engine.empty = false
      end
      serialize(engine.stream, buffer)
      flush(engine.stream)
      engine.tick += 1
    else
      close(engine.stream)
      dt = toq()
      sr = engine.tick/dt
      println("stopping...")
      println("time: $dt, sr: $sr, rsr: $(engine.config.sample_rate/engine.config.buffer_size)")
      Profile.print()
      break
    end
  end
end

function Base.open(engine::Engine)
  if engine.status == :stopped
    engine.status = :running
    @async run(engine)
  end
end

function Base.close(engine::Engine)
  if engine.status == :running
    engine.status = :stopped
  end
end

function empty!(engine::Engine)
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
