#!/usr/bin/env bash
# ==============================================================================
# Script de preparacion y automatizacion: Dia 36 (ARC en Kubernetes con Kind)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
DEMO_DIR="${SCRIPT_DIR}/k8s-arc-demo"

# Colores para salida de terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_err()  { echo -e "${RED}[ERROR]${NC} $1"; }

# 1. Verificar y ordenar archivos en sus ubicaciones correctas
organizar_archivos() {
    log_info "Verificando estructura de archivos de dia-36 y k8s-arc-demo..."

    # Verificar si deploy.yml quedo suelto en la raiz del repo
    if [[ -f "${REPO_ROOT}/.github/workflows/deploy.yml" ]]; then
        log_warn "Se detecto deploy.yml en la raiz del repo. Moviendolo a ${DEMO_DIR}/.github/workflows/deploy.yml"
        mkdir -p "${DEMO_DIR}/.github/workflows"
        mv "${REPO_ROOT}/.github/workflows/deploy.yml" "${DEMO_DIR}/.github/workflows/deploy.yml"
        log_ok "deploy.yml reubicado correctamente."
    fi

    # Verificar que deploy.yml exista en la carpeta demo
    if [[ ! -f "${DEMO_DIR}/.github/workflows/deploy.yml" ]]; then
        log_warn "No se encontro deploy.yml en ${DEMO_DIR}/.github/workflows/."
    else
        log_ok "Workflow deploy.yml ubicado en demo."
    fi

    # Normalizar extension de service (service.yml -> service.yaml)
    if [[ -f "${DEMO_DIR}/k8s/service.yml" && ! -f "${DEMO_DIR}/k8s/service.yaml" ]]; then
        mv "${DEMO_DIR}/k8s/service.yml" "${DEMO_DIR}/k8s/service.yaml"
        log_ok "Renombrado service.yml -> service.yaml en ${DEMO_DIR}/k8s/"
    fi

    # Normalizar Dockerfile si esta en minuscula
    if [[ -f "${DEMO_DIR}/dockerfile" && ! -f "${DEMO_DIR}/Dockerfile" ]]; then
        mv "${DEMO_DIR}/dockerfile" "${DEMO_DIR}/Dockerfile"
        log_ok "Renombrado dockerfile -> Dockerfile en ${DEMO_DIR}"
    fi

    # Asegurar plantilla de variables de entorno si falta
    if [[ ! -f "${SCRIPT_DIR}/arc-secrets.env.example" ]]; then
        cat << 'EOF' > "${SCRIPT_DIR}/arc-secrets.env.example"
GITHUB_APP_ID="TU_APP_ID"
GITHUB_APP_INSTALLATION_ID="TU_INSTALLATION_ID"
EOF
        log_ok "Creado arc-secrets.env.example"
    fi
}

# 2. Verificar dependencias instaladas en el sistema
verificar_dependencias() {
    log_info "Verificando herramientas requeridas..."
    local missing=0

    for cmd in docker kind kubectl helm; do
        if command -v "$cmd" >/dev/null 2>&1; then
            log_ok "Comando encontrado: $cmd ($( "$cmd" version --client 2>/dev/null || "$cmd" --version 2>/dev/null | head -n1 ))"
        else
            log_err "Falta herramienta obligatoria: $cmd"
            missing=$((missing + 1))
        fi
    done

    if ! docker info >/dev/null 2>&1; then
        log_err "El daemon de Docker no esta corriendo o el usuario no tiene permisos."
        missing=$((missing + 1))
    else
        log_ok "Docker daemon activo."
    fi

    if [[ $missing -gt 0 ]]; then
        log_warn "Hay $missing dependencias pendientes. Consulta ejecucion.md seccion Requisitos."
        return 1
    fi
    return 0
}

# 3. Validar estado de secretos de GitHub App
verificar_secretos() {
    log_info "Verificando secretos para GitHub App y ARC..."

    if [[ ! -f "${SCRIPT_DIR}/arc-secrets.env" ]]; then
        log_warn "No existe arc-secrets.env. Crealo a partir de arc-secrets.env.example:"
        echo "       cp ${SCRIPT_DIR}/arc-secrets.env.example ${SCRIPT_DIR}/arc-secrets.env"
    else
        chmod 600 "${SCRIPT_DIR}/arc-secrets.env" 2>/dev/null || true
        log_ok "arc-secrets.env presente (permisos 600 asegurados)."
    fi

    if [[ ! -f "${SCRIPT_DIR}/private-key.pem" ]]; then
        log_warn "No existe private-key.pem en ${SCRIPT_DIR}. Descarga la clave privada de tu GitHub App."
    else
        chmod 600 "${SCRIPT_DIR}/private-key.pem" 2>/dev/null || true
        log_ok "private-key.pem presente (permisos 600 asegurados)."
    fi
}

# 4. Operaciones de cluster y ARC
cluster_up() {
    log_info "Levantando cluster Kind 'arc-cluster'..."
    if kind get clusters 2>/dev/null | grep -q "^arc-cluster$"; then
        log_ok "El cluster 'arc-cluster' ya existe."
    else
        kind create cluster --config "${SCRIPT_DIR}/kind-config.yaml"
        log_ok "Cluster 'arc-cluster' creado exitosamente."
    fi
    kubectl cluster-info --context kind-arc-cluster
    kubectl get nodes
}

cluster_down() {
    log_info "Eliminando cluster Kind 'arc-cluster'..."
    if kind get clusters 2>/dev/null | grep -q "^arc-cluster$"; then
        kind delete cluster --name arc-cluster
        log_ok "Cluster 'arc-cluster' eliminado."
    else
        log_ok "El cluster no existia."
    fi
}

install_arc() {
    log_info "Instalando Actions Runner Controller (ARC) con Helm..."
    helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller 2>/dev/null || true
    helm repo update actions-runner-controller

    helm upgrade --install arc \
        --namespace arc-systems \
        --create-namespace \
        oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller

    log_ok "ARC Controller instalado en namespace arc-systems."
    kubectl get pods -n arc-systems
}

setup_runners() {
    if [[ ! -f "${SCRIPT_DIR}/arc-secrets.env" || ! -f "${SCRIPT_DIR}/private-key.pem" ]]; then
        log_err "Faltan arc-secrets.env o private-key.pem. Configuralos antes de crear los runners."
        exit 1
    fi

    # Cargar variables
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/arc-secrets.env"

    if [[ -z "${GITHUB_CONFIG_URL:-}" ]]; then
        echo -n "Introduce la URL de tu repositorio GitHub (ej: https://github.com/TU-USUARIO/k8s-arc-demo): "
        read -r GITHUB_CONFIG_URL
    fi

    kubectl create namespace arc-runners 2>/dev/null || true

    kubectl create secret generic github-auth \
        --namespace=arc-runners \
        --from-literal=github_app_id="${GITHUB_APP_ID}" \
        --from-literal=github_app_installation_id="${GITHUB_APP_INSTALLATION_ID}" \
        --from-file=github_app_private_key="${SCRIPT_DIR}/private-key.pem" \
        --dry-run=client -o yaml | kubectl apply -f -

    log_ok "Secret github-auth aplicado en arc-runners."

    helm upgrade --install mi-runners \
        --namespace arc-runners \
        --set githubConfigUrl="${GITHUB_CONFIG_URL}" \
        --set githubConfigSecret=github-auth \
        --set maxRunners=3 \
        --set minRunners=0 \
        oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set

    log_ok "Runner Scale Set 'mi-runners' configurado."
}

# --- Menu principal ---
case "${1:-check}" in
    check)
        organizar_archivos
        verificar_dependencias || true
        verificar_secretos
        echo ""
        log_info "Uso de comandos rapidos:"
        echo "  $0 check          # Revisa archivos, dependencias y credenciales"
        echo "  $0 cluster-up     # Crea el cluster Kind arc-cluster"
        echo "  $0 install-arc    # Instala el ARC controller con Helm"
        echo "  $0 setup-runners  # Aplica secretos y monta el scale set de runners"
        echo "  $0 cluster-down   # Elimina el cluster Kind"
        ;;
    cluster-up)
        organizar_archivos
        cluster_up
        ;;
    install-arc)
        install_arc
        ;;
    setup-runners)
        setup_runners
        ;;
    cluster-down)
        cluster_down
        ;;
    *)
        echo "Comando no reconocido: $1"
        echo "Uso: $0 [check|cluster-up|install-arc|setup-runners|cluster-down]"
        exit 1
        ;;
esac
