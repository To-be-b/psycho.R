% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/bayes_cor.R
\name{bayes_cor.test}
\alias{bayes_cor.test}
\title{Performs a Bayesian correlation.}
\usage{
bayes_cor.test(x, y, CI = 90, iterations = 10000,
  effsize_rules_r = "cohen1988", effsize_rules_bf = "jeffreys1961")
}
\arguments{
\item{x}{First continuous variable.}

\item{y}{Second continuous variable.}

\item{CI}{Credible interval bounds.}

\item{iterations}{The number of iterations to sample.}

\item{effsize_rules_r}{Grid for effect size interpretation. See \link[=interpret_r]{interpret_r}.}

\item{effsize_rules_bf}{Grid for effect size interpretation. See \link[=interpret_bf]{interpret_bf}.}
}
\value{
A psychobject.
}
\description{
Performs a Bayesian correlation.
}
\examples{
\dontrun{
library(psycho)
x <- psycho::affective$Concealing
y <- psycho::affective$Tolerating

bayes_cor.test(x, y)
summary(bayes_cor.test(x, y))
}

}
\author{
\href{https://dominiquemakowski.github.io/}{Dominique Makowski}
}
