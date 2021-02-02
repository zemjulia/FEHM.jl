import FEHM
import Test

volumes, areasoverlengths, connections = FEHM.parsestor(FEHM.fehmdir * "/data/stor/test.stor")

@Test.testset "stor" begin
    @Test.test volumes == ones(8) / 8
    @Test.test areasoverlengths == [0.0,0.25,0.25,0.25,0.0,0.25,0.0,0.0,
                                0.25,0.0,0.25,0.0,0.0,0.25,0.0,0.0,
                                0.25,0.25,0.25,0.25,0.0,0.0,0.25,0.25,
                                0.0,0.0,0.25,0.25,0.25,0.25,0.0,0.0,0.25,
                                0.0,0.0,0.25,0.0,0.25,0.0,0.0,0.25,0.0,
                                0.25,0.25,0.25,0.0]
end
