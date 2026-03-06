set shell := ["bash", "-euo", "pipefail", "-c"]
set dotenv-load := true

VARIANT      := env("VARIANT", "postgres")
REGISTRY_URL := env("REGISTRY_URL", "")
VERSION      := env("VERSION", "latest")

_default:
  @echo "Default env variables:"
  @echo "    VARIANT: {{VARIANT}}"
  @echo "    REGISTRY_URL: {{REGISTRY_URL}}"
  @echo "    VERSION: {{VERSION}}"
  @just --list

### Build & Publish ###

# Build image locally
build db=VARIANT:
  #!/usr/bin/env bash
  PREFIX=${REGISTRY_URL:+${REGISTRY_URL}/}
  IMAGE="{{db}}:{{VERSION}}"

  echo "docker build -f {{db}}/Dockerfile -t ${PREFIX}${IMAGE} ."
  docker build -f {{db}}/Dockerfile -t ${PREFIX}${IMAGE} .

# Build and push image to registry - no echo for security
publish db=VARIANT:
  #!/usr/bin/env bash
  PREFIX=${REGISTRY_URL:+${REGISTRY_URL}/}
  IMAGE="{{db}}:{{VERSION}}"

  just build {{db}}
  docker push ${PREFIX}${IMAGE}

### Tests ###

# Start a database and wait until it's healthy
db-up db=VARIANT:
  docker compose -f {{db}}/compose.yml up -d --wait

# Stop a database and remove volumes
db-down db=VARIANT:
  docker compose -f {{db}}/compose.yml down -v

# Run tests against a database variant
test db=VARIANT:
  @case "{{db}}" in \
    postgres)  just _test-postgres ;; \
    *)         echo "Unknown database: {{db}}" >&2; exit 1 ;; \
  esac

# Run tests against a Postgres database
_test-postgres:
  #!/usr/bin/env bash
  trap 'just db-down postgres' EXIT
  just db-up postgres
  docker compose -f postgres/compose.yml exec postgres pg_isready -U ${POSTGRES_USER}
