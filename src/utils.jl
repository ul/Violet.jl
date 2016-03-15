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

# Julia 0.5 only

function thread_run_thunk(thunk)
  ccall(:jl_threading_run, Void, (Any,), Core.svec(thunk))
end

macro thread(expr)
    expr = Base.localize_vars(esc(:(()->($expr))), false)
    :(thread_run_thunk($expr))
end
