# Práctica de Bash Scripting

### Integrantes
- Jhonatan Cabezas 70416

En el siguiente repositorio se encuentran los scripts desarrollados para la práctica de Bash Scripting, cada carpeta esta separado por el nivel establecido en el documento. 

Para poder ejecutar el nivel_1, nivel_3 y nivel_4, es necesario tener un .env con el webhook de un canal de discord y con un correo electrónico para mandar las alertas. El formato del .env es el siguiente:

```
DISCORD_WEBHOOK="Link del webhook de discord"
ALERT_EMAIL="Email para enviar las alertas"
``` 

Para el nivel_2 no es necesario los .env, pero si es necesario configurar el cron, en el script se encuentra comentado el cron utilizado y podria usarse de ejemplo.
