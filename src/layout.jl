module CSSLayout

const CSS_UNDEFINED = Symbol("")

const CSS_DIRECTION_INHERIT = :inherit
const CSS_DIRECTION_LTR = :ltr
const CSS_DIRECTION_RTL = :rtl

const CSS_FLEX_DIRECTION_ROW = :row
const CSS_FLEX_DIRECTION_ROW_REVERSE = :row_reverse
const CSS_FLEX_DIRECTION_COLUMN = :column
const CSS_FLEX_DIRECTION_COLUMN_REVERSE = :column_reverse

const CSS_JUSTIFY_FLEX_START = :flex_start
const CSS_JUSTIFY_CENTER = :center
const CSS_JUSTIFY_FLEX_END = :flex_end
const CSS_JUSTIFY_SPACE_BETWEEN = :space_between
const CSS_JUSTIFY_SPACE_AROUND = :space_around

const CSS_ALIGN_FLEX_START = :flex_start
const CSS_ALIGN_CENTER = :center
const CSS_ALIGN_FLEX_END = :flex_end
const CSS_ALIGN_STRETCH = :stretch

const CSS_POSITION_RELATIVE = :relative
const CSS_POSITION_ABSOLUTE = :absolute

const leading = Dict(
  :row => :left,
  :row_reverse => :right,
  :column => :top,
  :column_reverse => :bottom)

const trailing = Dict(
  :row => :right,
  :row_reverse => :left,
  :column => :bottom,
  :column_reverse => :top)

const pos = Dict(
  :row => :left,
  :row_reverse => :right,
  :column => :top,
  :column_reverse => :bottom)

const dim = Dict(
  :row => :width,
  :row_reverse => :width,
  :column => :height,
  :column_reverse => :height)

typealias Layout Dict{Symbol, Real}
typealias Style Dict{Symbol, Union{Symbol, Real}}

type Node
  style::Style
  layout::Layout
  children::Vector{Node}
end

layout() = Layout(
  :width => CSS_UNDEFINED,
  :height => CSS_UNDEFINED,
  :left => 0,
  :top => 0,
  :right => 0,
  :bottom => 0)

Node(style::Style, children::Vector{Node}) = Node(style, layout(), children)

is_undefined(value) = value === CSS_UNDEFINED

is_row_direction(flex_direction) =
  flex_direction === CSS_FLEX_DIRECTION_ROW ||
    flex_direction === CSS_FLEX_DIRECTION_ROW_REVERSE

is_column_direction(flex_direction) =
  flex_direction === CSS_FLEX_DIRECTION_COLUMN ||
    flex_direction === CSS_FLEX_DIRECTION_COLUMN_REVERSE

function get_edge(prefix, suffix, edge, node::Node, axis)
  key = symbol(prefix, "_", edge, "_", suffix)
  haskey(node.style, key) && is_row_direction(axis) && return node.style[key]
  key = symbol(prefix, "_", edge === :start ? leading[axis] : trailing[axis]), "_", suffix)
  haskey(node.style, key) ? node.style[key] : get(node.style, key, 0)
end

get_leading_margin(node, axis) = get_edge(:margin, "", :start, node, axis)
get_trailing_margin(node, axis) = get_trailing(:margin, "", :end, node, axis)
# FIXME node.style.padding* >= 0
get_leading_padding(node, axis) = get_edge(:padding, "", :start, node, axis)
get_trailing_padding(node, axis) = get_edge(:padding, "", :end, node, axis)
get_leading_border(node, axis) = get_edge(:border, :width, :start, node, axis)
get_trailing_border(node, axis) = get_edge(:border, :width, :end, node, axis)
get_leading_padding_and_border(node, axis) = get_leading_padding(node, axis) + get_leading_border(node, axis)
get_trailing_padding_and_border(node, axis) = get_trailing_padding(node, axis) + get_trailing_border(node, axis)
get_border_axis(node, axis) = get_leading_border(node, axis) + get_trailing_border(node, axis)
get_margin_axis(node, axis) = get_leading_margin(node, axis) + get_trailing_margin(node, axis)
get_padding_and_border_axis(node, axis) = get_leading_padding_and_border(node, axis) + get_trailing_padding_and_border(node, axis)

get_justify_content(node) = get(node.style, :justify_content, :flex_start)
get_align_content(node) = get(node.style, :align_content, :flex_start)

function get_align_item(node, child)
  haskey(child.style, :align_self) && return child.style[:align_self]
  get(node.style, :align_items, :stretch)
end

function resolve_axis(axis, direction)
  if direction === CSS_DIRECTION_RTL
    if axis === CSS_FLEX_DIRECTION_ROW
      return CSS_FLEX_DIRECTION_ROW_REVERSE
    elseif axis === CSS_FLEX_DIRECTION_ROW_REVERSE
      return CSS_FLEX_DIRECTION_ROW
    end
  end

  axis
end

function resolve_direction(node, parentDirection)
  direction = get(node.style, :direction, CSS_DIRECTION_INHERIT)
  if direction == CSS_DIRECTION_INHERIT
    direction = parentDirection === CSS_UNDEFINED ? CSS_DIRECTION_LTR : parentDirection
  end
  direction
end

function get_flex_direction(node)
  get(node.style, :flex_direction, CSS_FLEX_DIRECTION_COLUMN)
end

function get_cross_flex_direction(flex_direction, direction)
  if is_column_direction(flex_direction)
    resolve_axis(CSS_FLEX_DIRECTION_ROW, direction)
  else
    CSS_FLEX_DIRECTION_COLUMN
  end
end

get_position_type(node) = get(node.style, :position, :relative)

is_flex(node) =
  get_position_type(node) === CSS_POSITION_RELATIVE &&
    get(node.style, :flex, 0) > 0

is_flex_wrap(node) = get(node.style, :flex_wrap, nothing) === :wrap
get_dim_with_margin(node, axis) = get(node.layout, dim[axis], 0) + get_margin_axis(node, axis)
is_style_dim_defined(node, axis) = get(node.style, dim[axis], -1) >= 0
is_layout_dim_defined(node, axis) = get(node.layout, dim[axis], -1) >= 0
is_pos_defined(node, pos) = haskey(node.style, pos)
is_measure_defined(node) = haskey(node.style, :measure)
get_position(node, pos) = get(node.style, pos, 0)

function bound_axis(node, axis, value)
  min =
    if axis === :row || axis === :row_reverse
      get(node.style, :min_width, CSS_UNDEFINED)
    elseif axis === :column || axis === :column_reverse
      get(node.style, :min_height, CSS_UNDEFINED)
    else
      CSS_UNDEFINED
    end

  max =
    if axis === :row || axis === :row_reverse
      get(node.style, :max_width, CSS_UNDEFINED)
    elseif axis === :column || axis === :column_reverse
      get(node.style, :max_height, CSS_UNDEFINED)
    else
      CSS_UNDEFINED
    end

  bound_value = value

  if max !== CSS_UNDEFINED && max >= 0 && bound_value > max
    bound_value = max
  end

  if min !== CSS_UNDEFINED && min >= 0 && bound_value < min
    bound_value = min
  end

  bound_value

end

# When the user specifically sets a value for width or height
function set_dimension_from_style
  # The parent already computed us a width or height. We just skip it
  is_layout_dim_defined(node, axis) && return
  # We only run if there's a width or height defined
  is_style_dim_defined(node, axis) && return
  # The dimensions can never be smaller than the padding and border
  node.layout[dim[axis]] =
    max(
      bound_axis(node, axis, get(node.style, dim[axis], CSS_UNDEFINED)),
      get_padding_and_border_axis(node, axis))
end

function set_trailing_position(node, child, axis)
  child.layout[trailing[axis]] = node.layout[dim[axis]] -
    child.layout[dim[axis]] - child.layout[pos[axis]]
end

# If both left and right are defined, then use left. Otherwise return
# +left or -right depending on which is defined.
function get_relative_position(node, axis)
  if haskey(node.style, leading[axis])
    get_position(node, leading[axis])
  else
    -get_position(node, trailing[axis])
  end
end

function layout_node_impl(node, parent_max_width, parent_max_height, parent_direction)
end

end # module
