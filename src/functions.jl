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

"""
    funcdef_name(sig)

Return the function's Symbol given a signature expression `sig`. `sig`
is the first argument of the function definition expression.
"""
function funcdef_name(sig::Expr)
    sig.head == :call || throw(ArgumentError(string("expected call expression, got ", sig)))
    decl = sig.args[1]
    isa(decl, Symbol) && return decl::Symbol
    if isa(decl, Expr) && (decl::Expr).head == :curly
        return ((decl::Expr).args[1])::Symbol
    end
    throw(ArgumentError(string("unexpected call expression ", sig)))
end

"""
    funcdef_params(sig)

Return a Vector{Any} of the function's parameters (the part inside the
curlies) given a signature expression `sig`. `sig` is the first
argument of the function definition expression.

The elements of the return may be Symbols or Exprs, where the latter
is used for expressions like `T<:Integer`.
"""
function funcdef_params(sig::Expr)
    sig.head == :call || throw(ArgumentError(string("expected call expression, got ", sig)))
    ret = []
    decl = sig.args[1]
    isa(decl, Symbol) && return ret
    if isa(decl, Expr) && (decl::Expr).head == :curly
        for i = 2:length((decl::Expr).args)
            push!(ret, (decl::Expr).args[i])
        end
        return ret
    end
    throw(ArgumentError(string("unexpected call expression ", sig)))
end

"""
    funcdef_args(sig)

Return a Vector{Any} of the function's argument expressions, which
includes both the variable name and any type declaration, if any.

The elements of the return may be Symbols or Exprs, where the latter
is used for expressions like `x::Integer`.

See also `funcdef_argnames` and `funcdef_argtypes`.
"""
function funcdef_args(sig::Expr)
    sig.head == :call || throw(ArgumentError(string("expected call expression, got ", sig)))
    return sig.args[2:end]
end

"""
    funcdef_argnames(sig)

Return a vector of the function's argument names.  These are typically
Symbols, except for non-canonical syntax like that of Traitor.jl.

See also `funcdef_args` and `funcdef_argtypeexprs`.
"""
function funcdef_argnames(sig::Expr)
    sig.head == :call || throw(ArgumentError(string("expected call expression, got ", sig)))
    return [argname(a) for a in sig.args[2:end]]
end

argname(s::Symbol) = s
function argname(ex::Expr)
    ex.head == :(::) || throw(ArgumentError("expected :(::) expression, got ", ex))
    ex.args[1]
end

"""
    funcdef_argtypeexprs(sig)

Return a vector of the function's argument type expressions.  These
may be Symbols (`:Int`) or expressions (`AbstractArray{T}`).

See also `funcdef_args` and `funcdef_argnames`.
"""
function funcdef_argtypeexprs(sig::Expr)
    sig.head == :call || throw(ArgumentError(string("expected call expression, got ", sig)))
    return [argtypeexpr(a) for a in sig.args[2:end]]
end

argtypeexpr(s::Symbol) = :Any
function argtypeexpr(ex::Expr)
    ex.head == :(::) || throw(ArgumentError("expected :(::) expression, got ", ex))
    ex.args[2]
end
