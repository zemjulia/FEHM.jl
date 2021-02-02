import FEHM
import Test

zonenumbers, nodenumbers = FEHM.readzone(FEHM.fehmdir * "/data/smoothgrid/out_west.zonn")

@Test.testset "zone" begin
    @Test.test length(zonenumbers) == 1
    @Test.test length(nodenumbers) == 1
    @Test.test length(nodenumbers[1]) == 6059
    
    @Test.test zonenumbers[1] == 3
    @Test.test nodenumbers[1][1] == 2264
    @Test.test nodenumbers[1][2] == 2382
    @Test.test nodenumbers[1][end - 1] == 1263688
    @Test.test nodenumbers[1][end] == 1263779
end
