"""
Produz estatisticas de pobreza na PNADC 2012-2020
"""

# Pacotes
from importa_pnadc_dtas import *
from prepara_pnadc import *
from pobreza_pnadc import *
from timer_pnadc import *

# Pastas relevantes
DTA = os.path.join('D:', os.sep, 'OneDrive', 'dados', 'IBGE', 'PNADC', 'stata')
RAW = os.path.join('..', 'data', 'raw')
CLEANED = os.path.join('..', 'data', 'cleaned')
RESULTS = os.path.join('..', 'data', 'results')

# Parametros relevantes
YEARS = range(2012, 2021)
PPP = 2.712144227
RENDAS = ['rdpc_habi', 'rdpc_efet', 'rlpc_habi', 'rlpc_efet']

# Importa arquivos Stata e salva em Pickle
t1_importa = importa_pnadc_dtas(inputs=DTA,
                                years=YEARS,
                                outputs=RAW)

# Preparacao dos dados
t2_prepara = prepara_pnadc(inputs=RAW,
                           years=YEARS,
                           deflatores=os.path.join(RAW, 'ipeadata_inpc.xls'),
                           referencia='2020.12',
                           outputs=CLEANED)

# Calcula estatisticas de pobreza
pnadc, resultados_pobreza, t3_pobreza = pobreza_pnadc(input_file=os.path.join(CLEANED, 'pnadc.pkl'),
                                                      rendas=RENDAS,
                                                      ppp=2.712144227,
                                                      output_file=os.path.join(RESULTS, 'pobreza.csv'))

# Log com timer
timers = {obj: globals()[obj] for obj in dir() if re.match('^t[0-9]', obj)}
timer_pnadc(os.path.join(RESULTS, 'log.txt'), timers)
