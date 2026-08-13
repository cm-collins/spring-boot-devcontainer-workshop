# Spring Boot Dev Container Workshop

A hands-on guide for building Java and Spring Boot applications inside **Dev Containers** with Docker Compose and local development infrastructure.

This project focuses on a common problem:

> "Just clone the project and run it."

In real projects, that usually means installing the correct JDK, Maven or Gradle version, Docker, database tools, CLI tools, environment variables, and local services before writing any code.

This repository takes a different approach: the development environment lives inside the project.

```text
Clone -> Open in Dev Container -> Start Developing
```

## Learning Goals

After working through this repository, you should understand how to:

1. Clone a Java project and open it in a Dev Container.
2. Use a reproducible Java 21 development environment.
3. Work with Maven and Gradle inside the container.
4. Run local infrastructure with Docker Compose.
5. Start and inspect a local PostgreSQL database.
6. Connect a Spring Boot application to PostgreSQL.
7. Run builds and tests without relying on a shared remote database.
8. Explain how `Dockerfile.dev`, `compose.yaml`, and `devcontainer.json` work together.

## Current Repository Status

This repository currently contains the **development environment foundation**. It does not yet contain a generated Spring Boot application.

The repository is designed to build up in stages:

1. Understand the development environment.
2. Add or generate a Spring Boot application.
3. Connect the application to the local PostgreSQL service.

## Architecture Overview

The project separates three concerns:

```mermaid
flowchart TB
    DEV[Developer]
    REPO[Project Repository]

    ENV[Development Environment]
    INFRA[Local Infrastructure]
    WORKSPACE[Dev Container Workspace]

    DOCKERFILE[Dockerfile.dev]
    COMPOSE[compose.yaml]
    DEVCONTAINER[devcontainer.json]

    JAVA[Java 21]
    MAVEN[Maven]
    GRADLE[Gradle]
    TOOLS[Git, GitHub CLI, Azure CLI, Python]
    DOCKER[Docker CLI and Compose]
    POSTGRES[(PostgreSQL 18)]

    DEV --> REPO
    REPO --> ENV
    REPO --> INFRA
    REPO --> WORKSPACE

    ENV --> DOCKERFILE
    DOCKERFILE --> JAVA
    DOCKERFILE --> MAVEN
    DOCKERFILE --> GRADLE
    DOCKERFILE --> TOOLS
    DOCKERFILE --> DOCKER

    INFRA --> COMPOSE
    COMPOSE --> POSTGRES

    WORKSPACE --> DEVCONTAINER
    DEVCONTAINER --> ENV
    DEVCONTAINER --> INFRA
```

| Component | Responsibility |
| --- | --- |
| `.devcontainer/Dockerfile.dev` | Defines the developer workstation image and installed tools. |
| `.devcontainer/compose.yaml` | Defines local services used during development, currently PostgreSQL. |
| `.devcontainer/devcontainer.json` | Tells VS Code or Dev Containers how to build and enter the workspace. |
| `.devcontainer/scripts/` | Contains lifecycle and verification scripts used by the container. |

## Project Structure

```text
spring-boot-devcontainer-workshop/
|
+-- .devcontainer/
|   |
|   +-- Dockerfile.dev
|   +-- compose.yaml
|   +-- devcontainer.json
|   |
|   +-- scripts/
|       +-- post-create.sh
|       +-- show-devcontainer-summary.sh
|       +-- start-postgres.sh
|       +-- verify-environment.sh
|
+-- README.md
+-- LICENSE
```

## File Responsibilities

### `.devcontainer/Dockerfile.dev`

Defines the development image used by the Dev Container.

It installs and verifies:

| Tool | Purpose |
| --- | --- |
| Java 21 | Java and Spring Boot development |
| Maven 3.9.11 | Java build automation |
| Gradle 9.1.0 | Java build automation |
| Git | Source control |
| GitHub CLI | GitHub operations |
| Azure CLI | Azure development and deployment |
| Python 3 | Scripting and automation |
| Docker CLI | Container management |
| Docker Buildx | Image building |
| Docker Compose | Local infrastructure orchestration |
| Bash, curl, jq, zip, unzip | Common development utilities |

The image is based on:

```text
mcr.microsoft.com/devcontainers/java:21-bookworm
```

### `.devcontainer/compose.yaml`

Defines local infrastructure for the project.

Currently, it provides:

| Service | Version | Purpose |
| --- | --- | --- |
| PostgreSQL | 18 | Local application database |

The PostgreSQL service is intentionally separate from the development container. That mirrors a real application setup where the app and database run as separate services.

### `.devcontainer/devcontainer.json`

Defines how the workspace is opened inside VS Code or another Dev Containers compatible tool.

It configures:

| Setting | Purpose |
| --- | --- |
| `build.dockerfile` | Builds the Dev Container from `Dockerfile.dev`. |
| `workspaceFolder` | Opens the project under `/workspaces/...`. |
| `remoteUser` | Uses the standard `vscode` container user. |
| `mounts` | Mounts the host Docker socket for Docker CLI access. |
| `remoteEnv` | Provides PostgreSQL and Spring datasource environment variables. |
| `forwardPorts` | Forwards Spring Boot and PostgreSQL ports. |
| `customizations.vscode.extensions` | Installs Java, Spring Boot, Gradle, YAML, and Docker extensions. |
| `postCreateCommand` | Verifies the environment and starts PostgreSQL after the container is created. |
| `postStartCommand` | Runs `start-postgres.sh` whenever the container starts. |
| `postAttachCommand` | Prints a learner-friendly summary after VS Code attaches to the container. |

### `.devcontainer/scripts/`

| Script | Purpose |
| --- | --- |
| `post-create.sh` | Dev Container lifecycle hook that verifies the environment and starts services after creation. |
| `show-devcontainer-summary.sh` | Prints the workspace, tool versions, database connection details, and useful commands. |
| `start-postgres.sh` | Starts PostgreSQL, waits for readiness, and attaches the Dev Container to the PostgreSQL network. |
| `verify-environment.sh` | Verifies that required tools are installed and prints their versions. |

## Development Environment Flow

```mermaid
sequenceDiagram
    actor Developer
    participant Repository
    participant DevContainer as Dev Container
    participant Docker as Host Docker Engine
    participant PostgreSQL

    Developer->>Repository: Clone repository
    Developer->>DevContainer: Open in Dev Container
    DevContainer->>DevContainer: Build Java development image
    DevContainer->>Docker: Use mounted Docker socket
    Docker->>PostgreSQL: Start PostgreSQL via Docker Compose
    PostgreSQL-->>Docker: Healthy
    Docker-->>DevContainer: Service ready
    Developer->>DevContainer: Build and run Java application
    DevContainer->>PostgreSQL: Connect to database
```

## Local PostgreSQL

The project uses PostgreSQL as the local database.

```mermaid
flowchart LR
    DEV[Developer Machine]
    DOCKER[Docker Engine]
    COMPOSE[Docker Compose]
    NETWORK{{spring-dev-network}}
    POSTGRES[(PostgreSQL 18)]
    DB[(spring_boot_dev)]
    VOLUME[(spring-dev-postgres-data)]

    DEV --> DOCKER
    DOCKER --> COMPOSE
    COMPOSE --> NETWORK
    NETWORK --> POSTGRES
    POSTGRES --> DB
    POSTGRES --> VOLUME
```

### Database Configuration

| Setting | Value |
| --- | --- |
| Database | `spring_boot_dev` |
| Username | `spring_boot` |
| Password | `spring_boot_dev_password` |
| Host port | `5432` |
| PostgreSQL version | `18` |
| Docker network | `spring-dev-network` |
| Docker volume | `spring-dev-postgres-data` |

From the host machine, connect through:

```text
localhost:5432
```

From another container on the same Docker network, connect through:

```text
postgres:5432
```

Important: inside a container, `localhost` means "this same container." It does not mean "the PostgreSQL container." Container-to-container communication should use the Compose service name, which is `postgres`.

## Container Networking

The intended service-to-service model is:

```mermaid
flowchart LR
    APP[Spring Boot Dev Container]
    NETWORK{{spring-dev-network}}
    DB[(PostgreSQL Container)]

    APP --> NETWORK
    NETWORK --> DB
    APP -. "postgres:5432" .-> DB
```

The Dev Container starts PostgreSQL by using the mounted host Docker socket. The `start-postgres.sh` script also attaches the Dev Container to `spring-dev-network`, so `postgres:5432` works from inside the Dev Container.

## Getting Started

### Prerequisites

Before opening the Dev Container, install:

1. Docker Desktop, Docker Engine, or a compatible container runtime.
2. VS Code.
3. The Dev Containers extension for VS Code.
4. Git.

### 1. Clone the Repository

```bash
git clone <repository-url>
cd spring-boot-devcontainer-workshop
```

### 2. Open in a Dev Container

In VS Code:

1. Open the repository folder.
2. Open the Command Palette.
3. Run `Dev Containers: Reopen in Container`.

VS Code will build the development image from `.devcontainer/Dockerfile.dev`.

### 3. Verify the Environment

Inside the Dev Container terminal, run:

```bash
bash .devcontainer/scripts/verify-environment.sh
```

This checks Java, Maven, Gradle, Git, GitHub CLI, Azure CLI, Python, Docker, and Docker Compose.

## Working with PostgreSQL

### Validate the Compose File

```bash
docker compose \
  -f .devcontainer/compose.yaml \
  config
```

This validates the Docker Compose configuration without starting containers.

### Start PostgreSQL

```bash
docker compose \
  -f .devcontainer/compose.yaml \
  up -d
```

Docker will create:

1. A PostgreSQL container.
2. A Docker network.
3. A persistent Docker volume.

### Check the Container

```bash
docker compose \
  -f .devcontainer/compose.yaml \
  ps
```

You should eventually see PostgreSQL reported as healthy:

```text
Up ... (healthy)
```

The first startup may briefly show:

```text
health: starting
```

Wait a few seconds and check again.

### Check PostgreSQL Readiness

```bash
docker compose \
  -f .devcontainer/compose.yaml \
  exec postgres \
  pg_isready \
  -U spring_boot \
  -d spring_boot_dev
```

Expected output:

```text
/var/run/postgresql:5432 - accepting connections
```

### Open a PostgreSQL Shell

```bash
docker compose \
  -f .devcontainer/compose.yaml \
  exec postgres \
  psql \
  -U spring_boot \
  -d spring_boot_dev
```

Expected prompt:

```text
spring_boot_dev=#
```

Useful commands inside `psql`:

```sql
SELECT current_database();
```

```text
\conninfo
\l
\dt
\q
```

## PostgreSQL Persistence

The database uses a named Docker volume:

```text
spring-dev-postgres-data
```

That volume allows database data to survive container recreation.

```mermaid
flowchart TB
    CONTAINER[PostgreSQL Container]
    VOLUME[(spring-dev-postgres-data)]
    DATA[(Database Data)]
    REMOVE[Container Removed]
    PERSIST[Data Remains]

    CONTAINER --> VOLUME
    VOLUME --> DATA
    REMOVE -.-> CONTAINER
    DATA --> PERSIST
```

### Stop PostgreSQL

```bash
docker compose \
  -f .devcontainer/compose.yaml \
  stop
```

The database data remains intact.

### Start PostgreSQL Again

```bash
docker compose \
  -f .devcontainer/compose.yaml \
  start
```

### Remove Containers and Network

```bash
docker compose \
  -f .devcontainer/compose.yaml \
  down
```

This removes the PostgreSQL container and network. The named database volume remains.

### Completely Reset PostgreSQL

```bash
docker compose \
  -f .devcontainer/compose.yaml \
  down -v
```

Warning: this deletes the `spring-dev-postgres-data` volume and all local PostgreSQL data.

The next time PostgreSQL starts, Docker will initialize a fresh database.

## Build the Development Image Manually

The development image can also be built independently from VS Code.

From the repository root:

```bash
docker build \
  -f .devcontainer/Dockerfile.dev \
  -t spring-boot-devcontainer:dev \
  .
```

## Verify the Development Image Manually

```bash
docker run --rm spring-boot-devcontainer:dev bash -lc '
echo "===== JAVA ====="
java --version

echo "===== MAVEN ====="
mvn --version

echo "===== GRADLE ====="
gradle --version

echo "===== GIT ====="
git --version

echo "===== GITHUB CLI ====="
gh --version

echo "===== AZURE CLI ====="
az version

echo "===== PYTHON ====="
python3 --version
pip3 --version

echo "===== DOCKER ====="
docker --version
docker compose version
'
```

This verifies that the image contains the expected tooling.

## Current Verified Environment

The development image has been verified with the following major tools:

| Tool | Version |
| --- | --- |
| Java | 21.0.12 LTS |
| Maven | 3.9.11 |
| Gradle | 9.1.0 |
| Git | 2.55.0 |
| GitHub CLI | 2.97.0 |
| Azure CLI | 2.89.1 |
| Python | 3.11.2 |
| Docker | 29.7.2 |
| Docker Compose | 5.4.0 |

Exact patch versions may change as package repositories evolve.

## Why Dev Containers?

Without Dev Containers, each participant may need to manually install and configure:

```text
Developer Machine
|
+-- Java
+-- JAVA_HOME
+-- Maven
+-- Gradle
+-- Git
+-- Docker
+-- PostgreSQL
+-- Database credentials
+-- Environment variables
+-- Editor extensions
```

With Dev Containers, the project describes the development environment:

```mermaid
flowchart LR
    DEV[Developer]
    REPO[Clone Repository]
    DC[Open in Dev Container]
    ENV[Reproducible Environment]
    JAVA[Java 21]
    BUILD[Maven and Gradle]
    TOOLS[Development Tools]
    DB[(PostgreSQL)]

    DEV --> REPO
    REPO --> DC
    DC --> ENV
    ENV --> JAVA
    ENV --> BUILD
    ENV --> TOOLS
    ENV --> DB
```

## Learning Path

Work through the repository in this order:

1. Review the repository structure.
2. Open the project in a Dev Container.
3. Run `verify-environment.sh` to inspect the installed tools.
4. Start PostgreSQL with Docker Compose.
5. Inspect the database using `psql`.
6. Generate or add a Spring Boot application.
7. Configure Spring Boot to connect to PostgreSQL.
8. Run the application inside the Dev Container.
9. Run tests against local infrastructure.

## Key Lesson

The main idea is simple:

```mermaid
flowchart TB
    CODE[Application Code]
    ENV[Development Environment]
    INFRA[Local Infrastructure]
    REPO[Repository]

    CODE --> REPO
    ENV --> REPO
    INFRA --> REPO

    REPO --> REPRO[Reproducible Developer Experience]
```

When the environment is part of the repository, developers spend less time setting up tools and more time building Java applications.
