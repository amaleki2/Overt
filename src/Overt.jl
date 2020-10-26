module Overt

include("overt_utils.jl")
include("overt_1d.jl")
include("overt_nd.jl")
include("overt_parser.jl")

export OverApproximationParser,
       OverApproximation,
       overapprox_nd,
       add_overapproximate,
       bound,
       parse_bound,
       change_plotflag!,
       print_overapproximateparser
end
