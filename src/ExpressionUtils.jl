module ExpressionUtils

using Compat

export is_funcdef_expr, get_funcdef_expr, funcdef_longform
export funcdef_name, funcdef_params, funcdef_args, funcdef_argnames, funcdef_argtypeexprs
export walk, expr_replace, expr_bind, expr_bindings

include("blocks.jl")
include("functions.jl")
include("utils.jl")

end
