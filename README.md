# PobrezaPNADC

## Descrição

Gera indicadores de pobreza para as PNADC anuais de 2012-2019 (visita 1) e 2020 (visita 5). 

## Unidade geográfica

Brasil

## Período

2012-2020

## Conceito de renda

Todos os indicadores sobre rendimentos foram calculados para quatro definições distintas da _renda domiciliar per capita_ (rdpc), conforme os prefixos e definições abaixo:


```rdpc_efet_*``` : rdpc total calculada com rendimentos _efetivos_ do trabalho e de outras fontes

```rdpc_habi_*``` : rdpc total calculada com rendimentos _habituais_ do trabalho e rendimentos _efetivos_ de outras fontes

```rlpc_efet_*``` : rdpc líquida de benefícios do Programa Bolsa Família e de outros programas sociais (inclusive Auxílio Emergencial em 2020) calculada com rendimentos _efetivos_ do trabalho e de outras fontes exclusive transferências 

```rlpc_habi_*``` : rdpc líquida de benefícios do Programa Bolsa Família e de outros programas sociais (inclusive Auxílio Emergencial em 2020) calculada com rendimentos _habituais_ do trabalho e rendimentos _efetivos_ de outras fontes


## Indicadores

O arquivo ```./data/results/pobreza.csv``` contém os seguintes indicadores:

```populacao``` : população estimada pela PNADC (pós-calibração pela projeção de população, variável original _v1032_)

```*_avg``` : renda domiciliar per capita média no país (em reais de dezembro de 2020)

```vlr_linha_1.9``` : valor mensal em reais de dezembro de 2020 da linha internacional de pobreza de $1.90 por dia (em dólares internacionais de 2011)

```*_fgt0_1.9``` : percentual de pobres na população para linha de $1.90 por dia (em dólares internacionais de 2011)

```vlr_linha_3.2``` : valor mensal em reais de dezembro de 2020 da linha internacional de pobreza de $3.20 por dia (em dólares internacionais de 2011)

```*_fgt0_3.2``` : percentual de pobres na população para linha de $3.20 por dia (em dólares internacionais de 2011)

```vlr_linha_5.5``` :  valor mensal em reais de dezembro de 2020 da linha internacional de pobreza de $5.50 por dia (em dólares internacionais de 2011)

```*_fgt0_5.5``` : percentual de pobres na população para linha de $3.20 por dia (em dólares internacionais de 2011)

```*_bottom20_pct``` : percentual da população entre os 20% mais pobres (número somente para validação)

```*_bottom20_avg``` : rdpc média dos 20% mais pobres da população (em reais de dezembro de 2020)


## Instruções

1) Altere o objeto ```DTA``` em ```main.py``` para indicar o caminho local para os arquivos da PNADC em Stata

2) No terminal, mude para o diretório ```./code/``` e execute ```python main.py```

3) Planilha com resultados será gravada em ```./data/results/pobreza.csv```


## Benchmark _vs_ Stata

*Duração média em 10 execuções (segundos)*

| **Etapas**                 | **Stata (seg)** | **Python (seg)** | **Variação (%)**|
|-------------------------- |-------|--------|---------|
| Importação dos arquivos   | N/A   | 253.19     | N/A        |
| Preparação das variáveis  | 110.34 | 77.81      | -29.5        |
| Cálculo dos indicadores   | 15.24    | 9.85       | -35.4         |
| **Total (incl. importação)**  | **N/A**      | **340.85** | **N/A**  |
| **Total (exc.  importação)**  | **125.57**      |  **87.66**  | **-30.2**   |

