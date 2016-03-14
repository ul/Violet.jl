using Violet

engine = Engine()
run(engine)

function addgen(engine, gen)
  push!(engine.root.audio, gen)
end

function delgen(engine, gen)
  delete!(engine.root.audio, gen)
end

function snote(freq::Float64, dur::Float64, start::Float64, engine::Engine)
  f = sine(freq)
  e1 = Event(addgen, start, [engine, f])
  e2 = Event(delgen, start+dur, [engine, f])
  push!(engine.eventlist, e1)
  push!(engine.eventlist, e2)
end

snote(440.0, 1.0, 1.0, engine)

simple_synth(ν) =
  0.1(0.125sine(0.5ν) + 0.25sine(sqrt(0.5)*ν) + sine(ν)
 + 0.25sine(sqrt(2)*ν) + 0.125sine(2ν) + 0.125sine(4ν))
   #* 0.25env([0.0, 0.0, 0.02, 1, 0.02, 0.9, 0.2, 0.9, 0.2, 0])

#f = sine(440)
f = 0.5sine(440.0) + 0.3sine(440.0/sqrt(2)) + 0.2sine(880.0)
f = 0.2*saw(220.0)

push!(engine.root.audio, f)

#evt = Event(() -> push!(engine.root.audio, f), 5.0, [])
#push!(engine.eventlist, evt)

#engine.eventlist.current_beat

sleep(10)
delete!(engine.root.audio, f)
kill(engine)
sleep(2) # give time for async print to finish it's job
