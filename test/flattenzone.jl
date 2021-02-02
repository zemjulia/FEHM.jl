import FEHM
import Test

# Define parameters
zonenums = [336000, 3, 5]
nodesinzones = [[1, 2, 3], [4, 5, 6], [7, 8, 9, 10]]

# Run FEHM functions
isanode, zoneornodenums, skds, eflows, aipeds = FEHM.parseflow(FEHM.fehmdir * "/data/flow/wl.flow")
nodenums, newskds, neweflows, newaipeds = FEHM.flattenzones(zonenums, nodesinzones, isanode, zoneornodenums, skds, eflows, aipeds)

# Begin test set
@Test.testset "flattenzone" begin
    @Test.test length(newskds) == length(neweflows)
    @Test.test length(newskds) == length(newaipeds)
    @Test.test length(newskds) == length(skds) + sum(length.(nodesinzones)) - length(zonenums)
    @Test.test newskds[1:10] == [fill(skds[1], 3); fill(skds[2], 3); fill(skds[3], 4); ]
    @Test.test neweflows[1:10] == [fill(eflows[1], 3); fill(eflows[2], 3); fill(eflows[3], 4); ]
    @Test.test newaipeds[1:10] == [fill(aipeds[1], 3); fill(aipeds[2], 3); fill(aipeds[3], 4); ]
    @Test.test newskds[11:end] == skds[4:end]
    @Test.test neweflows[11:end] == eflows[4:end]
    @Test.test newaipeds[11:end] == aipeds[4:end]
end
