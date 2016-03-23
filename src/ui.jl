module UI
using Reactive, SFML

export window

typealias Position Signal{Vector2f}
typealias Size Signal{Vector2f}

#= Scrapbook
function draw(window::RenderWindow, object::CircleShape, renderStates::Ptr{Void})
foreach((x) -> set_position(circle, x), pos)
=#

type Node
  object::Drawable
  children::Vector{Node}
end

type Tree
  root::Node
end

Node(object::Drawable) = Node(object, Node[])

Base.push!(node::Node, child::Node) = push!(node.children, child)

function Base.delete!(node::Node, child::Node)
  n = findfirst(node.children, child)
  if n > 0
    deleteat!(node.children, n)
  end
end

Base.deleteat!(node::Node, n) = deleteat!(node.children, n)

type GUI
  window::RenderWindow
  root::Node
end

function draw(window::RenderWindow, node::Node)
  draw(window, node)
  for c in node.children
    draw(window, c)
  end
end

draw(gui::GUI) = draw(gui.window, gui.root)

function oscilloscope(points, x, y, width, height)
  box = SFML.RectangleShape()
  position = Position(x, y)
  size = Size(width, height)
end

function window(title::AbstractString, width::Integer, height::Integer)
  mode = VideoMode(width, height)
  ctx = ContextSettings(0, 0, 8, 3, 2)
  w = RenderWindow(mode, title, ctx, window_defaultstyle)
  set_framerate_limit(w, 60)
  w
end

function Base.run(gui::GUI)
  window = gui.window
  event = SFML.Event()
  while isopen(window)
    while pollevent(window, event)
      if get_type(event) == EventType.CLOSED
        close(window)
      end
    end
    clear(window, SFML.black)
    draw(gui)
    display(window)
    sleep(0)
  end
end

end #module
