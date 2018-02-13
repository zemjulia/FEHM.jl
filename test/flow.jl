import FEHM
using Base.Test

isanode, zoneornodenums, skds, eflows, aipeds = FEHM.parseflow(FEHM.fehmdir * "/data/flow/wl.flow")

@testset "flow" begin
    @test !any(isanode[1:3])
    @test all(isanode[4:end])
    @test zoneornodenums[1:4] == [336000, 3, 5, 760868]
    @test skds[1:4] ≈ [-3.2247363815851875, 1821.8003825641874, 1755.2461379629303, -4.33116584853531e-5]
    @test eflows[1:4] ≈ [1, 1, 1, 1]
    @test aipeds[1:4] ≈ [0, 1e10, 1e10, 0]
    @test isanode[end] == true
    @test zoneornodenums[end] == 766275
    @test skds[end] ≈ -0.008413254709758795
    @test eflows[end] == 1
    @test aipeds[end] == 0
end
