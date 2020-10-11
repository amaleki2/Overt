# Overt

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://sisl.github.io/Overt.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://sisl.github.io/Overt.jl/dev)
[![Build Status](https://travis-ci.com/sisl/Overt.jl.svg?branch=master)](https://travis-ci.com/sisl/Overt.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/sisl/Overt.jl?svg=true)](https://ci.appveyor.com/project/sisl/Overt-jl)
[![Coverage](https://codecov.io/gh/sisl/Overt.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/sisl/Overt.jl)


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
```
using Overt

func = :(sin(x + y) * exp(z))
range_dict = Dict(:x => [1., 2.], :y => [-1., 1.], :z => [0., 1.])
o1 = overapprox_nd(func, range_dict)

```
---
## Reference

- [1] "*Safety Verification of Neural Network Policies for Nonlinear Systems*", Sidrane et al. (2020) [link](some link)
- [2] *OvertVerify* [link](some link)
