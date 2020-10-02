using Overt
using Test

@testset "Overt" begin
    include("overt_nd_unittest1.jl")
    include("overt_nd_unittest2.jl")
    include("overt_parser_unittest.jl")
end
