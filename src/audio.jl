include("PortAudio.jl")
include("config.jl")

using PortAudio

function run(address=31337)
  PortAudio.initialize()

  devID = convert(PaDeviceIndex, -1)
  audiostream = PortAudio.open(devID, (0, CONFIG.output_channels), CONFIG.sample_rate, CONFIG.hardware_buffer_size)

  PortAudio.start(audiostream)

  server = listen(address)

  @async while true
    flush(audiostream)
  end

  while true
    stream = convert(IO, accept(server))
    @async while isopen(stream)
      x = deserialize(stream)
      write(audiostream, x)
    end
  end
end

# FIXME remove
run()
