; magnify, rotate and move selected figures
procedure(MagnifySelect()
   prog(list()
     figs = geGetSelSet()
     foreach(fig figs
        dbMoveFig(fig nil list(200:200 "R90" 4.0))
        )
      return(nil)
      )
      )
      
