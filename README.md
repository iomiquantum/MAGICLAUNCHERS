# MAGICLAUNCHERS

Setup de Claude Code con launchers por modelo para macOS, Linux y Windows.

Replica mi flujo personal: una sesión tmux por modelo, contador automático, orquestador que delega a workers, broadcast/dispatch de tareas a sesiones activas y un dashboard web opcional.

## Contenido

| Carpeta | Para qué |
|---|---|
| [`MAC/`](MAC/) | Mis `.command` originales de Mac (replica exacta de mi setup) |
| [`WINDOWS/`](WINDOWS/) | Instalador completo Windows (WSL2 + Ubuntu + launchers .bat en Escritorio) |
| [`GENERICOS/`](GENERICOS/) | Instalador universal — detecta macOS, Linux o Windows y hace lo correcto |

## Requisitos

- **macOS:** cualquier versión reciente (10.15+). Homebrew se auto-instala si falta.
- **Linux:** apt, dnf o pacman.
- **Windows 10/11 64-bit** con build 19041+ (para WSL2).

## Cómo usar

### Descargar

Opción A — ZIP desde GitHub:
1. Click en el botón verde **Code** → **Download ZIP**
2. Descomprimir

Opción B — git clone:
```bash
git clone https://github.com/iomiquantum/MAGICLAUNCHERS.git
```

### Instalar

**macOS (replica exacta de mi setup original):**
```bash
cd MAGICLAUNCHERS/MAC
bash INSTALAR.command
```
O doble-click en `MAC/INSTALAR.command` desde Finder.

**macOS o Linux (instalador universal):**
```bash
cd MAGICLAUNCHERS/GENERICOS
bash INSTALAR.command
```

**Linux:**
```bash
cd MAGICLAUNCHERS/GENERICOS
bash INSTALAR.sh
```

**Windows:**

Doble-click en `MAGICLAUNCHERS/WINDOWS/INSTALAR.bat` (te pide permisos de Administrador).

### Clave de acceso

Al arrancar, el instalador pide una clave. 3 intentos fallidos y aborta.

## Qué instala

Los mismos 8 launchers en todos los sistemas:

| Launcher | Modelo | Comportamiento |
|---|---|---|
| `Opus` | `claude-opus-4-6` | Nueva sesión tmux `OPUS-$N` |
| `Opus47` | `claude-opus-4-7` | Nueva sesión tmux `OPUS47-$N` |
| `Sonnet` | `claude-sonnet-4-6` | Nueva sesión tmux `SONNET-$N` |
| `Haiku` | `claude-haiku-4-5-20251001` | Nueva sesión tmux `HAIKU-$N` |
| `Orquestador` | `claude-opus-4-6` + prompt | Sesión única reutilizable |
| `Broadcast` | — | Envía misma tarea a TODAS las sesiones |
| `Dispatch` | — | Envía tarea a UNA sesión específica |
| `Kill-All` | — | Mata todas las sesiones tmux |

Y en Windows además:
- `Start-Dashboard.bat` — arranca el dashboard web en `http://localhost:3200`
- `Stop-Dashboard.bat`

## Flags de Claude Code usados

```
claude --model <modelo> --name <NOMBRE-N> --dangerously-skip-permissions --rc
```

Orquestador añade `--append-system-prompt-file` apuntando a `~/.claude-launchers/orquestador-prompt.txt`.

## Prevención de sleep

- **macOS:** `caffeinate -s` envuelve el proceso `claude`.
- **Linux:** no aplica (tmux mantiene la sesión viva).
- **Windows:** `powercfg` desactiva suspender/hibernar con corriente AC.

## Estructura de estado

```
~/.claude-launchers/
├── opus-counter         ← contador sesiones Opus 4.6
├── opus47-counter       ← contador Opus 4.7
├── sonnet-counter
├── haiku-counter
├── orquestador-prompt.txt
└── logs/
    ├── orchestrator.log
    └── usage.log
```

## Autor

Miguel Valencia ([@iomiquantum](https://github.com/iomiquantum))
