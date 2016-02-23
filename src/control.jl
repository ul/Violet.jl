"Creates a sample-accurate clock control function that triggers a `trigger_fn`
according to the tempo held within the `tempo`.  When the time has been
met, it will call the given `trigger_fn` and truncate the running `sample_count`.

User can supply an optional `state` for signaling to the clock for
different running states. Acceptable states are `:running`, `:paused`, and `:done`.
Any other state will result in `:done`.

User may also supply an optional `done_fn`. `done_fn` will be called when this
clock goes into the `:done` state. `done_fn` must be a 0-arity function."
function create_clock(tempo, trigger_fn, state, done_fn = nothing, sample_rate=CONFIG.sample_rate, buffer_size=CONFIG.buffer_size)
  sample_count = 60sample_rate / tempo
  function ()
    if state == :running
      num_samples_to_wait = 60sample_rate / tempo
      if sample_count >= num_samples_to_wait
        sample_count %= num_samples_to_wait
        trigger_fn()
      else
        sample_count += buffer_size
      end
      true
    elseif state == :paused
      true
    else
      done_fn != nothing && done_fn()
      false
    end
  end
end
