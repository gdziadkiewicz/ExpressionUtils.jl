"""
    is_trivial_block_wrapper(ex)

Returns `true` if `ex` is a "trivial" `:block` expression.  This means
that it has one or two `args`; if two, the first must represent line
number information or be `nothing`.
"""
function is_trivial_block_wrapper(ex::Expr)
    if ex.head == :block
        return length(ex.args) == 1 ||
            (length(ex.args) == 2 && (is_linenumber(ex.args[1]) || ex.args[1]===nothing))
    end
    false
end
is_trivial_block_wrapper(arg::ANY) = false

function is_linenumber(stmt::ANY)
    (isa(stmt, Expr) && (stmt::Expr).head == :line) || isa(stmt, LineNumberNode)
end
