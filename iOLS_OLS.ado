program define iOLS_OLS, eclass 
	syntax [anything] [if] [in] [aweight pweight fweight iweight] [, DELta(real 1) Robust CLuster(varlist numeric)]
	marksample touse
	if "`cluster'" =="" & "`robust'" =="" {
		di as error "Standard errors should be robust to heteroskedasticity using option robust or cluster" 
	}
	if  "`robust'" !="" {
		local opt1  = "`robust' "
	}
	if "`cluster'" !="" {
		local opt2 = "vce(cluster `cluster') "
	}
	local option = "`opt1'`opt2'"
	local list_var `anything'
	* Remarque : la fct gettoken utilise directement des local variables 
	* en 2e et 3e argument, donc pas besoin de prÃ©ciser que ce sont des
	* local variable en ajoutant les guillemets stata : `'
	* get depvar and indepvar
	gettoken depvar list_var : list_var
	gettoken indepvar list_var : list_var, p("(")
    * get endogenous variables and instruments
	gettoken endog list_var : list_var, bind
	gettoken endog endog : endog, p("(")
    gettoken endog instr_temp : endog , p("=")
    gettoken equalsign instr_temp : instr_temp , p("=")
	gettoken instr instr_temp : instr_temp, p(")")
	
	*di `"`depvar'"'
	*di `"`indepvar'"'
	*di `"`endog'"'
	*di `"`instr'"'
	
	*** Initialisation de la boucle
	tempvar y_tild 
	quietly gen `y_tild' = log(`depvar' + 1)
	quietly reg `y_tild' `indepvar' if `touse' [`weight'`exp'], `option'
	matrix beta_new = e(b)
	local k = 0
	local eps = 1000	
	*** ItÃ©rations iOLS
	_dots 0
	while (`k' < 1000 & `eps' > 1e-6) {
		matrix beta_initial = beta_new
		* Nouveaux beta
		tempvar xb_hat
		quietly predict `xb_hat', xb
		tempname cste_hat
		scalar `cste_hat' = _b[_cons]
		* Calcul de phi_hat
		tempvar temp1
		gen `temp1' = `depvar' * exp(-(`xb_hat' - `cste_hat'))
		quietly sum `temp1' [`weight'`exp'] if e(sample) 
		tempname phi_hat
		scalar `phi_hat' = log(`r(mean)')
		* Calcul de c_hat
		tempvar temp2
		gen `temp2' = log(`depvar' + `delta'*exp(`phi_hat' + (`xb_hat' - `cste_hat'))) - (`phi_hat' + (`xb_hat' - `cste_hat'))  // missing delta here
		quietly sum `temp2' [`weight'`exp'] if e(sample)
		tempname c_hat
		scalar `c_hat' = `r(mean)'
		* Update d'un nouveau y_tild et regression avec le nouvel y_tild
		quietly replace `y_tild' = log(`depvar' + `delta' * exp(`xb_hat')) - `c_hat'
		quietly reg `y_tild' `indepvar' if `touse' [`weight'`exp'], `option'
		matrix beta_new = e(b)
		* DiffÃ©rence entre les anciens betas et les nouveaux betas
		matrix diff = beta_initial - beta_new
		mata : st_matrix("abs_diff", abs(st_matrix("diff")))
		mata : st_matrix("abs_diff2", st_matrix("abs_diff"):*st_matrix("abs_diff"))
		mata : st_matrix("criteria", rowsum(st_matrix("abs_diff2"))/cols(st_matrix("abs_diff2")))
		local eps = criteria[1,1]
		local k = `k'+1
		_dots `k' 0
	}

	*** Calcul de la bonne matrice de variance-covariance
	* Calcul du "bon" rÃ©sidu
	preserve
	keep if e(sample)	
	tempvar xb_hat
	quietly predict `xb_hat', xb
	tempvar ui
	gen `ui' = exp(`y_tild' + `c_hat' - `xb_hat') - `delta'
	matrix beta_final = e(b)
	quietly sum [`weight'`exp'] if e(sample)
	tempname nobs
	scalar  `nobs' = r(N)
	*di `nobs'
	* Calcul de Sigma_0, de I-W et de Sigma_tild
	matrix Sigma = e(V)
	tempvar cste
	gen `cste' = 1
	tempvar ui_bis
	quietly gen `ui_bis' = 1 - `delta'/(`delta' + `ui')
	local var_list `indepvar' `cste'
	mata : X=.
	mata : IW=.
	mata : st_view(X,.,"`var_list'")
	mata : st_view(IW,.,"`ui_bis'")
	mata : IW = diag(IW)
	mata : Sigma_hat = st_matrix("Sigma")
	mata : Sigma_0 = (X'*X)*Sigma_hat*(X'*X)
	mata : invXpIWX = invsym(X'*IW*X)
	mata : Sigma_tild = invXpIWX*Sigma_0*invXpIWX
	mata : list_Variance = diagonal(Sigma_tild)
	mata : list_std_err = sqrt(list_Variance)
	mata : st_matrix("list_std_err", list_std_err)
    mata: st_matrix("Sigma_tild", Sigma_tild)
	*** Stocker les resultats dans une matrice
	local names : colnames e(b)
	local nbvar : word count `names'
	
******************************************************************************
* Return the information to STATA output
******************************************************************************
// You can use this to check if ereturn is working well or not.
*	mat result=J(`=`nbvar'+3',3,.) //Defining empty matrix
*	mat rownames result = `names' "nobs" "niter" "criteria"
*	mat colnames result = "Beta" "Std.Er." "Std.Er.Approx."
*	forv n=1/`nbvar' {
*		mat result[`n',1] = beta_final[1,`n']
*		mat result[`n',2] = list_std_err[`n',1]
*		mat result[`n',3] = sqrt(Sigma[`n',`n'])*(1+`delta') // adapted for delta case
*	}
*	mat result[`=`nbvar'+1',1] = `nobs'
*	mat result[`=`nbvar'+2',1] = `k'
*	mat result[`=`nbvar'+3',1] = `eps'
*	mat list result

* You need to tell stata what the column / row names are for your covariance matrix 
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

