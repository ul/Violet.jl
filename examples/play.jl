using Violet, Benchmarks
engine = Engine()

freq = Constant(110.0)
phase = Constant(0.0)
q = Sine()
w = Sine()
z = Sine()
push!(engine.graph, freq, :out, q, :ν)
push!(engine.graph, phase, :out, q, :θ)
push!(engine.graph, q, :out, w, :ν)
push!(engine.graph, phase, :out, w, :θ)
push!(engine.graph, q, :out, z, :ν)
push!(engine.graph, phase, :out, z, :θ)
push!(engine.graph, z, :out, engine.monomixer, :in)

println(engine.graph.ranks.index)

run(engine)

sleep(20)
#Profile.print()
#sleep(2)
