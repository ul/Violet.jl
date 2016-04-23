using Violet

### Lab


### Playground

engine = Engine()
run(engine)

inst = Instrument(sine, 0.1, 0.15, 0.66, 0.2)
engine.dsp = inst.dsp

function play1(n, x)
  playnote(engine, inst, 0.0, n+60.0, x/4.0)
  playnote(engine, inst, 0.5, n+64.0, x/4.0)
  playnote(engine, inst, 1.0, n+67.0, x/4.0)
  x > 0.1 &&
    schedule(engine, x, play1,
      [44100.0x%12.0, rand() > 0.3 ? x - 0.01 : x + 0.01])
  nothing
end

play1(0.0, 1.0)


sleep(300)
kill(engine)
sleep(2) # give time for async print to finish it's job
