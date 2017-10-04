using Base.Test
import FEHM

volumes, areasoverlengths, connections = FEHM.parsestor(FEHM.fehmdir * "/data/stor/test.stor")
@test volumes == ones(8) / 8
@test areasoverlengths == [0.0,0.25,0.25,0.25,0.0,0.25,0.0,0.0,0.25,0.0,0.25,0.0,0.0,0.25,0.0,0.0,0.25,0.25,0.25,0.25,0.0,0.0,0.25,0.25,0.0,0.0,0.25,0.25,0.25,0.25,0.0,0.0,0.25,0.0,0.0,0.25,0.0,0.25,0.0,0.0,0.25,0.0,0.25,0.25,0.25,0.0]
