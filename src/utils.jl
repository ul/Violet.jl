using Reactive

typealias Sample Nullable{Float64}
typealias Time Float64
typealias AudioChannel Int

function fop(op, f₁::Function, f₂::Function)
  function (τ::Time, ι::AudioChannel)
    x₁ = f₁(τ, ι)
    isnull(x₁) && return Sample()

    x₂ = f₂(τ, ι)
    isnull(x₂) && return Sample()

    Sample(op(get(x₁), get(x₂)))
  end
end

Base.(:+)(f₁::Function, f₂::Function) = fop(+, f₁, f₂)

Base.(:*)(f₁::Function, f₂::Function) = fop(*, f₁, f₂)

function Base.(:*)(a::Float64, f::Function)
  function (τ::Time, ι::AudioChannel)
    x = f(τ, ι)
    isnull(x) && return Sample()
    Sample(a*get(x))
  end
end

macro guarded(ex...)
  retval = nothing
  if length(ex) == 2
    retval = ex[1]
    ex = ex[2]
  else
    length(ex) == 1 || error("@guarded requires 1 or 2 arguments")
    ex = ex[1]
  end
  # do-block syntax
  if ex.head == :call && length(ex.args) >= 2 && ex.args[2].head == :->
    newbody = _guarded(ex.args[2], retval)
    ret = deepcopy(ex)
    ret.args[2] = Expr(ret.args[2].head, ret.args[2].args[1], newbody)
    return esc(ret)
  end
  newbody = _guarded(ex, retval)
  esc(Expr(ex.head, ex.args[1], newbody))
end

function _guarded(ex, retval)
  isa(ex, Expr) && (
    ex.head == :-> ||
    (ex.head == :(=) && isa(ex.args[1],Expr) && ex.args[1].head == :call) ||
    ex.head == :function
  ) || error("@guarded requires an expression defining a function")
  quote
    begin
      try
        $(ex.args[2])
      catch err
        warn("Error in @guarded callback")
        Base.display_error(err, catch_backtrace())
        $retval
      end
    end
  end
end

function addaudio(port=31337, config=CONFIG)
  cmd = `julia
   $(Pkg.dir("Violet", "src", "audio.jl"))
   $port
   $(config.input_channels)
   $(config.output_channels)
   $(config.sample_rate)
   $(config.hardware_buffer_size)`
  spawn(cmd)
end

function addvideo(port=31337, config=CONFIG)
  cmd = `julia
   $(Pkg.dir("Violet", "src", "video.jl"))
   $port
   $(config.buffer_size)`
  spawn(cmd)
end

# Julia 0.5 only

function thread_run_thunk(thunk)
  ccall(:jl_threading_run, Void, (Any,), Core.svec(thunk))
end

macro thread(expr)
    expr = localize_vars(esc(:(()->($expr))), false)
    :(thread_run_thunk($expr))
end
