# databases

Custom database Docker images for local development and self-hosted deployments.

## Postgres - base

Based on `postgres:18-alpine`.

### Extensions

The following extensions are enabled by default:

| Extension  | Description                                      |
| ---------- | ------------------------------------------------ |
| `citext`   | Case-insensitive text type                       |
| `pg_trgm`  | Trigram-based text similarity and fuzzy matching |
| `pgcrypto` | Cryptographic functions                          |

### Configuration
```bash
cp .env.example .env
```

| Variable            | Default    | Description                  |
| ------------------- | ---------- | ---------------------------- |
| `POSTGRES_USER`     | `postgres` | Postgres superuser name      |
| `POSTGRES_PASSWORD` | `postgres` | Postgres superuser password  |
| `POSTGRES_DB`       | `postgres` | Default database name        |
| `POSTGRES_PORT`     | `5432`     | Host port mapped to Postgres |

### Usage
```bash
docker pull git.fastwaydata.com/esauflores/db-postgres:base
```
```yaml
services:
  postgres:
    image: git.fastwaydata.com/esauflores/db-postgres:base
    env_file: .env
    ports:
      - "${POSTGRES_PORT:-5432}:5432"
```

