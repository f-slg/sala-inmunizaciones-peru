# Información sensible y alcance de seguridad

El repositorio distribuye código y datos simulados. No es un servicio de historias
clínicas ni un sistema de autenticación o autorización.

- Mantenga datos reales fuera del repositorio o en las carpetas privadas ignoradas.
- Revise `git diff --cached` y los nombres de archivo antes de cada publicación.
- No incluya registros nominales, DNI, contactos ni libros privados en issues.
- El modo público limita funciones nominales; no garantiza anonimización de agregados.
- Configure autenticación, acceso, almacenamiento y retención en el servidor donde
  ejecute una instancia privada. En Posit Cloud los datos se procesan en la nube.

Para comunicar una exposición de datos, use un canal privado con el mantenedor
que figura en DESCRIPTION. Describa la ruta afectada y el mecanismo sin copiar
registros personales. No publique credenciales ni datos en el reporte.
