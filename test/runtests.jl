if VERSION < v"0.5.0-dev"
    using BaseTestNext
else
    using Base.Test
end
using ExpressionUtils

include("functions.jl")
include("utils.jl")
