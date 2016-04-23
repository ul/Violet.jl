typealias Sample Float64
typealias Time Float64
typealias Beat Float64
typealias Tempo Float64
typealias Amplitude Float64
typealias Pitch Float64
typealias Frequency Float64
typealias AudioChannel Int
typealias AudioSignal Function
typealias AudioControl Union{AudioSignal,
                             Signal{Sample},
                             Signal{Vector{Sample}},
                             Vector{Sample},
                             Sample}
