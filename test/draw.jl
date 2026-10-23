module DrawTests

using VarNames
using Test

@testset "draw" begin
    # Since it's just a bare struct, just test its API.
    vnt = VarNamedTuple(x=0.5, y=randn(3))
    nt = (a=:hello, logjoint=randn())
    d = Draw(vnt, nt)

    @test parameters(d) == vnt
    @test extras(d) == nt
    @test d == Draw(vnt, nt)
    @test d != Draw(VarNamedTuple(x=1.0), nt)
    missing_vnt = VarNamedTuple(x=missing)
    @test ismissing(Draw(missing_vnt, nt) == Draw(missing_vnt, nt))
    @test (Draw(missing_vnt, (a=1,)) == Draw(missing_vnt, (a=2,))) === false
end

end # module DrawTests
