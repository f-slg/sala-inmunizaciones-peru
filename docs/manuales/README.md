# Manuales de la sala situacional · v0.2.0

| Manual | Word | PDF | Fuente legible |
|---|---|---|---|
| Uso · 15 páginas | [DOCX](Manual_de_uso.docx) | [PDF](Manual_de_uso.pdf) | [Markdown](Manual_de_uso.md) |
| Construcción técnica · 17 páginas | [DOCX](Manual_tecnico_construccion.docx) | [PDF](Manual_tecnico_construccion.pdf) | [Markdown](Manual_tecnico_construccion.md) |

Los comandos de cálculo y exportación se comprobaron contra el código 0.2.0.
Los Word pasaron validación OOXML y se renderizaron con LibreOffice; se revisaron
las 32 páginas de ambos manuales. Las secciones están separadas mediante
`<!-- PAGE -->` en los Markdown para mantener la paginación prevista.

## Editar y regenerar

Edite los Markdown y ejecute `node dev/generar_manuales.js` desde la raíz.
El generador requiere Node.js y `docx` (versión utilizada: 9.6.1); estas herramientas
no son necesarias para usar la aplicación ni los documentos ya generados.
Si se necesita instalar la dependencia localmente:

```text
npm install --no-save --package-lock=false docx@9.6.1
node dev/generar_manuales.js
```

Convierta los Word a PDF usando Word o LibreOffice y revise la maquetación.
Si añade texto a un capítulo puede aumentar la paginación; actualice las cifras
del README después de renderizar. Mantenga coherentes los tres formatos.

Los materiales de la clase tienen un guion propio, separado de estos manuales.
El manual técnico describe la implementación y una ruta didáctica de estudio;
no afirma registrar literalmente cada comando histórico de creación.
