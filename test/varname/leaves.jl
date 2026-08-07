module VarNameLeavesTests

using VarNames
using Test
using LinearAlgebra: LowerTriangular, UpperTriangular, cholesky

@testset "varname/leaves.jl" verbose = true begin
    @testset "single value: float, int" begin
        x = 1.0
        @test Set(varname_leaves(@vn(x), x)) == Set([@vn(x)])
        @test Set(collect(varname_and_value_leaves(@vn(x), x))) ==
              Set([(@vn(x), x)])
        x = 2
        @test Set(varname_leaves(@vn(x), x)) == Set([@vn(x)])
        @test Set(collect(varname_and_value_leaves(@vn(x), x))) ==
              Set([(@vn(x), x)])
    end

    @testset "Vector" begin
        x = randn(2)
        @test Set(varname_leaves(@vn(x), x)) == Set([@vn(x[1]), @vn(x[2])])
        @test Set(collect(varname_and_value_leaves(@vn(x), x))) ==
              Set([(@vn(x[1]), x[1]), (@vn(x[2]), x[2])])
        x = [(; a=1), (; b=2)]
        @test Set(varname_leaves(@vn(x), x)) ==
              Set([@vn(x[1].a), @vn(x[2].b)])
        @test Set(collect(varname_and_value_leaves(@vn(x), x))) ==
              Set([(@vn(x[1].a), x[1].a), (@vn(x[2].b), x[2].b)])
    end

    @testset "Matrix" begin
        x = randn(2, 2)
        @test Set(varname_leaves(@vn(x), x)) == Set([
            @vn(x[1, 1]),
            @vn(x[1, 2]),
            @vn(x[2, 1]),
            @vn(x[2, 2])
        ])
        @test Set(collect(varname_and_value_leaves(@vn(x), x))) == Set([
            (@vn(x[1, 1]), x[1, 1]),
            (@vn(x[1, 2]), x[1, 2]),
            (@vn(x[2, 1]), x[2, 1]),
            (@vn(x[2, 2]), x[2, 2]),
        ])
    end

    @testset "Lower/UpperTriangular" begin
        x = randn(2, 2)
        xl = LowerTriangular(x)
        @test Set(varname_leaves(@vn(x), xl)) ==
              Set([@vn(x[1, 1]), @vn(x[2, 1]), @vn(x[2, 2])])
        @test Set(collect(varname_and_value_leaves(@vn(x), xl))) == Set([
            (@vn(x[1, 1]), x[1, 1]),
            (@vn(x[2, 1]), x[2, 1]),
            (@vn(x[2, 2]), x[2, 2]),
        ])
        xu = UpperTriangular(x)
        @test Set(varname_leaves(@vn(x), xu)) ==
              Set([@vn(x[1, 1]), @vn(x[1, 2]), @vn(x[2, 2])])
        @test Set(collect(varname_and_value_leaves(@vn(x), xu))) == Set([
            (@vn(x[1, 1]), x[1, 1]),
            (@vn(x[1, 2]), x[1, 2]),
            (@vn(x[2, 2]), x[2, 2]),
        ])
    end

    @testset "NamedTuple" begin
        x = (a=1.0, b=[2.0, 3.0])
        @test Set(varname_leaves(@vn(x), x)) ==
              Set([@vn(x.a), @vn(x.b[1]), @vn(x.b[2])])
        @test Set(collect(varname_and_value_leaves(@vn(x), x))) == Set([
            (@vn(x.a), x.a),
            (@vn(x.b[1]), x.b[1]),
            (@vn(x.b[2]), x.b[2]),
        ])
    end

    @testset "Cholesky" begin
        x = cholesky([1.0 0.5; 0.5 1.0])
        @test Set(varname_leaves(@vn(x), x)) ==
              Set([@vn(x.U[1, 1]), @vn(x.U[1, 2]), @vn(x.U[2, 2])])
        @test Set(collect(varname_and_value_leaves(@vn(x), x))) == Set([
            (@vn(x.U[1, 1]), x.U[1, 1]),
            (@vn(x.U[1, 2]), x.U[1, 2]),
            (@vn(x.U[2, 2]), x.U[2, 2]),
        ])
    end

    @testset "fallback on other types, e.g. string" begin
        x = "a string"
        @test Set(varname_leaves(@vn(x), x)) == Set([@vn(x)])
        @test Set(collect(varname_and_value_leaves(@vn(x), x))) ==
              Set([(@vn(x), x)])
        x = 2
        @test Set(varname_leaves(@vn(x), x)) == Set([@vn(x)])
        @test Set(collect(varname_and_value_leaves(@vn(x), x))) ==
              Set([(@vn(x), x)])
    end
end

end # module
