#' Choose cells from a plot of suitability surface.
#'
#' @param r this is the surface (a single raster layer)
#'
#' @export
chooseRefugeCells <- function(r)
{
    if ("RasterLayer" %in% class(r))
    {
        pr = r
        plot(pr,main="Press mouse #1 for center of refuge point")
        p <- locator(type="p",n=1)
        #rw = rowFromY(pr, p$y)
        rw = seq(nrow(pr),1)[rowFromY(pr, p$y)]
        cl = colFromX(pr, p$x)

        rcells = c(
            cellFromRowCol(pr, rw,cl),
            cellFromRowCol(pr, rw,cl+1),
            cellFromRowCol(pr, rw,cl-1),
            cellFromRowCol(pr, rw+1,cl),
            cellFromRowCol(pr, rw-1,cl)
        )
        #pr[cl,c((rw-1):(rw+1))] <- 1
        #pr[c((cl-1):(cl+1)),rw] <- 1
        pr[c((seq(nrow(pr),1)[rw]-1):(seq(nrow(pr),1)[rw]+1)),cl] <- 1
        pr[seq(nrow(pr),1)[rw],c((cl-1):(cl+1))] <- 1
        plot(pr,main="Refugium cells")
        return(rcells)
    } else {
        stop("r must be a raster layer")
    }

}
