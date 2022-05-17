/*=======================================================*
Preparacao do arquivo de pessoas na PNADC 2012-2020
Pedro HGF Souza
Janeiro/2022
*========================================================*/


capture program drop prepara_pnadc
program define prepara_pnadc
	syntax, inputs(string) anos(numlist) output(string) [deflatores(string)]
	
*--- Leitura dos arquivos ---*

foreach yr of numlist `anos' {
	* Carrega arquivo, filtrando empregados domesticos etc
		local file = subinstr("`inputs'","_*_","_`yr'_",.)
		if `yr' < 2020 local file = subinstr("`file'", "visitaX", "visita1", .)
		if `yr' == 2020 local file = subinstr("`file'", "visitaX", "visita5", .)
		use "`file'" if v2005 <= 14 | v2005==16, clear	
	* Identificadores e peso pos estratificado
		gen double domicilioid = upa * 100 + v1008	
		gen double pesopop = v1032
		*gen double pesodom = v1032
	* Geografia e amostragem
		*gen estratos = uf*10 + v1023
	* Demografia 
		gen num_moradores = 1
		gen num_criancas = ( v2009 <= 17)
		gen num_adultos = ( inrange(v2009, 18, 64))
		recode vd3004 (1 2 = 2) (3 4 = 3) (5 6 = 4) (7 = 5), gen(educ5)
		replace educ5 = 1 if inrange(vd3005, 0, 4)
		label define feduc5 1 "<= 4 anos" 2 "nem fundamental" 3 "fundamental" 4 "medio" 5 "superior", replace
		label values educ5 feduc5
		tab educ5 if inrange(v2009, 18, 64), gen(num_adultos_educ5_)
		gen num_idosos = ( inrange(v2009, 65, 150) )
	* Rendimentos individuais 
		forvalues i = 1/13 { 
			if `i' < 9 capture gen v500`i'a2 = . 
			if `i' < 10 capture gen v500`i'11 = .
			if `i' >= 10 capture gen v50`i'11 = .
		} 
		egen double rtrab_habi = rowtotal(vd4019)
		egen double rtrab_efet = rowtotal(vd4020) 	
		egen double rprevi = rowtotal(v500111 v500211 v5004a2)
		egen double rsegdes = rowtotal(v500811 v5005a2)
		egen double rbpc = rowtotal(v500911 v5001a2)
		egen double rpbf = rowtotal(v501011 v5002a2)	
		egen double routprog = rowtotal(v501111 v5003a2)
		egen double routras = rowtotal(v500311 v500411 v500511 v500611 v500711 v501211 v501311 ///
			v5006a2 v5007a2 v5008a2)
		drop v50*
	* Collapse
		collapse (sum) rtrab_habi-routras pesopop num_*, by(ano trimestre domicilioid)	
	* Output intermediario e merge	
		compress
		if "`yr'"~=word("`anos'",1) append using "`output'"
		if "`yr'"==word("`anos'",-1) sort ano trimestre domicilioid 
		save "`output'", replace
}


*--- Deflacionamento (opcional) ---*

if "`deflatores'"~="" {
	use "`deflatores'" if ano >= 2012, clear
	*gen trimestre = int((mes - 1)/3 + 1)
	*keep if inlist(mes, 2, 5, 8, 11)
	*quietly describe deflator*, varlist
	*local deflvar = r(varlist)	
	egen deflator = gmean(deflator), by(ano trimestre)
	collapse (mean) deflator, by(ano trimestre)
	merge 1:m ano trimestre using "`output'", nogenerate keep(3)
	foreach var of varlist rtrab_habi-routras { 
		quietly replace `var' = `var' / deflator
	}
	*drop mes inpc data
}

*--- Rendimentos per capita ---*

foreach var of varlist rtrab_habi-routras  { 
	quietly replace `var' = `var' / num_moradores
}

*--- Rendimentos totais ---*

foreach var in habi efet { 
	egen double rdpc_`var' = rowtotal(rtrab_`var' rprevi rsegdes rbpc rpbf routprog routras)
	egen double rlpc_`var' = rowtotal(rtrab_`var' rprevi rsegdes rbpc routras)
}

*--- Agrega rendimentos ---*

*replace routras = routras + rprevi + rbpc + rsegdes
*drop rprevi rbpc rsegdes

*--- Output ---*

compress
sort ano trimestre domicilioid 
order ano trimestre domicilioid num* peso*  rtrab_habi-routras rdpc* rlpc*
save "`output'", replace
	

end	
