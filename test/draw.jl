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
end

end # module DrawTests
