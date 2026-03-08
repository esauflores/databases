# databases

Custom database Docker images for local development and self-hosted deployments.

## Postgres 18

Based on `postgres:18.3-alpine`.

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
docker pull git.fastwaydata.com/esauflores/database-postgres:latest
```
```yaml
services:
  postgres:
    image: git.fastwaydata.com/esauflores/database-postgres:latest
    env_file: .env
    ports:
      - "${POSTGRES_PORT:-5432}:5432"
```

