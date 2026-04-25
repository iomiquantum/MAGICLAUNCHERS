# Workspace de proyectos — instrucciones para Claude

Esta carpeta es el workspace de proyectos de esta máquina. Aquí se gestionan **todos los proyectos** que el usuario trabaja con Claude Code en este equipo.

## Estructura

```
PROYECTOS/      proyectos locales (ID: PROY-XXX)
ORQUESTADOS/    promovidos a MASTERORCA (ID: ORCA-XXX)
ARCHIVO/        proyectos terminados
```

## Tu rol como Claude

Cuando el usuario te pida acciones de gestión de proyectos, **NO le digas "tienes que correr X comando"**. Ejecuta tú los scripts directamente con la herramienta Bash.

## Capacidades disponibles (scripts en `~/.claude-launchers/scripts/`)

### Crear un proyecto nuevo
```bash
~/.claude-launchers/scripts/crear-proyecto.sh "nombre del proyecto"
```
Devuelve la ruta del proyecto. **Hace falta hacer `cd` ahí inmediatamente** para empezar a trabajar dentro.

### Listar todos los proyectos
```bash
~/.claude-launchers/scripts/listar-proyectos.sh
```
Muestra los proyectos en las 3 carpetas.

### Promover a MASTERORCA (de PROY-XXX a ORCA-XXX)
```bash
~/.claude-launchers/scripts/promover-a-orca.sh "/ruta/del/proyecto" "brief opcional"
```
Asigna ID global ORCA-XXX, mueve el proyecto a `ORQUESTADOS/`, crea entrada en repo MASTERORCA con BRIEF.md, hace push.

**Pre-requisitos**:
- MASTERORCA clonado en `~/MASTERORCA`
- `gh auth login` autenticado

Si el script falla, lee el mensaje y guía al usuario para resolver.

### Archivar
```bash
~/.claude-launchers/scripts/archivar-proyecto.sh "/ruta/del/proyecto"
```

## Mapa de frases del usuario → acciones

| Si el usuario dice algo como… | Tú haces |
|---|---|
| "creemos un proyecto X" / "nuevo proyecto X" | `crear-proyecto.sh "X"` y luego `cd` al path resultante |
| "qué proyectos tengo" / "lista los proyectos" | `listar-proyectos.sh` |
| "abrí el proyecto X" / "trabajemos en X" | `cd` a la carpeta `PROYECTOS/PROY-XXX-X/` o `ORQUESTADOS/ORCA-XXX-X/` |
| "subí esto a ORCA" / "promové a ORCA" / "orquestá este proyecto" | `promover-a-orca.sh "$(pwd)" "brief generado a partir del trabajo previo"` |
| "archivá este proyecto" / "guardá esto" | `archivar-proyecto.sh "$(pwd)"` |
| "estado del proyecto" / "info del proyecto" | `cat .proyecto.json` (si existe) |

## Reglas

1. **Antes de trabajar, asegurate de estar dentro de un proyecto.** Si el usuario abre una sesión y empieza a pedir cosas en el workspace raíz, sugerile crear un proyecto o elegir uno existente.

2. **Cuando el usuario pida "promover a ORCA", genera un BRIEF inteligente** a partir del trabajo previo. Lee los archivos del proyecto y resume el objetivo, contexto, entregables. Luego ejecuta `promover-a-orca.sh "$(pwd)" "brief que generaste"`.

3. **Si MASTERORCA no está configurado** y el usuario quiere promover, guíalo paso a paso:
   ```bash
   gh auth login
   cd ~ && git clone https://github.com/iomiquantum/MASTERORCA.git
   ```
   Y después reintentar.

4. **Nunca trabajes en el workspace raíz**. El root (`PROYECTOS CLAUDE CODE/MACHINE/`) es solo para tener visión global. Todo trabajo real va dentro de un PROYECTO o un ORQUESTADO.

## Identidad de esta máquina

El nombre de esta máquina está en `~/.claude-launchers/machine-name`. Si necesitás referenciarla:
```bash
cat ~/.claude-launchers/machine-name
```

## Repos relacionados

- **MAGICLAUNCHERS** (público): https://github.com/iomiquantum/MAGICLAUNCHERS — los launchers que abren tu sesión
- **MASTERORCA** (privado): https://github.com/iomiquantum/MASTERORCA — coordinación distribuida del cluster
