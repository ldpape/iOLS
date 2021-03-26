{smcl}
{* *! version 1.0 22march2021}{...}
{vieweralsosee "[R] poisson" "help poisson"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "reghdfe" "help reghdfe"}{...}
{vieweralsosee "ppml" "help ppml"}{...}
{vieweralsosee "ppmlhdfe" "help ppmlhdfe"}{...}
{viewerjumpto "Syntax" "iOLS_OLS##syntax"}{...}
{viewerjumpto "Description" "iOLS_OLS##description"}{...}
{viewerjumpto "Citation" "iOLS_OLS##citation"}{...}
{viewerjumpto "Authors" "iOLS_OLS##contact"}{...}
{viewerjumpto "Examples" "iOLS_OLS##examples"}{...}
{viewerjumpto "Description" "iOLS_OLS##Testing"}{...}
{viewerjumpto "Stored results" "iOLS_OLS##results"}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{cmd:iOLS_OLS} {hline 2}}Iterated Ordinary Least Squares (iOLS) {p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 15 2} {cmd:iOLS_OLS}
{depvar} [{indepvars}]
{ifin} {it:{weight}} {cmd:,} [{help iOLS_OLS##options:options}] {p_end}

{marker opt_summary}{...}
{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:SE: Robust/Cluster}
{synopt:{opt}{cmd:(}{help iOLS_OLS##opt_vce:vcetype}{cmd:)}}{it:vcetype}
may be {opt r:obust}, or {opt cl:uster} (allowing two- and multi-way clustering){p_end}
{syntab:Delta}
{synopt:}{it:delta} is any strictly positive constant. {p_end}



{marker description}{...}
{title:Description}

{pstd}{cmd:iOLS_OLS} iterated Ordinary Least Squares, Hello
as described by {browse "https://sites.google.com/site/louisdanielpape/":Bellego, Benatia, and Pape (2021)}.

{pstd}This package:

{pmore} 1. relies on Stata's OLS procedure for estimation.{p_end}

{pmore} 2. assumes the iOLS exogeneity condition with delta = 1. {p_end}


{title:Background}

{pstd} iOLS_delta is a solution to the problem of the log of zero.  The parameter associated with a log-transformed dependent variable can be interpreted as an elasticity. 


{marker absvar}{...}
{title:Syntax for absorbed variables}

{synoptset 22}{...}
{synopthdr: variables}
{synoptline}
{synopt:{it:depvar}} Dependent variable{p_end}
{synopt:{it:indepvars}} List of explanatory variables {p_end}
{synoptline}
{p2colreset}{...}


{marker caveats}{...}
{title:Caveats}

{pstd} Convergence is decided based on coefficients and not on the modulus of the contraction mapping.


{pstd}The {help test} postestimation commands are available after {cmd:iOLS_OLS}.  This command yields 'xb' using "predict xb, xb" . To obtain y_hat, you will need to also run "gen y_hat = exp(xb)".


{marker contact}{...}
{title:Authors}

{pstd}Louis Pape {break}
CREST {break}
Email: {browse "mailto:louis.pape@polytechnique.edu":louis.pape@polytechnique.edu}
{p_end}




{marker citation}{...}
{title:Citation}

{pstd}
Citation to be defined. 


{marker examples}{...}
{title:Examples}

{pstd} First, we will replicate Example 1 from Stata's
{browse "https://www.stata.com/manuals/rpoisson.pdf":poisson manual}.
{p_end}
{hline}
{phang2}{cmd:. use "http://www.stata-press.com/data/r14/airline"}{p_end}
{phang2}{cmd:. iOLS_OLS injuries XYZowned, robust}{p_end}
{phang2}{cmd:. poisson injuries XYZowned, rosut}{p_end}
{hline}


{pstd} Second, we show how to test for the pattern of zeros using iOLS with delta = 1.
{p_end}
{hline}
{phang2}{cmd:. clear all}{p_end}
{phang2}{cmd:. webuse womenwk }{p_end}
{phang2}{cmd:. replace wage = 0 if missing(wage) }{p_end}
{phang2}{cmd:. gen log_wage = log(wage) }{p_end}
{phang2}{cmd:. gen employment = wage!=0 }{p_end}

{phang2}{cmd:. iOLS_OLS wage education age , robust }{p_end}

{phang2}{cmd:. program iOLS_boostrap, rclass  }{p_end}
{phang2}{cmd:. iOLS_OLS wage education age , robust  }{p_end}
{phang2}{cmd:. scalar delta = 1  }{p_end}
{phang2}{cmd:. * lhs of test   {p_end}
{phang2}{cmd:. predict xb_temp, xb  }{p_end}
{phang2}{cmd:. gen u_hat_temp = wage*exp(-xb_temp)  }{p_end}
{phang2}{cmd:. gen lhs_temp = log(delta+u_hat_temp) - log(delta)  }{p_end}
{phang2}{cmd:. * rhs of test  }{p_end}
{phang2}{cmd:. gen temp = log(wage + delta*exp(xb_temp)) - xb_temp  }{p_end}
{phang2}{cmd:. egen c_hat_temp = mean(temp)   }{p_end}
{phang2}{cmd:. logit employment education age  }{p_end}
{phang2}{cmd:. predict p_hat_temp, pr  }{p_end}
{phang2}{cmd:. gen rhs_temp = (c_hat_temp-log(delta))/p_hat_temp  }{p_end}
{phang2}{cmd:. * run the test  }{p_end}
{phang2}{cmd:. reg lhs_temp rhs_temp if employment, nocons   }{p_end}
{phang2}{cmd:. matrix b = e(b)  }{p_end}
{phang2}{cmd:. ereturn post b  }{p_end}
{phang2}{cmd:. * drop created variables  }{p_end}
{phang2}{cmd:. cap drop *temp  }{p_end}
{phang2}{cmd:. end  }{p_end}

{phang2}{cmd:. bootstrap lambda = _b[rhs_temp] , reps(50): iOLS_boostrap  }{p_end}
{phang2}{cmd:. test lambda==1  }{p_end}


{phang2}{cmd:. poisson wage education  age , robust  }{p_end}

{phang2}{cmd:. program Poisson_boostrap, rclass  }{p_end}
{phang2}{cmd:. estimate the model  }{p_end}
{phang2}{cmd:. poisson wage education  age , robust  }{p_end}
{phang2}{cmd:. lhs of test  }{p_end}
{phang2}{cmd:. predict xb_temp, xb  }{p_end}
{phang2}{cmd:. gen u_hat_temp = wage*exp(-xb_temp)  }{p_end}
{phang2}{cmd:. egen mean_u_temp = mean(u_hat_temp)  }{p_end}
{phang2}{cmd:. gen lhs_temp = u_hat_temp*exp(-xb_temp)  }{p_end}
{phang2}{cmd:. rhs of test  }{p_end}
{phang2}{cmd:. logit employment education age  }{p_end}
{phang2}{cmd:. predict p_hat_temp, pr  }{p_end}
{phang2}{cmd:. gen rhs_temp = (mean_u_temp)/p_hat_temp  }{p_end}
{phang2}{cmd:. run the test  }{p_end}
{phang2}{cmd:. reg lhs_temp rhs_temp if employment, nocons   }{p_end}
{phang2}{cmd:. matrix b = e(b)  }{p_end}
{phang2}{cmd:. ereturn post b  }{p_end}
{phang2}{cmd:. drop created variables  }{p_end}
{phang2}{cmd:. cap drop *temp  }{p_end}
{phang2}{cmd:. end  }{p_end}

{phang2}{cmd:. bootstrap lambda = _b[rhs_temp] , reps(50): Poisson_boostrap  }{p_end}
{phang2}{cmd:. test lambda==1  }{p_end}
{hline}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:iOLS_OLS} stores the following in {cmd:e()}:

{synoptset 24 tabbed}{...}
{syntab:Scalars}
{synopt:{cmd:e(N)}}number of observations{p_end}
