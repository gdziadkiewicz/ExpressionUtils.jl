"""
    get_funcdef_expr(ex::Expr[, throws=true]) -> def::Expr, isinside::Bool, container::Expr

Given an expression `ex` that contains a single function definition,
return the "inner" expression `def` defining the function.  `def` may
be `ex`, or it may be `ex` stripped of "trivial" (single-expression)
`Expr(:block, ...)` wrappers or any macro calls such as `@inline` . If
container expressions are found, `isinside` will be `true` and
`container` will be the immediate "parent expression" of `def`---if
you rewrite `def`, then you should stash the result in the last of
`container`'s `args`.

If `throws = true` and the expression does not correspond to a
single function definition, an ArgumentError will be thrown.  When
`throws = false`, you should check `def` manually using
`is_funcdef_expr`.

# Examples:

```julia
julia> ex = :(foo(x) = 1)

julia> def, isinside, container = get_funcdef_expr(ex);

julia> def
:(foo(x) = begin
            1
        end)

julia> isinside
false

julia> container
quote
    nothing
end

julia> ex = quote
Base.@pure @inline function foo{T}(::Type{T})
    false
end
end

julia> def, isinside, container = get_funcdef_expr(ex);

julia> def
:(function foo{T}(::Type{T})
        false
    end)

julia> isinside
true

julia> container
:(@inline function foo{T}(::Type{T})
            false
        end)
"""
function get_funcdef_expr(ex::Expr, throws::Bool=true)
    def = ex
    isinside = false
    container = Expr(:block, nothing)
    while (def.head == :macrocall && isa(def.args[end], Expr)) || is_trivial_block_wrapper(def)
        container = def
        def = def.args[end]::Expr
        isinside = true
    end
    if throws && !is_funcdef_expr(def)
        throw(ArgumentError(string("expected function expression, got ", def)))
    end
    def, isinside, container
end

"""
    is_funcdef_expr(ex)

Return `true` if `ex` is an expression defining a function, either the
"long form" (`function`) or "short form" (`f(x) = 1`).

`ex` must be "stripped" of any macro calls or `Expr(:block, ...)`
wrappers; see `get_funcdef_expr`.
"""
function is_funcdef_expr(ex::Expr)
    ex.head == :function ||
        (ex.head == :(=) && isa(ex.args[1], Expr) && (ex.args[1]::Expr).head == :call)
end
is_funcdef_expr(arg::ANY) = false

"""
    funcdef_longform(ex)

Cannonicalizes a function-definition expression to "long form," like
```julia
function f(x)
    x^2
end
```
rather than
```julia
f(x) = x^2
```
Such expressions have head `:function` and two `args`, corresponding
to the signature and body, respectively.  In the returned expression,
the body is guaranteed to be a `:block` expression.
"""
function funcdef_longform(ex::Expr)
    if ex.head == :function
        return ex
    end
    if ex.head == :(=) && isa(ex.args[1], Expr) && (ex.args[1]::Expr).head == :call
        sig::Expr = ex.args[1]
        if !isa(ex.args[2], Expr)
            return Expr(:function, sig, Expr(:block, ex.args[2]))
        end
        body::Expr = ex.args[2]
        if body.head != :block
            body = Expr(:block, body)
        end
        return Expr(:function, sig, body)
    end
    throw(ArgumentError(string("expected a function definition, got ", ex)))
end
