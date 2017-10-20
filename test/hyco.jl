import FEHM
using Base.Test

isanode, zoneornodenums, kxs, kys, kzs = FEHM.parsehyco(FEHM.fehmdir * "/data/hyco/w01.hyco")

@testset "hyco" begin
    @test !isanode[1]
    @test isanode[2]
    @test zoneornodenums == [1, 2]
    @test kxs ≈ [1.6597775634462132e-5, 4.4853259404546345e-6]
    @test kys ≈ [2.3103422512424e-5, 5.007431708178284e-6]
    @test kzs ≈ [1.910140653452659e-6, 1.7228815098689173e-6]
end
