import numpy as np
import os
import pandas as pd
import time


def pobreza_pnadc(input_file, rendas, ppp, output_file):
    # Preambulo
    t0 = time.time()
    # Input
    pnadc = pd.read_pickle(input_file, compression={'method': 'gzip', 'compresslevel': 4}). \
        filter(rendas + ['ano', 'domicilioid', 'pesopop'])
    # Populacao total por ano
    pnadc['populacao'] = pnadc.groupby('ano').pesopop.transform('sum')
    resultados_pobreza = pnadc.groupby('ano', as_index=False).populacao.mean()
    # Renda media
    for renda in rendas:
        avg = f'{renda}_avg'
        tmp = pnadc.groupby(['ano']).apply(lambda x: np.average(x[renda], weights=x['pesopop'])).reset_index()
        tmp = tmp.rename(columns={0: avg})
        resultados_pobreza = pd.merge(resultados_pobreza, tmp, on='ano')
    # Linhas e percentuais de pobreza
    linhas_ppp = [1.90, 3.20, 5.50]
    linhas_reais = list(map(lambda x: np.ceil(x * (365 / 12) * ppp).astype(int), linhas_ppp))
    linhas = dict(zip(linhas_ppp, linhas_reais))
    for k, v in linhas.items():
        vlr_linha = f'vlr_linha_{k}'
        resultados_pobreza[vlr_linha] = v
        for renda in rendas:
            fgt0 = f'{renda}_fgt0_{k}'
            pnadc[fgt0] = 100 * (pnadc[renda] < v)
            tmp = pnadc.groupby(['ano']).apply(lambda x: np.average(x[fgt0], weights=x['pesopop']))
            tmp = tmp.rename(fgt0)
            resultados_pobreza = pd.merge(resultados_pobreza, tmp, on='ano')
    # Percentis
    for renda in rendas:
        cumsum = f'{renda}_cumsum'
        pnadc[cumsum] = pnadc.sort_values(by=['ano', renda]).groupby('ano').pesopop.cumsum()
        percentile = f'{renda}_percentile'
        pnadc[percentile] = (100 * pnadc[cumsum]) / pnadc['populacao']
        pnadc['pctpop'] = np.select([pnadc[percentile] <= 20, pnadc[percentile] > 20], [1, 0], default=np.nan)
        tmp1 = pnadc.groupby(['ano']).apply(lambda x: np.average(x['pctpop'], weights=x['pesopop']))
        tmp1 = tmp1.rename(f'{renda}_bottom20_pct')
        resultados_pobreza = pd.merge(resultados_pobreza, tmp1, on='ano')
        pnadc['bottom20'] = np.where(pnadc[percentile] <= 20, pnadc[renda], np.nan)
        tmp2 = pnadc.loc[(pnadc['pctpop'] == 1)].groupby(['ano']).apply(lambda x: np.average(x['bottom20'],
                                                                                             weights=x['pesopop']))
        tmp2 = tmp2.rename(f'{renda}_bottom20_avg')
        resultados_pobreza = pd.merge(resultados_pobreza, tmp2, on='ano')
    # Encerramento
    resultados_pobreza.to_csv(output_file, sep=';', index=False)
    t1 = time.time()
    print(f'SAVED: {output_file}')
    return pnadc, resultados_pobreza, (t1 - t0)
