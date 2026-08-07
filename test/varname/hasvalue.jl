module VarNameHasValueTests

using VarNames
using DimensionalData: DimensionalData as DD
using Test

@testset "canview" begin
    @testset "Vector" begin
        x = [1, 2, 3]
        @test canview(@opticof(_[1]), x)
        @test canview(@opticof(_[2]), x)
        @test canview(@opticof(_[1:2]), x)
        @test canview(@opticof(_[:]), x)
        @test !canview(@opticof(_[4]), x)
        @test !canview(@opticof(_[2:4]), x)
    end

    @testset "Matrix" begin
        x = [1 2 3; 4 5 6]
        @test canview(@opticof(_[1, 1]), x)
        @test canview(@opticof(_[2, 3]), x)
        @test canview(@opticof(_[1:2, 2]), x)
        @test canview(@opticof(_[:, 1]), x)
        @test canview(@opticof(_[1, :]), x)
        @test !canview(@opticof(_[3, 1]), x)
        @test !canview(@opticof(_[1, 4]), x)
        @test !canview(@opticof(_[2:3, 1]), x)
    end

    @testset "DimArray" begin
        x = DD.DimArray([1, 2, 3], (:i,))
        @test canview(@opticof(_[1]), x)
        @test canview(@opticof(_[2]), x)
        @test canview(@opticof(_[1:2]), x)
        @test canview(@opticof(_[:]), x)
        @test !canview(@opticof(_[4]), x)
        @test canview(@opticof(_[i=1]), x)
        # For some weird reason DimData does not error on these two but just warns that
        # there's no index j!
        @test canview(@opticof(_[j=2]), x)
        @test canview(@opticof(_[i=1, j=2]), x)
    end

    @testset "Dict" begin
        x = Dict(:a => [1, 2, 3], :b => (c=4, d=[5, 6]))
        @test canview(@opticof(_[:a]), x)
        @test canview(@opticof(_[:a][1]), x)
        @test canview(@opticof(_[:a][2]), x)
        @test canview(@opticof(_[:a][:]), x)
        @test canview(@opticof(_[:b]), x)
        @test canview(@opticof(_[:b].c), x)
        @test canview(@opticof(_[:b].d), x)
        @test canview(@opticof(_[:b].d[1]), x)
        @test canview(@opticof(_[:b].d[2]), x)
    end

    @testset "NamedTuple" begin
        x = (a=[1, 2, 3], b=(c=4, d=[5, 6]))
        @test canview(@opticof(_.a), x)
        @test canview(@opticof(_.a[1]), x)
        @test canview(@opticof(_.a[2]), x)
        @test canview(@opticof(_.a[:]), x)
        @test canview(@opticof(_.b), x)
        @test canview(@opticof(_.b.c), x)
        @test canview(@opticof(_.b.d), x)
        @test canview(@opticof(_.b.d[1]), x)
        @test canview(@opticof(_.b.d[2]), x)
    end

    @testset "Dynamic lenses" begin
        x = randn(2, 2)
        @test canview(@opticof(_[begin]), x)
        @test canview(@opticof(_[end]), x)
        @test canview(@opticof(_[1:end]), x)
        @test canview(@opticof(_[begin, end]), x)
        @test canview(@opticof(_[begin+1, end-1]), x)
        @test canview(@opticof(_[begin, :]), x)
        @test canview(@opticof(_[:, begin]), x)
    end
end

@testset "base getvalue + hasvalue" begin
    @testset "basic NamedTuple" begin
        nt = (a=[1], b=2, c=(x=3, y=[4], z=(; p=[(; q=5)])), d=[1.0 0.5; 0.5 1.0])
        @test hasvalue(nt, @vn(a))
        @test getvalue(nt, @vn(a)) == [1]
        @test hasvalue(nt, @vn(a[1]))
        @test getvalue(nt, @vn(a[1])) == 1
        @test hasvalue(nt, @vn(a[:]))
        @test getvalue(nt, @vn(a[:])) == [1]
        @test hasvalue(nt, @vn(b))
        @test getvalue(nt, @vn(b)) == 2
        @test hasvalue(nt, @vn(c))
        @test getvalue(nt, @vn(c)) == (x=3, y=[4], z=(; p=[(; q=5)]))
        @test hasvalue(nt, @vn(c.x))
        @test getvalue(nt, @vn(c.x)) == 3
        @test hasvalue(nt, @vn(c.y))
        @test getvalue(nt, @vn(c.y)) == [4]
        @test hasvalue(nt, @vn(c.y[1]))
        @test getvalue(nt, @vn(c.y[1])) == 4
        @test hasvalue(nt, @vn(c.z))
        @test getvalue(nt, @vn(c.z)) == (; p=[(; q=5)])
        @test hasvalue(nt, @vn(c.z.p))
        @test getvalue(nt, @vn(c.z.p)) == [(; q=5)]
        @test hasvalue(nt, @vn(c.z.p[1]))
        @test getvalue(nt, @vn(c.z.p[1])) == (; q=5)
        @test hasvalue(nt, @vn(c.z.p[1].q))
        @test getvalue(nt, @vn(c.z.p[1].q)) == 5
        @test hasvalue(nt, @vn(d))
        @test getvalue(nt, @vn(d)) == [1.0 0.5; 0.5 1.0]
        @test hasvalue(nt, @vn(d[1, 1]))
        @test getvalue(nt, @vn(d[1, 1])) == 1.0
        @test hasvalue(nt, @vn(d[1, 2]))
        @test getvalue(nt, @vn(d[1, 2])) == 0.5
        @test hasvalue(nt, @vn(d[2, 1]))
        @test getvalue(nt, @vn(d[2, 1])) == 0.5
        @test hasvalue(nt, @vn(d[2, 2]))
        @test getvalue(nt, @vn(d[2, 2])) == 1.0
        @test hasvalue(nt, @vn(d[3]))  # linear indexing works....
        @test getvalue(nt, @vn(d[3])) == 0.5
        @test hasvalue(nt, @vn(d[:]))
        @test getvalue(nt, @vn(d[:])) == [1.0, 0.5, 0.5, 1.0]
        @test !hasvalue(nt, @vn(nope))
        @test !hasvalue(nt, @vn(a[2]))
        @test !hasvalue(nt, @vn(a[1][1]))
        @test !hasvalue(nt, @vn(c.x[1]))
        @test !hasvalue(nt, @vn(c.y[2]))
        @test !hasvalue(nt, @vn(c.y.a))
        @test !hasvalue(nt, @vn(c.zzzz))
        @test !hasvalue(nt, @vn(d[1, 3]))
        @test !hasvalue(nt, @vn(d[3, :]))
    end

    @testset "basic Dict" begin
        # same tests as for NamedTuple
        d = Dict(
            @vn(a) => [1],
            @vn(b) => 2,
            @vn(c) => (x=3, y=[4], z=(; p=[(; q=5)])),
            @vn(d) => [1.0 0.5; 0.5 1.0],
        )
        @test hasvalue(d, @vn(a))
        @test getvalue(d, @vn(a)) == [1]
        @test hasvalue(d, @vn(a[1]))
        @test getvalue(d, @vn(a[1])) == 1
        @test hasvalue(d, @vn(a[:]))
        @test getvalue(d, @vn(a[:])) == [1]
        @test hasvalue(d, @vn(b))
        @test getvalue(d, @vn(b)) == 2
        @test hasvalue(d, @vn(c))
        @test getvalue(d, @vn(c)) == (x=3, y=[4], z=(; p=[(; q=5)]))
        @test hasvalue(d, @vn(c.x))
        @test getvalue(d, @vn(c.x)) == 3
        @test hasvalue(d, @vn(c.y))
        @test getvalue(d, @vn(c.y)) == [4]
        @test hasvalue(d, @vn(c.y[1]))
        @test getvalue(d, @vn(c.y[1])) == 4
        @test hasvalue(d, @vn(c.z))
        @test getvalue(d, @vn(c.z)) == (; p=[(; q=5)])
        @test hasvalue(d, @vn(c.z.p))
        @test getvalue(d, @vn(c.z.p)) == [(; q=5)]
        @test hasvalue(d, @vn(c.z.p[1]))
        @test getvalue(d, @vn(c.z.p[1])) == (; q=5)
        @test hasvalue(d, @vn(c.z.p[1].q))
        @test getvalue(d, @vn(c.z.p[1].q)) == 5
        @test hasvalue(d, @vn(d))
        @test getvalue(d, @vn(d)) == [1.0 0.5; 0.5 1.0]
        @test hasvalue(d, @vn(d[1, 1]))
        @test getvalue(d, @vn(d[1, 1])) == 1.0
        @test hasvalue(d, @vn(d[1, 2]))
        @test getvalue(d, @vn(d[1, 2])) == 0.5
        @test hasvalue(d, @vn(d[2, 1]))
        @test getvalue(d, @vn(d[2, 1])) == 0.5
        @test hasvalue(d, @vn(d[2, 2]))
        @test getvalue(d, @vn(d[2, 2])) == 1.0
        @test hasvalue(d, @vn(d[3]))  # linear indexing works....
        @test getvalue(d, @vn(d[3])) == 0.5
        @test hasvalue(d, @vn(d[:]))
        @test getvalue(d, @vn(d[:])) == [1.0, 0.5, 0.5, 1.0]
        @test !hasvalue(d, @vn(nope))
        @test !hasvalue(d, @vn(a[2]))
        @test !hasvalue(d, @vn(a[1][1]))
        @test !hasvalue(d, @vn(c.x[1]))
        @test !hasvalue(d, @vn(c.y[2]))
        @test !hasvalue(d, @vn(c.y.a))
        @test !hasvalue(d, @vn(c.zzzz))
        @test !hasvalue(d, @vn(d[1, 3]))
    end

    @testset "Dict with non-identity varname keys" begin
        d = Dict(
            @vn(a[1]) => [1.0, 2.0],
            @vn(b.x) => [3.0],
            @vn(c[2]) => (a=4.0, b=5.0),
        )
        @test hasvalue(d, @vn(a[1]))
        @test getvalue(d, @vn(a[1])) == [1.0, 2.0]
        @test hasvalue(d, @vn(a[1][1]))
        @test getvalue(d, @vn(a[1][1])) == 1.0
        @test hasvalue(d, @vn(a[1][2]))
        @test getvalue(d, @vn(a[1][2])) == 2.0
        @test hasvalue(d, @vn(b.x))
        @test getvalue(d, @vn(b.x)) == [3.0]
        @test hasvalue(d, @vn(b.x[1]))
        @test getvalue(d, @vn(b.x[1])) == 3.0
        @test hasvalue(d, @vn(c[2]))
        @test getvalue(d, @vn(c[2])) == (a=4.0, b=5.0)
        @test hasvalue(d, @vn(c[2].a))
        @test getvalue(d, @vn(c[2].a)) == 4.0
        @test hasvalue(d, @vn(c[2].b))
        @test getvalue(d, @vn(c[2].b)) == 5.0
        @test !hasvalue(d, @vn(a))
        @test !hasvalue(d, @vn(a[2]))
        @test !hasvalue(d, @vn(b.y))
        @test !hasvalue(d, @vn(b.x[2]))
        @test !hasvalue(d, @vn(c[1]))
        @test !hasvalue(d, @vn(c[2].x))
    end

    @testset "Dict with redundancy" begin
        d1 = Dict(@vn(x) => [[[[1.0]]]])
        d2 = Dict(@vn(x[1]) => [[[2.0]]])
        d3 = Dict(@vn(x[1][1]) => [[3.0]])
        d4 = Dict(@vn(x[1][1][1]) => [4.0])
        d5 = Dict(@vn(x[1][1][1][1]) => 5.0)

        d = Dict{VarName,Any}()
        for (new_dict, expected_value) in
            zip((d1, d2, d3, d4, d5), (1.0, 2.0, 3.0, 4.0, 5.0))
            d = merge(d, new_dict)
            @test hasvalue(d, @vn(x[1][1][1][1]))
            @test getvalue(d, @vn(x[1][1][1][1])) == expected_value
            # for good measure
            @test !hasvalue(d, @vn(x[1][1][1][2]))
            @test !hasvalue(d, @vn(x[1][1][2][1]))
            @test !hasvalue(d, @vn(x[1][2][1][1]))
            @test !hasvalue(d, @vn(x[2][1][1][1]))
        end
    end

    @testset "DimArray indices (including keyword)" begin
        x = (; a=DD.DimArray(randn(2, 3), (:i, :j)))
        @test hasvalue(x, @vn(a))
        @test getvalue(x, @vn(a)) == x.a
        @test hasvalue(x, @vn(a[1, 2]))
        @test getvalue(x, @vn(a[1, 2])) == x.a[1, 2]
        @test hasvalue(x, @vn(a[:]))
        @test getvalue(x, @vn(a[:])) == x.a[:]
        @test canview(@opticof(_[i=1]), x.a)
        @test hasvalue(x, @vn(a[i=1]))
        @test getvalue(x, @vn(a[i=1])) == x.a[i=1]
        @test canview(@opticof(_[i=1, j=2]), x.a)
        @test hasvalue(x, @vn(a[i=1, j=2]))
        @test getvalue(x, @vn(a[i=1, j=2])) == x.a[i=1, j=2]
        @test hasvalue(x, @vn(a[i=DD.Not(1)]))
        @test getvalue(x, @vn(a[i=DD.Not(1)])) == x.a[i=DD.Not(1)]

        y = (; b=DD.DimArray(randn(2, 3), (DD.X, DD.Y)))
        @test hasvalue(y, @vn(b))
        @test getvalue(y, @vn(b)) == y.b
        @test hasvalue(y, @vn(b[1, 2]))
        @test getvalue(y, @vn(b[1, 2])) == y.b[1, 2]
        @test hasvalue(y, @vn(b[:]))
        @test getvalue(y, @vn(b[:])) == y.b[:]
        @test hasvalue(y, @vn(b[DD.X(1)]))
        @test getvalue(y, @vn(b[DD.X(1)])) == y.b[DD.X(1)]
        @test hasvalue(y, @vn(b[DD.X(1), DD.Y(2)]))
        @test getvalue(y, @vn(b[DD.X(1), DD.Y(2)])) == y.b[DD.X(1), DD.Y(2)]
    end
end

@testset "with Distributions: getvalue + hasvalue" begin
    using Distributions
    using LinearAlgebra

    @testset "univariate" begin
        d = Dict(@vn(x) => 1.0, @vn(y) => [[2.0]])
        @test hasvalue(d, @vn(x), Normal())
        @test getvalue(d, @vn(x), Normal()) == 1.0
        @test hasvalue(d, @vn(y[1][1]), Normal())
        @test getvalue(d, @vn(y[1][1]), Normal()) == 2.0
    end

    @testset "multivariate + matrix" begin
        d = Dict(@vn(x[1]) => 1.0, @vn(x[2]) => 2.0)
        @test hasvalue(d, @vn(x), MvNormal(zeros(1), I))
        @test getvalue(d, @vn(x), MvNormal(zeros(1), I)) == [1.0]
        @test hasvalue(d, @vn(x), MvNormal(zeros(2), I))
        @test getvalue(d, @vn(x), MvNormal(zeros(2), I)) == [1.0, 2.0]
        @test !hasvalue(d, @vn(x), MvNormal(zeros(3), I))
        @test_throws ErrorException hasvalue(
            d,
            @vn(x),
            MvNormal(zeros(3), I);
            error_on_incomplete=true,
        )
        # If none of the varnames match, it should just return false instead of erroring
        @test !hasvalue(d, @vn(y), MvNormal(zeros(2), I); error_on_incomplete=true)
    end

    @testset "LKJCholesky :upside_down_smile:" begin
        # yes, this isn't a valid Cholesky sample, but whatever
        d = Dict(
            @vn(x.L[1, 1]) => 1.0,
            @vn(x.L[2, 1]) => 2.0,
            @vn(x.L[2, 2]) => 3.0,
        )
        @test hasvalue(d, @vn(x), LKJCholesky(2, 1.0))
        @test getvalue(d, @vn(x), LKJCholesky(2, 1.0)) ==
              Cholesky(LowerTriangular([1.0 0.0; 2.0 3.0]))
        @test !hasvalue(d, @vn(x), LKJCholesky(3, 1.0))
        @test_throws ErrorException hasvalue(
            d,
            @vn(x),
            LKJCholesky(3, 1.0);
            error_on_incomplete=true,
        )
        @test !hasvalue(d, @vn(y), LKJCholesky(3, 1.0); error_on_incomplete=true)

        d = Dict(
            @vn(x.U[1, 1]) => 1.0,
            @vn(x.U[1, 2]) => 2.0,
            @vn(x.U[2, 2]) => 3.0,
        )
        @test hasvalue(d, @vn(x), LKJCholesky(2, 1.0, :U))
        @test getvalue(d, @vn(x), LKJCholesky(2, 1.0, :U)) ==
              Cholesky(UpperTriangular([1.0 2.0; 0.0 3.0]))
        @test !hasvalue(d, @vn(x), LKJCholesky(3, 1.0, :U))
        @test_throws ErrorException hasvalue(
            d,
            @vn(x),
            LKJCholesky(3, 1.0, :U);
            error_on_incomplete=true,
        )
        @test !hasvalue(d, @vn(y), LKJCholesky(3, 1.0, :U); error_on_incomplete=true)
    end
end

end
