# databases

Custom database Docker images, built for local development and self-hosted deployments.

## Supported Variants

| Variant    | Base Image             |
| ---------- | ---------------------- |
| `postgres` | `postgres:18.3-alpine` |

## Prerequisites

- [mise](https://mise.jdx.dev/) — manages tool versions
- [Docker](https://docs.docker.com/get-docker/) with Compose plugin

```bash
mise install
```

## Configuration

Copy `.env.example` to `.env` and adjust as needed:

```bash
cp .env.example .env
```

| Variable            | Default    | Description                           |
| ------------------- | ---------- | ------------------------------------- |
| `REGISTRY_URL`      | _(empty)_  | Container registry URL for publishing |
| `POSTGRES_USER`     | `postgres` | Postgres superuser name               |
| `POSTGRES_PASSWORD` | `postgres` | Postgres superuser password           |
| `POSTGRES_DB`       | `postgres` | Default database name                 |
| `POSTGRES_PORT`     | `5432`     | Host port mapped to Postgres          |

## Usage

```bash
# Build image locally
just build [db]

# Start database (waits until healthy)
just db-up [db]

# Stop database and remove volumes
just db-down [db]

# Run tests
just test [db]

# Build and push to registry
just publish [db]
```

`db` defaults to `postgres` when not specified.

## CI/CD

The GitHub Actions workflow (`.github/workflows/test-and-push.yml`) triggers on `v*` tag pushes:

1. **Test** — spins up the database and verifies connectivity
2. **Publish** — builds and pushes the image to the configured registry

Required repository secrets: `REGISTRY_URL`, `REGISTRY_USERNAME`, `REGISTRY_PASSWORD`.

## Adding a New Variant

1. Create `<db>/Dockerfile` and `<db>/compose.yml`
2. Add a `_test-<db>` recipe and a case entry in `test` in the `Justfile`
3. Add `<db>` to the `matrix.db` list in `.github/workflows/test-and-push.yml`
4. Add any new env vars to `.env.example`
