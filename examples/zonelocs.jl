import FEHM

zones, nodes = FEHM.readzone("../data/smoothgrid/well_screens.zonn")
xyz = readdlm("../data/smoothgrid/tet.xyz")
pm2nodes = nodes[4]
