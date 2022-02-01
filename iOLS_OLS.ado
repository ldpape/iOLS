** 28/06/2021 : Corrected error on Diagonal Matrix of Weights using "cross".
** 14/12/2021 : Corrected convergence criteria with "( . )"
** 14/12/2021 : Changed Convergence Criteria from Absolute change to Relative Change
** 14/12/2021 : Added a quietly after "preserve" 
** 14/12/2021 : Changed the constant calculation to avoid numerical log(0).
** 21/12/2021 : Updated to matrix form for speed and options to control convergence.
** 04/01/2021 : Add additional stopping criteria + return of the constant alpha.
** 20/01/2021 : Corrected S.E. for symmetrization & Added PPML Singleton & Separation drop.
** 01/02/2021 : Drop "preserve" to gain speed
cap program drop iOLS_OLS
program define iOLS_OLS, eclass 
//	syntax [anything] [if] [in] [aweight pweight fweight iweight] [, DELta(real 1) Robust LIMit(real 0.00001) MAXimum(real 1000) CLuster(varlist numeric)]
syntax varlist [if] [in] [aweight pweight fweight iweight] [, DELta(real 1) LIMit(real 1e-8)  MAXimum(real 10000) Robust CLuster(string)]        

	marksample touse
	markout `touse'  `cluster', s     
	*** prepare options 
	if  "`robust'" !="" {
		local opt1  = "`robust' "
	}
	if "`cluster'" !="" {
		local opt2 = "vce(cluster `cluster') "
	}
	local option = "`opt1'`opt2'"
	local list_var `varlist'
	* get depvar and indepvar
	gettoken depvar list_var : list_var
	gettoken _rhs list_var : list_var, p("(")
foreach var of varlist `depvar' `_rhs' {
replace `touse' = 0 if missing(`var')	
}
*** check seperation : code from "ppml"
 tempvar logy                            																						// Creates regressand for first step
 quietly: gen `logy'=log(`depvar') if (`touse')&(`depvar'>0)
 quietly: reg `logy' `_rhs' if (`touse')&(`depvar'>0)	
 tempvar zeros                            																						// Creates regressand for first step
 quietly: gen `zeros'=1                                                                                                 // Initialize observations selector
 local _drop ""                                                                                                // List of regressors to exclude
 local indepvar ""     
    foreach x of varlist `_rhs' {   
      if (_se[`x']==0) {                                                                                       // Try to include regressors dropped in the
          qui summarize `x' if (`depvar'>0)&(`touse'), meanonly
          local _mean=r(mean)
          qui summarize `x' if (`depvar'==0)&(`touse')
          if (r(min)<`_mean')&(r(max)>`_mean'){                                            // Include regressor if conditions met and
              local indepvar "`indepvar' `x'"                                                                        // strict is off 
          }
          else{
              qui su `x' if `touse', d                                                                         // Otherwise, drop regressor
              local _mad=r(p50)
              qui inspect  `x'  if `touse'                                                                         
              qui replace `zeros'=0 if (`x'!=`_mad')&(r(N_unique)==2)&(`touse')                                // Mark observations to drop
              local _drop "`_drop' `x'"
          }
      }                                                                                                        // End of LOOP 1.1 
      if _se[`x']>0 {                                                                                          // Include safe regressors: LOOP 1.2
      local indepvar "`indepvar' `x'" 
      }                                                                                                        // End LOOP 1.2
    }   
 qui su `touse' if `touse', mean                                                                               // Summarize touse to obtain N
 local _enne=r(sum)                                                                                            // Save N
 qui replace `touse'=0 if (`zeros'==0)&("`keep'"=="")&(`depvar'==0)&(`touse')                                       // Drop observations with perfect fit
 di                                                                                                              // if keep is off
 local k_excluded : word count `_drop'                                                                         // Number of variables causing perfect fit
 di in green "Number of regressors excluded to ensure that the estimates exist: `k_excluded'" 
 if ("`_drop'" != "") di "Excluded regressors: `_drop'"                                                        // List dropped variables if any
 qui su `touse' if `touse', mean
 local _enne = `_enne' - r(sum)                                                                                // Number of observations dropped
 di in green "Number of observations excluded: `_enne'" 
 local _enne =  r(sum)
	** drop collinear variables
	tempvar cste
	gen `cste' = 1
    _rmcoll `indepvar' `cste' if `touse', forcedrop 
	local var_list `r(varlist)' 
	*** prepare iOLS 
	tempvar y_tild 
	quietly gen `y_tild' = log(`depvar' + `delta') if `touse'
	*** Initialisation de la boucle
	mata : X=.
	mata : y_tilde =.
	mata : y =.
	mata : st_view(X,.,"`var_list' `cste'")
	mata : st_view(y_tilde,.,"`y_tild'")
	mata : st_view(y,.,"`depvar'")
	mata : invXX = invsym(cross(X,X))
	mata : beta_initial = invXX*cross(X,y_tilde)
	mata : beta_t_1 = beta_initial // needed to initialize
	mata : beta_t_2 = beta_initial // needed to initialize
	mata : q_hat_m0 = 0
	local k = 1
	local eps = 1000	
	mata: q_hat = J(`maximum', 1, .)
	*** ItÃ©rations iOLS
	_dots 0
	while ( (`k' < `maximum') & (`eps' > `limit') ) {
	mata: alpha = log(mean(y:*exp(-X[.,1..(cols(X)-1)]*beta_initial[1..(cols(X)-1),1])))
	mata : beta_initial[(cols(X)),1] = alpha
	mata: xb_hat = X*beta_initial
		* Update d'un nouveau y_tild et regression avec le nouvel y_tild
	mata: y_tilde = log(y + `delta'*exp(xb_hat)) :-mean(log(y + `delta'*exp(xb_hat))- xb_hat)
		* 2SLS 
	mata: beta_new = invXX*cross(X,y_tilde)
		* Difference entre les anciens betas et les nouveaux betas
	mata: criteria = mean(abs(beta_initial - beta_new):^(2))
mata: st_numscalar("eps", criteria)
mata: st_local("eps", strofreal(criteria))
		* safeguard for convergence.
	if `k'==`maximum'{
		  di "There has been no convergence so far: increase the number of iterations."  
	}
	if `k'>4{
	mata: q_hat[`k',1] = mean(log( abs(beta_new-beta_initial):/abs(beta_initial-beta_t_2)):/log(abs(beta_initial-beta_t_2):/abs(beta_t_2-beta_t_3)))	
	mata: check_3 = abs(mean(q_hat)-1)
		if mod(`k'-4,50)==0{
    mata: q_hat_m =  mm_median(q_hat[((`k'-49)..`k'),.] ,1)
	mata: check_1 = abs(q_hat_m - q_hat_m0)
	mata: check_2 = abs(q_hat_m-1)
	mata: st_numscalar("check_1", check_1)
	mata: st_local("check_1", strofreal(check_1))
	mata: st_numscalar("check_2", check_2)
	mata: st_local("check_2", strofreal(check_2))
	mata: st_numscalar("check_3", check_3)
	mata: st_local("check_3", strofreal(check_3))
	mata: q_hat_m0 = q_hat_m
		if ((`check_1'<1e-4)&(`check_2'>1e-2)) {
di "delta is too small to achieve convergence -- update to larger value"
	local k = `maximum'
		}
		if ((`check_3'>0.5) & (`k'>500)) {
	local k = `maximum'
di "q_hat too far from 1: try another delta"
di "displaying final iteration"
		}
					  }
	}
	if `k'>2 { // keep in memory the previous beta_hat for q_hat 
	mata:   beta_t_3 = beta_t_2
	mata:   beta_t_2 = beta_initial
	}
mata: beta_initial = beta_new
	local k = `k'+1
	_dots `k' 0
	}

	*** Calcul de la bonne matrice de variance-covariance
	* Calcul du "bon" residu
	mata: alpha = log(mean(y:*exp(-X[.,1..(cols(X)-1)]*beta_initial[1..(cols(X)-1),1])))
	mata : beta_initial[(cols(X)),1] = alpha
	mata: xb_hat = X*beta_initial
	mata : y_tilde = log(y + `delta'*exp(xb_hat)) :-mean(log(y + `delta'*exp(xb_hat)) - xb_hat) 
	mata: ui = y:*exp(-xb_hat)
 	* Retour en Stata 
	cap drop `y_tild' 
	quietly mata: st_addvar("double", "`y_tild'")
	mata: st_store(.,"`y_tild'",y_tilde)
	quietly: reg `y_tild' `var_list' [`weight'`exp'] if `touse', `option'
	*cap drop xb_hat
	*quietly predict xb_hat, xb
	*cap drop ui
	*quietly gen ui = `depvar'*exp(-xb_hat)
	*mata : ui= st_data(.,"ui")
	mata: weight = ui:/(ui :+ `delta')
	matrix beta_final = e(b)
	matrix Sigma = e(V)
	mata : Sigma_hat = st_matrix("Sigma")
	mata : Sigma_0 = (quadcross(X,X))*Sigma_hat*(quadcross(X,X))
	mata : invXpIWX = invsym(quadcross(X, weight, X))
	mata : Sigma_tild = invXpIWX*Sigma_0*invXpIWX
	mata : Sigma_tild = (Sigma_tild+Sigma_tild'):/2 
 	mata: st_matrix("Sigma_tild", Sigma_tild)
	*** Stocker les resultats dans une matrice
	local names : colnames beta_final
	local nbvar : word count `names'
	mat rownames Sigma_tild = `names' 
    mat colnames Sigma_tild = `names' 
    ereturn post beta_final Sigma_tild , obs(`=e(N)') depname(`depvar') esample(`touse')  dof(`=e(df r)') 
ereturn scalar delta = `delta'
ereturn  scalar eps =   `eps'
ereturn  scalar niter =  `k'
ereturn local cmd "iOLS"
ereturn local vcetype `option'
di in gr _col(55) "Number of obs = " in ye %8.0f e(N)
ereturn display
end

