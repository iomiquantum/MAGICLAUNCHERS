# ============================================================
# setup-power.ps1 - Equivalente a "caffeinate -s" en Mac
# Hace que Windows no duerma mientras esta conectado a corriente
# ============================================================

Write-Host ""
Write-Host "== Configurando energia (no dormir con corriente) ==" -ForegroundColor Cyan
Write-Host ""

# standby = suspender, 0 = nunca
powercfg /change standby-timeout-ac 0
powercfg /change hibernate-timeout-ac 0

# Mantener disco activo con corriente
powercfg /change disk-timeout-ac 0

# Monitor: puede dormir (ahorra energia sin afectar sesiones)
# Si quieres que TAMPOCO duerma el monitor, descomenta:
# powercfg /change monitor-timeout-ac 0

Write-Host "Hecho. Con corriente: PC no se suspende ni hiberna." -ForegroundColor Green
Write-Host "(El monitor sigue durmiendose para ahorrar energia)" -ForegroundColor Gray
Write-Host ""
