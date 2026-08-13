# Spring Boot Dev Container Workshop

A hands-on Spring Boot development environment demonstrating **reproducible Java development with Dev Containers, Docker Compose, and local development infrastructure**.

The goal of this workshop is to solve a very common problem:

> "Just clone the project and run it."

Only to discover that the project requires a specific JDK, Maven version, Gradle version, database, CLI tools, environment variables, and several hours of setup.

Instead, we want the development environment to be part of the project.

---

## 🎯 Workshop Goal

By the end of this workshop, a developer should be able to:

1. Clone the repository.
2. Open the project inside a Dev Container.
3. Have Java and the required development tools available automatically.
4. Have a local PostgreSQL database available.
5. Build and run a Spring Boot application.
6. Connect Spring Boot to PostgreSQL.
7. Run tests without depending on a remote development database.
8. Reproduce the same development environment on different machines.

The target experience is:

```text
Clone → Open in Dev Container → Start Developing

🏗️ Architecture

The project intentionally separates three concerns:
flowchart TB
    DEV[Developer]

    DEV --> REPO[Spring Boot Repository]

    REPO --> ENV[Development Environment]
    REPO --> INFRA[Local Infrastructure]
    REPO --> WORKSPACE[Dev Container Workspace]

    ENV --> DOCKERFILE[Dockerfile.dev]

    DOCKERFILE --> JAVA[Java 21]
    DOCKERFILE --> MAVEN[Maven]
    DOCKERFILE --> GRADLE[Gradle]
    DOCKERFILE --> GIT[Git]
    DOCKERFILE --> GH[GitHub CLI]
    DOCKERFILE --> AZ[Azure CLI]
    DOCKERFILE --> PYTHON[Python]
    DOCKERFILE --> DOCKER[Docker CLI + Compose]

    INFRA --> COMPOSE[compose.yaml]
    COMPOSE --> POSTGRES[(PostgreSQL 18)]

    WORKSPACE --> DEVCONTAINER[devcontainer.json]

    DEVCONTAINER --> ENV
    DEVCONTAINER --> INFRA

    The three main responsibilities are:

Component	Responsibility
Dockerfile.dev	Defines the development environment
compose.yaml	Defines local infrastructure
devcontainer.json	Connects the developer workspace to the environment and infrastructure

This separation is intentional.
📁 Project Structure
spring-boot-devcontainer-workshop/
│
├── .devcontainer/
│   │
│   ├── Dockerfile.dev
│   │
│   ├── compose.yaml
│   │
│   ├── devcontainer.json
│   │
│   └── scripts/
│       ├── post-create.sh
│       ├── post-start.sh
│       └── verify.sh
│
├── README.md
│
└── ...
File responsibilities
Dockerfile.dev

Defines the developer workstation.

It contains:

Java 21
Maven
Gradle
Git
GitHub CLI
Azure CLI
Python
Docker CLI
Docker Compose
Linux development utilities
compose.yaml

Defines services required for local development.

Currently:

PostgreSQL 18

The database is intentionally kept separate from the development container.
devcontainer.json

Defines how VS Code / Dev Containers creates and configures the development workspace.

This will eventually connect:

Developer
    │
    ▼
Dev Container
    │
    └──── PostgreSQL
    scripts/

Contains lifecycle and verification scripts.

scripts/
├── post-create.sh
├── post-start.sh
└── verify.sh

These scripts will be introduced as the Dev Container setup progresses.
🐳 Development Environment

The development image is built from:

mcr.microsoft.com/devcontainers/java:21-bookworm

The image provides Java 21 and the base development environment.

Additional tools are installed in Dockerfile.dev.

Available Tools
Tool	Purpose
Java 21	Java/Spring Boot development
Maven 3.9.11	Java build automation
Gradle 9.1.0	Java build automation
Git	Source control
GitHub CLI	GitHub operations
Azure CLI	Azure development/deployment
Python 3	Scripting and automation
Docker CLI	Container management
Docker Buildx	Image building
Docker Compose	Local infrastructure
Bash	Shell environment
curl	HTTP/download utilities
jq	JSON processing
unzip/zip	Archive management
🐘 Local PostgreSQL

The project uses PostgreSQL 18 as the local development database.

We deliberately use Docker Compose instead of asking every developer to install PostgreSQL directly on their machine.
flowchart LR
    DEV[Developer Machine]

    DEV --> COMPOSE[Docker Compose]

    COMPOSE --> NETWORK[Spring Development Network]

    NETWORK --> POSTGRES[(PostgreSQL 18)]

    POSTGRES --> DB[(spring_boot_dev)]
    This gives every developer the same database technology and configuration.

🗄️ Database Configuration

The current local PostgreSQL configuration is:

Setting	Value
Database	spring_boot_dev
Username	spring_boot
Password	spring_boot_dev_password
Port	5432
PostgreSQL Version	18

From the host machine:

localhost:5432

From another container on the Compose network:

postgres:5432

Important: Container-to-container communication uses the Compose service name postgres, not localhost.
🔌 Container Networking

The database is attached to:

spring-dev-network

The intended architecture is:
flowchart LR
    DEV[Spring Boot Dev Container]

    NETWORK{{spring-dev-network}}

    DB[(PostgreSQL 18)]

    DEV --> NETWORK
    NETWORK --> DB

    DEV -. "postgres:5432" .-> DB

    Inside the Dev Container, Spring Boot will eventually connect using:

postgres:5432

Not:

localhost:5432

Why?

Inside a container:

localhost

means:

"This container."

It does not mean:

"The PostgreSQL container."

Docker Compose provides DNS-based service discovery, allowing containers on the same network to reach services using their service name.
🚀 Getting Started
1. Clone the repository
git clone <repository-url>
cd spring-boot-devcontainer-workshop
2. Validate the Docker Compose Configuration

Before starting PostgreSQL:

docker compose \
  -f .devcontainer/compose.yaml \
  config

This validates the Compose configuration without starting any containers.

3. Start PostgreSQL
docker compose \
  -f .devcontainer/compose.yaml \
  up -d

Docker will create:

PostgreSQL container
PostgreSQL network
PostgreSQL persistent volume
4. Check PostgreSQL
docker compose \
  -f .devcontainer/compose.yaml \
  ps

You should eventually see PostgreSQL as:

Up ... (healthy)

The first startup may initially report:

health: starting

Wait a few seconds and check again.

5. Check PostgreSQL Readiness

Run:

docker compose \
  -f .devcontainer/compose.yaml \
  exec postgres \
  pg_isready \
  -U spring_boot \
  -d spring_boot_dev

Expected:

/var/run/postgresql:5432 - accepting connections
6. Connect to PostgreSQL

Open a PostgreSQL shell:

docker compose \
  -f .devcontainer/compose.yaml \
  exec postgres \
  psql \
  -U spring_boot \
  -d spring_boot_dev

You should see:

Type "help" for help.

spring_boot_dev=#
7. Verify the Database

Inside PostgreSQL:

SELECT current_database();

Expected:

 current_database
------------------
 spring_boot_dev

Check the connection:

\conninfo

List databases:

\l

List tables:

\dt

Exit PostgreSQL:

\q

💾 PostgreSQL Persistence

The database uses a named Docker volume:

postgres-data

The volume allows PostgreSQL data to survive container recreation.
flowchart TB
    CONTAINER[PostgreSQL Container]

    CONTAINER --> VOLUME[(postgres-data)]

    VOLUME --> DATA[(Database Data)]

    REMOVE[Container Removed]
    REMOVE -.-> CONTAINER

    DATA --> PERSIST[Data Remains]

    Therefore:
    docker compose \
  -f .devcontainer/compose.yaml \
  down
  does not delete the database volume.
  ▶️ Start PostgreSQL Again

If the container has been stopped:

docker compose \
  -f .devcontainer/compose.yaml \
  start

Check:

docker compose \
  -f .devcontainer/compose.yaml \
  ps
⏹️ Stop PostgreSQL

To stop the database:

docker compose \
  -f .devcontainer/compose.yaml \
  stop

The database data remains intact.

🗑️ Remove PostgreSQL Containers

To remove the PostgreSQL container and network:

docker compose \
  -f .devcontainer/compose.yaml \
  down

The named database volume remains.

⚠️ Completely Reset PostgreSQL

If you want to delete the PostgreSQL container and all local database data:

docker compose \
  -f .devcontainer/compose.yaml \
  down -v

⚠️ Warning: This deletes the postgres-data volume and all local PostgreSQL data.

The next time you run:

docker compose \
  -f .devcontainer/compose.yaml \
  up -d

PostgreSQL will initialize a completely new database.

🐳 Build the Development Image

The development image can currently be built independently from the Dev Container.

From the repository root:

docker build \
  -f .devcontainer/Dockerfile.dev \
  -t spring-boot-devcontainer:dev \
  .
🔍 Verify the Development Image

Run:

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

This verifies that the development image contains the expected tooling.

🧪 Current Verified Environment

The development image has been successfully verified with:

Java             21.0.12 LTS
Maven            3.9.11
Gradle           9.1.0
Git              2.55.0
GitHub CLI       2.97.0
Azure CLI        2.89.1
Python           3.11.2
Docker           29.7.2
Docker Compose   5.4.0

The exact patch versions may change as the project evolves.

🔄 Development Environment Flow

The intended developer experience is:
sequenceDiagram
    actor Developer
    participant GitHub
    participant DevContainer as Dev Container
    participant PostgreSQL

    Developer->>GitHub: Clone repository
    GitHub-->>Developer: Repository

    Developer->>DevContainer: Open in Dev Container

    DevContainer->>DevContainer: Build development environment
    DevContainer->>DevContainer: Install Java + tools

    DevContainer->>PostgreSQL: Start / connect
    PostgreSQL-->>DevContainer: Healthy

    Developer->>DevContainer: Build Spring Boot application
    DevContainer->>PostgreSQL: Database connection
    PostgreSQL-->>DevContainer: Query results

    Developer->>DevContainer: Run tests
    DevContainer-->>Developer: Test results
    🧱 Separation of Responsibilities

The architecture follows a simple rule:
flowchart TB
    REPO[Repository]

    REPO --> ENV[Environment]
    REPO --> INFRA[Infrastructure]
    REPO --> WORKSPACE[Workspace]

    ENV --> DF[Dockerfile.dev]
    DF --> TOOLS[Java + Maven + Gradle + CLI Tools]

    INFRA --> CY[compose.yaml]
    CY --> SERVICES[PostgreSQL + Other Local Services]

    WORKSPACE --> DC[devcontainer.json]
    DC --> CONFIG[VS Code / Dev Container Configuration]
    Environment

Dockerfile.dev

What tools does the developer have?

Infrastructure

compose.yaml

What services does the application depend on?

Workspace

devcontainer.json

How does the developer enter and work inside the environment?

🌍 Why Dev Containers?

Without Dev Containers, a typical Java project might require:

Developer Machine
│
├── Install Java
├── Configure JAVA_HOME
├── Install Maven
├── Install Gradle
├── Install Git
├── Install Docker
├── Install PostgreSQL
├── Configure PostgreSQL
├── Configure credentials
├── Configure environment variables
└── Hope everything matches the team

With Dev Containers:

flowchart LR
    DEV[Developer]

    DEV --> REPO[Clone Repository]

    REPO --> DC[Open in Dev Container]

    DC --> ENV[Reproducible Environment]

    ENV --> JAVA[Java 21]
    ENV --> BUILD[Maven / Gradle]
    ENV --> TOOLS[Development Tools]
    ENV --> DB[(PostgreSQL)]
    