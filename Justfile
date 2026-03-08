set shell := ["bash", "-euo", "pipefail", "-c"]
set dotenv-load := true

DATABASE      := env("DATABASE", "postgres")
VARIANT      := env("VARIANT", "base")

_default:
  @echo "Default env variables:"
  @echo "    DATABASE: {{DATABASE}}"
  @echo "    VARIANT: {{VARIANT}}"
  @just --list

### Container Management ###

# Start the database and wait until it's healthy
up db=DATABASE variant=VARIANT:
  just build {{db}} {{variant}}
  docker compose -f {{db}}-{{variant}}/compose.yml up -d --wait

# Stop the database container but preserve data volumes
down db=DATABASE variant=VARIANT:
  docker compose -f {{db}}-{{variant}}/compose.yml down

# Remove containers and data volumes but preserve images
down-volumes db=DATABASE variant=VARIANT:
  docker compose -f {{db}}-{{variant}}/compose.yml down -v

# Remove containers, volumes, and images
down-all db=DATABASE variant=VARIANT:
  docker compose -f {{db}}-{{variant}}/compose.yml down -v --rmi local

### Build & Publish ###

# Build image locally
build db=DATABASE variant=VARIANT:
  #!/usr/bin/env bash
  IMAGE="db-{{db}}"
  VERSION="{{variant}}"

  echo "docker build -f {{db}}-{{variant}}/Dockerfile -t ${IMAGE}:${VERSION} {{db}}-{{variant}}"
  docker build -f {{db}}-{{variant}}/Dockerfile -t ${IMAGE}:${VERSION} {{db}}-{{variant}}

# Build and push image to registry
push db=DATABASE variant=VARIANT:
  #!/usr/bin/env bash
  PREFIX="${REGISTRY_URL:+${REGISTRY_URL}/}"
  IMAGE="db-{{db}}"
  VERSION="{{variant}}"

  just build {{db}} {{variant}}

  echo "docker tag ${IMAGE}:${VERSION} ${PREFIX}${IMAGE}:${VERSION}"
  docker tag ${IMAGE}:${VERSION} ${PREFIX}${IMAGE}:${VERSION}

  echo "docker push ${PREFIX}${IMAGE}:${VERSION}"
  docker push ${PREFIX}${IMAGE}:${VERSION}

### Tests ###

# Run tests against a database variant
test db=DATABASE variant=VARIANT:
  #!/usr/bin/env bash
  just up {{db}} {{variant}}
  case "{{db}}:{{variant}}" in
    postgres:base)  just _test-postgres base ;;
    *)         echo "Unknown database: {{db}}" >&2; exit 1 ;;
  esac
  just down {{db}} {{variant}}

# Run tests against a Postgres database
_test-postgres variant=VARIANT:
  docker compose -f postgres-{{variant}}/compose.yml exec postgres pg_isready -U ${POSTGRES_USER:-postgres}
