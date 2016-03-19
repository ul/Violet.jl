# Violet

[![Build Status](https://travis-ci.org/ul/Violet.jl.svg?branch=master)](https://travis-ci.org/ul/Violet.jl)

A library for music systems development, written in Julia.

Pre-α.

Heavily inspired by [Pink](https://github.com/kunstmusik/pink) and [Extempore](https://github.com/digego/extempore).

Uses [PortAudio](http://portaudio.com/) as an audio I/O backend, wrapper is based on [PortAudio.jl](https://github.com/seebk/PortAudio.jl)

## Getting started

### Start

First, you must create and start your engine. It can be done with:
```
engine = Engine()
run(engine)
```

Then, you can create something that you want to sound. Let it be 440Hz sine:
```
myfirstsound = sine(440.0)
```

And push it to engine:
```
push!(engine.root.audio, myfirstsound)
```

Yeah. Violet is talking to you :-)

Then turn it off:
```
delete!(engine.root.audio, myfirstsound)
```

You can create also saw() and tri() waves, in any combinations:
```
somethingelse = (sine(tri(3.3) + tri(2.0)) * myfirstsound)
```

### Swappers

Swapper is a type, once instantiated, it can easily switch any signals you create:
```
newswap = Swapper(engine, myfirstsound)
```

With swappers you don't need to push audiosignal manually to engine, it'll be pushed when you run it:
```
run(newswap)
```

And now feed swapper with another signal:
```
newswap(somethingelse)
```

To switch off audiosignal kill the swapper:
```
kill(newswap)
```

It could run again later.
