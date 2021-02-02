import FEHM
import Test

# Initialize FEHM.jl test suite
@Test.testset "FEHM.jl" begin
    include("flow.jl")
    include("flattenzone.jl")
    include("hyco.jl")
    include("zone.jl")
    # include("stor.jl")
end

return nothing