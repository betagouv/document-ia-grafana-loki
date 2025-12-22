# Grafana + Loki + Caddy Buildpack for Scalingo

This buildpack installs and configures a complete observability stack on Scalingo, running:
- **Grafana** (v12.3.1) - Visualization and Dashboarding
- **Loki** (v3.6.3) - Log Aggregation System
- **Caddy** (v2.10.2) - Reverse Proxy (Terminates SSL/HTTP and routes traffic)

## Architecture

Since Scalingo applications run as a single container (per process type), we use a wrapper script (`bin/run`) to launch all three services in parallel within the same container.

- **Caddy** listens on the public `$PORT` provided by Scalingo.
    - Maps `/loki/*` to Loki (internal port 3100).
    - Maps `/*` to Grafana (internal port 3001).
- **Grafana** listens on `localhost:3001`.
- **Loki** listens on `localhost:3100`.

## Configuration

### Environment Variables

You must configure the following environment variables in your Scalingo application dashboard or via CLI:

#### Authentication (Grafana)
- `GF_SECURITY_ADMIN_USER`: The default admin username (e.g., `admin`).
- `GF_SECURITY_ADMIN_PASSWORD`: The default admin password. \
  *Note: These are only applied on the **first run** (database initialization).*

#### Database (Grafana)
- **Scalingo PostgreSQL Addon**: Configuring the addon will automatically set `SCALINGO_POSTGRESQL_URL`. The buildpack detects this and configures Grafana to use it as its backend database.

#### Loki Storage (S3 / Object Storage)
Loki is configured to store logs in an S3-compatible object storage (e.g., Scalingo Object Storage, AWS S3, MinIO).

- `LOKI_S3_BUCKET`: Name of the S3 bucket.
- `LOKI_S3_ENDPOINT`: S3 Endpoint URL (e.g., `https://oss.eu-west-1.scalingo.com` for Scalingo OSS).
- `LOKI_S3_REGION`: Region (e.g., `eu-west-1` or `us-east-1`).
- `AWS_ACCESS_KEY_ID`: Access Key ID.
- `AWS_SECRET_ACCESS_KEY`: Secret Access Key.

### Loki Configuration
The Loki configuration (`conf/loki-config.yaml`) is set up to use **TSDB** as the index type and **S3** as the object store.

```yaml
schema_config:
  configs:
    - from: "2024-01-01"
      store: tsdb
      object_store: s3
      schema: v13
      index: { prefix: index_, period: 24h }

storage_config:
  aws:
    bucketnames: ${LOKI_S3_BUCKET}
    endpoint: ${LOKI_S3_ENDPOINT}
    region: ${LOKI_S3_REGION}
    # ... credentials mapped from env vars
```

### Auto-Provisioning
- **Datasources**: A Loki datasource is automatically provisioned in Grafana via `conf/provisioning/datasources/loki.yaml`. It connects to the local Loki instance (`http://127.0.0.1:3100`).

## Deployment

1.  Initialize a git repository if you haven't already.
2.  Push to Scalingo:
    ```bash
    git push scalingo main
    ```

## Local Development (Docker)

You can verify the entire stack locally using Docker Compose, which simulates the Scalingo environment.

1.  Create a `.env` file with the necessary variables (env vars are already set up in `docker-compose.yml` to read from host or `.env`):
    ```bash
    GF_SECURITY_ADMIN_USER=admin
    GF_SECURITY_ADMIN_PASSWORD=secret
    PORT=3000
    # Add your S3 credentials here if you want to test S3 locally
    ```

2.  Run the stack:
    ```bash
    docker-compose up --build
    ```

3.  Access Grafana at `http://localhost:3000`.
