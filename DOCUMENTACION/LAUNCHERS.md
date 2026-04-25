# Manual completo de los launchers

Cada launcher es un archivo que haces **doble-click** y arranca algo útil. Esta guía explica qué hace cada uno, para qué sirve y cómo usarlo.

---

## Los 4 launchers de MODELO

Cada uno abre una sesión nueva de Claude Code con un modelo específico. Son intercambiables, elige según la tarea.

### `Opus` (Claude Opus 4.6)
- **Modelo:** legacy, se mantiene por compatibilidad
- **Cuándo usar:** tareas que antes hacías con Opus 4.6 y querés mantener continuidad
- **Costo:** $15 input / $75 output por millón de tokens
- **Nombre de sesión:** `OPUS-{maquina}-{N}` (ej: `OPUS-PC1-1`, `OPUS-PC1-2`...)
- **Puedes abrirlo varias veces:** sí, cada vez es una sesión nueva numerada

### `Opus47` (Claude Opus 4.7)
- **Modelo:** el **Opus actual**, más capaz del momento
- **Cuándo usar:** tareas complejas que requieren razonamiento profundo, código difícil, arquitectura, decisiones
- **Costo:** mismo que Opus 4.6
- **Nombre de sesión:** `OPUS47-{maquina}-{N}`
- **Velocidad:** más lento que Haiku pero más inteligente

### `Sonnet` (Claude Sonnet 4.6)
- **Modelo:** balance medio entre Haiku y Opus
- **Cuándo usar:** tareas intermedias, código normal, análisis de archivos, explicaciones
- **Costo:** $3 input / $15 output por millón de tokens (5x más barato que Opus)
- **Nombre de sesión:** `SONNET-{maquina}-{N}`
- **Recomendación:** el "default" para el día a día si no necesitás lo más potente

### `Haiku` (Claude Haiku 4.5)
- **Modelo:** el más rápido y económico
- **Cuándo usar:** tareas simples, scripts cortos, revisiones rápidas, lookups
- **Costo:** $1 input / $5 output por millón de tokens (la opción barata)
- **Nombre de sesión:** `HAIKU-{maquina}-{N}`
- **Velocidad:** respuestas casi instantáneas

---

## `Orquestador` — tu MAESTRO

El launcher más poderoso. Abre una sesión especial de Opus 4.6 con un prompt adicional que le enseña a **delegar tareas a otros modelos**.

- **Sesión única:** si ya está abierto, te reconecta. No crea múltiples.
- **Nombre:** `ORQUESTADOR-{maquina}` (sin número)
- **Cómo funciona:** le das una tarea compleja, él decide si la hace solo o la divide entre workers (Haiku para partes baratas, Sonnet para intermedias, Opus para complejas)
- **Ejemplo práctico:**
  - Tú: *"Analizá estos 20 archivos, resumí cada uno y creá un índice"*
  - Orquestador lanza 20 Haikus en paralelo, cada uno resume 1 archivo, después combina resultados
- **Cuándo usar:** trabajos grandes, paralelizables, donde no querés esperar 1 hora en serie

---

## `Broadcast` — misma tarea a TODAS las sesiones

Envía el mismo mensaje a todas las sesiones tmux abiertas.

- **Uso típico:** tenés 3 sesiones trabajando en tareas distintas y querés preguntarles a las 3 "dame status en 1 línea"
- **Flujo:**
  1. Doble-click en `Broadcast`
  2. Te muestra lista de sesiones activas
  3. Escribís el mensaje
  4. Lo envía como si lo hubieras tipeado en cada sesión
- **Importante:** se envía a TODAS, incluye Orquestador

---

## `Dispatch` — tarea a UNA sesión específica

Envía un mensaje solo a una sesión que elijas.

- **Diferencia con Broadcast:** solo una sesión, no todas
- **Flujo:**
  1. Doble-click en `Dispatch`
  2. Te muestra lista de sesiones
  3. Escribís el nombre (ej: `OPUS47-PC1-2`)
  4. Escribís el mensaje
  5. Te pregunta si querés enviar otra a otra sesión
- **Uso típico:** coordinar varias sesiones sin tener que saltar ventanas

---

## `Kill-All` — cerrar todas las sesiones

Mata todas las sesiones tmux de golpe.

- **Atención:** cierra todas las Claude activas sin guardar contexto
- **Uso típico:**
  - Antes de apagar la PC
  - Cuando querés arrancar limpio
  - Después de renombrar la máquina (para que las sesiones nuevas tomen el nombre nuevo)
- **Lo que NO mata:** WSL, Claude ya instalado, tu autenticación — todo eso queda

---

## `Sesiones-Activas` — reconectar sin escribir comandos

Muestra menú numerado de sesiones vivas y te deja entrar con un click.

- **Caso de uso:** cerraste la ventana de terminal por error o a propósito, y querés volver a una sesión que sigue trabajando
- **Flujo:**
  1. Doble-click
  2. Ves lista: `1) OPUS47-PC1-1 (hace 12 min)`, `2) HAIKU-PC1-1 (hace 3 min)`...
  3. Escribís el número
  4. Te conecta directo a esa sesión
- **Tip:** el título de la pestaña ahora muestra el nombre completo, así identificás cuál es cuál cuando tenés varias abiertas

---

## `Renombrar-Mac` / `Renombrar-PC` — cambiar nombre de la máquina

Cambia cómo se identifica esta PC/Mac en los nombres de sesión.

- **Por defecto:** usa el hostname (ej: `DESKTOP-ABC123` en Windows, `MacBook-Air-de-IOMI` en Mac)
- **Con renombrar:** le pones algo corto (`PC1`, `MAC`, `CASA`, `LAB`...)
- **Efecto inmediato:** próximas sesiones nuevas usan el nombre nuevo
  - Sesiones ya abiertas: mantienen el nombre viejo hasta que las cierres
- **Enter vacío:** borra el custom, vuelve al hostname automático
- **Dónde se guarda:** `~/.claude-launchers/machine-name` (un solo archivo)

---

## `Actualizar` — descargar última versión

Descarga del repo GitHub la última versión de todos los launchers y reemplaza los locales.

- **Cuándo usarlo:**
  - Después de agregar nuevas features al repo
  - Cuando pasa algo raro y querés volver a versión conocida
  - Cada tanto, para tener lo último
- **Qué hace:**
  1. Descarga `github.com/iomiquantum/MAGICLAUNCHERS`
  2. Detecta dónde están tus launchers
  3. Reemplaza los `.command` / `.sh` con los nuevos
  4. No toca `~/.claude-launchers/` (tu nombre custom, contadores, etc. se conservan)
- **Cuánto tarda:** 10-20 segundos

---

## `Start-Dashboard` / `Stop-Dashboard` (solo Windows por ahora)

Arranca/apaga un dashboard web local.

- **URL:** http://localhost:3200
- **Qué muestra:** sesiones activas, costos por modelo, actividad
- **Puertos usados:** 3200 (Node.js) y 8420 (Python usage server)
- **Logs:** `~/.claude-launchers/logs/`
- **Cuándo usarlo:** si querés vista gráfica del estado. Opcional.

---

## ¿Se puede mover la carpeta de launchers a otra ubicación?

**Sí, todos los launchers son portables.** Puedes arrastrar la carpeta a donde quieras.

### Por qué funciona

Los launchers guardan su estado en `~/.claude-launchers/` — esa ruta es **fija por usuario** (en `$HOME`), no en la carpeta donde estén los launchers. Entonces:

- ✅ Muevas los launchers a Documents, Downloads, o donde sea → siguen funcionando
- ✅ Los contadores siguen sumando correctamente
- ✅ El nombre custom (machine-name) se conserva
- ✅ El prompt del orquestador sigue cargándose

### Lo único que notás al mover

- El acceso directo `.bat` o `.command` cambia de ruta — tus atajos visuales se actualizan al arrastrar
- Si tenés shortcuts del menú inicio de Windows apuntando a la ruta vieja, hay que recrearlos

### Lo que NO hay que mover

- `~/.claude-launchers/` — esta carpeta es sagrada, contiene tu estado. Si la movés, perdés contadores y nombre custom
- WSL y Ubuntu (si estás en Windows) — eso ya está instalado y no tiene ruta "movible"

---

## Estructura de archivos que tenés

```
En cualquier máquina después de instalar:

~/.claude-launchers/               (estado, NO mover)
├── opus-counter                   ← contador de sesiones Opus 4.6
├── opus47-counter                 ← contador de sesiones Opus 4.7
├── sonnet-counter
├── haiku-counter
├── machine-name                   ← tu nombre custom (opcional)
├── orquestador-prompt.txt         ← prompt del maestro
└── logs/                          ← logs del dashboard (si lo usás)

Tu carpeta de launchers (movible):
├── ClaudeCode-Opus.command    (o .bat)
├── ClaudeCode-Opus47.command
├── ClaudeCode-Sonnet.command
├── ClaudeCode-Haiku.command
├── ORQUESTADOR.command         (dentro de subcarpeta ORQUESTADOR/ en Mac)
├── BROADCAST.command           (dentro de BROADCAST-DISPATCH/ en Mac)
├── DISPATCH.command
├── KILL-ALL.command
├── Sesiones-Activas.command
├── Renombrar-Mac.command       (o Renombrar-PC.bat)
└── Actualizar.command          (o Actualizar.bat)
```

---

## Preguntas comunes

### ¿Puedo abrir muchas sesiones a la vez?
Sí, pero cada sesión usa RAM. En máquinas de 8GB, más de 3 sesiones simultáneas puede ir lento. En 16GB+ no hay problema.

### ¿Qué pasa si cierro la ventana de terminal?
La sesión Claude sigue viva en segundo plano. Para volver a verla: `Sesiones-Activas` o `tmux attach -t NOMBRE`.

### ¿Cómo cierro una sesión "bien" (liberando memoria)?
Dentro de Claude: escribe `/exit` o Ctrl+D. La sesión tmux también se cierra.

### ¿Los contadores se pueden resetear?
Sí: borra los archivos `~/.claude-launchers/*-counter`.

### ¿Puedo usar esto en Linux nativo (sin WSL)?
Sí, usa los launchers de `GENERICOS/`. Linux nativo funciona igual que Mac pero sin `caffeinate`.

### ¿Se puede tener sesiones sincronizadas entre PC y Mac?
No. Cada máquina tiene sus propias sesiones. Pero puedes hacer git push/pull de archivos que edites y así compartir trabajo entre máquinas.
