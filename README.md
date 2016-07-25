## Expression Utilities
Windows: [![Build status](https://ci.appveyor.com/api/projects/status/c9hibcda8b728daa?svg=true)](https://ci.appveyor.com/project/gdziadkiewicz/expressionutils-jl)


Linux, IOS: [![Build Status](https://travis-ci.org/gdziadkiewicz/ExpressionUtils.jl.svg?branch=master)](https://travis-ci.org/gdziadkiewicz/ExpressionUtils.jl)

Useful functions for working with the Julia `Expr` type.

### High level utilities

#### `map(f::Function, e::Expr)`

Constructs a new expression similar to `e`, but having had the function
`f` applied to every leaf.

```.jl
julia> map(x -> isa(x, Int) ? x + 1 : x, :(1 + 1))
# => :(+(2,2))
```

#### `walk(f::Function, e::Expr)`

Recursively walk an expression, applying a function `f` to each
subexpression and leaf in `e`. If the function application returns an
expression, that expression will be walked as well. The function can
return the special type `ExpressionUtils.Remove` to indicate that a
subexpression should be omitted.

```.jl
julia> b = quote
         let x=1, y=2, z=3
           x + y + z
         end
       end
# => quote  # none, line 2:
#        let x = 1, y = 2, z = 3 # line 3:
#            x + y + z
#        end
#    end

julia> remove_line_nodes(node::LineNumberNode) = ExpressionUtils.Remove
# remove_line_nodes (generic function with 1 method)
julia> remove_line_nodes(ex) = ex
# remove_line_nodes (generic function with 2 methods)

julia> walk(remove_line_nodes, b)
# => quote
#        let x = 1, y = 2, z = 3
#            x + y + z
#        end
#    end
```

#### `expr_replace(ex, template, out)`

Syntax rewriting!

```.jl
julia> ex = quote
           let x, y, z
               bar
               x + y
               y + z
           end
       end

julia> template = quote
           let _SPLAT_bindings_
               _funname_
               _SPLAT_body_
           end
       end

julia> out = quote
           function _funname_( _UNSPLAT_bindings_)
               _UNSPLAT_body_
           end
       end

julia> fnexpr = expr_replace(ex, template, out)
# => :(function bar(x, y, z)
#          x + y
#          y + z
#      end)

julia> eval(fnexpr)
# bar (generic function with 1 method)

julia> bar(1, 2, 3)
# => 5
```

Plays well with macros. See
[ValueDispatch.jl](https://github.com/gdziadkiewicz/ValueDispatch.jl)
for another example.

### Low-level utilities

#### Functions definition expressions

This package contains a range of utilities for working with
expressions that contain function definitions. Each of these has its
own docstring that goes into detail, so here is just a summary:

- `is_funcdef_expr` tests whether an expression is a function definition
- `get_funcdef_expr` returns the "inner" function definition
  expression, even if wrapped inside an `@inline` or `:block`
  expression
- `funcdef_longform` cannonicalizes function definition expressions
- `funcdef_name` returns the function's name Symbol
- `funcdef_params` returns the vector of parameters for a parametric function
- `funcdef_args` returns the vector of arguments (names + type declarations)
- `funcdef_argnames` returns the vector of argument names (Symbols)
- `funcdef_argtypeexprs` returns the vector of argument type declarations
