import FEHM
using Base.Test

isanode, zoneornodenums, skds, eflows, aipeds = FEHM.parseflow("../data/flow/wl.flow")
zonenums = [336000, 3, 5]
nodesinzones = [[1, 2, 3], [4, 5, 6], [7, 8, 9, 10]]
nodenums, newskds, neweflows, newaipeds = FEHM.flattenzones(zonenums, nodesinzones, isanode, zoneornodenums, skds, eflows, aipeds)
@test length(newskds) == length(neweflows)
@test length(newskds) == length(newaipeds)
@test length(newskds) == length(skds) + sum(length.(nodesinzones)) - length(zonenums)
