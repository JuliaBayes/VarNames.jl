module AquaTests

using Aqua: Aqua
using VarNames: VarNames

@info "Testing Aqua.jl"
Aqua.test_all(VarNames)

end
