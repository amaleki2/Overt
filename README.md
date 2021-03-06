# Overt

<!-- [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://sisl.github.io/Overt.jl/stable) -->
[![Build Status](https://travis-ci.com/sisl/Overt.jl.svg?branch=master)](https://travis-ci.com/sisl/Overt.jl)
[![Coverage](https://codecov.io/gh/sisl/Overt.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/sisl/Overt.jl)
<!-- [![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://sisl.github.io/Overt.jl/dev) -->
<!-- [![Build Status](https://ci.appveyor.com/api/projects/status/github/sisl/Overt.jl?svg=true)](https://ci.appveyor.com/project/sisl/Overt-jl) -->

This repo contains a julia implementation for the Overt algorithm, as part of [1]. Overt provides a relational piecewise linear over-approximation of any multi-dimensional functions. The over-approximation is useful for verifying systems with non-linear dynamics. In particular, we used Overt for verifying non-linear dynamical systems that are controlled by neural networks. Check out OvertVerify package [2] for more details

Output of Overt is a list of equality and inequality constraints that may include non-linear operations like `min` and `max`. Overt is guaranteed to identify the tightest linear piecewise over-approximation. In addition, Overt algorithm has a linear complexity, as the function dimension grows.

## Dependency
Overt is tested with `julia 1.x` and `Ubuntu 18`, `Windows 10` operating systems. The following packages are required for Overt:
```
Interpolations = "0.12"
NLsolve = "4.4"
Roots = "1.0"
SymEngine = "0.8"
Plots = "1.6"
Calculus = "0.5"
MacroTools = "0.5"
```

## Installation
```
]
add https://github.com/sisl/Overt.jl
```


## Usage
```julia
using Overt

func = :(sin(x + y) * exp(z))
range_dict = Dict(:x => [1., 2.], :y => [-1., 1.], :z => [0., 1.])
o1 = overapprox_nd(func, range_dict)

```
The output is
```julia
output = v_24
v_1 == x + y
v_2 == 0.01 * max(0, -1.006 (v_1 - 0.994)) + 1.004 max(0, min(1.006 (v_1 - 0.0), -0.883 (v_1 - 2.126))) + 1.015 max(0, min(0.883 (v_1 - 0.994), -1.144 (v_1 - 3.0))) + 0.151max(0, 1.145 (v_1 - 2.126))
v_3 == -0.01 max(0, -0.923 (v_1 - 1.083)) + 0.873 max(0, min(0.923 (v_1 - 0.0), -1.130 (v_1 - 1.968))) + 0.912 max(0, min(1.130 (v_1 - 1.083), -0.970 (v_1 - 3.0))) + 0.131 max(0, 0.967 (v_1 -1.967))
v_5 == 1.01 max(0, -2.691 (z - 0.371)) + 1.46 max(0, min(2.69 (z - 0.0), -3.02(z - 0.702))) + 2.028 max(0, min(3.024 (z - 0.37), -3.35 (z - 1.0))) + 2.72 max(0, 3.357 (z - 0.702))
v_6 == 0.99 max(0, -3.387 (z - 0.295)) + 1.28 max(0, min(3.387 (z - 0.0), -2.03 (z - 0.788))) + 2.132 max(0, min(2.028
(z - 0.295), -4.72(z - 1.0))) + 2.708 max(0, 4.72 (z - 0.788))
v_8 == (v_4 - -0.01) / 1.025 + 0.1
v_9 == (v_7 - 0.99) / 1.738+ 0.1
v_10 == -2.292 max(0, -11.258 (v_8 - 0.19)) -1.404 max(0, min(11.259 (v_8 - 0.1), -2.138(v_8 - 0.657))) -0.298 max(0, min(2.13 (v_8 - 0.189), -2.255 (v_8 - 1.1))) + 0.105 max(0, 2.255(v_8 - 0.656))
v_11 == -2.31max(0, -5.60 (v_8 - 0.278)) -1.289 max(0, min(5.60 (v_8 - 0.1), -3.129 (v_8 - 0.598))) -0.524 max(0, min(3.129 (v_8 - 0.278), -1.992(v_8 - 1.1))) + 0.0853 max(0, 1.99 (v_8 - 0.598))
v_13 == -2.292 max(0, -11.258 (v_9 - 0.189)) -1.404 max(0, min(11.258 (v_9 - 0.1), -2.138 (v_9 - 0.656))) -0.298 max(0, min(2.138 (v_9 - 0.189), -2.255 (v_9 - 1.1))) + 0.105 max(0, 2.255 (v_9 - 0.657))
v_14 == -2.312 max(0, -5.603 (v_9 - 0.278)) -1.288 max(0, min(5.603 (v_9 - 0.1), -3.129 (v_9 - 0.598))) -0.524 max(0, min(3.129 (v_9 - 0.278), -1.99 (v_9 - 1.1))) + 0.085 max(0, 1.99 (v_9 - 0.598))
v_16 == v_12 + v_15
v_17 == 0.0198 max(0, -0.398 (v_16+2.115)) + 0.130 max(0, min(0.398 (v_16 +4.625), -0.725 (v_16 + 0.736))) + 0.488 max(0, min(0.725(v_16 + 2.115), -1.056 (v_16 - 0.210))) + 1.244 max(0, 1.056(v_16 +0.736))
v_18 == 0.024 max(0, min(0.397 (v_16 +4.625), -0.566 (v_16+0.340))) + 0.544 max(0, min(0.566 (v_16 + 2.106), -1.814 (v_16 - 0.211))) + 1.224 max(0, 1.814(v_16 + 0.340))
v_20 == 1.783v_19
v_21 == -0.191v_9
v_22 == v_20 + v_21
v_23 == 0.913v_8 - 0.098
v_24 == v_22 + v_23
v_3 ≦ v_4
v_4 ≦ v_2
v_6 ≦ v_7
v_7 ≦ v_5
v_11 ≦ v_12
v_12 ≦ v_10
v_14 ≦ v_15
v_15 ≦ v_13
v_18 ≦ v_19
v_19 ≦ v_17
```

## Reference

- [1] "*Safety Verification of Neural Network Policies for Nonlinear Systems*", Sidrane et al. (2020) [link](some link)
- [2] *OvertVerify* [link](https://github.com/sisl/OvertVerify.jl)
