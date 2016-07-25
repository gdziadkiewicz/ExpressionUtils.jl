@testset "Expression destructuring"  begin

    @testset "expr_bindings" begin

        @test expr_bindings(:(x = 5), :(x = _val_)) == Dict(:_val_ => 5)
        @test expr_bindings(:(x = 5), :(_sym_ = 5)) == Dict(:_sym_ => :x)
        @test expr_bindings(:(x = 5), :_ex_) == Dict(:_ex_ => :(x = 5))

        splatex = Expr(:let, :_body_, :_SPLAT_bindings_)
        ex = :(let x=1, y=2, z=3
                   x + y
                   y + z
               end)

        bindings = expr_bindings(ex, splatex)
        body = bindings[:_body_]
        b = bindings[:_bindings_]

        @test haskey(bindings, :_body_)
        @test haskey(bindings, :_bindings_)
        @test isa(body, Expr) && body.head == :block
        @test isa(b, Array) && length(b) == 3
    end

    @testset "expr_replace"  begin

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

        @test foofun.head == :function
        @test eval(foofun)(1,2,3) == 5
        @test bar(1,2,3) == 5
    end

end
