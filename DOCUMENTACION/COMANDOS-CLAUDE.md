# Cómo hablarle a Claude para gestionar proyectos

Dentro de cualquier sesión Claude (abierta desde `Opus47`, `Haiku`, `Sonnet`, `Orquestador`, etc.), **no necesitas escribir comandos técnicos**. Solo habla en español natural y Claude ejecuta los scripts apropiados.

## Frases clave — chuleta rápida

### Proyectos

| Lo que le digas | Qué hace Claude |
|---|---|
| *"creá un proyecto para X"* | Ejecuta `crear-proyecto.sh "X"` → devuelve ruta con ID tipo `PROY-001-X` → entra ahí |
| *"nuevo proyecto X"* | Igual al anterior |
| *"qué proyectos tengo"* | Ejecuta `listar-proyectos.sh` → muestra los 3 grupos (PROYECTOS / ORQUESTADOS / ARCHIVO) |
| *"lista los proyectos"* | Igual |
| *"abrí el proyecto PROY-003"* | Hace `cd` a esa carpeta |
| *"trabajemos en el de landings"* | Busca por nombre y entra |
| *"estado del proyecto actual"* | Lee `.proyecto.json` y te lo muestra |

### Promover a MASTERORCA

| Lo que le digas | Qué hace Claude |
|---|---|
| *"subí esto a ORCA"* | Ejecuta `promover-a-orca.sh` con el directorio actual → asigna ID global, mueve a `ORQUESTADOS/`, push al repo privado |
| *"promové este proyecto"* | Igual |
| *"orquestá esto"* | Igual |
| *"pasá esto a MASTERORCA"* | Igual |

Antes de ejecutar, Claude lee lo que hiciste en el proyecto (archivos, README, notas) y **genera automáticamente un BRIEF.md inteligente** para que el Orquestador tenga contexto.

### Archivar

| Lo que le digas | Qué hace |
|---|---|
| *"archivá este proyecto"* | Ejecuta `archivar-proyecto.sh` → mueve a `ARCHIVO/` |
| *"guardá y cerrá esto"* | Igual |
| *"esto ya terminó"* | Igual |

## Ejemplos de sesión real

### Ejemplo 1 — Empezar un proyecto desde cero

```
Tú:      necesito armar 5 landings para clientes de Ecuador, creemos el proyecto

Claude:  (ejecuta crear-proyecto.sh "landings Ecuador")
         Creé el proyecto PROY-001-landings-ecuador.
         Estoy dentro de esa carpeta. ¿Por dónde empezamos?
         ¿Me das el brief de cada ciudad o uno genérico?

Tú:      ...y le contás lo que quieres
         (trabajan un rato)

Tú:      esto está quedando bien, subilo a ORCA para que se reparta

Claude:  (lee README.md y archivos del proyecto, genera brief inteligente)
         (ejecuta promover-a-orca.sh con el brief)
         Promovido a ORCA-005.
         La carpeta local ahora está en ORQUESTADOS/ORCA-005-landings-ecuador/
         Ya hice push al repo MASTERORCA.
         Lo próximo: un Orquestador puede generar ANALISIS.md y asignar tareas.
```

### Ejemplo 2 — Retomar un proyecto existente

```
Tú:      qué proyectos tengo activos

Claude:  (ejecuta listar-proyectos.sh)
         
         PROYECTOS LOCALES:
           PROY-001-landings-ecuador     "landings Ecuador"
           PROY-002-script-pdfs          "Script PDFs"
           PROY-003-idea-app             "App idea cliente X"
         
         ORQUESTADOS:
           ORCA-005-landings-ecuador    "landings Ecuador (orquestado)"
         
         ARCHIVO:
           PROY-002-viejo                "test archivado"

Tú:      abrí el de script pdfs

Claude:  (cd PROYECTOS/PROY-002-script-pdfs/)
         Listo, estoy en el proyecto "Script PDFs". 
         Veo que tienes un README.md y 3 archivos. ¿Seguimos donde quedamos?
```

### Ejemplo 3 — Promover con brief explícito

```
Tú:      promové este proyecto a ORCA con el brief: "generar 20 resúmenes de PDFs 
         técnicos, cada uno de máximo 500 palabras, en español"

Claude:  (ejecuta promover-a-orca.sh "$(pwd)" "el brief que le diste")
         Promovido a ORCA-007.
         BRIEF.md creado con tu texto.
         Repo actualizado en GitHub.
```

## Qué necesitas tener listo por máquina

Para que **todo esto funcione**, la máquina debe tener:

1. **MAGICLAUNCHERS instalado** (ya lo tienes) — los launchers, scripts, CLAUDE.md en workspace
2. **MASTERORCA clonado** (solo si vas a promover):
   ```bash
   gh auth login
   cd ~ && git clone https://github.com/iomiquantum/MASTERORCA.git
   ```

Si no tienes MASTERORCA clonado, la primera vez que pidas "promover a ORCA", Claude te dará los 2 comandos de arriba y los ejecuta por ti si se lo permites.

## Qué NO necesitas memorizar

- No necesitas acordarte de rutas de scripts
- No necesitas saber qué ID toca (PROY-001, PROY-002)
- No necesitas escribir `git commit` o `git push`
- No necesitas crear carpetas manualmente

Todo eso lo maneja Claude leyendo el `CLAUDE.md` del workspace.

## Inspeccionar manualmente (si querés saber qué hay)

Desde terminal, sin sesión Claude:

```bash
ls ~/Documents/PROYECTOS\ CLAUDE\ CODE/         # tu carpeta por máquina
cat ~/.claude-launchers/machine-name            # nombre actual
ls ~/.claude-launchers/scripts/                  # scripts que Claude puede invocar
cat ~/.claude-launchers/workspace-template/CLAUDE.md  # las instrucciones que lee Claude
```

## Para aprender más

- Manual de launchers: [`LAUNCHERS.md`](LAUNCHERS.md)
- Arquitectura MASTERORCA: https://github.com/iomiquantum/MASTERORCA (privado)
