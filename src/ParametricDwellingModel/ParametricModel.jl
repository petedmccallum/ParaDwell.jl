
#-----------------------------------------------------------
function Orientation(project,polygons)
	L = nrow(project.dat["master"])
	function TestOrthogonality(α;tol=1.)
		Δα = diff.(α)
		orthogonal = [sum(abs.(δα.-round.(δα)).>tol) for δα in Δα].==0
	end

	orientation(val) = 180 ./π .* atan.(val)
	tmp = orientation.(polygons.grad)
	# Flag dwellings as orthogonal (true) or otherwise (false). Include in master
	tol_deg=1.
	project.dat["master"][!,"orthogonal"] = TestOrthogonality(tmp;tol=tol_deg)
	# Determine the first quadrant angle (subtract from 90deg for North bearing)
	polygons[!,:orient_quad1] = [mean(ang)+45 for ang in tmp]
	polygons[!,:orient_set] = [abs.(tmp[i].-polygons.orient_quad1[i]).<tol_deg for i in 1:L]
	return polygons
end

#-----------------------------------------------------------
function FindAdiabatics(project,polygons)

	# Create large DataFrame, one row per edge, for adjacency matching
	ranges(l) = collect(range(1,stop=l))

	cen_e = vcat(polygons.cen_e...)
	cen_n = vcat(polygons.cen_n...)

	L = length.(polygons.cen_e)
	osgb = Int.(vcat(ones.(L).*project.dat["master"].osgb...))
	iEdge = vcat(ranges.(L)...)
	grad = vcat(polygons.grad...)

	edges = DataFrame(
		:cen_e=>cen_e,
		:cen_n=>cen_n,
		:osgb=>osgb,
		:iEdge=>iEdge,
		:grad=>grad,
	)

	# Find line constant 'c' (y=mx+c)
	edges[!,:e0_crossing] = edges.cen_n .- edges.cen_e.*edges.grad

	# Find edges with similar grad and zero-crossing, from different polygons
	L = size(edges,1)
	withinTol(arr,tol) = [findall(abs.(arr.-val).<tol) for val in arr]
	function MatchEdges(edges)
		# Find edges throughout all domain with same gradient ±tol
		i1 = withinTol(edges.grad,0.002)
		# Find edges throughout all domain with same Eastings=0 crossing (line constant 'c') ±tol
		i2 = withinTol(edges.e0_crossing,5)
		# Exclude self reference of same edge/dwelling, plus edges from all other
		# ... dwellings in same osgb polygon (building)
		i4 = [findall(edges.osgb.!=ed) for ed in edges.osgb]
		# Collapse to edges that meet all above criteria
		iMatch = [intersect(i1[i],i2[i],i4[i]) for i in 1:L]
	end
	iMatch = MatchEdges(edges)

	# Exclude out-of-tollerance matches (e.g. tol=1.0m)
	pythag(x,y) = sqrt(x^2+y^2)
	L = length.(iMatch)
	tol_dist = 1.
	[iMatch[i]=iMatch[i][pythag.(edges.cen_e[i].-edges.cen_e[iMatch[i]],edges.cen_n[i].-edges.cen_n[iMatch[i]]).<=tol_dist] for i in 1:length(iMatch) if L[i].!=0]

	# Append to edges DataFrame
	edges[!,:neighbours] = iMatch
	edges[!,:adiabatic_bool] = length.(iMatch).>0

	# Plot
	addtraces!(ui.p0,scatter(
		x=edges.cen_e[edges.adiabatic_bool],
		y=edges.cen_n[edges.adiabatic_bool],
		mode="markers"
	))

	return edges
end

#-----------------------------------------------------------
function ProcessGeom(project)

	L = nrow(project.dat["master"])

	# DataFrame of footprints (arrays of northings/eastings/diffs/centroids)
	n = project.dat["master"].northings_GML
	e = project.dat["master"].eastings_GML
	Δn = diff.(n)
	Δe = diff.(e)
	cen_n = [n[i][1:end-1] .+ Δn[i]./2 for i in 1:L]
	cen_e = [e[i][1:end-1] .+ Δe[i]./2 for i in 1:L]
	# Combine in DataFrame
	polygons = DataFrame(:n=>n,:e=>e,:Δn=>Δn,:Δe=>Δe,:cen_n=>cen_n,:cen_e=>cen_e)

	# Line gradients
	grad(Δn,Δe) = Δn./Δe
	polygons[!,:grad] = grad.(polygons.Δn,polygons.Δe)

	polygons = Orientation(project,polygons)
	edges = FindAdiabatics(project,polygons)

	return polygons
end

#-----------------------------------------------------------

@time polygons = ProcessGeom(project)

[length(polygons[1,c]) for c in 1:7]
