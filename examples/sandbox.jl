using Violet

engine = Engine()

prev = silence

function addgen(engine, gen)
  global prev = engine.dsp
  engine.dsp = gen
end

function delgen(engine, gen)
  engine.dsp = prev
end

function snote(freq::Float64, dur::Float64, start::Float64, engine::Engine)
  f = sine(freq)
  e1 = Event(addgen, start, [engine, f])
  e2 = Event(delgen, start+dur, [engine, f])
  push!(engine.eventlist, e1)
  push!(engine.eventlist, e2)
end

#snote(440.0, 1.0, 1.0, engine)

simple_synth(ν) =
  0.1(0.125sine(0.5ν) + 0.25sine(sqrt(0.5)*ν) + sine(ν)
 + 0.25sine(sqrt(2)*ν) + 0.125sine(2ν) + 0.125sine(4ν))
   #* 0.25env([0.0, 0.0, 0.02, 1, 0.02, 0.9, 0.2, 0.9, 0.2, 0])

#f = sine(440)
f = 0.5sine(440.0) + 0.3sine(440.0/sqrt(2)) + 0.2sine(880.0)
f = 0.2*saw(220.0)

#amps = AudioControl[0.2, 0.1, 0.4, 0.1, 0.2]
#ff(freq, ph) = snapshot(overtones(sine, amps, freq, ph))
#f = overtones(sine, amps, ff(110.0, sine(13.0)), 0.0)

#f = overtones(sine, AudioControl[0.3, 0.5, 0.2], sine(110.0)+1.0, 0.0)
f1 = sine(440.0)
f2 = adsr(0.5, 0.8, 0.4, 0.2, 0.2)
f3 = f1*f2

e1 = Event(addgen, 2.0, [engine, f3])
e2 = Event(delgen, 5.0, [engine, f3])
push!(engine.eventlist, e1)
push!(engine.eventlist, e2)

run(engine)

#evt = Event(() -> push!(engine.root.audio, f), 5.0, [])
#push!(engine.eventlist, evt)

#engine.eventlist.current_beat

sleep(60)
engine.dsp = silence
kill(engine)
sleep(2) # give time for async print to finish it's job
