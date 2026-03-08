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

### Container Management ###

# Start the database and wait until it's healthy
up db=VARIANT:
  just build {{db}}
  docker compose -f {{db}}/compose.yml up -d --wait

# Stop the database container but preserve data volumes
down db=VARIANT:
  docker compose -f {{db}}/compose.yml down

# Stop the database container and remove data volumes
clean db=VARIANT:
  docker compose -f {{db}}/compose.yml down -v

### Build & Publish ###

# Build image locally
build db=VARIANT:
  #!/usr/bin/env bash
  PREFIX=${REGISTRY_URL:+${REGISTRY_URL}/}
  IMAGE="database-{{db}}:{{VERSION}}"

  echo "docker build -f {{db}}/Dockerfile -t ${PREFIX}${IMAGE} {{db}}"
  docker build -f {{db}}/Dockerfile -t ${PREFIX}${IMAGE} {{db}}

# Build and push image to registry
push db=VARIANT:
  #!/usr/bin/env bash
  PREFIX=${REGISTRY_URL:+${REGISTRY_URL}/}
  IMAGE="database-{{db}}:{{VERSION}}"

  just build {{db}}
  echo "docker push ${PREFIX}${IMAGE}"
  docker push ${PREFIX}${IMAGE}

push-latest db=VARIANT:
  #!/usr/bin/env bash
  PREFIX=${REGISTRY_URL:+${REGISTRY_URL}/}
  IMAGE="database-{{db}}:latest"

  just build {{db}}
  echo "docker push ${PREFIX}${IMAGE}"
  docker push ${PREFIX}${IMAGE}

### Tests ###

# Run tests against a database variant
test db=VARIANT:
  @case "{{db}}" in \
    postgres)  just _test-postgres ;; \
    *)         echo "Unknown database: {{db}}" >&2; exit 1 ;; \
  esac

# Run tests against a Postgres database
_test-postgres:
  #!/usr/bin/env bash
  just up postgres
  docker compose -f postgres/compose.yml exec postgres pg_isready -U ${POSTGRES_USER}
