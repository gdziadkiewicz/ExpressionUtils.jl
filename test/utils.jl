facts("Expression destructuring") do

    context("expr_bindings") do

        @fact expr_bindings(:(x = 5), :(x = _val_)) --> Dict(:_val_ => 5)
        @fact expr_bindings(:(x = 5), :(_sym_ = 5)) --> Dict(:_sym_ => :x)
        @fact expr_bindings(:(x = 5), :_ex_) --> Dict(:_ex_ => :(x = 5))

        splatex = Expr(:let, :_body_, :_SPLAT_bindings_)
        ex = :(let x=1, y=2, z=3
                   x + y
                   y + z
               end)

        bindings = expr_bindings(ex, splatex)

        @fact haskey(bindings, :_body_) --> true
        @fact haskey(bindings, :_bindings_) --> true
        @fact bindings[:_body_] --> body -> isa(body, Expr) && body.head == :block
        @fact bindings[:_bindings_] --> b -> isa(b, Array) && length(b) == 3
    end

    context("expr_replace") do

        ex = quote
            let x, y, z
                bar
                x + y
                y + z
            end
        end

        template = quote
            let _SPLAT_bindings_
                _funname_
                _SPLAT_body_
            end
        end

        out = quote
            function _funname_( _UNSPLAT_bindings_)
                _UNSPLAT_body_
            end
        end

        foofun = expr_replace(ex, template, out)
        eval(foofun)
        @fact foofun.head --> :function
        @fact eval(foofun)(1,2,3) --> 5
        @fact bar(1,2,3) --> 5
    end

end
