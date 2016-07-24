@testset "Functions" begin
    ex1 = :(f(x) = 1)
    ex2 = :(@inline f(x) = 1)
    ex3 = :(Base.@pure @inline f(x) = 1)
    ex4 = quote
        f(x) = 1
    end
    ex5 = :(function f(x) 1 end)
    ex6 = quote
        function f(x)
            1
        end
    end
    ex7 = quote
        @inline function f(x)
            1
        end
    end
    ex8 = :(immutable NotAFunction end)

    for ex in (ex1, ex5)
        @test is_funcdef_expr(ex)
    end
    for ex in (ex2, ex3, ex4, ex6, ex7, ex8)
        @test !is_funcdef_expr(ex)
    end
    for (ex,contains) in ((ex1,false), (ex2,true), (ex3,true), (ex4,true),
                          (ex5,false), (ex6,true), (ex7,true))
        def, c, container = get_funcdef_expr(ex)
        @test c == contains
        @test is_funcdef_expr(def)
        @test isa(container, Expr)
        if contains
            @test container.args[end] === def
        end
        lf = funcdef_longform(def)
        @test lf.head == :function
    end
    @test_throws ArgumentError get_funcdef_expr(ex8)
    def, c, container = get_funcdef_expr(ex8, false)
    @test isa(def, Expr)
    @test !is_funcdef_expr(def)
end
