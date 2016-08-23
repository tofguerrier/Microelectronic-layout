;Create Matched Line
/*
; Remaining issues
Connection at angle - only one path is connected
45 degree swap and routing !
*/



;--------------------------------------------------------------------------
; procedure to determine swap layer
procedure(DetermineSwapLayer(metalname)
	; could this be done with regexp sub ?
	prog((lower_metal via2connect)
		cond(
		((metalname == "M2") lower_metal = "M1" via2connect = "V1")
		((metalname == "M3") lower_metal = "M2" via2connect = "V2")
		((metalname == "M4") lower_metal = "M3" via2connect = "V3")
		((metalname == "M5") lower_metal = "M4" via2connect = "V4")
		((metalname == "M6") lower_metal = "M5" via2connect = "V5")
		((metalname == "M7") lower_metal = "M6" via2connect = "V6")
		((metalname == "IA") lower_metal = "M7" via2connect = "YX")
		((metalname == "IB") lower_metal = "IA" via2connect = "XA")
		((metalname == "LB") lower_metal = "IB" via2connect = "VV")
		(t lower_metal = "M5" via2connect = "V5" metalname = "M6" ))
	return(list(lower_metal via2connect metalname))
	)
)

;-------------------------------------------------------------------------
procedure(GetDirection(pt1 pt2)
	prog((direction)
	cond(
	((xCoord(pt1) == xCoord(pt2) && (yCoord(pt1) < yCoord(pt2))) direction = "vertical")
	((xCoord(pt1) == xCoord(pt2) && (yCoord(pt1) > yCoord(pt2))) direction = "vertical_revert")
	((xCoord(pt1) < xCoord(pt2) && (yCoord(pt1) == yCoord(pt2))) direction = "horizontal")
	((xCoord(pt1) > xCoord(pt2) && (yCoord(pt1) == yCoord(pt2))) direction = "horizontal_revert")
	((xCoord(pt1) == xCoord(pt2) && (yCoord(pt1) == yCoord(pt2))) direction = "identical_points")
	(t direction= "at_angle")
	)
	return(direction)
	)
)
;-------------------------------------------------------------------------
;get technology information
procedure(GetTechInfo(@optional (cv deGetCellView()))
	let((libName tfId rules myRule layerName listlayer)
	listlayer=list("M1" "M2" "M3" "M4" "M5" "M6" "M7" "IA" "IB" "LB" "V1" "V2" "V3" "V4" "V5" "V6" "YX" "XA" "VV")
	;get libName
	libName = cv~>libName	
	;technology file ID
	tfid = techGetTechFile(ddGetObj(libName))
	rules = techGetSpacingRules(tfid)
	;to get specific via
	;rules_via = techGetParam(tfid "viaspacing")
	;voluntary left global table to be ready for access later
	SpacingTable = makeTable("LayerName" 0)
	WidthTable = makeTable("LayerName" 0)
	DiagSpacingTable = makeTable("LayerName" 0)
	DiagWidthTable = makeTable("LayerName" 0)
	foreach( elem rules
		layerName = car(cdr(cdr(elem)))
		;println(layerName)
		if(member(layerName listlayer) then
			;println(car(elem))
			;println(car(cdr(elem)))
			cond(
				((car(elem) == "minWidth") 		WidthTable[layerName] = car(cdr(elem)))
				((car(elem) == "viaSpacing") 		SpacingTable[layerName] = car(cdr(cddddr(cddddr(car(cdr(elem)))))))   
				((car(elem) == "minViaSpacing") 	SpacingTable[layerName] = car(cdr(elem)))   
				((car(elem) == "minDiagonalWidth") 	DiagWidthTable[layerName] = car(cdr(elem))) 
				((car(elem) == "minDiagonalSpacing")  	DiagSpacingTable[layerName] = car(cdr(elem)))
			)
		)
	)
	length(DiagWidthTable)
	length(DiagSpacingTable)
	length(WidthTable)
	length(SpacingTable)
	);let
);procedure
;-------------------------------------------------------------------------
;procedure to check the values of width and spacing
procedure(CheckSpaceAndWidthValue(cv spacing width metalname)
	GetTechInfo(cv)
	if(width < DiagWidthTable[metalname] then width = DiagWidthTable[metalname])
	if(spacing < DiagSpacingTable[metalname] then spacing = DiagSpacingTable[metalname])
	; spacing must be >= 2 width
	if(spacing < (3 * width) then spacing = ( 3 * width ) )
	;println("Updating width and spacing")
	;println(metalname)
	;println(spacing)
	;println(width)
)

;--------------------------------------------------------------------------
;create 2 parallel lines in a given metal
;this proc work with negative coordinates and at angle.
procedure(CreateParallelLines(cv, metalname, width, spacing, coord_in, coord_out)
	
	CheckSpaceAndWidthValue(cv spacing width metalname)
	if(spacing < (3 * width) then spacing = ( 3 * width ) )

	rodCreatePath(
			?cvId cv
			?layer list(metalname "drawing")
			?pts list(coord_in coord_out)
			?width width
			?justification "center"
			?offset (0-spacing/2)
			?offsetSubPath list(
				list(
				?layer list(metalname "drawing")
				?width width
				?justification "center"
				?sep spacing
				))
			
		)
)

;--------------------------------------------------------------------------
procedure(CreatCornerLines(cv, metalname, width, spacing, pt1, pt2, pt3)
	let((pt1c pt1d pt2c pt2d pt3c pt3d direction transvalue)
		transvalue = spacing / 2
		;use dbTransformPointPOint(l_point l_list)
		; where l_list displacement vector offset, rotation magnification
		pt1c = dbTransformPoint(pt2 list(0:transvalue "R0" 1.0))
		pt1d = dbTransformPoint(pt2 list(0:(0-transvalue) "R0" 1.0))
		pt3c = dbTransformPoint(pt2 list(transvalue:0 "R0" 1.0))
		pt3d = dbTransformPoint(pt2 list((0 - transvalue):0 "R0" 1.0))
		cond(
			;horizontal then turn right down
			((xCoord(pt1) == xCoord(pt2) && yCoord(pt1) < yCoord(pt2) && yCoord(pt3) < yCoord(pt2)) direction = 1)
			;horizontal then turn up left
			((xCoord(pt1) == xCoord(pt2) && yCoord(pt1) < yCoord(pt2) && yCoord(pt3) > yCoord(pt2)) direction = -1)
			((yCoord(pt1) == yCoord(pt2) && xCoord(pt1) < xCoord(pt2) && xCoord(pt3) < xCoord(pt2)) direction = 1)
			((yCoord(pt1) == yCoord(pt2) && xCoord(pt1) < xCoord(pt2) && xCoord(pt3) > xCoord(pt2)) direction = -1)
			((xCoord(pt1) == xCoord(pt2) && yCoord(pt1) > yCoord(pt2) && yCoord(pt3) < yCoord(pt2)) direction = -1)
			((xCoord(pt1) == xCoord(pt2) && yCoord(pt1) > yCoord(pt2) && yCoord(pt3) > yCoord(pt2)) direction = 1)
			((yCoord(pt1) == yCoord(pt2) && xCoord(pt1) > xCoord(pt2) && xCoord(pt3) < xCoord(pt2)) direction = -1)
			((yCoord(pt1) == yCoord(pt2) && xCoord(pt1) > xCoord(pt2) && xCoord(pt3) > xCoord(pt2)) direction = 1)



			(t direction = 1)
		)
		
		pt2c = dbTransformPoint(pt2 list(direction*transvalue:transvalue "R0" 1.0))
		pt2d = dbTransformPoint(pt2 list(direction*(0 - transvalue):(0 - transvalue) "R0" 1.0))
		







	CheckSpaceAndWidthValue(cv spacing width metalname)
	if(spacing < (3 * width) then spacing = ( 3 * width ) )
	rodCreatePath(
			?cvId cv
			?layer list(metalname "drawing")
			?pts list(pt1c pt2c pt3c)
			?width width
			?justification "center"
			?offset 0
		)
	rodCreatePath(
			?cvId cv
			?layer list(car(DetermineSwapLayer(metalname)) "drawing")
			?pts list(pt1d pt2d pt3d)
			?width width
			?justification "center"
			?offset 0
		)
	);let
);procedure



;--------------------------------------------------------------------------
;create swap
procedure(CreateLineSwap(cv,metalname,width,spacing,coord_in,coord_out)

	CheckSpaceAndWidthValue(cv spacing width metalname)

	if(spacing < (3 * width) then spacing = ( 3 * width ) )

	let( (xin xout yout yin tmpy tmpx viaw length_swap distance_coord gridu)
	; check coord_in/ccord_out are leaving enough space to make the swap
	xin = xCoord(coord_in)
	yin = yCoord(coord_in)
	xout = xCoord(coord_out)
	yout = yCoord(coord_out)
	viaw = width
	if( xout <= xin then
		tmpx = xin
		xin = xout
		xout = tmpx
	)
	if( yout <= yin then
		tmpy = yin
		yin = yout
		yout = tmpy
	)
	gridu = 0.001 ; use to avoid case where distance_coord get rounded down - floating point operation
	distance_coord = sqrt( (xout-xin)**2 + (yout-yin)**2) + gridu 
	length_swap = viaw*2 + spacing 
	
	
	cond(
		((distance_coord < length_swap )
			;not enough space to do the swap
		println("Warning: not enough space to do the swap, go straight")
		println(distance_coord)
		println(length_swap)
		CreateParallelLines(cv, metalname, width, spacing, coord_in,coord_out)
		)
		((yin == yout) 
		;Horizontal swap+5*DIST+2*WI+SP
			rodCreatePath(
				?cvId cv
				?layer list(metalname "drawing")
				?pts list(xin:yin+(spacing/2) xin+viaw:yin+(spacing/2) xin+viaw+spacing:yout-(spacing/2) xout:yout-(spacing/2)) 
				?width width
				?justification "center"
				?offset 0.0
			)
			rodCreatePath(
				?cvId cv
				?layer list(car(DetermineSwapLayer(metalname)) "drawing")
				?pts list(xin:yin-(spacing/2) xin+viaw:yin-(spacing/2) xin+viaw+spacing:yout+(spacing/2) xout:yout+(spacing/2)) 
				?width width
				?justification "center"
				?offset 0.0
			)
			via2use = car(cdr(DetermineSwapLayer(metalname)))
			rodCreatePath(
				?cvId cv
				?layer list(metalname "drawing")
				?pts list(xin:yin-(spacing/2) xin+viaw:yin-(spacing/2)) 
				?width width
				?justification "center"
				?offset 0.0
				?subRect list(
					list(
					?layer list(via2use "drawing")
					?width WidthTable[via2use] 
					?length WidthTable[via2use] 
					?choppable	 t
					?sep	0.000000
					?justification	 "center"
					?space	SpacingTable[via2use]
					?beginOffset	 -0.014000
					?endOffset	 -0.014000
					?beginSegOffset	 0.151000
					?endSegOffset	 -0.151000
					?gap	 "minimum"
				))
			)
			rodCreatePath(
				?cvId cv
				?layer list(metalname "drawing")
				?pts list(xin+viaw+spacing:yout+(spacing/2) xout:yout+(spacing/2)) 
				?width width
				?justification "center"
				?offset 0.0
				?subRect list(
					list(
					?layer list(via2use "drawing")
					?width WidthTable[via2use] 
					?length WidthTable[via2use] 
					?choppable	 t
					?sep	0.000000
					?justification	 "center"
					?space	SpacingTable[via2use]
					?beginOffset	 -0.014000
					?endOffset	 -0.014000
					?beginSegOffset	 0.151000
					?endSegOffset	 -0.151000
					?gap	 "minimum"
				))
			)
		)
		((xin == xout) 
		;Vertical swap
			rodCreatePath(
				?cvId cv
				?layer list(metalname "drawing")
				?pts list(xin+(spacing/2):yin xin+(spacing/2):yin+viaw xout-(spacing/2):yin+viaw+spacing xout-(spacing/2):yout) 
				?width width
				?justification "center"
				?offset 0.0
			)
			rodCreatePath(
				?cvId cv
				?layer list(car(DetermineSwapLayer(metalname)) "drawing")
				?pts list(xin-(spacing/2):yin xin-(spacing/2):yin+viaw xout+(spacing/2):yin+viaw+spacing xout+(spacing/2):yout) 
				?width width
				?justification "center"
				?offset 0.0
			)
			via2use = car(cdr(DetermineSwapLayer(metalname)))
			rodCreatePath(
				?cvId cv
				?layer list(metalname "drawing")
				?pts list(xin-(spacing/2):yin xin-(spacing/2):yin+viaw) 
				?width width
				?justification "center"
				?offset 0.0
				?subRect list(
					list(
					?layer list(via2use "drawing")
					?width WidthTable[via2use] 
					?length WidthTable[via2use] 
					?choppable	 t
					?sep	0.000000
					?justification	 "center"
					?space	SpacingTable[via2use]
					?beginOffset	 -0.014000
					?endOffset	 -0.014000
					?beginSegOffset	 0.151000
					?endSegOffset	 -0.151000
					?gap	 "minimum"
				))
			)
			rodCreatePath(
				?cvId cv
				?layer list(metalname "drawing")
				?pts list(xout+(spacing/2):yin+viaw+spacing xout+(spacing/2):yout) 
				?width width
				?justification "center"
				?offset 0.0
				?subRect list(
					list(
					?layer list(via2use "drawing")
					?width WidthTable[via2use] 
					?length WidthTable[via2use] 
					?choppable	 t
					?sep	0.000000
					?justification	 "center"
					?space	SpacingTable[via2use]
					?beginOffset	 -0.014000
					?endOffset	 -0.014000
					?beginSegOffset	 0.151000
					?endSegOffset	 -0.151000
					?gap	 "minimum"
				))
			)
		)
		(t 
		; not horizontal nor evrtical go for straight lines
		CreateParallelLines(cv, metalname, width, spacing, coord_in,coord_out)
		)
	);cond
	);let
);procedure

;-------------------------------------------------------------------------
; PB all coordinates have to be positive !!
; via not array
procedure(CreatMatchedLines(cv, metalname, width, spacing, list_points)
	let((lenp pt1 pt2 nis si lbs lis xstart xS1end xS2end xS3end ystart yS1end yS2end yS3end xpt2s ypt2s)
	;need to make sure this function can override.
	println("Check width space values")
	CheckSpaceAndWidthValue(cv spacing width metalname)
	
	;Number of iteration to go straight

	si = 10
	;Length Basic Segment, also length of swap
	lbs = width
	;

	
	;Need to divide the path into section of 4Sp and 1 Sp
	;thenon 4sp segments draw straight lines and 1 sp swap
	; very similar to cut shape skill
	lenp = length(list_points)
; DEBUG 		println(lenp)
	if(lenp < 2 then println("Error, not enough points")
	else
	for(i 1 (lenp - 1)
		pt1 = nthelem( i list_points )
		pt2 = nthelem( (i+1) list_points )
		direction = GetDirection(pt1 pt2)
		if( (i != 1 && i != (lenp - 1) ) then
			CreatCornerLines(cv, metalname, width, spacing, nthelem( (i-1) list_points ), pt1, pt2)
		)
		;reverting coordinates
		; DEBUG 	println(direction)
		; DEBUG 	println(pt1)
		; DEBUG 	println(pt2)
		cond(
		((direction == "vertical_revert") ptx=pt1 pt1=pt2 pt2=ptx)
		((direction == "horizontal_revert") ptx=pt1 pt1=pt2 pt2=ptx)
		)
		;splitting segments
		cond(
			((direction == "vertical" || direction == "vertical_revert")  length_segment = yCoord(pt2) - yCoord(pt1) )
			((direction == "horizontal" || direction == "horizontal_revert")  length_segment = xCoord(pt2) - xCoord(pt1) )
			((direction == "at_angle")  length_segment = sqrt((xCoord(pt2) - xCoord(pt1))**2 + (yCoord(pt2)-yCoord(pt1))**2))
		)
		; DEBUG println(length_segment)
		;Calculate number of swap. intermediates segment
		; one intermediate segment =
		; (si-1) * lbs of straight line
		; + lbs + 2*width for the swap
		; lbs of straight lines
		; in case of line at angles no swap !!
		; Lengtyh Intermediate Segment
		lis = ( si * lbs + 4 * width + lbs )
		;Number of intermediate segments
		;DEBUG	println("xxxxxx")
		;DEBUG	println( length_segment / lis )
		nis = round( length_segment / lis ) - 1
		;DEBUG	println(nis)
		if((nis <= 0 || direction == "at_angle") then CreateParallelLines(cv1, metalname, width, spacing, pt1, pt2)
		else
			xstart = xCoord(pt1) 
			ystart = yCoord(pt1)

			for(iteration 1 nis
				/* DEBUG message 
				println("xxxxxx")
				println(pt1)
				println(pt2)
				println(xstart)
				println(ystart)
				*/
				cond(
				((direction == "vertical" || direction == "vertical_revert")
					xS1end=xstart
					yS1end=ystart+((si-1)*lbs)
					xS2end=xstart
					yS2end=yS1end+4*width+lbs
					xS3end=xstart
					yS3end=yS2end+lbs
					;adjust to simplify connection between segments
					if( (iteration == 1) then ystart = ystart + spacing/2)
				)
				((direction == "horizontal" || direction == "horizontal_revert")
					xS1end=xstart+((si-1)*lbs)
					yS1end=ystart
					xS2end=xS1end+4*width+lbs
					yS2end=ystart
					xS3end=xS2end+lbs
					yS3end=ystart
					;adjust to simplify connection between segments
					if( (iteration == 1) then xstart = xstart + spacing/2)
				)
				)
			CreateParallelLines(cv1, metalname, width, spacing, xstart:ystart, xS1end:yS1end)
			CreateLineSwap(cv1, metalname, width, spacing, xS1end:yS1end, xS2end:yS2end)
			CreateParallelLines(cv1, metalname, width, spacing, xS2end:yS2end, xS3end:yS3end)
			xstart=xS3end
			ystart=yS3end
			)
		;Finish with straigth line.
				;adjustemnt to ease connection
				cond(
				((direction == "vertical" || direction == "vertical_revert")
					xpt2s = xCoord(pt2)
					ypt2s = yCoord(pt2) - (spacing/2) + (width/2)
				)
				((direction == "horizontal" || direction == "horizontal_revert")
					xpt2s = xCoord(pt2) - (spacing/2) + (width/2)
					ypt2s = yCoord(pt2)
				)
				)
			CreateParallelLines(cv1, metalname, width, spacing, xstart:ystart, xpt2s:ypt2s)
		);if nis

		); for each points
	);if check length list points
);let
);proc

;-------------------------------------------------------------------------
procedure(CreateMatchedLinesFromSelectedPath(@optional (cv deGetCellView()) (path geGetSelectedSet(deGetCellView())))
	let((metalname listValidLayer width spacing list_pts)
 	if(car(path~>objType) == "path" then
 		metalname = car(path~>layerName)
		listValidLayer = list("M2" "M3" "M4" "M5" "M6" "M7" "IB" "IB" "LB")
		if( member(metalname listValidLayer) then
			println("Valid layer")
		else
			metalname = "M5"
		)
		;get points
 		list_pts = car(path~>points)
 		width = car(path~>width)
		GetTechInfo()
		if( (width < DiagWidthTable[metalname]) then width = DiagWidthTable[metalname] ) 
 		spacing = 3 * width
		CreatMatchedLines(cv, metalname, width, spacing, list_pts)
 	else
 		println("Error: Not a path selected.. aborting")
 	);if path
	);let
)



;-------------------------------------------------------------------------
;TEST
procedure(testit()
cv1=deGetCellView()
WI = 0.5
SP = 2 * WI
DIST = 2 * SP

	
for(j 0 20
	i = 5 * DIST * j
	dist = 0
	for(n 0 10
	CreateParallelLines(cv1, "M7", WI, SP, dist:i,dist+5*DIST:i)
	CreateLineSwap(cv1,"M7", WI, SP, dist+5*DIST:i,dist+5*DIST+3*WI+SP:i)
	CreateParallelLines(cv1, "M7", WI, SP, dist+5*DIST+3*WI+SP:i,dist+7*DIST:i)
	dist = dist + 7*DIST
	)
)

	
for(j 0 20
	ix = 2*dist + 5 * DIST * j
	dista = 0
	for(n 1 20
	CreateParallelLines(cv1, "M3", WI, SP, ix:dista,ix:dista+5*DIST)
	CreateLineSwap(cv1,"M3", WI, SP, ix:dista+5*DIST,ix:dista+5*DIST+3*WI+SP)
	CreateParallelLines(cv1, "M3", WI, SP, ix:dista+5*DIST+3*WI+SP,ix:dista+7*DIST)
	dista = dista + 7*DIST
	;println(dista)
	)
)



;L1 = list((7.047 7.979) (22.523 7.979) (22.523 20.417) (31.168 20.417) (31.168 28.571))
/*
p1 = car(geGetSelectedSet(deGetCellView())~>points)
CreatMatchedLines(cv1, "M5", 1.0, 3.0, p1)
*/

;CreateLineSwap(cv1,"M5", 1.0, 1,0:0,-40:0)

;CreateLineSwap(cv1,"M6", 1.0, 1,0:0,0:-40)

;CreateLineSwap(cv1,"M6", 1.0, 1,10:10,10:40)

;CreateLineSwap(cv1,"M7", 1.0, 1,40:40,50:-40)

;CreateParallelLines(cv1, "M5", 2.0, 1.0, 0:0,30:25)
)

