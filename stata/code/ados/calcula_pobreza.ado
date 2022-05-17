

capture program drop calcula_pobreza
program define calcula_pobreza
	syntax , input(string) output(string) ppp(real)
	

	* Input
		use "`input'" , clear
		
	
	* Indicadores 
		* Populacao 
			gen populacao = 1
		* Linhas de pobreza
			gen linha190 = ceil(1.90 * (365/12) * `ppp')
			gen linha320 = ceil(3.20 * (365/12) * `ppp')
			gen linha550 = ceil(5.50 * (365/12) * `ppp')
		* Rendas
			foreach var of varlist rdpc* rlpc* { 
				* Media
					gen `var'_avg = `var'
				* FGT0 
					gen `var'_fgt0_190 = cond( `var' < linha190, 100, 0)
					gen `var'_fgt0_320 = cond( `var' < linha320, 100, 0)
					gen `var'_fgt0_550 = cond( `var' < linha550, 100, 0)
				* Percentis
					bysort ano (`var'): gen double sumpeso = sum(pesopop)
					bysort ano (sumpeso): gen double fracpop = 100 * sumpeso / sumpeso[_N]
					gen `var'_bot20_pct = fracpop if fracpop < 0.20
					gen `var'_bot20_avg = `var' if fracpop < 0.20 
					drop sumpeso fracpop
			}

	* Collapse
		collapse (mean) linha* *_avg *fgt0* (max) *pct [w=pesopop], by(ano)

	* Output
		export delimited "`output'", delimiter(";") replace
		
end

