
#-----------------------------------------------------------
function TestOrthogonality(α;tol=1.)
	Δα = diff.(α)
	orthogonal = [sum(abs.(δα.-round.(δα)).>tol) for δα in Δα].==0
end

#-----------------------------------------------------------
function Orientation(project,polygons)
	L = nrow(project.dat["master"])

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
	INonSelfRef(vec,i) = findall(vec.!=vec[i])
	IAdiab(vec,not_i,i) = findall(vec[not_i[i]].==vec[i])
	Ranges(l) = collect(range(1,stop=l))
	IPoly(l,i) = Int.(ones(l)).*i
	IMap(iPolyⱼ,i) = findall(iPolyⱼ.==i)
	remap(iAdiab,iMapᵢ) = iAdiab[iMapᵢ]
	iRedundantVertices(angles,tol_deg) = findall(abs.(diff(angles)).<(tol_deg*π/180)).+1
	iSelectiveVertexRemoval(iAdiabⱼ,iRmⱼ) = iRmⱼ[[iAdiabⱼ[i].==iAdiabⱼ[i-1] for i in iRmⱼ]]
	RemoveRedundantVertices(nⱼ,iRmⱼ,offset) = nⱼ[Not(iRmⱼ.+offset)]

	# Generate list of all vertices (all polygons, one list)
	edges = DataFrame()
	edges[!,:cen_e] = vcat(polygons.cen_e...)
	edges[!,:cen_n] = vcat(polygons.cen_n...)

	# List of osgb refs
	L = length.(polygons.cen_e)
	edges[!,:osgbs] = Int.(vcat(ones.(L).*project.dat["master"].osgb...))
	edges[!,:iOtherOsgb] = INonSelfRef.((edges.osgbs,),1:length(edges.cen_e))

	# List of edge sequence order
	edges[!,:iEdge] = vcat(Ranges.(L)...)

	# List of parent polygon indicces
	edges[!,:iPoly] = vcat(IPoly.(L,1:length(L))...)

	# Find all adjacencies, based on matching edge centroids ()
	L = length(edges.cen_e)
	edges[!,:iAdiab] = IAdiab.((edges.cen_e,),(edges.iOtherOsgb,),1:L)
	edges[!,:adiabBool] = length.(edges.iAdiab).>0

	# Remap adiabatic edges and booleans back to parent polygons
	L = nrow(polygons)
	iMap = IMap.((edges.iPoly,),1:L)
	iAdiab′ = remap.((edges.iAdiab,),iMap)
	adiabBool′ = remap.((edges.adiabBool,),iMap)

	# Remove redundant vertices - first pass (matching centroids)
	iRm₁ = iRedundantVertices.(polygons.orient,8.)

	# Check that for the vertex targeted for removal, that the connected edges
	# ... are either both external, or both adiabatic (mixed should be retained)
	iRm₂ = iSelectiveVertexRemoval.(adiabBool′,iRm₁)

	# Remove redundant vertices
	n″ = RemoveRedundantVertices.(polygons.n,iRm₂,0)
	e″ = RemoveRedundantVertices.(polygons.e,iRm₂,0)
	iAdiab″ = RemoveRedundantVertices.(iAdiab′,iRm₂,-1)
	adiabBool″ = RemoveRedundantVertices.(adiabBool′,iRm₂,-1)

	return n″, e″, iAdiab″, adiabBool″
end

function CompilePolygons(n,e)
	Orient(nᵢ,eᵢ) = atan.(diff(nᵢ)./diff(eᵢ))
	L = nrow(project.dat["master"])
	# Evaluate edge orientations
	orient = Orient.(n,e)
	# Eval diffs and centroids
	Δn = diff.(n)
	Δe = diff.(e)
	cen_n = [n[i][1:end-1] .+ Δn[i]./2 for i in 1:L]
	cen_e = [e[i][1:end-1] .+ Δe[i]./2 for i in 1:L]
	# Combine in DataFrame
	polygons = DataFrame(
		:n=>n,
		:e=>e,
		:Δn=>Δn,
		:Δe=>Δe,
		:cen_n=>cen_n,
		:cen_e=>cen_e,
		:orient=>orient
	)
	return polygons
end
#-----------------------------------------------------------
function ProcessGeom(project)
	# Gather vertices, diffs, and centroids
	n = deepcopy(project.dat["master"].northings_GML)
	e = deepcopy(project.dat["master"].eastings_GML)

	# First pass (pre-clean)
	polygons = CompilePolygons(n,e)
	# Find adiabatics and remove redundant vertices
	n, e, iAdiab, adiabBool = FindAdiabatics(project,polygons)
	# Second pass (post-clean)
	polygons = CompilePolygons(n,e)
	polygons[!,:iAdiab] = iAdiab
	polygons[!,:adiabBool] = adiabBool

	# polygons = Orientation(project,polygons)

	return polygons
end
