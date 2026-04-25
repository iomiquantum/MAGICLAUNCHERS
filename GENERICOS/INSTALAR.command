#!/bin/bash
# Entrypoint para Mac - doble-click desde Finder
cd "$(dirname "$0")"
exec bash scripts/install-universal.sh
