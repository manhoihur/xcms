.validXChromatogram <- function(object) {
    txt <- character()
    if (nrow(object@chromPeaks)) {
        if (!all(.CHROMPEAKS_REQ_NAMES %in% colnames(object@chromPeaks)))
            txt <- c(txt, paste0("chromPeaks matrix does not have all required",
                                 " columns: ", paste(.CHROMPEAKS_REQ_NAMES,
                                                     collapse = ",")))
        if (!is.numeric(object@chromPeaks))
            txt <- c(txt, "chromPeaks should be a numeric matrix")
        if (!is.null(colnames(object@chromPeaks)) &&
            any(object@chromPeaks[, "rtmax"] < object@chromPeaks[, "rtmin"]))
            txt <- c(txt, "rtmax has to be larger than rtmin")
    }
    if (length(txt)) txt
    else TRUE
}

#' @title Containers for chromatographic and peak detection data
#'
#' @aliases XChromatogram-class XChromatograms-class coerce,Chromatograms,XChromatograms-method
#'
#' @description
#'
#' The `XChromatogram` object allows to store chromatographic data (e.g.
#' an extracted ion chromatogram) along with identified chromatographic peaks
#' within that data. The object inherits all functions from the [Chromatogram()]
#' object in the `MSnbase` package.
#'
#' Multiple `XChromatogram` objects can be stored in a `XChromatograms` object.
#' This class extends [Chromatograms()] from the `MSnbase` package and allows
#' thus to arrange chromatograms in a matrix-like structure, columns
#' representing samples and rows m/z-retention time ranges.
#'
#' All functions are described (grouped into topic-related sections) after the
#' **Arguments** section.
#'
#' @section Creation of objects:
#'
#' Objects can be created with the contructor function `XChromatogram` and
#' `XChromatograms`, respectively. Also, they can be coerced from
#' [Chromatogram] or [Chromatograms()] objects using
#' `as(object, "XChromatogram")` or `as(object, "XChromatograms")`.
#'
#' @param rtime For `XChromatogram`: `numeric` with the retention times
#'     (length has to be equal to the length of `intensity`).
#'
#' @param intensity For `XChromatogram`: `numeric` with the intensity values
#'     (length has to be equal to the length of `rtime`).
#'
#'     For `featureValues`: `character(1)` specifying the name
#'     of the column in `chromPeaks(object)` containing the intensity value
#'     of the peak that should be used for the `method = "maxint"` conflict
#'     resolution if.
#'
#' @param mz For `XChromatogram`: `numeric(2)` representing the m/z value
#'     range (min, max) on which the chromatogram was created. This is
#'     supposed to contain the *real* range of m/z values in contrast
#'     to the `filterMz` below.
#'     For `chromPeaks` and `featureDefinitions`: `numeric(2)` defining the
#'     m/z range for which chromatographic peaks or features should be returned.
#'     For `filterMz`: `numeric(2)` defining the m/z range for which
#'     chromatographic peaks should be retained.#'
#'
#' @param filterMz For `XChromatogram`: `numeric(2)` representing the m/z
#'     value range (min, max) that was used to filter the original object
#'     on m/z dimension. If not applicable use `filterMz = c(0, 0)`.
#'
#' @param precursorMz For `XChromatogram`: `numeric(2)` for SRM/MRM transitions.
#'     Represents the mz of the precursor ion. See details for more information.
#'
#' @param productMz For `XChromatogram`: `numeric(2)` for SRM/MRM transitions.
#'     Represents the mz of the product. See details for more information.
#'
#' @param fromFile For `XChromatogram`: `integer(1)` the index of the file
#'     within the `OnDiskMSnExp` or `MSnExp` object from which the chromatogram
#'     was extracted.
#'
#' @param aggregationFun For `XChromatogram`: `character(1)` specifying the
#'     function that was used to aggregate intensity values for the same
#'     retention time across the m/z range.
#'
#' @param msLevel For `XChromatogram`: `integer` with the MS level from which
#'     the chromatogram was extracted.
#'
#' @param chromPeaks For `XChromatogram`: `matrix` with required columns
#'     `"rt"`, `"rtmin"`, `"rtmax"`, `"into"`, `"maxo"` and `"sn"`.
#'     For `XChromatograms`: `list`, same length than `data`, with the
#'     chromatographic peaks for each chromatogram. Each element has to be
#'     a `matrix`, the ordering has to match the order of the chromatograms
#'     in `data`.
#'
#' @param object An `XChromatogram` or `XChromatograms` object.
#'
#' @param ... For `plot`: additional parameters to passed to the `plot`
#'     function.
#'     For `XChromatograms`: additional parameters to be passed to the
#'     [matrix] constructor, such as `nrow`, `ncol` and `byrow`.
#'
#' @return
#'
#' See help of the individual functions.
#'
#' @md
#'
#' @author Johannes Rainer
#'
#' @rdname XChromatogram
#'
#' @examples
#'
#' ## Create a XChromatogram object
#' pks <- matrix(nrow = 1, ncol = 6)
#' colnames(pks) <- c("rt", "rtmin", "rtmax", "into", "maxo", "sn")
#' pks[, "rtmin"] <- 2
#' pks[, "rtmax"] <- 9
#' pks[, "rt"] <- 4
#' pks[, "maxo"] <- 19
#' pks[, "into"] <- 93
#'
#' xchr <- XChromatogram(rtime = 1:10,
#'     intensity = c(4, 8, 14, 19, 18, 12, 9, 8, 5, 2),
#'     chromPeaks = pks)
#' xchr
XChromatogram <- function(rtime = numeric(), intensity = numeric(),
                          mz = c(NA_real_, NA_real_),
                          filterMz = c(NA_real_, NA_real_),
                          precursorMz = c(NA_real_, NA_real_),
                          productMz = c(NA_real_, NA_real_),
                          fromFile = integer(), aggregationFun = character(),
                          msLevel = 1L, chromPeaks) {
    if (missing(chromPeaks))
        chromPeaks <- matrix(ncol = length(.CHROMPEAKS_REQ_NAMES), nrow = 0,
                             dimnames = list(character(),
                                             .CHROMPEAKS_REQ_NAMES))
    else if (!is.matrix(chromPeaks))
        stop("'x' has to be a 'matrix'")
    x <- as(Chromatogram(rtime = rtime, intensity = intensity, mz = mz,
                         filterMz = filterMz, precursorMz = precursorMz,
                         productMz = productMz, fromFile = fromFile,
                         msLevel = msLevel), "XChromatogram")
    x@chromPeaks <- chromPeaks
    if (validObject(x)) x
}

#' Internal function to plot/draw identified chromatographic peaks in a
#' plot.
#'
#' @param x `XChromatogram` or an `XChromatograms` object.
#'
#' @param pks chromatographic peaks as returned by `chromPeaks(x)`.
#'
#' @noRd
.add_chromatogram_peaks <- function(x, pks, col, bg, type, pch, ...) {
    switch(type,
           point = {
               points(pks[, "rt"], pks[, "maxo"], pch = pch, col = col,
                      bg = bg, ...)
           },
           rectangle = {
               rect(xleft = pks[, "rtmin"], xright = pks[, "rtmax"],
                    ybottom = rep(0, nrow(pks)), ytop = pks[, "maxo"],
                    col = bg, border = col, ...)
           },
           polygon = {
               ordr <- order(pks[, "maxo"], decreasing = TRUE)
               pks <- pks[ordr, , drop = FALSE]
               col <- col[ordr]
               bg <- bg[ordr]
               xs_all <- numeric()
               ys_all <- numeric()
               for (i in seq_len(nrow(pks))) {
                   if (inherits(x, "XChromatograms")) {
                       chr <- filterRt(x[pks[i, "row"], pks[i, "column"]],
                                       rt = pks[i, c("rtmin", "rtmax")])
                   } else
                       chr <- filterRt(x, rt = pks[i, c("rtmin", "rtmax")])
                   xs <- rtime(chr)
                   if (!length(xs)) {
                       next
                       col <- col[-i]
                       bg <- bg[-i]
                   }
                   xs <- c(xs[1], xs, xs[length(xs)])
                   ys <- c(0, intensity(chr), 0)
                   nona <- !is.na(ys)
                   if (length(xs_all)) {
                       xs_all <- c(xs_all, NA)
                       ys_all <- c(ys_all, NA)
                   }
                   xs_all <- c(xs_all, xs[nona])
                   ys_all <- c(ys_all, ys[nona])
                   ## polygon(xs[nona], ys[nona], border = col[i], col = bg[i],
                   ##         ...)
               }
               polygon(xs_all, ys_all, border = col, col = bg, ...)
           })
}
