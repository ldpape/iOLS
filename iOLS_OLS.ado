** 28/06/2021 : Corrected error on Diagonal Matrix of Weights using "cross".
** 14/12/2021 : Corrected convergence criteria with "( . )"
** 14/12/2021 : Changed Convergence Criteria from Absolute change to Relative Change
** 14/12/2021 : Added a quietly after "preserve" 
** 14/12/2021 : Changed the constant calculation to avoid numerical log(0).
** 21/12/2021 : Updated to matrix form for speed and options to control convergence.

program define iOLS_OLS, eclass 
	syntax [anything] [if] [in] [aweight pweight fweight iweight] [, DELta(real 1) Robust LIMit(real 0.00001) MAXimum(real 1000) CLuster(varlist numeric)]
	marksample touse
	preserve
	quietly keep if `touse'
	if  "`robust'" !="" {
		local opt1  = "`robust' "
	}
	if "`cluster'" !="" {
		local opt2 = "vce(cluster `cluster') "
	}
	local option = "`opt1'`opt2'"
	local list_var `anything'
	* get depvar and indepvar
	gettoken depvar list_var : list_var
	gettoken indepvar list_var : list_var, p("(")
	tempvar y_tild 
	quietly gen `y_tild' = log(`depvar' + 1)
	tempvar cste
	gen `cste' = 1
	** drop collinear variables
    _rmcoll `indepvar' `cste', forcedrop 
	local var_list `endog' `r(varlist)' `cste'  
	*** Initialisation de la boucle
	mata : X=.
	mata : y_tilde =.
	mata : y =.
	mata : st_view(X,.,"`var_list'")
	mata : st_view(y_tilde,.,"`y_tild'")
	mata : st_view(y,.,"`depvar'")
	mata : invXX = invsym(cross(X,X))
	mata : beta_initial = invXX*X'*y_tilde

	local k = 0
	local eps = 1000	
	*** ItÃ©rations iOLS
	_dots 0
	while ( (`k' < `maximum') & (`eps' > `limit') ) {
	mata: xb_hat = X*beta_initial
		* Update d'un nouveau y_tild et regression avec le nouvel y_tild
	mata: y_tilde = log(y + `delta'*exp(xb_hat)) :-mean(log(y + `delta'*exp(xb_hat))- xb_hat)
		* 2SLS 
	mata: beta_new = invXX*X'*y_tilde
		* Difference entre les anciens betas et les nouveaux betas
	mata: criteria = mean(abs(beta_initial - beta_new):^(2))
mata: st_numscalar("eps", criteria)
mata: st_local("eps", strofreal(criteria))
mata: beta_initial = beta_new
	local k = `k'+1
	_dots `k' 0
	}

	*** Calcul de la bonne matrice de variance-covariance
	* Calcul du "bon" rÃ©sidu
	mata: xb_hat = X*beta_new
	mata : y_tilde = log(y + `delta'*exp(xb_hat)) :-mean(log(y + `delta'*exp(xb_hat)) - xb_hat)
	mata: ui = y:*exp(-xb_hat)
	mata: ui = ui:/(`delta' :+ ui)
	* Retour en Stata 
	cap drop y_tild 
	quietly mata: st_addvar("double", "y_tild")
	mata: st_store(.,"y_tild",y_tilde)
	quietly reg y_tild `r(varlist)' [`weight'`exp'] if `touse', `option'
	matrix beta_final = e(b) // 	mata: st_matrix("beta_final", beta_new)
	matrix Sigma = e(V)
	mata : Sigma_hat = st_matrix("Sigma")
	mata : Sigma_0 = cross(X,X)*Sigma_hat*cross(X,X)
	mata : invXpIWX = invsym(cross(X, ui, X))  
	mata : Sigma_tild = invXpIWX*Sigma_0*invXpIWX
    mata: st_matrix("Sigma_tild", Sigma_tild)
	*** Stocker les resultats dans une matrice
	local names : colnames e(b)
	local nbvar : word count `names'
	mat rownames Sigma_tild = `names' 
    mat colnames Sigma_tild = `names' 
    ereturn post beta_final Sigma_tild , obs(`=r(N)') depname(`depvar') esample(`touse')  dof(`=r(df r)') 
	restore 
ereturn scalar delta = `delta'
ereturn  scalar eps =   `eps'
ereturn  scalar niter =  `k'
ereturn local cmd "iOLS"
ereturn local vcetype `option'
ereturn display
end

