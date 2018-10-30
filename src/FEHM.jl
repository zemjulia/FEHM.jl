__precompile__()

module FEHM

import JLD
import WriteVTK
import DocumentFunction

fehmdir = Base.source_path()
if fehmdir == nothing
	fehmdir = splitdir(dirname(@__FILE__))[1]
else
	fehmdir = splitdir(splitdir(fehmdir)[1])[1]
end

"""
Run the tests in runtests.jl

$(DocumentFunction.documentfunction(test))
"""
function test()
	include(joinpath(fehmdir, "test", "runtests.jl"))
end

function myreadlines(filename::String)
	if isfile(filename)
		f = open(filename)
		l = myreadlines(f)
		close(f)
		return l
	else
		warn("File $filename does not exist!")
		return nothing
	end
end
function myreadlines(stream::IO)
	return readlines(stream; chomp=false)
end

function checknode()
	proc = spawn(`ls`)
	timedwait(() -> process_exited(proc), 10.) # 10 seconds
	if process_running(proc)
		kill(proc)
		exit()
	end
end

function runmodelindir(dir::Symbol; rootname::AbstractString="w01")
	runmodelindir(string(dir); rootname=rootname)
end

function runmodelindir(dir::AbstractString; rootname::AbstractString="w01")
	info("run $dir")
	run(pipeline(`bash -c "cd $dir; xfehm $rootname.files"`, stdout=DevNull, stderr=DevNull))
end

function symlinkdir(filename::AbstractString, dir::AbstractString)
	symlink(abspath(filename), joinpath(dir, filename))
end

@doc """
Read lines of a file

$(DocumentFunction.documentfunction(myreadlines;
argtext=Dict("filename"=>"file name",
            "stream"=>"file handle")))

Returns:

- an array with each line of the file an element
""" myreadlines

"""
Convert a year into FEHM day (default start year is 1964)

$(DocumentFunction.documentfunction(year2fehmday;
argtext=Dict("year"=>"the year to convert"),
keytext=Dict("offset"=>"the start year [default=`1964`]")))

Returns:

- FEHM day
"""
function year2fehmday(year; offset::Number=1964)
	return (year - offset) * 365.25
end

"""
Convert FEHM day into a year (default start year is 1964)

$(DocumentFunction.documentfunction(fehmday2year;
argtext=Dict("fehmday"=>"the FEHM day to convert"),
keytext=Dict("offset"=>"the start year [default=`1964`]")))

Returns:

- the converted year
"""
function fehmday2year(fehmday; offset::Number=1964)
	return fehmday / 365.25 + offset
end

"""
Parse the input file

$(DocumentFunction.documentfunction(parsefin;
argtext=Dict("filename"=>"file name")))

Returns:

- a dictionary of parsed file
"""
function parsefin(filename)
	lines = myreadlines(filename)
	result = Dict()
	result["title"] = strip(split(lines[2], ":")[2])
	result["time"] = parse(Float64, lines[3])
	result["nddp"] = parse(Int, split(lines[4])[1])
	i = 5
	while i <= length(lines)
		key = strip(lines[i])
		result[key] = Float64[]
		i += 1
		while i <= length(lines) && length(result[key]) < result["nddp"]
			append!(result[key], map(x->parse(Float64, x), split(lines[i])))
			i += 1
		end
	end
	return result
end

"""
Write data into a file

$(DocumentFunction.documentfunction(writefin;
argtext=Dict("findata"=>"input data to write",
            "filename"=>"file name"),
keytext=Dict("writekeys"=>"the keys of the items that will be written into the file [default=`\[\"saturation\", \"pressure\", \"no fluxes\"\]`]")))

Dumps:

- a file with input data written in it and named by the value of 'filename'
"""
function writefin(findata, filename; writekeys=["saturation", "pressure", "no fluxes"])
	f = open(filename, "w")
	write(f, "written by FEHM.jl\n")
	write(f, "title:  $(findata["title"])\n")
	write(f, "   $(findata["time"])\n")
	write(f, "    $(findata["nddp"]) nddp")
	for k in writekeys
		write(f, "\n$k")
		for x in findata[k]
			write(f, "\n$x")
		end
	end
	close(f)
end

function getwellnodes(filename::String, x::Number, y::Number; kw...)
	c = readdlm(filename)
	getwellnodes(c, x, y; kw...)
end
function getwellnodes(c::Array, x::Number, y::Number; topnodes::Integer=2, nodespercolumn::Integer=44)
	d = sqrt.((c[:,1].-x).^2 + (c[:,2].-y).^2)
	s = sortperm(d)
	n = s[1:nodespercolumn][end-(topnodes-1):end]
	a = [s[1:nodespercolumn] c[s[1:nodespercolumn],:] d[s[1:nodespercolumn]]][end-(topnodes-1):end,:]
	d = minimum(d[s[1:nodespercolumn]][end-(topnodes-1):end])
	convert(Array{Int64,1}, ceil.(n)), d
end

@doc """
Get nodes of wells from the input file

$(DocumentFunction.documentfunction(getwellnodes;
argtext=Dict("filename"=>"input file name",
            "x"=>"x coordinates",
            "y"=>"y coordinates",
            "c"=>"file handle"),
keytext=Dict("topnodes"=>"top nodes [default=`2`]",
            "nodespercolumn"=>"nodes per column [default=`44`]",
            "kw..."=>"other keyword argument")))

Example:

```julia
FEHM.getwellnodes("tet.xyz", (499950.3031-100), 539101.3053)
```
""" getwellnodes

"""
Write zone information into a file

$(DocumentFunction.documentfunction(dumpzone;
argtext=Dict("filename"=>"output file name",
            "zonenumbers"=>"zone numbers",
            "nodenumbers"=>"node numbers"),
keytext=Dict("keyword"=>"[default=`\"zonn\"`]")))

Dumps:

- a file contain zone information named by the value of 'filename'
"""
function dumpzone(filename::String, zonenumbers::Vector, nodenumbers::Vector; keyword::String="zonn")
	@assert length(nodenumbers) == length(zonenumbers)
	f = open(filename, "w")
	println(f, keyword)
	for i = 1:length(zonenumbers)
		println(f, zonenumbers[i])
		println(f, "nnum")
		println(f, length(nodenumbers[i]))
		writedlm(f, nodenumbers[i]')
	end
	println(f, "")
	println(f, "stop")
	close(f)
end

readzone(filename; returndict::Bool=false) = parsezone(filename; returndict=returndict)

function parsezone(filename::String; returndict::Bool=false)
	info("Parse zones in $filename")
	return parsezone(myreadlines(filename), returndict=returndict)
end
function parsezone(lines::Vector; returndict::Bool=false)
	lines = chomp.(lines)
	if !startswith(lines[1], "zone") && !startswith(lines[1], "zonn")
		error("Provided file doesn't start with zone or zonn on the first line")
	end
	nnumlines = Int64[]
	for i = 1:length(lines)
		if contains(lines[i], "nnum")
			push!(nnumlines, i)
		end
	end
	zonenumbers = Array{Int64}(length(nnumlines))
	for i = 1:length(nnumlines)
		zonenumbers[i] = parse(Int, split(lines[nnumlines[i] - 1])[1])
	end
	nodenumbers = Array{Array{Int64, 1}}(length(nnumlines))
	for i = 1:length(nnumlines)
		nodenumbers[i] = Int64[]
		numnodes = parse(Int, lines[nnumlines[i] + 1])
		nodenumbers[i] = Array{Int64}(numnodes)
		j = 2
		k = 1
		while k <= numnodes
			newnodes = map(x->parse(Int, x), split(lines[nnumlines[i] + j]))
			nodenumbers[i][k:k + length(newnodes) - 1] = newnodes
			j += 1
			k += length(newnodes)
		end
	end
	if returndict
		d1 = Dict()
		d2 = Dict()
		for i = 1:length(nnumlines)
			d2[zonenumbers[i]] = Int64[]
			for j = 1:length(nodenumbers[i])
				d1[nodenumbers[i][j]] = zonenumbers[i]
				push!(d2[zonenumbers[i]], nodenumbers[i][j])
			end
		end
		return d1, d2
	else
		return zonenumbers, nodenumbers
	end
end

@doc """
Parse zone information from input file

$(DocumentFunction.documentfunction(parsezone;
argtext=Dict("filename"=>"input file name",
            "lines"=>"a vector of the input file with each line an element"),
keytext=Dict("returndict"=>"whether to return the zone information in dictoinaries [default=`false`]")))

Returns:

- zone numbers and node numbers
""" parsezone

"""
Parse the grid coordinates from the input FEHM file

$(DocumentFunction.documentfunction(parsegrid;
argtext=Dict("fehmfilename"=>"FEHM file name")))

Returns:

- coordinates of the grid
"""
function parsegrid(fehmfilename)
	lines = myreadlines(fehmfilename)
	if !startswith(lines[1], "coor")
		error("FEHM grid file doesn't start with \"coor\"")
	end
	numgridpoints = parse(Int, lines[2])
	dims = length(split(lines[3])) - 1
	coords = Array{Float64}(dims, numgridpoints)
	for i = 1:numgridpoints
		splitline = split(lines[2 + i])
		for j = 1:dims
			coords[j, i] = parse(Float64, splitline[j + 1])
		end
	end
	return coords
end

"""
Parse geo file

$(DocumentFunction.documentfunction(parsegeo;
argtext=Dict("geofilename"=>"geo file name",
            "docells"=>"whether to get cell information [default=`true`]")))

Returns:

- x, y, z coordinates and mesh cell information
"""
function parsegeo(geofilename, docells=true)
	lines = myreadlines(geofilename)
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
	if docells
		cells = Array{WriteVTK.MeshCell}(length(lines) - i + 1)
		fourtoseven = 4:7
		for j = i:length(lines)
			splitline = split(lines[j])
			if splitline[3] != "tet"
				error("only tets supported")
			end
			ns = map(i->parse(Int, splitline[i]), fourtoseven)
			cells[j - i + 1] = WriteVTK.MeshCell(WriteVTK.VTKCellTypes.VTK_TETRA, ns)
		end
	else
		cells = Array{WriteVTK.MeshCell}(0)
	end
	return xs, ys, zs, cells
end

"""
$(DocumentFunction.documentfunction(avs2vtk;
argtext=Dict("geofilename"=>"geo file name",
            "rootname"=>"root name of .avs_log file",
            "pvdrootname"=>"pvd file root name",
            "vtkrootname"=>"vtk file root name")))

Dumps:

- vtk file
"""
function avs2vtk(geofilename, rootname, pvdrootname, vtkrootname)
	pvd = WriteVTK.paraview_collection(pvdrootname)
	xs, ys, zs, cells = parsegeo(geofilename)
	avslines = myreadlines(string(rootname, ".avs_log"))
	for i = 5:length(avslines)
		splitline = split(avslines[i])
		avsrootname = splitline[1]
		time = parse(Float64, splitline[2])
		vtkfile = WriteVTK.vtk_grid(string(vtkrootname, "_$(i - 5)"), xs, ys, zs, cells)
		timedata = readdlm(string(avsrootname, "_con_node.avs"), skipstart=2)
		filename = string(avsrootname, "_sca_node.avs")
		if isfile(filename)
			timedata = readdlm(filename, skipstart=2)
			WriteVTK.vtk_point_data(vtkfile, timedata[:, 2], "WL")
			WriteVTK.vtk_save(vtkfile)
			WriteVTK.collection_add_timestep(pvd, vtkfile, time)
		end
		filename = string(avsrootname, "_con_node.avs")
		if isfile(filename)
			timedata = readdlm(filename, skipstart=2)
			WriteVTK.vtk_point_data(vtkfile, timedata[:, 2], "Cr")
			WriteVTK.vtk_save(vtkfile)
			WriteVTK.collection_add_timestep(pvd, vtkfile, time)
		end
	end
	WriteVTK.vtk_save(pvd)
end

"""
$(DocumentFunction.documentfunction(avs2jld;
argtext=Dict("geofilename"=>"geo file name",
            "rootname"=>"root name of .avs_log file",
            "jldfilename"=>"jld file name"),
keytext=Dict("timefilter"=>"function which defines whether the data of a specific time is going to be used [default=`true`]")))

Dumps:

- jld file
"""
function avs2jld(geofilename, rootname, jldfilename; timefilter=t->true, suffix="_con_node.avs")
	xs, ys, zs, cells = parsegeo(geofilename, false)
	filename = string(rootname, ".avs_log")
	avslines = myreadlines(filename)
	if avslines == nothing
		warn("FEHM AVS processing failed!")
		return nothing
	end
	wldatas = Array{Float64, 1}[]
	crdatas = Array{Float64, 1}[]
	times = Float64[]
	for i = 5:length(avslines)
		splitline = split(avslines[i])
		avsrootname = joinpath(rootdir, splitline[1])
		time = parse(Float64, splitline[2])
		if timefilter(time)
			push!(times, time)
			timedata = readdlm(string(avsrootname, suffix), skipstart=2)
			crdata = timedata[:, 2]
			push!(crdatas, crdata)
		end
	end
	JLD.save(jldfilename, "WL", wldatas, "Cr", crdatas, "times", times, "xs", xs, "ys", ys, "zs", zs)
end

"""
$(DocumentFunction.documentfunction(avs2jld2;
argtext=Dict("geofilename"=>"geo file name",
            "rootname"=>"root name of .avs_log file",
            "jld2filename"=>"jld file name"),
keytext=Dict("timefilter"=>"function which defines whether the data of a specific time is going to be used [default=`true`]")))

Dumps:

- jld2 file
"""
function avs2jld2(geofilename, rootname, jld2filename; timefilter::Function=t->true)
  if !endswith(jld2filename,".jld2")
    jld2filename = "$jld2filename.jld2"
  end
  rootdir = splitdir(rootname)[1]
	xs, ys, zs, cells = parsegeo(geofilename, false)
	filename = string(rootname, ".avs_log")
	avslines = myreadlines(filename)
	if avslines == nothing
		warn("FEHM AVS processing failed!")
		return nothing
	end
	wldatas = Array{Float64, 1}[]
	crdatas = Array{Float64, 1}[]
	times = Float64[]
	for i = 5:length(avslines)
		splitline = split(avslines[i])
		avsrootname = joinpath(rootdir, splitline[1])
		time = parse(Float64, splitline[2])
		if timefilter(time)
      push!(times, time)
			filename = string(avsrootname, "_sca_node.avs")
			if isfile(filename)
				timedata = readdlm(filename, skipstart=2)
				wldata = timedata[:, 2]
				push!(wldatas, wldata)
			end
			filename = string(avsrootname, "_con_node.avs")
			if isfile(filename)
				timedata = readdlm(filename, skipstart=2)
				crdata = timedata[:, 2]
				push!(crdatas, crdata)
			end
		end
	end
	FileIO.save(jld2filename, "WL", wldatas, "Cr", crdatas, "times", times, "xs", xs, "ys", ys, "zs", zs)
end

"""
$(DocumentFunction.documentfunction(parsestor;
argtext=Dict("filename"=>"input file name")))

Returns:

- `volumes` :
- `areasoverlengths` : areas over lengths
- `connections` :
"""
function parsestor(filename)
	#see LaGriT's documentation for details on the format: http://lagrit.lanl.gov/docs/STOR_Form.html
	#"coefficients" are really areas divided by lengths
	f = open(filename)
	readline(f)#throw away the first 2 lines
	readline(f)
	goodline = readline(f)
	close(f)
	numwrittencoeffs, numequations, ncoef_p_neq_p1, numareacoeffs = map(x->parse(Int, x), split(goodline)[1:4])
	numcoeffs = ncoef_p_neq_p1 - numequations - 1
	if numareacoeffs != 1
		error("only scalar coefficients supported -- see http://lagrit.lanl.gov/docs/STOR_Form.html")
	end
	tokens_any = filter(x->isa(x, Number), permutedims(readdlm(filename; skipstart=3), (2, 1)))
	tokens::Array{Float64, 1} = Float64.(tokens_any)
	tokens_any = nothing
	volumes = tokens[1:numequations]
	fehmweirdness = Int.(tokens[numequations + 1:2 * numequations + 1])#see http://lagrit.lanl.gov/docs/STOR_Form.html to understand the fehmweirdness
	numconnections = diff(fehmweirdness)
	rowentries = Int.(floor.(tokens[2 * numequations + 2:2 * numequations + 1 + numcoeffs]))
	connections = Array{Pair{Int, Int}}(numcoeffs)
	k = 1
	for i = 1:numequations
		for j = 1:numconnections[i]
			connections[k] = i=>rowentries[k]
			k += 1
		end
	end
	coeffindices = Int.(floor.(tokens[2 * numequations + 2 + numcoeffs:2 * numequations + 1 + 2 * numcoeffs]))
	@assert tokens[2 * numequations + 2 + 2 * numcoeffs:3 * numequations + 2 + 2 * numcoeffs] == zeros(numequations + 1)#check that the zeros are where they should be
	for i = 3 * numequations + 3 + 2 * numcoeffs:4 * numequations + 2 + 2 * numcoeffs
		j = Int(tokens[i])
		@assert connections[j - length(volumes) - 1][1] == connections[j - length(volumes) - 1][2]#check that the diagonals are in the right places
	end
	coeffs = tokens[4 * numequations + 3 + 2 * numcoeffs:4 * numequations + 2 + 2 * numcoeffs + numwrittencoeffs]
	@assert 4 * numequations + 2 + 2 * numcoeffs + numwrittencoeffs == length(tokens)
	areasoverlengths = Array{Float64}(length(connections))
	for i = 1:length(areasoverlengths)
		areasoverlengths[i] = abs(coeffs[coeffindices[i]])
	end
	return volumes, areasoverlengths, connections
end

function parseflow(filename::String)
	parseflow(myreadlines(filename), filename)
end
function parseflow(lines::Vector, filename)
	@assert startswith(lines[1], "flow")
	isanode = Array{Bool}(length(lines) - 2)
	zoneornodenums = Array{Int}(length(lines) - 2)
	skds = Array{Float64}(length(lines) - 2)
	eflows = Array{Float64}(length(lines) - 2)
	aipeds = Array{Float64}(length(lines) - 2)
	for i = 2:length(lines) - 1
		splitline = split(lines[i])
		zoneornodenums[i - 1] = parse(Int, splitline[1])
		skds[i - 1] = parse(Float64, splitline[4])
		eflows[i - 1] = parse(Float64, splitline[5])
		aipeds[i - 1] = parse(Float64, splitline[6])
		if zoneornodenums[i - 1] < 0#it is a zone
			@assert splitline[2] == "0"
			@assert splitline[3] == "0"
			isanode[i - 1] = false
			zoneornodenums[i - 1] = -zoneornodenums[i - 1]
		else#it is a node
			if splitline[2] != splitline[1]
				error("FEHM stride syntax not supported flow macro (line $i in $filename)")
			end
			isanode[i - 1] = true
		end
	end
	return isanode, zoneornodenums, skds, eflows, aipeds
end

@doc """
$(DocumentFunction.documentfunction(parseflow;
argtext=Dict("filename"=>"input file name",
            "lines"=>"a vector of the input file with each line an element")))

Returns:

- `isanode` : whether this is a node
- `zoneornodenums` : zone or node numbers
- `skds` :
- `eflows` :
- `aipeds` :
""" parseflow

function parsehyco(filename::String)
	parsehyco(myreadlines(filename), filename)
end
function parsehyco(lines::Vector, filename::String)
	@assert startswith(lines[1], "hyco")
	isanode = Array{Bool}(length(lines) - 2)
	zoneornodenums = Array{Int}(length(lines) - 2)
	kxs = Array{Float64}(length(lines) - 2)
	kys = Array{Float64}(length(lines) - 2)
	kzs = Array{Float64}(length(lines) - 2)
	for i = 2:length(lines) - 1
		splitline = split(lines[i])
		zoneornodenums[i - 1] = parse(Int, splitline[1])
		kxs[i - 1] = parse(Float64, splitline[4])
		kys[i - 1] = parse(Float64, splitline[5])
		kzs[i - 1] = parse(Float64, splitline[6])
		if zoneornodenums[i - 1] < 0#it is a zone
			@assert splitline[2] == "0"
			@assert splitline[3] == "0"
			isanode[i - 1] = false
			zoneornodenums[i - 1] = -zoneornodenums[i - 1]
		else#it is a node
			if splitline[2] != splitline[1]
				error("FEHM stride syntax not supported hyco macro (line $i in $filename)")
			end
			isanode[i - 1] = true
		end
	end
	return isanode, zoneornodenums, kxs, kys, kzs
end

@doc """
$(DocumentFunction.documentfunction(parsehyco;
argtext=Dict("filename"=>"input file name",
            "lines"=>"a vector of the input file with each line an element")))

Returns:

- `isanode` : whether this is a node
- `zoneornodenums` : zone or node numbers
- `kxs` :
- `kys` :
- `kzs` :
""" parsehyco

"""
Flatten zones

$(DocumentFunction.documentfunction(flattenzones;
argtext=Dict("zonenumbers"=>"zone numbers",
            "nodenumbers"=>"node numbers",
            "isanode"=>"whether this is a node",
            "zoneornodenums"=>"zone or node numbers",
            "otherstuff..."=>"other input arguments")))

Returns:

- node numbers
- other stuff
"""
function flattenzones(zonenumbers, nodenumbers, isanode, zoneornodenums, otherstuff...)
	zone2nodes = Dict{Int, Array{Int, 1}}(zip(zonenumbers, nodenumbers))
	numflatnodes = 0
	for i = 1:length(isanode)
		if isanode[i]
			numflatnodes += 1
		else
			numflatnodes += length(zone2nodes[zoneornodenums[i]])
		end
	end
	nodenums = Array{Int}(numflatnodes)
	newotherstuff = Array{Any}(length(otherstuff))
	for (i, x) in enumerate(otherstuff)
		newotherstuff[i] = Array{eltype(x)}(numflatnodes)
	end
	k = 1
	for i = 1:length(isanode)
		if isanode[i]
			for j = 1:length(otherstuff)
				newotherstuff[j][k] = otherstuff[j][i]
			end
			nodenums[k] = zoneornodenums[i]
			k += 1
		else
			for nodenum in zone2nodes[zoneornodenums[i]]
				for j = 1:length(otherstuff)
					newotherstuff[j][k] = otherstuff[j][i]
				end
				nodenums[k] = nodenum
				k += 1
			end
		end
	end
	return nodenums, newotherstuff...
end

end
