type Engine
  config::Config
  status::Symbol
  empty::Bool
  graph::Graph
  monomixer::Node
  stereomixer::Node
  eventlist::EventList
  port::Int
  frame::Int
end

function Engine(port=31337, config=CONFIG)
  graph = Graph()
  monomixer = mixer(1)
  stereomixer = mixer(2)
  dub = stereo(2)
  push!(graph, monomixer, 1, dub, 1)
  push!(graph, dub, 1, stereomixer, 1)
  push!(graph, dub, 2, stereomixer, 2)
  Engine(
    config,
    :stopped,
    false,
    graph,
    monomixer,
    stereomixer,
    EventList(config),
    port,
    0)
end

function Base.run(engine::Engine)
  if engine.status == :running
    return
  end
  engine.status = :running
  stream = audiostream(engine.config)
  buffer = Array{Float32}(10engine.config.buffer_size, engine.config.output_channels)
  δframes = 0
  Δτ = 1/engine.config.sample_rate
  @async while true
    if engine.status == :running
      tic()
      Δframes = min(3engine.config.buffer_size, writeavailable(stream) + δframes)
      engine.eventlist(engine.frame + Δframes)

      ###
      for frame=1:Δframes
        τ = (engine.frame + frame)*Δτ
        run(engine.graph, τ)
        for ι=1:engine.config.output_channels
          @inbounds buffer[frame, ι] = engine.stereomixer.y[ι]
        end
      end
      ###


      if engine.empty
        empty!(engine.root)
        empty!(engine.eventlist)
        engine.empty = false
      end
      write(stream, buffer, Δframes)
      engine.frame += Δframes
      sleep(0)
      δframes = round(Int, toq()*engine.config.sample_rate)
    else
      kill(stream)
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
