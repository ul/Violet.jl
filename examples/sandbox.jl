using Violet

engine = Engine()

f1 = sine(440.0)
f2 = adsr(0.5, 0.4, 0.5, 0.8, 0.5)
f3 = f1*f2

relschedule(engine, 2.0, () -> engine.dsp = f3)
relschedule(engine, 5.0, () -> engine.dsp = silence)

run(engine)
sleep(60)
kill(engine)
sleep(2) # give time for async print to finish it's job
