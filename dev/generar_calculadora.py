"""Build the distributable Excel calculator. Python is a development dependency only."""
from pathlib import Path
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment
from openpyxl.comments import Comment
from openpyxl.worksheet.datavalidation import DataValidation
import csv
root=Path(__file__).resolve().parents[1]
products=list(csv.DictReader((root/'inst/extdata/productos.csv').open(encoding='utf-8')))
wb=Workbook();info=wb.active;info.title='Instrucciones'
info.append(['Concepto','Indicacion'])
for row in [
 ('Objetivo','Programar dosis por regla y consolidar un pedido por producto y territorio.'),
 ('Leyenda','Azul y fondo amarillo: entradas editables. Negro: formulas. Verde: vinculos entre hojas.'),
 ('Ejemplo','Todos los valores iniciales son SIMULADOS y editables; no representan adquisiciones ni presentaciones oficiales.'),
 ('Unidad de fila','Dosis_programadas: una dosis/regla. Necesidades: un producto/territorio, sin duplicados.'),
 ('Perdida','Proporcion de dosis no utilizadas entre dosis suministradas. Factor = 1/(1-perdida). No sumar simplemente el porcentaje.'),
 ('Recuperacion','Incluir solo pendientes no contemplados en poblacion programada. No duplicar grupos superpuestos ni alternativas.'),
 ('Inventario','Stock utilizable al fin del horizonte, excluyendo vencido/cuarentena. Documentar consumo previsto de lotes que vencen antes.'),
 ('Transito','Solo entregas confirmadas y oportunas. Reserva segun politica local, tiempo de reposicion y riesgo.'),
 ('Insumos','Jeringas de administracion sobre dosis a administrar; diluyentes/reconstitucion sobre frascos del pedido.'),
 ('Frascos','Primero agrupar todas las dosis de un producto; despues descontar stock y redondear frascos hacia arriba.'),
 ('Capacidad','Volumen empacado por dosis en cm3, segun proveedor. No usar volumen de liquido como volumen de almacenamiento.'),
 ('Uso','Reemplazar ejemplos, duplicar filas con sus formulas si se necesitan mas territorios. No cambiar codigos de producto.'),
 ('Fuente de metodo','https://www.who.int/publications/m/item/vaccine-wastage-rates-calculator'),
 ('Fuente esquema','https://www.gob.pe/institucion/minsa/normas-legales/8265031-561-2026-minsa'),
 ('Limite','Esta calculadora no decide elegibilidad clinica ni valida esquemas individuales. No es una orden de compra.')]:info.append(row)
p=wb.create_sheet('Dosis_programadas')
p.append(['ubigeo','producto_id','dosis_regla','poblacion_elegible','meta','recuperacion','dosis_administrar','perdida','dosis_brutas','fuente'])
for product in products:
 count=3 if product['producto_id']=='PENTA' else 1
 for dose in range(1,count+1):
  r=p.max_row+1
  p.append(['090301',product['producto_id'],str(dose),100,.95,5,f'=ROUNDUP(D{r}*E{r},0)+F{r}',.10,f'=G{r}/(1-H{r})','SIMULADO - validar elegibilidad'])
# Room for new entries; formulas remain blank until an explicit product is entered.
for r in range(p.max_row+1,501):
 p.cell(r,7,f'=IF(B{r}="","",ROUNDUP(D{r}*E{r},0)+F{r})')
 p.cell(r,9,f'=IF(B{r}="","",G{r}/(1-H{r}))')
n=wb.create_sheet('Necesidades')
n.append(['ubigeo','producto_id','dosis_administrar','dosis_brutas','reserva_dosis','stock_utilizable','transito_confirmado','pedido_neto','dosis_frasco','frascos','dosis_redondeadas','jeringas_por_dosis','jeringas_admin','diluyentes_frasco','diluyentes','reconstitucion_frasco','jeringas_reconst','capacidad_caja','cajas_seguridad','cm3_dosis_empacado','litros_pedido','dias_horizonte','dias_reposicion','dias_existencia','punto_pedido','alerta','fuente_presentacion'])
for i,prod in enumerate(products,2):
 # SUMIFS uses the same INEI territory AND physical product; stock is subtracted once.
 n.append(['090301',prod['producto_id'],
  f'=SUMIFS(Dosis_programadas!$G$2:$G$500,Dosis_programadas!$A$2:$A$500,A{i},Dosis_programadas!$B$2:$B$500,B{i})',
  f'=ROUNDUP(SUMIFS(Dosis_programadas!$I$2:$I$500,Dosis_programadas!$A$2:$A$500,A{i},Dosis_programadas!$B$2:$B$500,B{i}),0)',
  20,40,0,f'=MAX(0,D{i}+E{i}-F{i}-G{i})',1,f'=ROUNDUP(H{i}/I{i},0)',f'=J{i}*I{i}',0 if prod['via']=='ORAL' else 1,
  f'=ROUNDUP(C{i}*L{i},0)',0,f'=ROUNDUP(J{i}*N{i},0)',0,f'=ROUNDUP(J{i}*P{i},0)',100,
  f'=ROUNDUP((M{i}+Q{i})/R{i},0)',5,f'=K{i}*T{i}/1000',365,30,
  f'=IF(D{i}>0,F{i}/(D{i}/V{i}),0)',f'=ROUNDUP((D{i}/V{i})*W{i}+E{i},0)',
  f'=IF(D{i}=0,"Sin demanda",IF(X{i}<W{i},"Riesgo de quiebre","Revisar FEFO"))','SIMULADO - sustituir ficha real'])
# Two input scenarios make expected arithmetic explicit and reviewable.
s=wb.create_sheet('Verificacion')
s.append(['Caso','Esperado','Calculado','Resultado'])
s.append(['100 dosis / supervivencia 80%',125,'=100/(1-0.2)','=IF(B2=C2,"OK","ERROR")'])
s.append(['300 dosis + 10 reserva - 40 stock - 20 transito',250,'=MAX(0,300+10-40-20)','=IF(B3=C3,"OK","ERROR")'])
s.append(['250 dosis en frascos de 10',25,'=ROUNDUP(250/10,0)','=IF(B4=C4,"OK","ERROR")'])
formula_cols={'Dosis_programadas':{7,9},'Necesidades':{3,4,8,10,11,13,15,17,19,21,24,25,26},'Verificacion':{3,4}}
for ws in wb:
 ws.freeze_panes='A2';ws.auto_filter.ref=ws.dimensions
 for c in ws[1]:c.font=Font(name='Arial',bold=True,color='FFFFFF');c.fill=PatternFill('solid',fgColor='542583');c.alignment=Alignment(wrap_text=True,vertical='center')
 ws.row_dimensions[1].height=42
 for row in ws.iter_rows(min_row=2):
  for c in row:
   is_formula=c.data_type=='f';color='008000' if is_formula and '!' in c.value else '000000' if is_formula else '1258A2'
   c.font=Font(name='Arial',size=10,color=color);c.alignment=Alignment(vertical='top')
   if not is_formula and ws.title in ['Dosis_programadas','Necesidades']:c.fill=PatternFill('solid',fgColor='FFF5CF')
 for col in ws.columns:ws.column_dimensions[col[0].column_letter].width=22
for ws in [p,n]:
 for row in range(2,ws.max_row+1):ws.cell(row,1).number_format='@'
for row in range(2,p.max_row+1):
 for col in [5,8]:p.cell(row,col).number_format='0.0%'
 if p.cell(row,2).value:
  p.cell(row,4).comment=Comment('Valor de ejemplo SIMULADO. Reemplazar con poblacion elegible documentada por dosis.','Sala situacional')
for col in ['E','H']:
 dv=DataValidation(type='decimal',operator='between',formula1=0,formula2=1 if col=='E' else .9999);dv.errorTitle='Proporcion fuera de rango';dv.error='Meta 0 a 1; perdida menor que 1.';dv.showErrorMessage=True;p.add_data_validation(dv);dv.add(f'{col}2:{col}500')
info.column_dimensions['B'].width=120
for row in info.iter_rows(min_row=2):
 row[1].alignment=Alignment(wrap_text=True,vertical='top');info.row_dimensions[row[0].row].height=34
root.joinpath('entregables').mkdir(exist_ok=True)
wb.save(root/'entregables/Calculadora_necesidades.xlsx')
print(root/'entregables/Calculadora_necesidades.xlsx')
