# Día 4: Profundizando en Git y Flujos de Trabajo de GitHub

Hoy dejé atrás los comandos básicos para adentrarme en flujos de trabajo más realistas y potentes que se usan en el día a día de un equipo de DevOps. La práctica se centró en manipular el historial y gestionar cambios de una manera más profesional, todo dentro de mi propio repositorio del desafío.

## Desafío 1: Flujo de Trabajo con Ramas y Pull Requests (PR)

Este fue el ejercicio más importante, ya que simula el ciclo de colaboración completo.
1.  Creé una nueva rama `dia4-practica-pr` desde `main`.
2.  Añadí este mismo archivo `dia-04.md` como un nuevo cambio.
3.  Subí la rama a GitHub con `git push origin dia4-practica-pr`.
4.  Desde la web de GitHub, abrí un **Pull Request** para fusionar mis cambios en la rama `main`.
5.  Revisé y completé el **merge** del PR. Este es el flujo de trabajo estándar para proponer y aprobar cambios en un proyecto.

## Desafío 2: Revirtiendo Cambios de Forma Segura con `git revert`

Para practicar cómo deshacer cambios sin destruir el historial, realicé una reversión del merge anterior.
1.  Busqué el "hash" (identificador único) del commit de merge que se generó con el PR.
2.  Usando `git revert <hash>`, creé un nuevo commit que anula exactamente los cambios introducidos, eliminando el archivo `dia-04.md` pero manteniendo un registro transparente de todo lo que ha sucedido.

## Desafío 3: Guardando Cambios Temporales con `git stash`

Practiqué el uso de `git stash` para gestionar trabajo no finalizado.
1.  Modifiqué un archivo localmente pero no lo confirmé con un `commit`.
2.  Ejecuté `git stash` para guardar esos cambios en una "pila" temporal, dejando mi directorio de trabajo limpio.
3.  Después de simular un cambio de contexto, usé `git stash pop` para recuperar mis cambios y continuar trabajando donde lo había dejado. Es una herramienta increíblemente útil para manejar interrupciones.

## Desafío 4: Limpiando el Historial con Rebase Interactivo

Para crear un historial de commits más limpio y profesional, practiqué con el rebase interactivo.
1.  En una rama de prueba, hice varios commits pequeños y con mensajes poco descriptivos ("WIP", "fix", etc.).
2.  Ejecuté `git rebase -i HEAD~3` para agrupar los últimos 3 commits.
3.  Usé la opción `squash` en el editor interactivo para fusionar los 3 commits en uno solo.
4.  Escribí un único mensaje de commit, claro y descriptivo, para el nuevo commit combinado. Esta técnica es fundamental para mantener la historia de un proyecto legible.

## Conclusión del Día

Hoy fue un día denso pero muy productivo. Pasar de solo "guardar" cambios a "gestionar" el historial de forma estratégica es un salto de nivel importante. Herramientas como el flujo de PRs, `revert`, `stash` y `rebase` son las que realmente marcan la diferencia en un entorno colaborativo.
