from datetime import datetime


def timer_pnadc(txt, ts):
    ts['Total'] = sum(ts.values())
    ts['Total excl. importacao'] = ts.get('Total') - ts.get('t1_importa')
    with open(txt, 'w') as f:
        dt_string = datetime.now().strftime("%d/%m/%Y %H:%M:%S")
        f.write(f'DATA DE EXECUCAO: {dt_string}\n\n')
        f.write('Etapas:\n')
        f.write(f"Importacao dos .dtas:     {ts.get('t1_importa'):5.1f} segundos\n")
        f.write(f"Preparacao das variaveis: {ts.get('t2_prepara'):5.1f} segundos\n")
        f.write(f"Calculo dos indicadores:  {ts.get('t3_pobreza'):5.1f} segundos\n\n")
        f.write(f'Tempo total:\n')
        f.write(f"Incluindo a importacao:   {ts.get('Total'):5.1f} segundos\n")
        f.write(f"Excluindo a importacao:   {ts.get('Total excl. importacao'):5.1f} segundos\n")
    f.close()
    print(f'SAVED: {txt}')

