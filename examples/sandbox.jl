using Violet

pid = addaudio()
sleep(2) # give audio server time to spin up

engine = Engine()

run(engine)

simple_synth(ν) =
  0.1(0.125sine(0.5ν) + 0.25sine(sqrt(0.5)*ν) + sine(ν)
 + 0.25sine(sqrt(2)*ν) + 0.125sine(2ν) + 0.125sine(4ν))
   #* 0.25env([0.0, 0.0, 0.02, 1, 0.02, 0.9, 0.2, 0.9, 0.2, 0])

f = simple_synth(440)

push!(engine.root.audio, f)

sleep(10)
delete!(engine.root.audio, f)
kill(engine)
sleep(2) # give time for async print to finish it's job
rmaudio(pid)
