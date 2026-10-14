#!/bin/bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
for f in 01-namespace.yaml 02-storage.yaml 03-configs-secrets.yaml \
  04-postgres.yaml 05-redis.yaml 06-vote.yaml 07-worker.yaml 08-result.yaml; do
  echo "Applying $f..."
  kubectl apply -f "$DIR/$f"
done
kubectl rollout status deployment/database -n voting-app --timeout=180s
kubectl rollout status deployment/redis -n voting-app --timeout=120s
kubectl rollout status deployment/vote -n voting-app --timeout=120s
kubectl rollout status deployment/worker -n voting-app --timeout=120s
kubectl rollout status deployment/result -n voting-app --timeout=120s
kubectl get all -n voting-app
