from pathlib import Path
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment
from openpyxl.worksheet.datavalidation import DataValidation
import csv
root=Path(__file__).resolve().parents[1]
groups=list(csv.DictReader((root/'inst/extdata/grupos.csv').open(encoding='utf-8')))
wb=Workbook();w=wb.active;w.title='Instrucciones';w.append(['Tema','Indicacion'])
for r in [
 ('Uso','Plantilla complementaria: copie las hojas poblacion y territorios al libro integral conservando los encabezados.'),
 ('Leyenda','Azul y fondo amarillo: entradas del alumno. Ejemplos estan separados para no contaminar los datos.'),
 ('Grano','Una fila por anio, ubigeo INEI y grupo_id; no duplicar la clave.'),
 ('Fuentes','Identificar fuente oficial/nominal/programada, fecha o version y metodo de estimacion. No promediar denominadores de fuentes distintas.'),
 ('Poblacion','Conteo entero positivo. Si el grupo no aplica, omitirlo. No sustituir ausencia de informacion por cero.'),
 ('Superposicion','VIH, gestantes, comorbilidad y otros grupos pueden superponerse. No sumarlos para calcular personas unicas.'),
 ('Ubigeo','Texto de seis digitos. Usar INEI; verificar diferencias con otros sistemas.'),
 ('Edad','RN, M1 y A1 son denominadores distintos. Tercera dosis de neumococo usa A1.'),
 ('Ejemplo','Ver hoja ejemplos. Valores exclusivamente simulados, no cifras de Lircay.'),
 ('Fuente normativa','https://www.gob.pe/institucion/minsa/normas-legales/8265031-561-2026-minsa')]:w.append(r)
p=wb.create_sheet('poblacion');p.append(['anio','ubigeo','grupo_id','poblacion','fuente','version'])
t=wb.create_sheet('territorios');t.append(['ubigeo','distrito','provincia','departamento'])
e=wb.create_sheet('ejemplos');e.append(['anio','ubigeo','grupo_id','poblacion','fuente','version']);e.append([2026,'090301','A1',120,'SIMULADO - sustituir fuente','ejemplo-2026'])
g=wb.create_sheet('grupos');g.append(list(groups[0]));[g.append(list(r.values())) for r in groups]
for s in wb:
 s.freeze_panes='A2'
 for c in s[1]:c.font=Font(name='Arial',bold=True,color='FFFFFF');c.fill=PatternFill('solid',fgColor='542583');c.alignment=Alignment(wrap_text=True)
 s.row_dimensions[1].height=32
 for row in s.iter_rows(min_row=2):
  for c in row:c.font=Font(name='Arial',size=10,color='1258A2');c.alignment=Alignment(wrap_text=True,vertical='top')
 for col in s.columns:s.column_dimensions[col[0].column_letter].width=25
for s in [p,t]:
 for row in s.iter_rows(min_row=2,max_row=101):
  for c in row:c.fill=PatternFill('solid',fgColor='FFF5CF');c.font=Font(name='Arial',color='1258A2',size=10)
 for r in range(2,102):s.cell(r,2 if s==p else 1).number_format='@'
w.column_dimensions['B'].width=120
for r in range(2,w.max_row+1):w.row_dimensions[r].height=34
val=DataValidation(type='whole',operator='greaterThan',formula1=0);val.showErrorMessage=True;p.add_data_validation(val);val.add('D2:D5000')
wb.save(root/'entregables/Plantilla_poblacion.xlsx')
print('Plantilla_poblacion.xlsx creada')
