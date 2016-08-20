; Display the centroid of a set of selected cells
; August 17, 2016 - UNTESTED
procedure(CGShowCentroid()
  let((cv)
  cv = geGetWindowCellView()

  ; Get All coords of selected set
  coordListX = nil
  coordListY = nil
  n = 0
  foreach(item geGetSelSet()
    ;printf("Selected item coordinate: %L\n" item~>xy)
    coordList = cons(item~>xy coordList)
    coordListX = cons(item~>x coordListX)
    coordListY = cons(item~>y coordListY)
    llb = lowerLeft(item~>bBox)
    urb = upperRight(item~>bBox)
    n = n + 1
) 

if (n != 0
  foreach(x coordListX
    sumx = x + sumx
    )
foreach(y coordListY
    sumy = y + sumy
    )
  
   )

showMarker(sumx/n,sumy/n)

) ; let

) ; procedure
