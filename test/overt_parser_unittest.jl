using Overt, Test

oa = overapprox_nd(:(sin(x + y)/y), Dict(:x=>[2,3], :y=>[1,2]))

oAP = OverApproximationParser();

parse_bound(oa, oAP);

#print_overapproximateparser(oAP);

state_vars = [:x]
control_vars = [:y]
output_vars = [:x]


# these one should pass
Overt.assert_expr(:(w == 2x + 3.4y +1z), "eq")
Overt.assert_expr(:(w == max(0, x)), "eq")
Overt.assert_expr(:(w == min(x, y)), "eq")
Overt.assert_expr(:(x5 ≦ y1), "ineq")
Overt.assert_expr(:(w == 2max(0, x) + 3max(0,y)), "max")
Overt.assert_expr(:(w == 2max(0, x) + 3max(0, min(2z,t-1))), "max")
Overt.assert_expr(:(w == max(0, x)), "single max")
Overt.assert_expr(:(w == max(0, min(2z,t-1))), "single max")
Overt.assert_expr(:(w == min(x,-y)), "single min")
Overt.assert_expr(:(w == 2x-1), "linear")

# these one should NOT pass
# assert_expr(:(2x + 3.4y + 2z), "eq") # missing w == ...
# assert_expr(:(w==2x + 3.4y^2 -z), "eq") # squared term
# assert_expr(:(-x ≦ y), "ineq") # either sides should be symbols and not expressions
# assert_expr(:(w == 2max(y, x) + 3max(0,y)), "max") # max constraints are always relu.
# assert_expr(:(w == max(0, x)), "max") # this is a single max.
# assert_expr(:(w == max(x, 0)), "single max") # first max argument should be 0.
# assert_expr(:(w == 2max(0, min(2z,t-1))), "single max") # single max does not have a coefficient.
# assert_expr(:(w == min(x+y)), "linear")
# assert_expr(:(w == 2max(x, 3) + 3max(min(x,-y), min(2z,t-1))), "single max")
# assert_expr(:(w == max(x,y)), "single max")
# assert_expr(:(w == 2x-y+1.5z), "linear")

# """ other tests """
oAP_test = OverApproximationParser()
Overt.parse_ineq(:(x ≦ y), oAP_test)
@test oAP_test.ineq_list[1].varleft == :x
@test oAP_test.ineq_list[1].varrite == :y

oAP_test = OverApproximationParser()
Overt.parse_single_max_expr(:(y == max(0, x)), oAP_test)
@test oAP_test.relu_list[1].varin == :x
@test oAP_test.relu_list[1].varout == :y
@test oAP_test.max_list == []

oAP_test = OverApproximationParser()
Overt.parse_linear_expr(:(z == 2x+4y), oAP_test)
@test oAP_test.eq_list[1].vars == [:x, :y, :z]
@test oAP_test.eq_list[1].coeffs == [-2, -4, 1]
@test oAP_test.eq_list[1].scalar == 0

oAP_test = OverApproximationParser()
Overt.parse_linear_expr(:(z == -2x+1), oAP_test)
@test oAP_test.eq_list[1].vars == [:x, :z]
@test oAP_test.eq_list[1].coeffs == [2, 1]
@test oAP_test.eq_list[1].scalar == 1

oAP_test = OverApproximationParser()
Overt.parse_linear_expr(:(z == -2x-2y-2), oAP_test)
@test oAP_test.eq_list[1].vars == [:x, :y, :z]
@test oAP_test.eq_list[1].coeffs == [2, 2, 1]
@test oAP_test.eq_list[1].scalar == -2

# TODO figure what is wrong with these tests

# oAP_test = OverApproximationParser()
# parse_single_max_expr(:(z == max(0, min(3x-1, 2y))), oAP_test)
# @assert length(oAP_test.relu_list) == 1
# @assert length(oAP_test.max_list) == 1
# @assert length(oAP_test.eq_list) == 3

# oAP_test = OverApproximationParser()
# parse_max_expr(:(z == 3*max(0,y) + 2*max(0, min(3x-1, 2y))), oAP_test)
# @assert length(oAP_test.relu_list) == 2
# @assert length(oAP_test.max_list) == 1
# @assert length(oAP_test.eq_list) == 4

# oAP_test = OverApproximationParser()
# parse_single_min_expr(:(z == min(y, x)), oAP_test)
# @assert length(oAP_test.relu_list) == 0
# @assert length(oAP_test.max_list) == 1
# @assert length(oAP_test.eq_list) == 3

print("overt_parser tests passed.")
