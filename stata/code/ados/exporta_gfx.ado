
capture program drop exporta_gfx
program define exporta_gfx
	syntax anything, outputs(string) [formatos(string)] [vars(varlist)]

local anything = subinstr(`"`anything'"',`"""',"",.)

if "`formatos'"=="" local formatos "pdf emf eps" 
if "`vars'"=="" local vars "*"

display as result _newline "*---------------------------------------------------------------------*"
display as result  "Graficos:"
foreach ext in `formatos' { 
	quietly graph export "`outputs'/`anything'.`ext'", replace
	display as result _col(6) "`outputs'/`anything'.`ext'"
}

	display as result "Planilha:"
	display as result _col(6) "(xls)" _col(13) "`outputs'/figures.xls"
	display as result _col(6) "(aba)" _col(13) "`anything'"
	display as result _col(6) "(vars)" _col(13) "`vars'"
	quietly export excel `vars' using "`outputs'/figures.xls", sheet("`anything'") sheetreplace firstrow(variables)

	
display as result "*---------------------------------------------------------------------*" _newline

	
end


