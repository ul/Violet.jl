reload("Violet")
using Violet

engine = Engine()
run(engine)

simple_synth(ν) =
  0.1(0.125sine(0.5ν) + 0.25sine(sqrt(0.5)*ν) + sine(ν)
 + 0.25sine(sqrt(2)*ν) + 0.125sine(2ν) + 0.125sine(4ν))
   #* 0.25env([0.0, 0.0, 0.02, 1, 0.02, 0.9, 0.2, 0.9, 0.2, 0])

#f = sine(440)
f = 0.5sine(440.0) + 0.3sine(440.0/sqrt(2)) + 0.2sine(880.0)

push!(engine.root.audio, f)

#evt = Event(() -> push!(engine.root.audio, f), 5.0, [])
#push!(engine.eventlist, evt)

#engine.eventlist.current_beat

sleep(10)
delete!(engine.root.audio, f)
kill(engine)
sleep(2) # give time for async print to finish it's job
