module FEHM

import WriteVTK

function readzone(filename)
	f = open(filename)
	lines = readlines(f)
	lines = map(chomp, lines)
	close(f)
	if !startswith(lines[1], "zone") && !startswith(lines[1], "zonn")
		error("zone/zonn file doesn't start with zone or zonn on the first line")
	end
	nnumlines = Int64[]
	for i = 1:length(lines)
		if contains(lines[i], "nnum")
			push!(nnumlines, i)
		end
	end
	zonenumbers = Array(Int64, length(nnumlines))
	for i = 1:length(nnumlines)
		zonenumbers[i] = parse(Int, split(lines[nnumlines[i] - 1])[1])
	end
	nodenumbers = Array(Array{Int64, 1}, length(nnumlines))
	for i = 1:length(nnumlines)
		nodenumbers[i] = Int64[]
		numnodes = parse(Int, lines[nnumlines[i] + 1])
		j = 2
		while(length(nodenumbers[i]) < numnodes)
			newnodes = map(x->parse(Int, x), split(lines[nnumlines[i] + j]))
			nodenumbers[i] = [nodenumbers[i]; newnodes]
			j += 1
		end
	end
	return zonenumbers, nodenumbers
end

function parsegeo(geofilename)
	lines = readlines(geofilename)
	i = 1
	xs = Float64[]
	ys = Float64[]
	zs = Float64[]
	splitline = split(lines[1])
	if length(splitline) != 4
		error("only 3 dimensional meshes supported")
	end
	while length(splitline) == 4
		x = parse(Float64, splitline[2])
		y = parse(Float64, splitline[3])
		z = parse(Float64, splitline[4])
		push!(xs, x)
		push!(ys, y)
		push!(zs, z)
		i += 1
		splitline = split(lines[i])
	end
	cells = Array(WriteVTK.MeshCell, length(lines) - i + 1)
	fourtoseven = 4:7
	for j = i:length(lines)
		splitline = split(lines[j])
		if splitline[3] != "tet"
			error("only tets supported")
		end
		ns = map(i->parse(Int, splitline[i]), fourtoseven)
		cells[j - i + 1] = WriteVTK.MeshCell(WriteVTK.VTKCellTypes.VTK_TETRA, ns)
	end
	return xs, ys, zs, cells
end

function avs2vtk(geofilename, rootname, pvdrootname, vtkrootname)
	pvd = WriteVTK.paraview_collection(pvdrootname)
	xs, ys, zs, cells = parsegeo(geofilename)
	avslines = readlines(string(rootname, ".avs_log"))
	for i = 5:length(avslines)
		splitline = split(avslines[i])
		avsrootname = splitline[1]
		time = parse(Float64, splitline[2])
		vtkfile = WriteVTK.vtk_grid(string(vtkrootname, "_$(i - 5)"), xs, ys, zs, cells)
		timedata = readdlm(string(avsrootname, "_con_node.avs"), skipstart=2)
		WriteVTK.vtk_point_data(vtkfile, timedata[:, 2], "Cr")
		WriteVTK.vtk_save(vtkfile)
		WriteVTK.collection_add_timestep(pvd, vtkfile, time)
	end
	WriteVTK.vtk_save(pvd)
end

end
