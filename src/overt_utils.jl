using SymEngine
using MacroTools
import MacroTools.postwalk

# opeartions and functions that are supported in overapproax_nd.jl
special_oper = [:+, :-, :/, :*, :^]
special_func = [:exp, :log, :log10,
                :sin, :cos, :tan,
                :sinh, :cosh, :tanh,
                :asin, :acos, :atan,
                :asinh, :acosh, :atanh]

increasing_special_func = [:exp, :log, :log10,
                         :tan, :sinh, :tanh,
                         :asin, :atan,
                         :asinh, :atanh, :acosh]

N_VARS = 0 # number of variables defined so far; has to be defined globally.

"""
This function returns symbolic variable with proper numbering.
    The counter has to be a global variable.
TODO: remove input; it is not used.
"""
add_var() = add_var(1.)

function add_var(bound)
    global N_VARS
    N_VARS += 1
    return Symbol("v_$N_VARS")
end

function reset_NVARS()
    global N_VARS
    N_VARS = 0
end

function to_pairs(B)
    """
    This function converts the output of overest, a tuple of (x points, y points) in the form ready
        for closed form generator: [(x1,y1), (x2, y2), ...]
    B is an array of points.
    """
    xp,yp = B
    x = vcat(xp...)
    y = vcat(yp...)
    pairs = collect(zip(x,y))
    return pairs
end

# todo: does this do the same thing as SymEngine, free_symbols or Tomer's autoline.get_symbols ?
function find_variables(expr)
    """
    given an expression expr, this function finds all the variables.
    it is useful to identify 1d functions that can be directly implemented
    in the overest algorithm, without any composition hacking.
    Example: find_variables(:(x+1))     = [:x]
             find_variables(:(-x+2y-z)) = [:x, :y, :z]
             find_variables(:(log(x)))  = [:x]
             find_variables(:(x+ x*z))   = [:x, :z]
    """
    all_vars = []
    for arg in expr.args
        if arg isa Expr
            all_vars = vcat(all_vars, find_variables(arg))
        elseif arg isa Symbol
            if !(arg in special_oper) && !(arg in special_func)
                all_vars = vcat(all_vars, arg)
            end
        end
    end
    return unique(all_vars)
end

function is_affine(expr)
    """
    given an expression expr, this function determines if the expression
    is an affine function.

    Example: is_affine(:(x+1))       = true
             is_affine(:(-x+(2y-z))) = true
             is_affine(:(log(x)))    = false
             is_affine(:(x + x*z))   = false
             is_affine(:(x/6))       = true
             is_affine(:(5*x))       = true
             is_affine(:(log(2)*x))  = true
             is_affine(:(-x))        = true
     """
    # it is number
    if is_number(expr)
        return true
    elseif expr isa Symbol # symbol
        return true
    elseif expr isa Expr
        check_expr_args_length(expr)
        func = expr.args[1]
        if func ∉ [:+, :-, :*, :/] # only these operations are allowed
            return false
        else  # func ∈ [:+, :-, :*, :/]
            if func == :* # one of args has to be a number
                option1 =  is_number(expr.args[2]) && is_affine(expr.args[3])
                option2 =  is_number(expr.args[3]) && is_affine(expr.args[2])
                return (option1 || option2)
            elseif func == :/ # second arg has to be a number
                return is_number(expr.args[3])
            else # func is + or -
                return all(is_affine.(expr.args[2:end]))
            end
        end
    else
        return false # if not a number, symbol, or Expr, return false
    end
end

is_outer_affine(s::Symbol) = true
is_outer_affine(r::Real) = true
function is_outer_affine(expr::Expr)
    """
    5*sin(x) - 3*cos(y) is _outer_ affine. It can be re-written:
    5*z - 3*w    where z = sin(x)   w = cos(y)
    """
    if is_number(expr)
        return true
    else
        check_expr_args_length(expr)
        func = expr.args[1]
        if func ∈ [:+, :-]
            # check args
            return all(is_outer_affine.(expr.args[2:end]))
        elseif func == :* # one of args has to be a number
            option1 =  is_number(expr.args[2]) && is_outer_affine(expr.args[3])
            option2 =  is_number(expr.args[3]) && is_outer_affine(expr.args[2])
            return (option1 || option2)
        elseif func == :/ # second arg has to be a number
            return is_number(expr.args[3])
        else
            return false
        end
    end
end

function add_ϵ(points, ϵ)
    `Add ϵ to the y values of all points in a container`
    new_points = []
    for p in points
        push!(new_points, (p[1], p[2] + ϵ))
    end
    return new_points
end

function rewrite_division_by_const(e)
    return e
end
function rewrite_division_by_const(expr::Expr)
    if expr.args[1] == :/ && !is_number(expr.args[2]) && is_number(expr.args[3])
        return :( (1/$(expr.args[3])) * $(expr.args[2]) )
    else
        return expr
    end
end

function find_UB(func, a, b, N; lb=false, digits=nothing, plot=false, existing_plot=nothing, ϵ=0)

    """
    This function finds the piecewise linear upperbound (lowerbound) of
        a given function func in internval [a,b] with N
        sampling points over each concave/convex region.
        see the overest_new.jl for more details.

    Return values are points (UB_points), the min-max closed form (UB_sym)
    as well the lambda function form (UB_eval).
    """

    UB = bound(func, a, b, N; lowerbound=lb, plot=plot, existing_plot=existing_plot)
    UB_points = unique(sort(to_pairs(UB), by = x -> x[1]))
    #println("points: ", UB_points)
    if abs(ϵ) > 0
        UB_points = add_ϵ(UB_points, ϵ) # return new points shifted by epsilon up or down
    end
    #println("points: ", UB_points)
    UB_sym = closed_form_piecewise_linear(UB_points)
    # if !isnothing(digits)
    #     # note this degrades numerical precision, use with care
    #     UB_sym = round_expr(UB_sym)
    # end
    UB_eval = eval(:(x -> $UB_sym))
    return UB_points, UB_sym, UB_eval
end

function find_1d_range(B)
    """
    given a set of points B representing a piecewise linear bound function
        this function finds the range of the bound.
    """

    y_pnts = [point[2] for point in B]
    min_B = minimum(y_pnts)
    max_B = maximum(y_pnts)
    return min_B, max_B
end

function check_expr_args_length(expr)
    if length(expr.args) > 3
        throw(ArgumentError("""
        Operation $(expr.args[1]) has $(length(expr.args)-1) arguments.
        Use parantheses to make this into multiple operations, each with two arguments,
        For example, change (x+y+z)^2 to ((x+y)+z)^2.
                          """))
    end
end

# Think we could use stuff from https://github.com/JuliaIntervals/IntervalArithmetic.jl
# but whose to say if it's better tested?
function find_affine_range(expr, range_dict)
    """
    given a an affine expression expr, this function finds the
        lower and upper bounds of the range.
    """
    @assert is_affine(expr)

    expr isa Symbol ? (return range_dict[expr]) : nothing
    try (return eval(expr), eval(expr)) catch; nothing end # works if expr is a number

    check_expr_args_length(expr)
    all_vars = find_variables(expr)

    if length(all_vars) == 1
        a, b = range_dict[all_vars[1]]
        expr_copy = copy(expr)
        c = eval(substitute!(expr_copy, all_vars[1], a))
        expr_copy = copy(expr)
        d = eval(substitute!(expr_copy, all_vars[1], b))
        return min(c,d), max(c,d)
    end

    func = expr.args[1]
    a, b = find_affine_range(expr.args[2], range_dict)
    c, d = find_affine_range(expr.args[3], range_dict)
    if func == :+
        return (a+c), (b+d)
    elseif func == :-
        return (a-d), (b-c)
    elseif func == :*
        # Does this assume anything about the order of the multiplication being const*variable ?
        try
            a = eval(expr.args[2])
            a > 0 ? (return a*c, a*d) : return a*d, a*c
        catch
            c = eval(expr.args[3])
            c > 0 ? (return c*a, c*b) : (return c*b, c*a)
        end
    elseif func == :/
        c = eval(expr.args[3])
        c > 0 ? (return a/c, b/c) : return( b/c, a/c)
    end
end

mutable struct MyException <: Exception
    var::String
end

function find_range(expr, range_dict)
    """
    Find range of PWL function.
    """
    if is_relu(expr)
        if expr.args[1] == :relu
            inner_expr = expr.args[2]
        elseif expr.args[1] == :max # max with 0
            inner_expr = expr.args[3]
        end
        l,u = find_range(inner_expr, range_dict)
        return [0, max(0, u)]
    elseif is_affine(expr)
        l,u = find_affine_range(expr, range_dict)
        return [l,u]
    elseif is_min(expr)
        x = expr.args[2]
        y = expr.args[3]
        xl, xu = find_range(x, range_dict)
        yl, yu = find_range(y, range_dict)
        return [min(xl,yl), min(xu,yu)]
    else
        throw(MyException("not implemented yet"))
    end
end

function is_relu(expr)
    if length(expr.args) < 2
        return false
    end
    return (expr.args[1] == :max && expr.args[2] == 0.) || expr.args[1] == :relu
end

function is_min(expr)
    return expr.args[1] == :min
end

# todo: pretty sure we can use SymEngine.subs.
# maybe better tested? but subs is also overly complicated...
function substitute!(expr, old, new)

    """
    This function substitutes the old value `old' with the
         new value `new' in the expression expr

    Example: substitute!(:(x^2+1), :x, :(y+1)) = :((y+1)^2+1))
    """

    for (i,arg) in enumerate(expr.args)
       if arg==old
           expr.args[i] = new
       elseif arg isa Expr
           substitute!(arg, old, new)
       end
    end
    return expr
end

function substitute!(expr::Expr, old_list::Vector{Any}, new_list::Array{Any})
    for (k, v) in zip(old_list, new_list)
        substitute!(expr, k, v)
    end
    return expr
end


∉(e, set) = !(e ∈ set)

function reduce_args_to_2(f::Symbol, arguments::Array)
    """
    reduce_args_to_2(x+y) = x+y
    reduce_args_to_2(x+y+z) = x+(y+z)
    reduce_args_to_2(0.5+y+z) = (0.5+y)+z
    """
    if (length(arguments) <= 2) | (f ∉ [:+, :*])
        e = Expr(:call)
        e.args = [f, map(reduce_args_to_2, arguments)...]
        return e
    elseif length(arguments) ==3 #length(args) = 3 and f ∈ [:+, :*]
        if is_number(arguments[1])
            a = reduce_args_to_2(arguments[2])
            fbc = reduce_args_to_2(f, arguments[1:3 .!= 2])
        else
            a = reduce_args_to_2(arguments[1])
            fbc = reduce_args_to_2(f, arguments[2:3])
        end
        return :($f( $a, $fbc))
    else
        first_half = reduce_args_to_2(f, arguments[1:2])
        second_half = reduce_args_to_2(f, arguments[3:end])
        return reduce_args_to_2(f, [first_half, second_half])
        error("""
            operations with more than 3 arguments are not supported.
            use () to break the arguments.
            Example= x+y+z+w -> (x+y) + (y+z)
            """)
    end
end

reduce_args_to_2(x::Number) = x
reduce_args_to_2(x::Symbol) = x

function reduce_args_to_2(expr::Expr)
    #println(expr)
    f = expr.args[1]
    arguments = expr.args[2:end]
    return reduce_args_to_2(f::Symbol, arguments::Array)
end

function is_number(expr)
    try
        eval(expr)
        return true
    catch
        return false
    end
end

function is_unary(expr::Expr)
    # one for function, one for single argument to function
    return length(expr.args) == 2
end

function is_1d(expr::Expr)
    return length(find_variables(expr)) == 1
end


function is_effectively_unary(expr::Expr)
    # has 3 args, but first is function and one of next 2 is a constant
    f = expr.args[1]
    x = expr.args[2]
    y = expr.args[2]
    #TODO: finish
    # if x is_number(expr) hten.... elseif y is_number(expr) then...
    return false # placeholder
end

is_binary(expr::Expr) = length(expr.args) == 3

function multiply_interval(range, constant)
    S = [range[1]*constant, range[2]*constant]
    return [min(S...), max(S...)]
end

simplify(ex::Expr) = postwalk(e -> _simplify(e), ex)
_simplify(s) = s
_simplify(e::Expr) = Meta.parse(string(expand(Basic(e))))

"""
Construct a symbolic expression for a line between the points (x₀, 1.0) on the left and (x₁, 0) on the right.
`pos_unit` has positive slope while `neg_unit` has negative slope. Note that due to the left-to-right assumption

    neg_unit(x₀, x₁) == pos_unit(x₁, x₀)
"""
neg_unit(x0, x1) = :($(1/(x0-x1)) * (x - $x1))
"""
Construct a symbolic expression for a line between the points (x₀, 0.0) on the left and (x₁, 1.0) on the right.
`pos_unit` has positive slope while `neg_unit` has negative slope. Note that due to the left-to-right assumption

    neg_unit(x₀, x₁) == pos_unit(x₁, x₀)
"""
pos_unit(x0, x1) = :($(1/(x1-x0)) * (x - $x0))

"""
    closed_form_piecewise_linear(pts)::Expr

Constructs a closed-form piecewise linear expression from an ordered (left to right) sequence of points.
The method is inspired by the paper by Lum and Chua (cite) that considers a piecewise linear function of the form:
`f(x) = Σᵢ(yᵢ⋅gᵢ(xᵢ))` where `gᵢ(xⱼ) = δᵢⱼ`
Here in the 1D case, `gᵢ = max(0, yᵢ*min(L1, L2))`, where `L1` and `L2` are the lines "ramping up" towards xᵢ
and "ramping down" away from xᵢ. The function returns an `Expr` based on a variable `x`.
This can be turned into a callable function `f` by running something like `eval(:(f(x) = \$expression_of_x))`.

# Example
    julia> pts = [(0,0), (1,1), (2, 0)]
    3-element Array{Tuple{Int64,Int64},1}:
     (0, 0)
     (1, 1)
     (2, 0)

    julia> closed_form_piecewise_linear(pts)
    :(max(0, 0 * (-1.0 * (x - 1))) + max(0, 1 * min(1.0 * (x - 0), -1.0 * (x - 2))) + max(0, 0 * (1.0 * (x - 1))))
"""
function closed_form_piecewise_linear(pts)
    n = length(pts)
    x, y = first.(pts), last.(pts) # split the x and y coordinates
    G = []
    for i in 2:n-1
        x0, x1, x2 = x[i-1:i+1] # consider the "triangulation" of points x0,x1,x2
        L1 = pos_unit(x0, x1) # x0-x1 is an increasing linear unit
        L2 = neg_unit(x1, x2) # x1-x2 is a decreasing linear unit
        gᵢ = :($(y[i]) * max(0, min($L1, $L2)))
        push!(G, gᵢ)
    end
    # first and last points are special cases that ignore the min
    g₀ = :($(y[1]) * max(0, $(neg_unit(x[1], x[2]))))
    gᵣ = :($(y[end]) * max(0, $(pos_unit(x[end-1], x[end]))))
    # Order doesn't matter now but for our debugging purposes earlier we enforce sequential ordering.
    pushfirst!(G, g₀)
    push!(G, gᵣ)
    return :(+$(G...))
end


function get_symbols(ex::Union{Expr, Symbol})
    syms = Symbol[]
    ops = (:*, :+, :-, :relu)
    postwalk(e -> e isa Symbol && e ∉ ops ? push!(syms, e) : nothing, ex)
    unique(syms)
end
