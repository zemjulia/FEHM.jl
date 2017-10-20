import FEHM
using Base.Test

zonenumbers, nodenumbers = FEHM.readzone(FEHM.fehmdir * "/data/smoothgrid/out_west.zonn")

@testset "zone" begin
    @test length(zonenumbers) == 1
    @test length(nodenumbers) == 1
    @test length(nodenumbers[1]) == 6059
    
    @test zonenumbers[1] == 3
    @test nodenumbers[1][1] == 2264
    @test nodenumbers[1][2] == 2382
    @test nodenumbers[1][end - 1] == 1263688
    @test nodenumbers[1][end] == 1263779
end
