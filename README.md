# Violet

A library for music systems development, written in Julia.

Pre-α.

Heavily inspired by [Pink](https://github.com/kunstmusik/pink) and [Extempore](https://github.com/digego/extempore).

Uses [PortAudio](http://portaudio.com/) as an audio I/O backend, wrapper is based on [PortAudio.jl](https://github.com/seebk/PortAudio.jl)

# Manual

## Start

First, you must create and start your engine. It can be done with:
```
engine = Engine()
run(engine)
```

Then, you can create something that you want to sound. Let it be 440Hz sine:
```
myfirstsine = sine(440.0)
```

And push it to engine:
```
push!(engine.root.audio, myfirstsound)
```

Yeah. Violet talking to you :)

Then turn it off:
```
delete!(engine.root.audio, myfirstsound)
```

You can create also saw() and tri() waves, in any combinations:
```
somethingelse = (sine(tri(3.3) + tri(2.0)) * myfirstsound)
```

##Swappers

Swapper is a type, once created, it can easily switch any signals you create:
```
newswap = Swapper(engine, myfirstsound)
```

With swappers you don't need to push it manual to engine, it'll pushed when you run it:
```
run(newswap)
```

And now feed swapper with another signal:
```
newswap(somethingelse)
```

When you don't need it anymore, delete the swapper:
```
kill(newswap)
```
