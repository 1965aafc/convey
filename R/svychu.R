#' CHU class of poverty measures (EXPERIMENTAL)
#'
#' Estimate the Clark, Hemming and Ulph (1981) class of poverty measures
#'
#' @param formula a formula specifying the income variable
#' @param design a design object of class \code{survey.design} or class \code{svyrep.design} from the \code{survey} library.
#' @param type_thresh type of poverty threshold. If "abs" the threshold is fixed and given the value
#' of abs_thresh; if "relq" it is given by percent times the quantile; if "relm" it is percent times the mean.
#' @param abs_thresh poverty threshold value if type_thresh is "abs"
#' @param g A parameter where (1 - g) defines the inequality aversion among the poor. If g = 0, the CHU class becomes the Watts poverty measure.
#' @param percent the multiple of the the quantile or mean used in the poverty threshold definition
#' @param quantiles the quantile used used in the poverty threshold definition
#' @param thresh return the poverty threshold value
#' @param na.rm Should cases with missing values be dropped?
#' @param ... passed to \code{svyarpr} and \code{svyarpt}
#'
#' @details you must run the \code{convey_prep} function on your survey design object immediately after creating it with the \code{svydesign} or \code{svrepdesign} function.
#'
#' @return Object of class "\code{cvystat}", which are vectors with a "\code{var}" attribute giving the variance and a "\code{statistic}" attribute giving the name of the statistic.
#'
#' @author Guilherme Jacob, Djalma Pessoa and Anthony Damico
#'
#' @note This function is experimental and is subject to change in later versions.
#'
#' @seealso \code{\link{svyarpt}}
#'
#' @references Stephen Clark, Richard Hemming and David Ulph (1968). On Indices
#' for the Measurement of Poverty. \emph{The Economic Journal}, Vol.91, No.362, (Jun., 1981), pp. 515-526,
#' URL \url{http://www.jstor.org/stable/2232600}.
#'
#' Guillaume Osier (2009). Variance estimation for complex indicators
#' of poverty and inequality. \emph{Journal of the European Survey Research
#' Association}, Vol.3, No.3, pp. 167-195,
#' ISSN 1864-3361, URL \url{http://ojs.ub.uni-konstanz.de/srm/article/view/369}.
#'
#' Jean-Claude Deville (1999). Variance estimation for complex statistics and estimators:
#' linearization and residual techniques. Survey Methodology, 25, 193-203,
#' URL \url{http://www5.statcan.gc.ca/bsolc/olc-cel/olc-cel?lang=eng&catno=12-001-X19990024882}.
#'
#' @keywords survey
#'
#' @examples
#' library(survey)
#' library(vardpoor)
#' data(eusilc) ; names( eusilc ) <- tolower( names( eusilc ) )
#'
#' # linearized design
#'
#' des_eusilc <- svydesign( ids = ~rb030 , strata = ~db040 ,  weights = ~rb050 , data = eusilc )
#' des_eusilc <- convey_prep( des_eusilc )
#'
#' # replicate-weighted design
#' des_eusilc_rep <- as.svrepdesign( des_eusilc , type = "bootstrap" )
#' des_eusilc_rep <- convey_prep( des_eusilc_rep )
#'
#' # absolute poverty threshold
#' svychu(~eqincome, des_eusilc, g=1,  abs_thresh=10000)
#' # poverty threshold equal to arpt
#' svychu(~eqincome, des_eusilc, g=1, type_thresh= "relq" , thresh = TRUE)
#' # poverty threshold equal to 0.6 times the mean
#' svychu(~eqincome, des_eusilc, g=1, type_thresh= "relm" , thresh = TRUE)
#'
#' #  using svrep.design:
#' # absolute poverty threshold
#' svychu(~eqincome, des_eusilc_rep, g=1,  abs_thresh=10000)
#' # poverty threshold equal to arpt
#' svychu(~eqincome, des_eusilc_rep, g=1, type_thresh= "relq" , thresh = TRUE)
#' # poverty threshold equal to 0.6 times the mean
#' svychu(~eqincome, des_eusilc_rep, g=1, type_thresh= "relm" , thresh = TRUE)
#'
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
#'
#' dbd_eusilc <- convey_prep( dbd_eusilc )
#'
#' # absolute poverty threshold
#' svychu(~eqincome, dbd_eusilc, g=1,  abs_thresh=10000)
#' # poverty threshold equal to arpt
#' svychu(~eqincome, dbd_eusilc, g=1, type_thresh= "relq" , thresh = TRUE)
#' # poverty threshold equal to 0.6 times the mean
#' svychu(~eqincome, dbd_eusilc, g=1, type_thresh= "relm" , thresh = TRUE)
#'
#' dbRemoveTable( conn , 'eusilc' )
#'
#' dbDisconnect( conn , shutdown = TRUE )
#'
#' }
#'
#' @export
svychu <-
  function(formula, design,  ...) {

    if( !( 'g' %in% names(list(...)) ) ) stop( "g= parameter must be specified" )

    if( !is.na( list(...)[["g"]] ) && ( list(...)[["g"]] == 0 ) ) return( svywatts( formula , design , ... ) )

    warning("The svychu function is experimental and is subject to changes in later versions.")

    if( !is.na( list(...)[["g"]] ) && !( list(...)[["g"]] <= 1 ) ) stop( "g= must be in the [0, 1] interval." )

    if( 'type_thresh' %in% names( list( ... ) ) && !( list(...)[["type_thresh"]] %in% c( 'relq' , 'abs' , 'relm' ) ) ) stop( 'type_thresh= must be "relq" "relm" or "abs".  see ?svychu for more detail.' )

    if( length( attr( terms.formula( formula ) , "term.labels" ) ) > 1 ) stop( "convey package functions currently only support one variable in the `formula=` argument" )

    UseMethod("svychu", design)

  }

#' @rdname svychu
#' @export
svychu.survey.design <-
  function(formula, design, g, type_thresh="abs",  abs_thresh=NULL, percent = .60, quantiles = .50, na.rm = FALSE, thresh = FALSE, ...){

    if (is.null(attr(design, "full_design"))) stop("you must run the ?convey_prep function on your linearized survey design object immediately after creating it with the svydesign() function.")

    if( type_thresh == "abs" & is.null( abs_thresh ) ) stop( "abs_thresh= must be specified when type_thresh='abs'" )

    # if the class of the full_design attribute is just a TRUE, then the design is
    # already the full design.  otherwise, pull the full_design from that attribute.
    if ("logical" %in% class(attr(design, "full_design"))) full_design <- design else full_design <- attr(design, "full_design")


    #  survey design h function
    h <- function( y , thresh , g ) ifelse( y <= thresh , 1 - ( y / thresh )^g , 0 )

    # ht function
    ht <- function( y , thresh , g ) ifelse( y <= thresh , g*(y^g / thresh^(g + 1) ) , 0 )

    # domain
    incvar <- model.frame(formula, design$variables, na.action = na.pass)[[1]]

    if(na.rm){
      nas<-is.na(incvar)
      design<-design[!nas,]
      if (length(nas) > length(design$prob))incvar <- incvar[!nas] else incvar[nas] <- 0
    }

    w <- 1/design$prob

    if( any( incvar[w > 0] <= 0 , na.rm = TRUE ) ){
      nps<-incvar <= 0
      design<-design[!nps,]
      if (length(nps) > length(design$prob))incvar <- incvar[!nps] else incvar[nps] <- 0
      w <- 1/design$prob
    }

    if( is.null( names( design$prob ) ) ) ind <- as.character( seq( length( design$prob ) ) ) else ind <- names(design$prob)

    N <- sum(w)

    # if the class of the full_design attribute is just a TRUE, then the design is
    # already the full design.  otherwise, pull the full_design from that attribute.
    if ("logical" %in% class(attr(design, "full_design"))) full_design <- design else full_design <- attr(design, "full_design")

    incvec <- model.frame(formula, full_design$variables, na.action = na.pass)[[1]]

    if(na.rm){
      nas<-is.na(incvec)
      full_design<-full_design[!nas,]
      if (length(nas) > length(full_design$prob)) incvec <- incvec[!nas] else incvec[nas] <- 0
    }

    wf <- 1/full_design$prob

    if( any( incvec[wf > 0] <= 0 , na.rm = TRUE ) ){
      warning("keeping strictly positive incomes only.")
      nps <- incvec <= 0
      full_design<-full_design[!nps,]
      if (length(nps) > length(full_design$prob)) incvec <- incvec[!nps] else incvec[nps] <- 0

      wf <- 1/full_design$prob
    }

    if( is.null( names( full_design$prob ) ) ) ncom <- as.character( seq( length( full_design$prob ) ) ) else ncom <- names(full_design$prob)

    htot <- h_fun(incvec, wf)
    if (sum(1/design$prob==0) > 0) ID <- 1*(1/design$prob!=0) else ID <- 1 * ( ncom %in% ind )


    # linearization

    if( type_thresh == 'relq' ){

      ARPT <- svyarpt(formula = formula, full_design, quantiles=quantiles, percent=percent,  na.rm=na.rm, ...)
      th <- coef(ARPT)
      arptlin <- attr(ARPT, "lin")
      rval <- sum(w*h(incvar,th,g))/N
      ahat <- sum(w*ht(incvar,th,g))/N

      chulin <-ID*( h( incvec , th , g ) - rval ) / N + ( ahat * arptlin )

    }

    if( type_thresh == 'relm'){

      # thresh for the whole population
      th <- percent*sum(incvec*wf)/sum(wf)
      rval <- sum(w*h(incvar,th,g))/N
      ahat <- sum(w*ht(incvar,th,g))/N
      chulin <-ID*( h( incvec , th , g ) - rval + ( ( percent * incvec ) - th ) * ahat ) / N

    }

    if( type_thresh == 'abs' ){

      th <- abs_thresh

      rval <- sum( w*h( incvar , th , g ) ) / N

      chulin <- ID*( h( incvec , th , g ) - rval ) / N

    }

    variance <- survey::svyrecvar(chulin/full_design$prob, full_design$cluster, full_design$strata, full_design$fpc, postStrata = full_design$postStrata)



    colnames( variance ) <- rownames( variance ) <-  names( rval ) <- strsplit( as.character( formula )[[2]] , ' \\+ ' )[[1]]
    class(rval) <- c( "cvystat" , "svystat" )
    attr(rval, "var") <- variance
    attr(rval, "statistic") <- paste0("chu",g)
    attr(rval, "lin") <- chulin
    if(thresh) attr(rval, "thresh") <- th
    rval

  }



#' @rdname svychu
#' @export
svychu.svyrep.design <-
  function(formula, design, g, type_thresh="abs", abs_thresh=NULL, percent = .60, quantiles = .50, na.rm = FALSE, thresh = FALSE,...) {

    if (is.null(attr(design, "full_design"))) stop("you must run the ?convey_prep function on your replicate-weighted survey design object immediately after creating it with the svrepdesign() function.")

    if( type_thresh == "abs" & is.null( abs_thresh ) ) stop( "abs_thresh= must be specified when type_thresh='abs'" )

    # if the class of the full_design attribute is just a TRUE, then the design is
    # already the full design.  otherwise, pull the full_design from that attribute.
    if ("logical" %in% class(attr(design, "full_design")))
      full_design <- design else full_design <- attr(design, "full_design")

      # svyrep design h function
      h <- function( y , thresh , g ) ifelse( y <= thresh , 1 - ( y / thresh )^g , 0 )

      # svyrep design ComputeCHU function
      ComputeCHU <-
        function( y , w , thresh , g ){
          N <- sum(w)
          sum( w * h( y , thresh , g ) ) / N
        }


      df <- model.frame(design)
      incvar <- model.frame(formula, design$variables, na.action = na.pass)[[1]]

      if(na.rm){
        nas<-is.na(incvar)
        design<-design[!nas,]
        df <- model.frame(design)
        incvar <- incvar[!nas]
      }

      ws <- weights(design, "sampling")

      if( any(incvar[ ws > 0 ] <= 0 , na.rm = TRUE ) ){
        nps<-incvar <= 0
        design<-design[!nps,]
        df <- model.frame(design)
        incvar <- incvar[!nps]
        ws <- weights(design, "sampling")
      }


      df_full<- model.frame(full_design)
      incvec <- model.frame(formula, full_design$variables, na.action = na.pass)[[1]]

      if(na.rm){
        nas<-is.na(incvec)
        full_design<-full_design[!nas,]
        df_full <- model.frame(full_design)
        incvec <- incvec[!nas]
      }

      wsf <- weights(full_design,"sampling")

      if( any(incvec[ wsf > 0 ] <= 0 , na.rm = TRUE ) ){
        warning("keeping strictly positive incomes only.")
        nps<-incvec <= 0
        full_design<-full_design[!nps,]
        df_full <- model.frame(full_design)
        incvec <- incvec[!nps]
        wsf <- weights(full_design,"sampling")
      }

      names(incvec) <- names(wsf) <- row.names(df_full)
      ind<- row.names(df)

      # poverty threshold
      if(type_thresh=='relq') th <- percent * computeQuantiles( incvec, wsf, p = quantiles)
      if(type_thresh=='relm') th <- percent*sum(incvec*wsf)/sum(wsf)
      if(type_thresh=='abs') th <- abs_thresh


      rval <- ComputeCHU(incvar, ws, thresh = th , g = g)

      wwf <- weights(full_design, "analysis")

      qq <-
        apply(wwf, 2, function(wi){
          names(wi)<- row.names(df_full)
          wd<-wi[ind]
          incd <- incvec[ind]
          ComputeCHU( incd, wd, thresh = th , g = g )}
        )
      if(anyNA(qq))variance <- NA
      else variance <- survey::svrVar(qq, design$scale, design$rscales, mse = design$mse, coef = rval)

      variance <- as.matrix( variance )

      colnames( variance ) <- rownames( variance ) <-  names( rval ) <- strsplit( as.character( formula )[[2]] , ' \\+ ' )[[1]]
      class(rval) <- c( "cvystat" , "svrepstat" )
      attr(rval, "var") <- variance
      attr(rval, "statistic") <- paste0("chu",g)
      attr(rval, "lin") <- NA
      if(thresh) attr(rval, "thresh") <- th
      rval
  }

#' @rdname svychu
#' @export
svychu.DBIsvydesign <-
  function (formula, design, ...){

    if (!( "logical" %in% class(attr(design, "full_design"))) ){

      full_design <- attr( design , "full_design" )

      full_design$variables <-
        getvars(
          formula,
          attr( design , "full_design" )$db$connection,
          attr( design , "full_design" )$db$tablename,
          updates = attr( design , "full_design" )$updates,
          subset = attr( design , "full_design" )$subset
        )

      attr( design , "full_design" ) <- full_design

      rm( full_design )

    }

    design$variables <-
      getvars(
        formula,
        design$db$connection,
        design$db$tablename,
        updates = design$updates,
        subset = design$subset
      )

    NextMethod("svychu", design)
  }
