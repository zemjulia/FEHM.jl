import FEHM
import Test

isanode, zoneornodenums, skds, eflows, aipeds = FEHM.parseflow(FEHM.fehmdir * "/data/flow/wl.flow")

@Test.testset "flow" begin
    @Test.test !any(isanode[1:3])
    @Test.test all(isanode[4:end])
    @Test.test zoneornodenums[1:4] == [336000, 3, 5, 760868]
    @Test.test skds[1:4] ≈ [-3.2247363815851875, 1821.8003825641874, 1755.2461379629303, -4.33116584853531e-5]
    @Test.test eflows[1:4] ≈ [1, 1, 1, 1]
    @Test.test aipeds[1:4] ≈ [0, 1e10, 1e10, 0]
    @Test.test isanode[end] == true
    @Test.test zoneornodenums[end] == 766275
    @Test.test skds[end] ≈ -0.008413254709758795
    @Test.test eflows[end] == 1
    @Test.test aipeds[end] == 0
end
