function audiostream(config=CONFIG)
  devID = convert(PaDeviceIndex, -1)
  audiostream = open(devID, (config.input_channels, config.output_channels),
    config.sample_rate, config.hardware_buffer_size)
  start_stream(audiostream)
  audiostream
end

function Base.kill(audiostream::PaStreamWrapper)
  stop_stream(audiostream)
  close(audiostream)
end
