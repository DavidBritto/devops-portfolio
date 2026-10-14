#!/bin/bash
set -euo pipefail

NEW_TAG="${1:-v1.0.0}"
echo "=== [Dia 66] Automatizacion de Release e Ingenieria de Versiones ==="
echo "Preparando release para tag: ${NEW_TAG}"

# Validar formato semantico
if [[ ! "${NEW_TAG}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: El tag debe seguir el formato semantico vX.Y.Z (ejemplo: v1.0.0)"
  exit 1
fi

echo "1. Ejecutando comprobaciones pre-release..."
git status --porcelain

echo "2. Generando changelog automatico..."
echo "## Release ${NEW_TAG} - $(date +%F)" > CHANGELOG_NEW.md
echo "- Actualizacion de arquitectura y dependencias" >> CHANGELOG_NEW.md
echo "- Mejoras de resiliencia y observabilidad" >> CHANGELOG_NEW.md

echo "Release ${NEW_TAG} preparado correctamente."
rm -f CHANGELOG_NEW.md
