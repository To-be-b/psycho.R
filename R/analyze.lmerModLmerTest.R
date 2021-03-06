#' Analyze lmerModLmerTest objects.
#'
#' Analyze lmerModLmerTest objects.
#'
#' @param x lmerModLmerTest object.
#' @param CI Bootsrapped confidence interval bounds (slow). Set to NULL turn off their computation.
#' @param effsize_rules Grid for effect size interpretation. See \link[=interpret_d]{interpret_d}.
#' @param ... Arguments passed to or from other methods.
#'
#' @return output
#'
#' @examples
#' library(psycho)
#' library(lmerTest)
#' fit <- lmerTest::lmer(Sepal.Length ~ Sepal.Width + (1|Species), data=iris)
#'
#' results <- analyze(fit)
#' summary(results)
#' print(results)
#'
#' @author \href{https://dominiquemakowski.github.io/}{Dominique Makowski}
#'
#' @references Nakagawa, S., & Schielzeth, H. (2013). A general and simple method for obtaining R2 from generalized linear mixed-effects models. Methods in Ecology and Evolution, 4(2), 133-142.
#'
#' @importFrom MuMIn r.squaredGLMM
#' @importFrom MuMIn std.coef
#' @importFrom stringr str_squish
#' @import dplyr
#' @export
analyze.lmerModLmerTest <- function(x, CI=95, effsize_rules="cohen1988", ...) {


  # Processing
  # -------------
  fit <- x

  info <- get_info(fit)
  R2 <- get_R2(fit)



  # TODO: Bootstrapped p values
  # nsim determines p-value decimal places
  # boot.out = lme4::bootMer(fit, lme4::fixef, nsim=1000)
  # p = rbind(
  #   (1-apply(boot.out$t<0, 2, mean))*2,
  #   (1-apply(boot.out$t>0, 2, mean))*2)
  # p = apply(p, 2, min)



  # Summary
  # -------------
  summary <- data.frame(summary(fit)$coefficients)

  summary$Variable <- rownames(summary)
  summary$Coef <- summary$Estimate
  summary$SE <- summary$`Std..Error`
  summary$df <- as.numeric(summary$df)
  summary$t <- summary$`t.value`
  summary$p <- summary$`Pr...t..`

  # standardized coefficients
  standardized <- tibble::rownames_to_column(standardize(fit, method = "refit"), "Variable")
  summary <- merge(summary, standardized, by = "Variable", all.x = TRUE, sort = FALSE)
  summary$Effect_Size <- c(NA, interpret_d(tail(summary$Coef_std, -1), rules = effsize_rules))

  summary <- dplyr::select_(
    summary, "Variable", "Coef", "SE", "t", "df", "p", "Coef_std", "SE_std", "Effect_Size"
  )

  # CI computation
  if (!is.null(CI)) {
    CI_values <- tryCatch({
      suppressMessages(confint(fit, level = CI / 100))
    }, error = function(e) {
      warning("Couldn't compute CI. Skipping.")
      CI_values <- NA
      return(CI_values)
    })
    if (!all(is.na(CI_values))) {
      CI_values <- tail(CI_values, n = length(rownames(summary)))
      summary$CI_lower <- CI_values[, 1]
      summary$CI_higher <- CI_values[, 2]
    } else {
      CI <- NULL
    }
  }


  # Varnames
  varnames <- summary$Variable
  row.names(summary) <- varnames


  # Values
  # -------------
  # Initialize empty values
  values <- list(model = list(), effects = list())
  values$model$R2m <- R2$R2m
  values$model$R2c <- R2$R2c


  # Loop over all variables
  for (varname in varnames) {
    if (summary[varname, "p"] < .1) {
      significance <- " "
    } else {
      significance <- " not "
    }

    if (!is.null(CI)) {
      CI_text <- paste0(
        ", ",
        CI, "% CI [",
        format_digit(summary[varname, "CI_lower"], null_treshold = 0.0001),
        ", ",
        format_digit(summary[varname, "CI_higher"], null_treshold = 0.0001),
        "]"
      )
    } else {
      CI_text <- ""
    }




    if (varname == "(Intercept)") {
      text <- paste0(
        "The model's intercept is at ",
        format_digit(summary[varname, "Coef"], 2),
        " (SE = ",
        format_digit(summary[varname, "SE"], 2),
        CI_text,
        "). Within this model:"
      )
    } else {
      text <- paste0(
        "The effect of ",
        varname,
        " is",
        significance,
        "significant (beta = ",
        format_digit(summary[varname, "Coef"], 2),
        ", SE = ",
        format_digit(summary[varname, "SE"], 2),
        CI_text,
        ", t(",
        format_digit(summary[varname, "df"], 0),
        ") = ",
        format_digit(summary[varname, "t"], 2),
        ", p ",
        format_p(summary[varname, "p"], stars = FALSE),
        ") and can be considered as ",
        tolower(summary[varname, "Effect_Size"]),
        " (std. beta = ",
        format_digit(summary[varname, "Coef_std"], 2),
        ", std. SE = ",
        format_digit(summary[varname, "SE_std"], 2),
        ")."
      )
    }

    values$effects[[varname]] <- list(
      Coef = summary[varname, "Coef"],
      SE = summary[varname, "SE"],
      CI_lower = summary[varname, "CI_lower"],
      CI_higher = summary[varname, "CI_higher"],
      t = summary[varname, "t"],
      df = summary[varname, "df"],
      Coef_std = summary[varname, "Coef_std"],
      SE_std = summary[varname, "SE_std"],
      p = summary[varname, "p"],
      Effect_Size = summary[varname, "Effect_Size"],
      Text = text
    )
  }



  # Text
  # -------------
  text <- c(paste0(
    "The overall model predicting ",
    info$outcome,
    " (formula = ",
    format(info$formula),
    ") has an total explanatory power (conditional R2) of ",
    format_digit(R2$R2c * 100, 2),
    "%, in which the fixed effects explain ",
    format_digit(R2$R2m * 100, 2), "% of the variance (marginal R2). ",
    values$effects[["(Intercept)"]]$Text
  ))

  for (varname in varnames) {
    if (varname != "(Intercept)") {
      text <- c(text, paste("   -", values$effects[[varname]]$Text))
    }
  }



  # Plot
  # -------------
  plot <- "Not available yet"

  output <- list(text = text, plot = plot, summary = summary, values = values)

  class(output) <- c("psychobject", "list")
  return(output)
}
