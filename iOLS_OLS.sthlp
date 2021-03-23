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
{syntab:Model}

{syntab:SE/Robust/Cluster}
{synopt:{opt}{cmd:(}{help iOLS_OLS##opt_vce:vcetype}{cmd:)}}{it:vcetype}
may be {opt c:lassic} (default), {opt r:obust}, or {opt cl:uster} (allowing two- and multi-way clustering){p_end}


{syntab:Delta}
{synopt:{opt}{cmd:(}{help iOLS_OLS##delta}{cmd:)}}
{it:delta} is any strictly positive constant. {p_end}



{marker description}{...}
{title:Description}

{pstd}{cmd:iOLS_OLS} iterated Ordinary Least Squares,
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

{pstd}Convergence is decided based on coefficients and not on the modulus of the contraction mapping. {opth tol:erance(#)}.


{pstd}The {help reg postestimation##predict:predict}, {help test}, and {help margins} postestimation commands are available after {cmd:iOLS_OLS}.


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

{pstd}First, we will replicate Example 1 from Stata's
{browse "https://www.stata.com/manuals/rpoisson.pdf":poisson manual}.
{p_end}
{hline}
{phang2}{cmd:. use "http://www.stata-press.com/data/r14/airline"}{p_end}
{phang2}{cmd:. iOLS_OLS injuries XYZowned, vce(robust)}{p_end}
{phang2}{cmd:. poisson injuries XYZowned}{p_end}
{hline}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:iOLS_OLS} stores the following in {cmd:e()}:

{synoptset 24 tabbed}{...}
{syntab:Scalars}
{synopt:{cmd:e(N)}}number of observations{p_end}
