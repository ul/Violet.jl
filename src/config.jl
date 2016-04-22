immutable Config
  samplerate::Int
  buffersize::Int
  inchannels::Int
  outchannels::Int
  port::Int
end

Config() = Config(44100, 256, 0, 2, 31337)

"Default config"
CONFIG = Config()
