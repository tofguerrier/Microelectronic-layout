;List procedure:
; createT3

; Skill to create A T3 surrounding around a particular cell
;cv = dbOpenCellViewByType("librarytest" "celltest" "layout")

procedure( CreateT3(@optional (cv deGetCellView()))

	;need to define local variable with let !!!!
	;let(bbox, list_layer urx, ury, llx, lly)
	; Check if there is already T3
	list_layer = cv~>lpps~>layerName
	; if T3 already present don't do anything
	if((member "T3" list_layer) then
		printf("T3 layer is already present, aborting operation\n")
	else

		;; Variables
		;; should try to get some of those variables from techfile
		; use rectangular bbox need override if other boundary shape
		bbox = cv~>bBox
		offset = 0.5
		; min spacing between 2 pwell of different grounding, ie min width of nwell separation isolated pwell from main pwell
		WidthNwell = 1.2
		; Offset of Nwell path over T3, so inside nwell enclosure  is 0.4
		OffsetNW = ( WidthNwell / 2 ) - 0.4
		; Distance of center of nw-tap to T3
		OffsetTap = 0.1
		; Distance of diode to tap
		OffsetDiode = OffsetTap + 0.5
		;Width Active RX
		WidthRX = 0.078
		WidthM1 = 0.080
		WidthBP = 0.12

		; need to add check on min size box
		ll = lowerLeft(bbox)
		ur = upperRight(bbox)
		llx = xCoord(ll) - offset
		lly = yCoord(ll) - offset
		urx = xCoord(ur) + offset
		ury = yCoord(ur) + offset


		printf("Create T3\n")
		;oversized by offset
		rodCreateRect(?cvId cv ?layer list("T3" "drawing") ?bBox list((llx:lly) (urx:ury)))
		printf("Add Nwell\n")
		rodCreatePath(
			?cvId cv
			?layer list("NW" "drawing")
			?pts list((llx + OffsetNW):(ury + OffsetNW) (urx + OffsetNW):(ury + OffsetNW) (urx + OffsetNW):(lly - OffsetNW) (llx - OffsetNW):(lly - OffsetNW) (llx - OffsetNW):(ury + OffsetNW) (llx + OffsetNW):(ury +  OffsetNW))
			?width WidthNwell
			?justification "center"
		)
		printf("AddNwell Tap\n")
		; Nwell tap
		rodCreatePath(
			?cvId cv
			?layer list("RX" "drawing")
			?pts list((llx + WidthNwell):(ury + OffsetTap) (urx - WidthNwell):(ury + OffsetTap))
			?width WidthRX
			?justification "center"
			?offset	 0.000000
			?choppable	 t
			?encSubPath	 list(
			list(
				?layer	 list("M1" "drawing")
				?enclosure	 0.014000
				?choppable	 t
				?beginOffset	 0.007000
				?endOffset	 0.007000
				)
			)
			?subRect	 list(
			list(
				?layer	 list("CA" "drawing")
				?width	 0.040000
				?length	 0.040000
				?choppable	 t
				?sep	 0.000000
				?justification	 "center"
				?space	 0.092000
				?beginOffset	 -0.01400ddGetObj(0
				?endOffset	 -0.014000
				?beginSegOffset	 0.151000
				?endSegOffset	 -0.151000
				?gap	 "minimum"
			)

		)


		)
		; nwell diode
		rodCreatePath(
			?cvId cv
			?layer list("RX" "drawing")
			?pts list((llx + WidthNwell):(ury + OffsetDiode) (urx - WidthNwell):(ury + OffsetDiode))
			?width WidthRX
			?justification "center"
			?choppable	 nil
			?endType	 "truncate"
			?beginExt	 0.000000
			?endExt	 0.000000
			?offset	 0.000000
			?encSubPath	 list(
			list(
				?layer	 list("M1" "drawing")
				?enclosure	 0.016000
				?choppable	 t
				?beginOffset	 0.007000
				?endOffset	 0.007000
			)
			list(
				?layer	 list("BP" "drawing")
				?enclosure	 -0.056000
				?choppable	nil
				?beginOffset	 0.021000
				?endOffset	 0.021000
			)
			)
			?subRect	 list(
			list(
				?layer	 list("CA" "drawing")
				?width	 0.040000
				?length	 0.040000
				?choppable	 t
				?sep	 0.000000
				?justification	 "center"
				?space	 0.092000
				?beginOffset	 -0.014000
				?endOffset	 -0.014000
				?beginSegOffset	 0.151000
				?endSegOffset	 -0.151000
				?gap	 "minimum"
			)
			)
		)
		; connect diode and tap
		rodCreatePath(
			?cvId cv
			?layer list("M1" "drawing")
			?pts list(((llx + urx)/2):(ury + OffsetDiode) ((llx + urx)/ 2):(ury + OffsetTap))
			?width (2 * WidthM1 )
			?justification "center"
			?choppable	 nil
			?endType	 "truncate"
			?beginExt	 0.000000
			?endExt	 0.000000
			?offset	 0.000000
		)


	) ;end if T3 exists
) ;end procedure
