/*=======================================================*
Preparacao dos deflatores p
Pedro HGF Souza e Raphael Bruce
Janeiro/2021
*========================================================*/

capture program drop prepara_inpc
program define prepara_inpc
	syntax using/, referencia(string) output(string)
	
*--- Importacao ---*

import excel using "`using'" , clear  cellrange(A2)

*--- Limpeza ---*

gen data = monthly(A, "YM")
format data %tmCCYY.NN
gen ano = real(substr(A,1,4)) 
gen mes = real(substr(A,-2,2))
gen inpc = B

*--- Somente periodo pos PBF ---* 
	
sum data if ano==2001 & mes==1, meanonly
quietly drop if data < r(mean) | ano==.
	
*--- Deflator ---*

sum inpc if A=="`referencia'", meanonly
gen deflator_`=substr("`referencia'",6,2)'_`=substr("`referencia'",1,4)' = inpc / r(mean)
capture rename deflator_01_* deflator_jan*
capture rename deflator_02_* deflator_fev*
capture rename deflator_03_* deflator_mar*
capture rename deflator_04_* deflator_abr*
capture rename deflator_05_* deflator_mai*
capture rename deflator_06_* deflator_jun*
capture rename deflator_07_* deflator_jul*
capture rename deflator_08_* deflator_ago*
capture rename deflator_09_* deflator_set*
capture rename deflator_10_* deflator_out*
capture rename deflator_11_* deflator_nov*
capture rename deflator_12_* deflator_dez*

*--- Trimestre ---*

recode mes (1/3=1) (4/6=2) (7/9=3) (10/12=4), gen(trimestre)

*--- Output ---*

drop A B 
sort data
save "`output'",replace
	
end




	
