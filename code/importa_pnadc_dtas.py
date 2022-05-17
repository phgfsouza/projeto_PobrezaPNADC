"""
Modulo para importar arquivos da PNADC Anual lidos em Stata e salvar como Pickle

inputs = local com os arquivos dta
outputs = local para salvar arquivos pkl

"""

import pandas as pd
import os
import fnmatch
import time


def importa_pnadc_dtas(inputs, years, outputs):
    # Timer
    t0 = time.time()
    # Builds list with selected files
    files_in_path = os.listdir(inputs)
    selected_files = []
    for year in years:
        if year != 2020:
            selected_files += fnmatch.filter(files_in_path, f'*{year}*visita1.dta')
        if year == 2020:
            selected_files += fnmatch.filter(files_in_path, f'*{year}*visita5.dta')
    # Loads each dta file and saves to pickle
    for file in selected_files:
        print(f'Processing: {file}')
        df = pd.read_stata(os.path.join(inputs, file))
        df.to_pickle(os.path.join(outputs, file.replace('.dta', '.pkl')),
                     compression={'method': 'gzip', 'compresslevel': 4})
    # Timer
    t1 = time.time()
    # Returns elapsed time
    return (t1 - t0)


if __name__ == '__main__':
    INPUTS = os.path.join('D:', os.sep, 'OneDrive', 'dados', 'IBGE', 'PNADC', 'stata')
    timer_importacao = importa_pnadc_dtas(INPUTS, range(2012, 2021), outputs=os.path.join('..','data','raw'))
