typealias Sample Float64
typealias Time Float64
typealias Beat Float64
typealias Tempo Float64
typealias Amplitude Float64
typealias AudioChannel Int
typealias AudioSignal Function
typealias AudioControl Union{AudioSignal,
                             Signal{Float64},
                             Signal{Array{Float64}},
                             Float64}
