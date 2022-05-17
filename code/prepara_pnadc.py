# Pacotes
import os
import time
import pandas as pd
import numpy as np
import fnmatch
import re
from scipy import stats

global df, pnadc


def filtra_colunas_e_linhas(method=1):
    # df as global
    global df
    # Colunas - Metodo 1 - Boolean Operators
    if method == 1:
        vars_basicas = df.columns.isin(['ano', 'trimestre', 'upa', 'v1023', 'v1008', 'v1032', 'v2005', 'v2009',
                                        'vd3004', 'vd3005', 'vd4019', 'vd4020'])
        vars_ate_2015 = [bool(re.match('v50[0-1]{1}[0-9]{1}11', column)) for column in df.columns]
        vars_desde_2015 = df.columns.str.endswith('a2')
        df = df[df.columns[vars_basicas | vars_ate_2015 | vars_desde_2015].values]
    # Colunas - Metodo 2 - Lista
    if method == 2:
        vars_basicas = ['ano', 'trimestre', 'upa', 'v1023', 'v1008', 'v1032', 'v2005', 'v2009',
                        'vd3004', 'vd3005', 'vd4019', 'vd4020']
        vars_ate_2015 = [column for column in df.columns if re.match('v50[0-1]{1}[0-9]{1}11', column)]
        vars_desde_2015 = [column for column in df.columns if column.endswith('a2')]
        df = df.filter(items=vars_basicas + vars_ate_2015 + vars_desde_2015)
        # Linhas
        df = df.loc[(df['v2005'] <= 14) | (df['v2005'] > 16)]


def cria_variaveis(drop=True):
    # df as global
    global df
    # Identificacao do domicilio como int64
    df['domicilioid'] = df['upa'].astype('int64') * 100 + df['v1008']
    # Peso
    df.rename(columns={'v1032': 'pesopop'}, inplace=True)
    # Numero de moradores, criancas, adultos por nivel educacional, e idosos
    df['num_moradores'] = 1
    df['num_criancas'] = np.select(
        [(df['v2009'] <= 17), (df['v2009'] > 17)],
        [1, 0]
    )
    df['num_adultos'] = np.select(
        [(df['v2009'] >= 18) & (df['v2009'] <= 64), (df['v2009'] < 18) | (df['v2009'] > 64)],
        [1, 0]
    )
    df['num_idosos'] = np.select(
        [(df['v2009'] > 64), (df['v2009'] <= 64)],
        [1, 0]
    )
    df['educ5'] = np.select(
        [(df['num_adultos'] == 1) & (df['vd3004'] % 2 == 0), (df['num_adultos'] == 1) & (df['vd3004'] % 2 == 1)],
        [(df['vd3004'] + 2) / 2, (df['vd3004'] + 3) / 2],
        default=np.nan
    )
    df.loc[df['vd3005'] <= 4, 'educ5'] = 1
    df = pd.get_dummies(data=df, prefix='educ', columns=['educ5'])
    df.columns = df.columns.str.replace(r'\.0', '', regex=True)
    # Preparacao para  rendimentos de outras fontes
    df[df.columns[df.columns.str.startswith('v')]] = df[df.columns[df.columns.str.startswith('v')]].fillna(0)
    if df['ano'].mean() < 2015:
        df[['v500' + f'{i}' + 'a2' for i in range(1, 10)]] = 0
    if df['ano'].mean() > 2015:
        df[['v50' + f'{i}'.zfill(2) + '11' for i in range(1, 14)]] = 0
    # Rendimentos de outras fontes
    df['rprevi'] = df[['v500111', 'v500211', 'v5004a2']].sum(axis=1)
    df['rsegdes'] = df[['v500811', 'v5005a2']].sum(axis=1)
    df['rbpc'] = df[['v500911', 'v5001a2']].sum(axis=1)
    df['rpbf'] = df[['v501011', 'v5002a2']].sum(axis=1)
    df['routprog'] = df[['v501111', 'v5003a2']].sum(axis=1)
    df['routras'] = df[['v500311', 'v500411', 'v500511', 'v500611', 'v500711', 'v501211', 'v501311', 'v5006a2',
                        'v5007a2', 'v5008a2']].sum(axis=1)
    # Rendimentos do trabalho
    df.rename(columns={'vd4019': 'rtrab_habi', 'vd4020': 'rtrab_efet'}, inplace=True)
    # Descarta variaveis originais (opcional)
    if drop is True:
        df = df.filter(regex='^(num|r|peso|ano|tri|domi|educ)')


def collapse_por_domicilio():
    global df
    df = df.groupby(['ano', 'trimestre', 'domicilioid'], as_index=False).sum()
    vars_renda = [column for column in df.columns if column.startswith('r')]
    for var in vars_renda:
        df[var] = df[var] / df['num_moradores']


def deflacionamento(defl, ref):
    global pnadc
    inpcs = pd.read_excel(defl, dtype={'data': str, 'inpc': np.float64})
    new_columns = inpcs['data'].astype(str).str.split(".", n=1, expand=True)
    inpcs['ano'] = new_columns[0].astype(int)
    inpcs['mes'] = new_columns[1].astype(int)
    inpcs['trimestre'] = np.select([inpcs['mes'] <= 3, inpcs['mes'] <= 6, inpcs['mes'] <= 9, inpcs['mes'] <= 12],
                                   [1, 2, 3, 4], default=np.nan).astype(int)
    inpcs = inpcs.loc[inpcs['ano'] >= 2012]
    inpc_referencia = inpcs.loc[(inpcs['data'] == ref)]['inpc'].sum()
    inpcs['deflator'] = inpcs['inpc'] / inpc_referencia
    inpcs_trimestrais = inpcs.groupby(['ano', 'trimestre'], as_index=False).deflator.apply(stats.gmean)
    pnadc = pnadc.merge(inpcs_trimestrais, on=['ano', 'trimestre'], how='inner')
    for var in [col for col in pnadc.columns if col.startswith('r')]:
        pnadc[var] = pnadc[var] / pnadc['deflator']


def prepara_pnadc(inputs, years, deflatores, referencia, outputs):
    # Preambulo
    t0 = time.time()
    global df
    global pnadc
    # Cria lista com arquivos a serem processados
    selected_files = []
    for year in years:
        selected_files += fnmatch.filter(os.listdir(inputs), f'*{year}*.pkl')
    # Loop por ano
    pnadc = pd.DataFrame()
    for file in selected_files:
        print(f'Harmonizing {file}')
        df = pd.read_pickle(os.path.join(inputs, file), compression={'method': 'gzip', 'compresslevel': 4})
        filtra_colunas_e_linhas(method=2)
        cria_variaveis(drop=True)
        collapse_por_domicilio()
        pnadc = pd.concat([pnadc, df])
        del df
    # Deflacionamento das rendas
    deflacionamento(deflatores, referencia)
    # Rendimentos per capita
    pnadc['rdpc_habi'] = pnadc[['rtrab_habi', 'rprevi', 'rsegdes', 'rbpc', 'rpbf', 'routprog', 'routras']].sum(axis=1)
    pnadc['rdpc_efet'] = pnadc[['rtrab_efet', 'rprevi', 'rsegdes', 'rbpc', 'rpbf', 'routprog', 'routras']].sum(axis=1)
    pnadc['rlpc_habi'] = pnadc[['rtrab_habi', 'rprevi', 'rsegdes', 'rbpc', 'routras']].sum(axis=1)
    pnadc['rlpc_efet'] = pnadc[['rtrab_efet', 'rprevi', 'rsegdes', 'rbpc', 'routras']].sum(axis=1)
    # Encerramento
    pnadc.to_pickle(os.path.join(outputs, 'pnadc.pkl'), compression={'method': 'gzip', 'compresslevel': 4})
    t1 = time.time()
    print(f"SAVED: {os.path.join(outputs,'pnadc.pkl')}")
    return (t1 - t0)
