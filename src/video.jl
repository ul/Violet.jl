using Reactive, GLAbstraction, Colors, GeometryTypes, GLVisualize

include("config.jl")
include("circularbuffer.jl")

function init(port=31337,
              buffer_size=CONFIG.hardware_buffer_size)
  global gport = port
  global window = glscreen()
  global buffer = CircularBuffer(Float32, 20buffer_size)
  global stream = convert(IO, connect(port))
  clock = fps(60)
  points = map(clock, window.inputs[:window_size]) do clock, size
    y₀ = size[2]/2
    n = buffer.write_cursor - buffer_size
    if n < 0
      n += 20buffer_size
    end
    Point2f0[(i - 1, y₀*(1 + buffer[i + n])) for i=1:buffer_size]
  end
  color = map(RGBA{Float32}, colormap("Blues", buffer_size))
  view(visualize(points, :lines, color=color))
end

function clean()
  close(stream)
end

atexit(clean)

function run()
  @async renderloop(window)
  while true
    try
      append!(buffer, deserialize(stream))
    catch
      sleep(1)
      global stream = convert(IO, connect(gport))
    end
  end
end

init(map((x) -> parse(Int, x), ARGS)...)
run()
