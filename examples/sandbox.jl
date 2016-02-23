# start server separately
# $ julia audio.jl

using Violet

engine = Engine()

open(engine)

simple_synth(ν) =
  0.1(0.125sine(0.5ν) + 0.25sine(sqrt(0.5)*ν) + sine(ν)
 + 0.25sine(sqrt(2)*ν) + 0.125sine(2ν) + 0.125sine(4ν))
   #* 0.25env([0.0, 0.0, 0.02, 1, 0.02, 0.9, 0.2, 0.9, 0.2, 0])

function demo(e::Engine)
  push!(e.root.audio, simple_synth(440))
  #push!(e.root.audio, simple_synth(220))
  #push!(e.root.audio, simple_synth(660))
  #push!(e.root.audio, simple_synth(500))
end

demo(engine)
sleep(10)
close(engine)
sleep(2) # give time for async print to finish it's job