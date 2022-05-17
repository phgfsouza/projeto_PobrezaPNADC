/*=======================================================*
Pobreza no Brasil
Pedro HGF Souza
Janeiro/2022
*========================================================*/

*--------------------------------------------------------*
* Setup
*--------------------------------------------------------*

*--- Caminhos ---*

global pnad "D:\onedrive\dados\ibge\pnads"
global pnadc "D:\onedrive\dados\ibge\PNADC\stata\"
global pnadcovid "d:\onedrive\dados\ibge\pnad covid\microdados\dados"
global root "D:\OneDrive\work\Incompletos\curso-python\projetoPNADC\stata\"
cd "$root"

*--- Preferencias ---*

*ssc install egenmore, replace
adopath ++"./code/ados/"
set logtype text
set scheme pedrobw


*--- Parametros ---*

global dataref "2020.12"
global ppp2011 = 2.712 


*--------------------------------------------------------*
* Processamento dos dados -- PNADC
*--------------------------------------------------------*

*= Importacao = etapa nao necessaria

*= Preparacao 
clear
timer off 2
timer clear 2
timer on 2
forvalues i = 1/10 { 
	prepara_inpc using "./data/raw/ipeadata_inpc.xls", referencia("$dataref") output("./data/cleaned/inpc")
	prepara_pnadc, inputs("${pnadc}/pnadc_*_visitaX") anos(2012/2020) deflatores("./data/cleaned/inpc") ///
		output("./data/cleaned/pnadc")
}
timer off 2
timer list 2
scalar t2_prepara = `r(t2)' / 10
	
*= Calcula indicadores de pobreza + exporta csv
clear
timer off 3 
timer clear 3
timer on 3
forvalues i = 1/10 {  
	calcula_pobreza, input("./data/cleaned/pnadc") output("./data/results/pobreza.csv") ppp($ppp2011)
}
timer off 3
timer list 3
scalar t3_pobreza = `r(t3)' / 10 
	
*= Timer

display "T2, preparacao:" _col(20) t2_prepara
display "T3, pobreza:" _col(20) t3_pobreza
display "Total:" _col(20) t2_prepara + t3_pobreza
	
	
*--------------------------------------------------------*
* Graficos 2001-2020
*--------------------------------------------------------*

*--- Macros ---*

global x `"xtitle("") xscale(range(1999.85 2020.15) lwidth(*1.2) line) xlabel(2000(2)2020, angle(30) labgap(*3)) xmticks(2005(2)2019)"'
global y "yscale(range(\`min' \`max')) ylabel(\`min' \`max', labgap(*1.5) nogrid tl(*.5))"
global markers "connect(d) msymbol(O) mlabgap(*2.5 *2.5)"
global pnad_opts "color(navy) mlabel(lab_pnad) mlabvpos(labpos_pnad) mlabcolor(navy)"
global pnadc_opts `"lcolor("0 157 204") mlcolor("0 157 204") mfcolor(white) mlabel(lab_pnadc) mlabvpos(labpos_pnadc) mlabcolor("0 157 204")"'
global recessao2001	"(scatteri \`max' `=2000.85' \`max' `=2001.15', recast(area) color(gs14))"
global recessao2003 "(scatteri \`max' `=2002.85' \`max' `=2003.15', recast(area) color(gs14))"
global recessao2008 "(scatteri \`max' `=2007.85' \`max' `=2009.15', recast(area) color(gs14))"
global recessao2014 "(scatteri \`max' `=2013.85' \`max' `=2016.15', recast(area) color(gs14))"
global recessao2020 "(scatteri \`max' `=2019.85' \`max' `=2020.15', recast(area) color(gs14))"
global etc "legend(off) plotregion(lwidth(none) margin(zero) ) graphregion(margin(medsmall))"

*--- Pobreza 1.90 ---*

* Macros
	local varpnadc = "rdpc_habi"
	local varname "fgt0"
	local min = 0 
	local max = 16
* Dados
	use ano *`varname' using "./data/results/pnad", clear
	merge 1:1 ano using "./data/results/pnadc", nogenerate keepusing(*`varpnadc'_`varname')
	tostring pnad_rdpc_`varname' , gen(lab_pnad) format("%4,1f") force
	tostring pnadc_`varpnadc'_`varname', gen(lab_pnadc) format("%4,1f") force
	replace lab_pnad = "" if  !inlist(ano, 2001, 2012, 2014)
	replace lab_pnadc = "" if !inlist(ano, 2012, 2014, 2016, 2019, 2020)
	gen labpos_pnad = cond( ano == 2001, 12, 6)
	gen labpos_pnadc = cond( ano == 2020, 6, 12)
* Grafico
	twoway $recessao2001 $recessao2003 $recessao2008 $recessao2014 $recessao2020 ///
		(scatter pnad_rdpc_`varname' ano, $markers $pnad_opts) ///
		(scatter pnadc_`varpnadc'_`varname' ano, $markers $pnadc_opts), $x $y $etc ///
			ytitle("Taxa de pobreza (%)") ///
			text(7 2005.5 "PNAD", placement(c) color(navy) size(*.9)) ///
			text(9 2018 "PNADC", placement(c) color("0 157 204") size(*.9)) 
	exporta_gfx "fig01_`varname'_2001_2020", outputs("./text/bps/figures/") vars("ano pnad*_`varname'")
	
*--- Renda média dos 20% mais pobres ---*
	
* Macros
	local varpnadc = "rdpc_habi"
	local varname "bot20"
	local min = 0 
	local max = 280
* Dados
	use ano *`varname' using "./data/results/pnad", clear
	merge 1:1 ano using "./data/results/pnadc", nogenerate keepusing(*`varpnadc'_`varname')
	tostring pnad_rdpc_`varname' , gen(lab_pnad) format("%4,0f") force
	tostring pnadc_`varpnadc'_`varname', gen(lab_pnadc) format("%4,0f") force
	replace lab_pnad = "" if  !inlist(ano, 2001, 2012, 2014)
	replace lab_pnadc = "" if !inlist(ano, 2012, 2014, 2016, 2019, 2020)
	gen labpos_pnad = cond( ano == 2001, 12, 12)
	gen labpos_pnadc = cond( ano == 2020,12, 6)
* Grafico
	twoway $recessao2001 $recessao2003 $recessao2008 $recessao2014 $recessao2020 ///
		(scatter pnad_rdpc_`varname' ano, $markers $pnad_opts) ///
		(scatter pnadc_`varpnadc'_`varname' ano, $markers $pnadc_opts), $x $y $etc ///
			ytitle("Renda média, 20% mais pobres (R$ 2020)") ///
			text(185 2005.5 "PNAD", placement(c) color(navy) size(*.9)) ///
			text(165 2018 "PNADC", placement(c) color("0 157 204") size(*.9)) 
	exporta_gfx "fig02_`varname'_2001_2020", outputs("./text/bps/figures/") vars("ano pnad*_`varname'")
	
*--- Razao 20+/20- ---*

* Macros
	local varpnadc = "rdpc_habi"
	local varname "razao"
	local min = 1
	local max = 30
* Dados
	use ano *`varname' using "./data/results/pnad", clear
	merge 1:1 ano using "./data/results/pnadc", nogenerate keepusing(*`varpnadc'_`varname')
	tostring pnad_rdpc_`varname' , gen(lab_pnad) format("%4,1f") force
	tostring pnadc_`varpnadc'_`varname', gen(lab_pnadc) format("%4,1f") force
	replace lab_pnad = "" if  !inlist(ano, 2001, 2012, 2014)
	replace lab_pnadc = "" if !inlist(ano, 2012, 2014, 2016, 2019, 2020)
	gen labpos_pnad = cond( ano == 2001, 12, 6)
	gen labpos_pnadc = cond( ano == 2020, 6, 12)	
* Grafico
	twoway  $recessao2001 $recessao2003 $recessao2008 $recessao2014 $recessao2020 ///
		(scatter pnad_rdpc_`varname' ano, $markers $pnad_opts) ///
		(scatter pnadc_`varpnadc'_`varname' ano, $markers $pnadc_opts), $x $y $etc ///
			ytitle("Razão 20+/20-") ///
			text(17 2005.5 "PNAD", placement(c) color(navy) size(*.9)) ///
			text(24 2018.0 "PNADC", placement(c) color("0 157 204") size(*.9)) 
	exporta_gfx "fig03_`varname'_2001_2020", outputs("./text/bps/figures/") vars("ano pnad*_`varname'")
		
		
*--------------------------------------------------------*
* Graficos 2012-2020
*--------------------------------------------------------*

*--- Macros ---*

global x `"xtitle("") xscale(range(2011.80 2020.15) lwidth(*1.2) line) xlabel(2012(1)2020, angle(30) labgap(*3))"'
global y "yscale(range(\`min' \`max')) ylabel(\`min' \`max', labgap(*1.5) nogrid tl(*.5))"
global markers "connect(d) msymbol(O) mlabgap(*3 *3)"
global rlpc_opts "color(maroon) mlabcolor(maroon) mlabpos(12) "
global rdpc_opts `"lcolor("0 157 204") mlcolor("0 157 204") mfcolor(white) mlabpos(6) mlabcolor("0 157 204")"'
global recessao2014 "(scatteri \`max' `=2013.85' \`max' `=2016.15', recast(area) color(gs14))"
global recessao2020 "(scatteri \`max' `=2019.85' \`max' `=2020.15', recast(area) color(gs14))"
global etc "legend(off) plotregion(lwidth(none) margin(zero) ) graphregion(margin(medsmall))"

*--- FGT0 com e sem transferências ---*	

* Macros
	local varname "habi_fgt0"
	local min = 0 
	local max = 12
* Dados
	use ano *r?pc_`varname'* using "./data/results/pnadc", clear
	format *fgt0* %3,1f
* Grafico
	twoway $recessao2014 $recessao2020 ///
		(scatter pnadc_rdpc_`varname' ano, $markers $rdpc_opts mlabel(pnadc_rdpc_`varname')) ///
		(scatter pnadc_rlpc_`varname' ano, $markers $rlpc_opts mlabel(pnadc_rlpc_`varname')) , $x $y $etc ///
			ytitle("Taxa de pobreza (%)") /// 
			text(10.6 2019.0 "Sem PBF e AE", placement(w) color(maroon) size(*.9)) ///
			text(4.2 2019.0 "Com PBF e AE", placement(w) color("0 157 204") size(*.9)) 	
	exporta_gfx "fig04_`varname'_2012_2020", outputs("./text/bps/figures/")

*--- Renda dos 20% mais pobres com e sem transferências ---*	

* Macros
	local varname "habi_bot20"
	local min = 0
	local max = 270 
* Dados
	use ano *r?pc_`varname'* using "./data/results/pnadc", clear
	format *bot* %4,0f
* Grafico
	twoway $recessao2014 $recessao2020 ///
		(scatter pnadc_rdpc_`varname' ano, $markers $rdpc_opts mlabel(pnadc_rdpc_`varname')) ///
		(scatter pnadc_rlpc_`varname' ano, $markers $rlpc_opts mlabel(pnadc_rlpc_`varname')) , $x $y $etc ///
			ytitle("Renda média, 20% mais pobres (R$ 2020)") /// 
			text(145 2017 "Sem PBF e AE", placement(e) color(maroon) size(*.9)) ///
			text(250 2017 "Com PBF e AE", placement(e) color("0 157 204") size(*.9)) 	
	gr_edit .plotregion1.plot3.style.editstyle label(position(12)) editcopy
	gr_edit .plotregion1.plot4.EditCustomStyle , j(9) style(label(position(6)))
	exporta_gfx "fig05_`varname'_2012_2020", outputs("./text/bps/figures/") 

	
*--------------------------------------------------------*
* Graficos 2020
*--------------------------------------------------------*

*--- Macros ---*

global x `"ttitle("") tscale(range(723.8 730.2) lwidth(*1.2) line) tlabel(724(1)730, angle(30) labgap(*3) format(%tmCCYY.NN))"'
global y "yscale(range(\`min' \`max')) ylabel(\`min' \`max', labgap(*1.5) nogrid tl(*.5) format(%3,0f))"
global markers "connect(d) msymbol(O) mlabgap(*3 *3)"
global rlpc_opts "color(maroon) mlabcolor(maroon) mlabpos(12) "
global rdpc_opts `"lcolor("0 157 204") mlcolor("0 157 204") mfcolor(white) mlabpos(6) mlabcolor("0 157 204")"'
global recessao2020 "(scatteri \`max' `=723.9' \`max' `=725.1', recast(area) color(gs14))"
global etc "legend(off) plotregion(lwidth(none) margin(zero) ) graphregion(margin(medsmall))"

*--- FGT0 com e sem transferências ---*	

* Macros
	local varname "habi_fgt0"
	local min = 0 
	local max = 12
* Dados
	use ano mes data *`varname'* using "./data/results/pnadcovid", clear
	format *`varname'* %3,1f
* Grafico
	twoway $recessao2020 ///
		(scatter pnadcovid_rdpc_`varname' data, $markers $rdpc_opts mlabel(pnadcovid_rdpc_`varname')) ///
		(scatter pnadcovid_rlpc_`varname' data, $markers $rlpc_opts mlabel(pnadcovid_rlpc_`varname')) , $x $y $etc ///
			ytitle("Taxa de pobreza (%)") /// 
			text(9 730 "Sem PBF e AE", placement(w) color(maroon) size(*.9)) ///
			text(5.7 730 "Com PBF e AE", placement(w) color("0 157 204") size(*.9)) 
	drop data
	exporta_gfx "fig06_`varname'_2020", outputs("./text/bps/figures/")	

*--- Renda dos 20% mais pobres com e sem transferencias ---*

* Macros 
	local varname "habi_bot20"
	local min = 0
	local max = 350
* Dados
	use ano mes data *`varname'* using "./data/results/pnadcovid", clear
	format *`varname'* %3,0f
* Grafico
	twoway $recessao2020 ///
		(scatter pnadcovid_rdpc_`varname' data, $markers $rdpc_opts mlabel(pnadcovid_rdpc_`varname')) ///
		(scatter pnadcovid_rlpc_`varname' data, $markers $rlpc_opts mlabel(pnadcovid_rlpc_`varname')) , $x $y $etc ///
			ytitle("Renda média, 20% mais pobres (R$ 2020)") /// 
			text(97 730 "Sem PBF e AE", placement(w) color(maroon) size(*.9)) ///
			text(210 730 "Com PBF e AE", placement(w) color("0 157 204") size(*.9)) 	
	drop data
	exporta_gfx "fig07_`varname'_2020", outputs("./text/bps/figures/") 

	
*--------------------------------------------------------*
* Graficos trimestrais 2012-2021
*--------------------------------------------------------*

global x `"ttitle("") tscale(range(207 248) lwidth(*1.2) line) tlabel(208(4)248, angle(30) labgap(*3) format(%tqCCYY.!tq))"'
global y "yscale(range(\`min' \`max')) ylabel(\`min' \`max', labgap(*1.5) nogrid tl(*.5))"
global ygrid "yscale(range(\`min' \`max')) ylabel(\`min'(\`step')\`max', labgap(*1.5)  tl(*.5))"
global markers1 "connect(d) msymbol(O) mlabgap(*2 *2) color(navy) mlabcolor(navy) mlabpos(12) "
global markers2 "connect(d) msymbol(T) mlabgap(*2 *2) lcolor(maroon) mcolor(maroon)"
global markers3 "connect(d) msymbol(s) mlabgap(*2 *2) lcolor(emerald) mcolor(emerald) "
global recessao2014 "(scatteri \`max' `=216.9' \`max' `=227.1', recast(area) color(gs14))"
global recessao2020 "(scatteri \`max' `=239.9' \`max' `=241.1', recast(area) color(gs14))"
global recessao2021 "(scatteri \`max' `=244.9' \`max' `=246.1', recast(area) color(gs14))"
global etc "legend(off) plotregion(lwidth(none) margin(zero) ) graphregion(margin(medsmall))"

*--- FGT0 do trabalho ---*

* Macros
	local varname "rtrab_habi_fgt0"
	local min = 0 
	local max = 30
* Dados
	use ano trimestre data *`varname'* using "./data/results/pnadc_tri", clear
	tostring pnadct_`varname', gen(lab_`varname') format(%3,1f) force
	replace lab_`varname' = "" if !inlist(data, 208, 217, 227, 239, 242, 246)
	gen lpos_`varname' = cond( inlist(data, 227, 239, 246), 6, 12) if lab_`varname'~=""
* Grafico
	twoway $recessao2014 $recessao2020 $recessao2021 ///
		(scatter pnadct_`varname' data, $markers1 mlabel(lab_`varname') mlabvpos(lpos_`varname')), ///
			ytitle("Taxa de pobreza (%)") ///
			$x $y $etc
	keep ano trimestre pnadct*`varname'
	exporta_gfx "fig08_`varname'_2012_2021", outputs("./text//bps/figures/")
	
*--- Percentis ---*

* Macros
	local varname "vs2012"
	local min = 0 
	local max = 120
	local step = 20
* Dados
	use ano trimestre data *rtrab_habi*`varname' using "./data/results/pnadc_tri", clear
	drop *_p50*
	rename pnadct_rtrab_habi_* *
	gen yline = 100
* Grafico
	twoway $recessao2014 $recessao2020 $recessao2021 ///
		(scatter p20_`varname' data, $markers1 ) ///
		(scatter p30_`varname' data, $markers2 ) ///
		(scatter p40_`varname' data, $markers3 ) ///
		(line yline data, lcolor(red) lpattern(solid)), ///
			ytitle("Remuneração per capita (2012.t1 = 100)") ymticks(`min'(`=`step'/2')`max', grid noticks) ///
			text(64 246.5 "P20", placement(w) color(navy)) ///
			text(79 246.5 "P30", placement(w) color(maroon)) ///
			text(115 239 "P40", placement(w) color(emerald)) ///
			$x $ygrid $etc 
	keep ano trimestre p*`varname'
	exporta_gfx "fig09_`varname'_2012_2021", outputs("./text/bps/figures/")		
		
