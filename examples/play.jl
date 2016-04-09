using Violet, Benchmarks
engine = Engine()

freq = Violet.constant(110.0)
phase = Violet.constant(0.0)
q = Violet.sine()
w = Violet.sine()
z = Violet.sine()
push!(engine.graph, freq, 1, q, 1)
push!(engine.graph, phase, 1, q, 2)
push!(engine.graph, q, 1, w, 1)
push!(engine.graph, phase, 1, w, 2)
push!(engine.graph, q, 1, z, 1)
push!(engine.graph, phase, 1, z, 2)
push!(engine.graph, z, 1, engine.monomixer, 1)

println(engine.graph.ranks.index)

run(engine)

sleep(20)
#Profile.print()
#sleep(2)
