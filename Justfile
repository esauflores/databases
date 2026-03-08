set shell := ["bash", "-euo", "pipefail", "-c"]
set dotenv-load := true

SERVICE      := env("SERVICE", "postgres")
VARIANT      := env("VARIANT", "base")

_default:
  #!/usr/bin/env bash
  echo "Default env variables:"
  echo "    SERVICE: {{SERVICE}}"
  echo "    VARIANT: {{VARIANT}}"
  just --list

### Container Management ###

# Start the service and wait until it's healthy
up service=SERVICE variant=VARIANT:
  just build {{service}} {{variant}}
  docker compose -f {{service}}/{{variant}}/compose.yml up -d --wait

# Stop the service container but preserve data volumes
down service=SERVICE variant=VARIANT:
  docker compose -f {{service}}/{{variant}}/compose.yml down

# Remove containers and data volumes but preserve images
down-volumes service=SERVICE variant=VARIANT:
  docker compose -f {{service}}/{{variant}}/compose.yml down -v

# Remove containers, volumes, and images
down-all service=SERVICE variant=VARIANT:
  docker compose -f {{service}}/{{variant}}/compose.yml down -v --rmi all

### Shell Access ###

# Access a bash shell inside the running container
bash service=SERVICE variant=VARIANT:
  docker compose -f {{service}}/{{variant}}/compose.yml exec {{service}} bash

# Access a sh shell inside the running container
sh service=SERVICE variant=VARIANT:
  docker compose -f {{service}}/{{variant}}/compose.yml exec {{service}} sh

### Build & Publish ###

# Build image locally
build service=SERVICE variant=VARIANT:
  #!/usr/bin/env bash
  IMAGE="db-{{service}}"
  VERSION="{{variant}}"

  echo "docker build -f {{service}}/{{variant}}/Dockerfile -t ${IMAGE}:${VERSION} {{service}}/{{variant}}"
  docker build -f {{service}}/{{variant}}/Dockerfile -t ${IMAGE}:${VERSION} {{service}}/{{variant}}

# Build and push image to registry
push service=SERVICE variant=VARIANT:
  #!/usr/bin/env bash
  PREFIX=${REGISTRY_URL:+${REGISTRY_URL}/}
  IMAGE="db-{{service}}"
  VERSION="{{variant}}"

  just build {{service}} {{variant}}

  echo "docker tag ${IMAGE}:${VERSION} ${PREFIX}${IMAGE}:${VERSION}"
  docker tag ${IMAGE}:${VERSION} ${PREFIX}${IMAGE}:${VERSION}

  echo "docker push ${PREFIX}${IMAGE}:${VERSION}"
  docker push ${PREFIX}${IMAGE}:${VERSION}

### Tests ###

# Run tests against a service
test service=SERVICE variant=VARIANT:
  #!/usr/bin/env bash
  just up {{service}} {{variant}}
  trap "just down {{service}} {{variant}}" EXIT
  case "{{service}}:{{variant}}" in
    postgres:base)  just _test-postgres base ;;
    *)         echo "Unknown service: {{service}} {{variant}}" >&2; exit 1 ;;
  esac

_test-postgres variant=VARIANT:
  #!/usr/bin/env bash
  docker compose -f postgres/{{variant}}/compose.yml exec postgres bash -c "
    psql -U ${POSTGRES_USER:-postgres} -c 'SELECT 1;'
  "
