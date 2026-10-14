#!/bin/bash
set -euo pipefail

echo "=== [Dia 44] Escaneo de Secretos con Gitleaks ==="
if command -v gitleaks &> /dev/null; then
  gitleaks detect --config .gitleaks.toml --source . --verbose
else
  echo "Gitleaks no esta instalado localmente. Simulando comando:"
  echo "gitleaks detect --config .gitleaks.toml --source . --verbose"
fi
