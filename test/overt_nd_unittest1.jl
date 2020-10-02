using Overt
using Test

# test for find_variables
@test Overt.find_variables(:(x+1)) == [:x]
@test Overt.find_variables(:(log(x + y*z))) == [:x, :y, :z]

# test for is_affine
@test Overt.is_affine(:(x+1)) == true
@test Overt.is_affine(:(-x+(2y-z))) == true
@test Overt.is_affine(:(log(x))) == false
@test Overt.is_affine(:(x+ xz)) == true # interprets xz as one variable
@test Overt.is_affine(:(x+ x*z)) == false
@test Overt.is_affine(:(x + y*log(2))) == true

# test for is_1d
@test Overt.is_1d(:(x*log(2))) == true
@test Overt.is_1d(:(x^2.5)) == true

# test for is_unary
@test Overt.is_unary(:(x+y)) == false
@test Overt.is_unary(:(x^2.5)) == false # this is like pow(x, 2.5), hence not unary. is taken care of in is_1d
@test Overt.is_unary(:(sin(x))) == true
@test Overt.is_unary(:(x*y)) == false

# test find_affine_range
@test Overt.find_affine_range(:(x + 1), Dict(:x => (0, 1))) == (1,2)
@test Overt.find_affine_range(:(- x + 1), Dict(:x => (0, 1))) == (0,1)
@test Overt.find_affine_range(:((-1 + y) + x), Dict(:x => (0,1), :y => (1,2))) == (0,2)
@test Overt.find_affine_range(:(2*x), Dict(:x => (0,1))) == (0,2)
@test Overt.find_affine_range(:(x*2), Dict(:x => (0,1))) == (0,2)

# test substitute
@test Overt.substitute!(:(x^2+1), :x, :(y+1)) == :((y+1)^2+1)

# test upperbound_expr_compositions
# need clarity on precise purpose and signature of the function

# test reduce_args_to_2!
@test Overt.reduce_args_to_2(:(x+y+z)) == :(x+(y+z))
@test Overt.reduce_args_to_2(:(sin(x*y*z))) == :(sin(x*(y*z)))
# bug ^ doesn't seem to modify sin(x*y*z)

print("overt_nd unit test 1 passed.")
