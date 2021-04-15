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
{p2col :{cmd:iOLS_OLS} {hline 2}} Iterated Ordinary Least Squares (iOLS) with delta {p_end}
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
{syntab: Standard Errors: Classical/Robust/Clustered}
{synopt:{opt vce}{cmd:(}{help iOLS_OLS##opt_vce:vcetype}{cmd:)}}{it:vcetype}
may be classical (assuming homoskedasticity), {opt r:obust}, or {opt cl:uster} (allowing two- and multi-way clustering){p_end}
{syntab: Delta}
{synopt:{opt delta}{cmd:(}{help iOLS_OLS##delta:delta}{cmd:)}}{it:delta} is any strictly positive constant. {p_end}

{marker description}{...}
{title:Description}

{pstd}{cmd:iOLS_OLS} iterated Ordinary Least Squares with delta, as described by {browse "https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3444996":Bellego, Benatia, and Pape (2021)}.

{pstd} This package:

{pmore} 1. relies on Stata's OLS reg procedure for estimation. {p_end}

{pmore} 2. assumes the iOLS exogeneity condition with delta E(X'log(delta+U)) = constant. {p_end}


{title:Background}

{pstd}
{cmd: iOLS_OLS} estimates iOLS_delta, a solution to the problem of the log of zero.  This method relies on running the "regress" function iteratively.
This provides the reader with the final OLS estimates and allows the use the post-estimation commands available under regress (using Y_tilde = log(Y + delta*exp(xb))) as a 
dependent variable.  The benefit of using "regress" comes at the cost of limited capacity to deal with many fixed effects. In such a case, iOLS_hdfe may be more appropriate.

{synoptset 22}{...}
{synopthdr: variables}
{synoptline}
{synopt:{it:depvar}} Dependent variable{p_end}
{synopt:{it:indepvars}} List of explanatory variables {p_end}
{synoptline}
{p2colreset}{...}


{marker caveats}{...}
{title:Caveats}

{pstd} Convergence is decided based on coefficients (sum of squared coefficients < 1e-6) and not on the modulus of the contraction mapping.

{pstd} The {help test} postestimation commands are available after {cmd:iOLS_OLS}.  This command yields 'xb' using "predict xb, xb" . To obtain y_hat, you will need to also run "gen y_hat = exp(xb)".

{marker contact}{...}
{title:Authors}

{pstd} Christophe Bellego, David Benatia, Louis Pape {break}
CREST - ENSAE - HEC Montréal - Ecole Polytechnique {break}
Contact: {browse "mailto:louis.pape@polytechnique.edu":louis.pape@polytechnique.edu} {p_end}

{marker citation}{...}
{title:Citation}

{pstd}
Bellégo Christophe, Benatia David, and Pape Louis-Daniel, Dealing with Logs and Zeros in Regression Models (2019).
Série des Documents de Travail n° 2019-13.
Available at SSRN: https://ssrn.com/abstract=3444996 

{marker examples}{...}
{title:Examples}

{pstd} First, we will replicate Example 1 from Stata's
{browse "https://www.stata.com/manuals/rpoisson.pdf":poisson manual}.
{p_end}
{hline}
{phang2}{cmd:. use "http://www.stata-press.com/data/r14/airline"}{p_end}
{phang2}{cmd:. iOLS_OLS injuries XYZowned, delta(1) robust}{p_end}
{phang2}{cmd:. poisson injuries XYZowned, robust}{p_end}
{hline}

{pstd} Second, we show how to test for the pattern of zeros with iOLS. We use data on households' trips away from home, as used in {browse "https://www.stata.com/manuals/rivpoisson.pdf":ivpoisson manual}.
to study the effect of cost of transportation (tcost). 
{p_end}
{hline}
{phang2}{cmd:. clear all}{p_end}
{phang2}{cmd:. webuse trip }{p_end}
{phang2}{cmd:. gen outside = trips>0 }{p_end}

{phang2}{cmd:. iOLS_OLS trips cbd ptn worker weekend tcost, delta(1) robust }{p_end}

{phang2}{cmd:. cap program drop iOLS_bootstrap  }{p_end}
{phang2}{cmd:. program iOLS_bootstrap, rclass  }{p_end}
{phang2}{cmd:. iOLS_OLS trips cbd ptn worker weekend tcost , delta(1) robust  }{p_end}
{phang2}{cmd:. scalar delta = 1  }{p_end}
{phang2}{cmd:. *lhs of test  }{p_end}
{phang2}{cmd:. predict xb_temp, xb  }{p_end}
{phang2}{cmd:. gen u_hat_temp = trips*exp(-xb_temp)  }{p_end}
{phang2}{cmd:. gen lhs_temp = log(delta+u_hat_temp) - log(delta)  }{p_end}
{phang2}{cmd:. * rhs of test  }{p_end}
{phang2}{cmd:. gen temp = log(trips + delta*exp(xb_temp)) - xb_temp  }{p_end}
{phang2}{cmd:. egen c_hat_temp = mean(temp)   }{p_end}
{phang2}{cmd:. logit outside cbd ptn worker weekend tcost }{p_end}
{phang2}{cmd:. predict p_hat_temp, pr  }{p_end}
{phang2}{cmd:. gen rhs_temp = (c_hat_temp-log(delta))/p_hat_temp  }{p_end}
{phang2}{cmd:. * run the test  }{p_end}
{phang2}{cmd:. reg lhs_temp rhs_temp if outside, nocons   }{p_end}
{phang2}{cmd:. matrix b = e(b)  }{p_end}
{phang2}{cmd:. ereturn post b  }{p_end}
{phang2}{cmd:. * drop created variables  }{p_end}
{phang2}{cmd:. cap drop *temp  }{p_end}
{phang2}{cmd:. end  }{p_end}

{phang2}{cmd:. bootstrap lambda = _b[rhs_temp] , reps(50): iOLS_bootstrap  }{p_end}
{phang2}{cmd:. test lambda==1  }{p_end}
{hline}

{pstd} Third, we show how to test for the pattern of zeros using Poisson regression.
{p_end}
{hline}
{phang2}{cmd:. poisson trips cbd ptn worker weekend tcost , robust  }{p_end}

{phang2}{cmd:. cap program drop Poisson_bootstrap }{p_end}
{phang2}{cmd:. program Poisson_bootstrap, rclass  }{p_end}
{phang2}{cmd:. estimate the model  }{p_end}
{phang2}{cmd:. poisson trips cbd ptn worker weekend tcost , robust  }{p_end}
{phang2}{cmd:. lhs of test  }{p_end}
{phang2}{cmd:. predict xb_temp, xb  }{p_end}
{phang2}{cmd:. gen u_hat_temp = wage*exp(-xb_temp)  }{p_end}
{phang2}{cmd:. egen mean_u_temp = mean(u_hat_temp)  }{p_end}
{phang2}{cmd:. gen lhs_temp = u_hat_temp*exp(-xb_temp)  }{p_end}
{phang2}{cmd:. rhs of test  }{p_end}
{phang2}{cmd:. logit outside trips cbd ptn worker weekend tcost}{p_end}
{phang2}{cmd:. predict p_hat_temp, pr  }{p_end}
{phang2}{cmd:. gen rhs_temp = (mean_u_temp)/p_hat_temp  }{p_end}
{phang2}{cmd:. run the test  }{p_end}
{phang2}{cmd:. reg lhs_temp rhs_temp if outside, nocons   }{p_end}
{phang2}{cmd:. matrix b = e(b)  }{p_end}
{phang2}{cmd:. ereturn post b  }{p_end}
{phang2}{cmd:. drop created variables  }{p_end}
{phang2}{cmd:. cap drop *temp  }{p_end}
{phang2}{cmd:. end  }{p_end}

{phang2}{cmd:. bootstrap lambda = _b[rhs_temp] , reps(50): Poisson_bootstrap  }{p_end}
{phang2}{cmd:. test lambda==1  }{p_end}
{hline}

{pstd} Fourth, you can convert your results into latex using esttab where "eps" provides the convergence criteria:
{p_end}
{hline}
{phang2}{cmd:. eststo clear}{p_end}
{phang2}{cmd:. eststo: iOLS_OLS trips cbd ptn worker weekend tcost, delta(1) robust }{p_end}
{phang2}{cmd:. eststo: iOLS_OLS trips cbd ptn worker weekend tcost, delta(10) robust }{p_end}
{phang2}{cmd:. eststo: esttab * using table.tex,  scalars(delta eps) }{p_end}
{hline}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:iOLS_OLS} stores the following in {cmd:e()}:

{synoptset 24 tabbed}{...}
{syntab:Scalars}
{synopt:{cmd:e(N)}} number of observations{p_end}
{synopt:{cmd:e(sample)}} marks the sample used for estimation {p_end}
{synopt:{cmd:e(eps)}} sum of the absolute differences between the parameters from the last two iterations of iOLS {p_end}
{synopt:{cmd:e(k)}} number of iterations of iOLS{p_end}

