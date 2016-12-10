#' Alkire-Foster multimensional poverty class
#'
#' Estimate indices from the Alkire-Foster class, a class of poverty measures.
#'
#' @param formula a formula specifying the variables. Variables can be numeric or ordered factors.
#' @param design a design object of class \code{survey.design} or class \code{svyrep.design} from the \code{survey} library.
#' @param g a scalar defining the exponent of the indicator.
#' @param cutoffs a list defining each variable's deprivation limit.
#' @param k a scalar defining the multimensional cutoff.
#' @param dimw a vector defining the weight of each dimension in the multidimensional deprivation sum.
#' @param na.rm Should cases with missing values be dropped?
#' @param ... future expansion
#'
#' @details you must run the \code{convey_prep} function on your survey design object immediately after creating it with the \code{svydesign} or \code{svrepdesign} function.
#'
#' @return Object of class "\code{cvystat}", which are vectors with a "\code{var}" attribute giving the variance and a "\code{statistic}" attribute giving the name of the statistic.
#'
#' @author Guilherme Jacob, Djalma Pessoa and Anthony Damico
#'
#' @seealso \code{\link{svyfgt}}
#'
#' @references Sabina Alkire and James Foster (2011). Counting and multidimensional poverty measurement.
#' Journal of Public Economics, v. 95, n. 7-8, August 2011, pp. 476-487, ISSN 0047-2727.
#' URL \url{http://dx.doi.org/10.1016/j.jpubeco.2010.11.006}.
#'
#' Alkire et al. (2015). Multidimensional Poverty Measurement and Analysis. Oxford University Press, 2015.
#'
#' Daniele Pacifico and Felix Poege (2016). MPI: Stata module to compute the Alkire-Foster multidimensional poverty measures and their decomposition by deprivation indicators and population sub-groups.
#' URL \url{http://EconPapers.repec.org/RePEc:boc:bocode:s458120}.
#'
#' @keywords survey
#'
#' @examples
#' library(survey)
#' library(vardpoor)
#' data(eusilc) ; names( eusilc ) <- tolower( names( eusilc ) )
#'
#' # linearized design
#' des_eusilc <- svydesign( ids = ~rb030 , strata = ~db040 ,  weights = ~rb050 , data = eusilc )
#' des_eusilc <- convey_prep(des_eusilc)
#' des_eusilc <- update(des_eusilc, pb220a = ordered( pb220a ) )
#'
#' # replicate-weighted design
#' des_eusilc_rep <- as.svrepdesign( des_eusilc , type = "bootstrap" )
#' des_eusilc_rep <- convey_prep(des_eusilc_rep)
#'
#' # cutoffs
#' cos <- list( 10000, 5000 )
#'
#' # variables without missing values
#' svyafc( ~ eqincome + hy050n , design = des_eusilc , k = .5 , g = 0, cutoffs = cos )
#' svyafc( ~ eqincome + hy050n , design = des_eusilc_rep , k = .5 , g = 0, cutoffs = cos )
#'
#' # subsetting:
#' sub_des_eusilc <- subset( des_eusilc, db040 == "Styria")
#' sub_des_eusilc_rep <- subset( des_eusilc_rep, db040 == "Styria")
#'
#' svyafc( ~ eqincome + hy050n , design = sub_des_eusilc , k = .5, g = 0, cutoffs = cos )
#' svyafc( ~ eqincome + hy050n , design = sub_des_eusilc_rep , k = .5, g = 0, cutoffs = cos )
#'
#' # including factor variable with missings
#' cos <- list( 10000, 5000, "EU" )
#' svyafc(~eqincome+hy050n+pb220a, des_eusilc, k = .5, g = 0, cutoffs = cos , na.rm = FALSE )
#' svyafc(~eqincome+hy050n+pb220a, des_eusilc, k = .5, g = 0, cutoffs = cos , na.rm = TRUE )
#' svyafc(~eqincome+hy050n+pb220a, des_eusilc_rep, k = .5, g = 0, cutoffs = cos , na.rm = FALSE )
#' svyafc(~eqincome+hy050n+pb220a, des_eusilc_rep, k = .5, g = 0, cutoffs = cos , na.rm = TRUE )
#'
#' # library(MonetDBLite) is only available on 64-bit machines,
#' # so do not run this block of code in 32-bit R
#' \dontrun{
#'
#' # database-backed design
#' library(MonetDBLite)
#' library(DBI)
#' dbfolder <- tempdir()
#' conn <- dbConnect( MonetDBLite::MonetDBLite() , dbfolder )
#' dbWriteTable( conn , 'eusilc' , eusilc )
#'
#' dbd_eusilc <-
#' 	svydesign(
#' 		ids = ~rb030 ,
#' 		strata = ~db040 ,
#' 		weights = ~rb050 ,
#' 		data="eusilc",
#' 		dbname=dbfolder,
#' 		dbtype="MonetDBLite"
#' 	)
#'
#' dbd_eusilc <- convey_prep( dbd_eusilc )
#' dbd_eusilc <- update( dbd_eusilc, pb220a = ordered( pb220a ) )
#'
#' # cutoffs
#' cos <- list( 10000 , 5000 )
#'
#' # variables without missing values
#' svyafc(~eqincome+hy050n, design = dbd_eusilc, k = .5, g = 0, cutoffs = cos )
#'
#' # subsetting:
#' sub_dbd_eusilc <- subset( dbd_eusilc, db040 == "Styria")
#' svyafc(~eqincome+hy050n, design = sub_dbd_eusilc, k = .5, g = 0, cutoffs = cos )
#'
#' # cutoffs
#' cos <- list( 10000, 5000, "EU" )
#'
#' # including factor variable with missings
#' svyafc(~eqincome+hy050n+pb220a, dbd_eusilc, k = .5, g = 0, cutoffs = cos , na.rm = FALSE )
#' svyafc(~eqincome+hy050n+pb220a, dbd_eusilc, k = .5, g = 0, cutoffs = cos , na.rm = TRUE )
#'
#' dbRemoveTable( conn , 'eusilc' )
#'
#' dbDisconnect( conn , shutdown = TRUE )
#'
#' }
#'
#' @export
svyafc <- function(formula, design, k = NULL, g = NULL, cutoffs = NULL, dimw = NULL, na.rm = FALSE, ...) {

  if ( k <= 0 | k > 1 ) { stop( "This functions is only defined for k in (0,1]." ) }
  if ( g < 0 ) { stop( "This function is undefined for g < 0." ) }
  if ( is.null( cutoffs ) ) { stop( "No dimensional cutoffs defined." ) }
  if ( !is.list( cutoffs ) ) { stop( "The parameter 'cutoffs' has to be a list." ) }

  UseMethod("svyafc", design)

}

#' @rdname svyafc
#' @export
svyafc.survey.design <- function( formula, design, k = NULL, g = NULL, cutoffs = NULL, dimw = NULL, na.rm = FALSE, ... ) {

  if (is.null(attr(design, "full_design"))) stop("you must run the ?convey_prep function on your linearized survey design object immediately after creating it with the svydesign() function.")

  ach.matrix <- model.frame(formula, design$variables, na.action = na.pass)[,]

  var.class <- lapply( ach.matrix, function(x) class(x)[1] )
  var.class <- matrix(var.class, nrow = 1, ncol = ncol(ach.matrix),
                      dimnames = list( c("var.class"), colnames( ach.matrix ) ) )

  if ( any( !( var.class %in% c( "numeric", "integer", "ordered" ) ) ) ) {
    stop( "This function is only applicable to variables of types 'numeric' or 'ordered factor'." )
  }
  if ( any( ( var.class == "integer" ) ) ) {
    stop( "At least one of the variables is an integer.\nCoerce your column to numeric with as.numeric if you are sure it's what you want." )
  }

  w <- 1/design$prob

  if ( any( ach.matrix[ w != 0, var.class == "numeric" ] < 0, na.rm = TRUE ) ) stop( "The Alkire-Foster multimensional poverty class is defined for non-negative numeric variables only.")
  
  if (na.rm) {
    nas <- apply( ach.matrix, 1, function(x) any( is.na(x) ) )
    design <- design[nas == 0, ]
    w <- 1/design$prob
  }

  ach.matrix <- model.frame(formula, design$variables, na.action = na.pass)[,]
  ach.matrix <- ach.matrix [ w > 0, ]
  w <- w [ w > 0 ]

  if ( any( is.na(ach.matrix) ) ) {

    rval <- as.numeric(NA)
    variance <- as.numeric(NA)
    class(rval) <- c( "cvystat" , "svystat" )
    attr(rval, "var") <- variance
    attr(rval, "statistic") <- "alkire-foster"
    attr(rval, "dimensions") <- matrix( strsplit( as.character( formula )[[2]] , ' \\+ ' )[[1]], nrow = 1, ncol = ncol(var.class), dimnames = list( "variables", paste("dimension", 1:ncol(var.class) ) ) )
    attr(rval, "parameters") <- matrix( c( g, k ), nrow = 1, ncol = 2, dimnames = list( "parameters", c( "g=", "k=" ) ) )
    return(rval)

  }


  # Deprivation Matrix
  dep.matrix <- ach.matrix
  for ( i in seq_along(cutoffs) ) {

    cut.value <- cutoffs[[i]]

    if ( is.numeric( cut.value ) ) {
      dep.matrix[ , i ] <- 1*( cut.value > ach.matrix[ , i ] )
    } else {
      dep.matrix[ , i ] <- 1*( cut.value > ach.matrix[ , i ] )
    }

  }

  # Unweighted count of deprivations:
  # depr.count <- rowSums( dep.matrix )

  # deprivation k cut
  if ( is.null(dimw) ) {
    dimw = rep( 1 / ncol(dep.matrix), ncol(dep.matrix) )
  }

  # Weighted sum of deprivations:
  depr.sums <- rowSums( dep.matrix * dimw )

  # k multidimensional cutoff:
  multi.cut <- depr.sums*( depr.sums >= k )
  rm(dep.matrix) ; gc()

  # Censored Deprivation Matrix
  cen.dep.matrix <- ach.matrix
  for ( i in seq_along(cutoffs) ) {

    cut.value <- cutoffs[[i]]

    if ( var.class[ i ] == "numeric" ) {
      cen.dep.matrix[ , i ] <- 1*( cut.value > ach.matrix[ , i ] ) * ( ( cut.value - ach.matrix[ , i ] ) / cut.value )^g
    } else {
      cen.dep.matrix[ , i ] <- 1*( cut.value > ach.matrix[ , i ] )
    }

  }

  cen.dep.matrix[ multi.cut == 0, ] <- 0

  # Sum of censored deprivations:
  cen.depr.sums <- rowSums( cen.dep.matrix * dimw )
  rm( cen.dep.matrix, ach.matrix ) ; gc()

  if ( any( is.na(cen.depr.sums) ) ) {
    rval <- as.numeric(NA)
    variance <- as.numeric(NA)
    class(rval) <- c( "cvystat" , "svystat" )
    attr(rval, "var") <- variance
    attr(rval, "statistic") <- "alkire-foster"
    attr(rval, "dimensions") <- matrix( strsplit( as.character( formula )[[2]] , ' \\+ ' )[[1]], nrow = 1, ncol = ncol(var.class), dimnames = list( "variables", paste("dimension", 1:ncol(var.class) ) ) )
    attr(rval, "parameters") <- matrix( c( g, k ), nrow = 1, ncol = 2, dimnames = list( "parameters", c( "g=", "k=" ) ) )
    return(rval)

  }


  w <- 1/design$prob
  w[ w > 0 ] <- cen.depr.sums
  cen.depr.sums <- w
  rm(w)

  if ( g == 0 ) {
    w <- 1/design$prob
    w[ w > 0 ] <- ( depr.sums >= k )
    h_i <- w
    rm(w)

    h_est <- survey::svymean( h_i, design )

    w <- 1/design$prob
    w[ w > 0 ] <- multi.cut
    multi.cut <- w
    rm(w)

    a_est <- survey::svyratio( multi.cut, h_i, design )


  }

  estimate <- survey::svymean( cen.depr.sums , design )
  #survey::svymean(cen.dep.matrix,design)

  rval <- estimate
  variance <- attr( estimate, "var" )
  class(rval) <- c( "cvystat" , "svystat" )
  attr(rval, "var") <- variance
  attr(rval, "statistic") <- "alkire-foster"
  attr(rval, "dimensions") <- matrix( strsplit( as.character( formula )[[2]] , ' \\+ ' )[[1]], nrow = 1, ncol = ncol(var.class), dimnames = list( "variables", paste("dimension", 1:ncol(var.class) ) ) )
  attr(rval, "parameters") <- matrix( c( g, k ), nrow = 1, ncol = 2, dimnames = list( "parameters", c( "g=", "k=" ) ) )
  if ( g == 0 ) {
    attr(rval, "extra") <- matrix( c( h_est[1], a_est[[1]], attr( h_est, "var" )[1]^.5, a_est[[2]]^.5 ), nrow = 2, ncol = 2, dimnames = list( c("H", "A"), c( "coef", "SE" ) ) )
  }

  return( rval )

}

#' @rdname svyafc
#' @export
svyafc.svyrep.design <- function(formula, design, k = NULL, g = NULL, cutoffs = NULL, dimw = NULL, na.rm=FALSE, ...) {
  if (is.null(attr(design, "full_design"))) stop("you must run the ?convey_prep function on your linearized survey design object immediately after creating it with the svydesign() function.")

  ach.matrix <- model.frame(formula, design$variables, na.action = na.pass)[,]

  var.class <- lapply( ach.matrix, function(x) class(x)[1] )
  var.class <- matrix(var.class, nrow = 1, ncol = ncol(ach.matrix),
                      dimnames = list( c("var.class"), colnames( ach.matrix ) ) )

  if ( any( !( var.class %in% c( "numeric", "integer", "ordered" ) ) ) ) {
    stop( "This function is only applicable to variables of types 'numeric' or 'ordered factor'." )
  }
  if ( any( ( var.class == "integer" ) ) ) {
    stop( "At least one of the variables is an integer.\nCoerce your column to numeric with as.numeric if you are sure it's what you want." )
  }

  w <- weights(design, "sampling" )

  if ( any( ach.matrix[ w != 0, var.class == "numeric" ] < 0, na.rm = TRUE ) ) stop( "The Alkire-Foster multimensional poverty class is defined for non-negative numeric variables only.")

  if (na.rm) {
    nas <- apply( ach.matrix, 1, function(x) any( is.na(x) ) )
    design <- design[nas == 0, ]
    w <- weights(design, "sampling" )
  }

  ach.matrix <- model.frame(formula, design$variables, na.action = na.pass)[,]
  ach.matrix <- ach.matrix [ w > 0, ]
  w <- w [ w > 0 ]


  if ( any( is.na(ach.matrix) ) ) {
    rval <- as.numeric(NA)
    variance <- as.numeric(NA)
    class(rval) <- c( "cvystat" , "svystat" )
    attr(rval, "var") <- variance
    attr(rval, "statistic") <- "alkire-foster"
    attr(rval, "dimensions") <- matrix( strsplit( as.character( formula )[[2]] , ' \\+ ' )[[1]], nrow = 1, ncol = ncol(var.class), dimnames = list( "variables", paste("dimension", 1:ncol(var.class) ) ) )
    attr(rval, "parameters") <- matrix( c( g, k ), nrow = 1, ncol = 2, dimnames = list( "parameters", c( "g=", "k=" ) ) )
    return(rval)

  }

  # Deprivation Matrix
  dep.matrix <- ach.matrix
  for ( i in seq_along(cutoffs) ) {

    cut.value <- cutoffs[[i]]

    if ( var.class[ i ] == "numeric" ) {
      dep.matrix[ , i ] <- 1*( cut.value > ach.matrix[ , i ] )
    } else {
      dep.matrix[ , i ] <- 1*( cut.value > ach.matrix[ , i ] )
    }

  }

  # Unweighted count of deprivations:
  # depr.count <- rowSums( dep.matrix )

  # deprivation k cut
  if ( is.null(dimw) ) {
    dimw = rep( 1 / ncol(dep.matrix), ncol(dep.matrix) )
  }

  # Weighted sum of deprivations:
  depr.sums <- rowSums( dep.matrix * dimw )

  # k multidimensional cutoff:
  multi.cut <- depr.sums*( depr.sums >= k )
  rm(dep.matrix) ; gc()

  # Censored Deprivation Matrix
  cen.dep.matrix <- ach.matrix
  for ( i in seq_along(cutoffs) ) {

    cut.value <- cutoffs[[i]]

    if ( is.numeric( cut.value ) ) {
      cen.dep.matrix[ , i ] <- 1*( cut.value > ach.matrix[ , i ] ) * ( ( cut.value - ach.matrix[ , i ] ) / cut.value )^g
    } else {
      cen.dep.matrix[ , i ] <- 1*( cut.value > ach.matrix[ , i ] )
    }

  }
  cen.dep.matrix[ multi.cut == 0, ] <- 0

  # Sum of censored deprivations:
  cen.depr.sums <- rowSums( cen.dep.matrix * dimw )
  rm( cen.dep.matrix, ach.matrix ) ; gc()

  if ( any( is.na(cen.depr.sums) ) ){

    rval <- as.numeric(NA)
    variance <- as.numeric(NA)
    class(rval) <- c( "cvystat" , "svystat" )
    attr(rval, "var") <- variance
    attr(rval, "statistic") <- "alkire-foster"
    attr(rval, "dimensions") <- matrix( strsplit( as.character( formula )[[2]] , ' \\+ ' )[[1]], nrow = 1, ncol = ncol(var.class), dimnames = list( "variables", paste("dimension", 1:ncol(var.class) ) ) )
    attr(rval, "parameters") <- matrix( c( g, k ), nrow = 1, ncol = 2, dimnames = list( "parameters", c( "g=", "k=" ) ) )
    return(rval)

    }

  if ( g == 0 ) {
    w <- weights(design, "sampling" )
    w[ w > 0 ] <- ( depr.sums >= k )
    h_i <- w
    rm(w)

    h_est <- survey::svymean( h_i, design )

    w <- weights(design, "sampling" )
    w[ w > 0 ] <- multi.cut
    multi.cut <- w
    rm(w)

    a_est <- survey::svyratio( multi.cut, h_i, design )

  }

  w <- weights(design, "sampling" )
  w[ w != 0 ] <- cen.depr.sums
  cen.depr.sums <- w
  rm(w)

  estimate <- survey::svymean(cen.depr.sums,design)
  #survey::svymean(cen.dep.matrix,design)

  rval <- estimate
  variance <- attr( estimate, "var" )
  class(rval) <- c( "cvystat" , "svystat" )
  attr(rval, "var") <- variance
  attr(rval, "statistic") <- "alkire-foster"
  attr(rval, "dimensions") <- matrix( strsplit( as.character( formula )[[2]] , ' \\+ ' )[[1]], nrow = 1, ncol = ncol(var.class), dimnames = list( "variables", paste("dimension", 1:ncol(var.class) ) ) )
  attr(rval, "parameters") <- matrix( c( g, k ), nrow = 1, ncol = 2, dimnames = list( "parameters", c( "g=", "k=" ) ) )
  if ( g == 0 ) {
    attr(rval, "extra") <- matrix( c( h_est[1], a_est[[1]], attr( h_est, "var" )[1]^.5, a_est[[2]]^.5 ), nrow = 2, ncol = 2, dimnames = list( c("H", "A"), c( "coef", "SE" ) ) )
  }

 return( rval )

}

#' @rdname svyafc
#' @export
svyafc.DBIsvydesign <-
  function (formula, design, ...) {

    if (!( "logical" %in% class(attr(design, "full_design"))) ){

      full_design <- attr( design , "full_design" )

      full_design$variables <- getvars(formula, attr( design , "full_design" )$db$connection, attr( design , "full_design" )$db$tablename,
                                       updates = attr( design , "full_design" )$updates, subset = attr( design , "full_design" )$subset)

      attr( design , "full_design" ) <- full_design

      rm( full_design )

    }

    design$variables <- getvars(formula, design$db$connection, design$db$tablename,
                                updates = design$updates, subset = design$subset)

    NextMethod("svyafc", design)
  }