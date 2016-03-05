export Config, CONFIG

immutable Config
  sample_rate::Int
  buffer_size::Int
  input_channels::Int
  output_channels::Int
  tempo::Float64
  hardware_buffer_size::Int
end

Config() = Config(44100, 1024, 1, 2, 60.0, 1024)

"Default config"
CONFIG = Config()
