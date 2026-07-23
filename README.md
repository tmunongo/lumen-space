[![CI](https://github.com/tmunongo/lumen-space/actions/workflows/ci.yml/badge.svg)](https://github.com/tmunongo/lumen-space/actions/workflows/ci.yml)

# ◉ Lumen Space

> A local-first tool for deep research and structured thinking — now as a Ruby on Rails web application.

Lumen Space is a self-hosted research companion that helps you capture, connect, and make sense of information. It supports web pages, notes, quotes, markdown documents, highlights, tags, and a semantic relationship graph.

Originally built as a Flutter desktop application, this version is a full **Ruby on Rails 8** port backed by SQLite, designed for easy self-hosting on any machine or server.

---

## Features

- 📁 **Projects** — Organize research into isolated workspaces
- 🌐 **Web Artifacts** — Paste a URL; Lumen fetches and stores the article text in the background
- 📝 **Notes, Quotes & Markdown Docs** — Rich text capture with attribution and sourcing
- 🏷️ **Tags** — Lightweight, multi-tag taxonomy per artifact
- 🖊️ **Highlights** — Select any text in the reader and save colour-coded highlights
- ⬡ **Relationships** — Semantic graph powered by tag co-occurrence — discover bridge artifacts and get tag suggestions automatically
- 🔒 **Basic Auth** — Optional single-user HTTP authentication (perfect for self-hosting over a VPN or reverse proxy)
- ⚡ **Hotwire (Turbo + Stimulus)** — No page reloads; all interactions are fast and reactive

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Ruby on Rails 8.1 |
| Database | SQLite 3 (single-file, zero config) |
| Frontend | Hotwire (Turbo + Stimulus) + Vanilla CSS |
| Background Jobs | ActiveJob (async adapter in dev; swap for Solid Queue in production) |
| Web scraping | Nokogiri + HTTParty |
| Markdown | Redcarpet |
| Server | Puma |

---

## Quick Start — Local CLI

### Prerequisites

- Ruby ≥ 3.1 (Ruby 4.0.6 recommended, matches the Docker image)
- Bundler (`gem install bundler`)

### Steps

```bash
# Clone
git clone https://github.com/tmunongo/lumen-space.git
cd lumen-space

# Install dependencies (into local vendor/bundle)
bundle config set --local path 'vendor/bundle'
bundle install

# Create the database
bin/rails db:create db:migrate

# Start the server  (http://localhost:3000)
bin/rails server
```

Open [http://localhost:3000](http://localhost:3000) in your browser. No configuration is required for local use.

#### Optional: Enable Basic Authentication

Set environment variables before starting the server:

```bash
LUMEN_USERNAME=me LUMEN_PASSWORD=secret bin/rails server
```

---

## Self-Hosting via Docker Compose

This is the recommended approach for running Lumen Space on a server.

### 1. Create a `docker-compose.yml`

```yaml
services:
  lumen:
    image: ghcr.io/tmunongo/lumen-space:latest
    restart: unless-stopped
    ports:
      - "3000:80"
    environment:
      # Optional custom secret key base for cookie/session encryption
      SECRET_KEY_BASE: "${SECRET_KEY_BASE:-}"
      # Optional single-user basic auth
      LUMEN_USERNAME: "${LUMEN_USERNAME:-lumen}"
      LUMEN_PASSWORD: "${LUMEN_PASSWORD:-}"
    volumes:
      # Persist the SQLite database between container restarts
      - lumen_storage:/rails/storage

volumes:
  lumen_storage:
```

### 2. Create a `.env` file (optional, in the same directory)

```dotenv
# Optional: set basic auth credentials or custom secret key base
LUMEN_USERNAME=your_username
LUMEN_PASSWORD=a_strong_password
SECRET_KEY_BASE=a_random_secret_key_string
```

> **Tip:** If you're running behind a reverse proxy (Nginx, Caddy, Traefik) that terminates TLS, add `RAILS_SERVE_STATIC_FILES=true` to your environment.

### 3. Pull and start

```bash
docker compose up -d
```

Lumen Space will be available at [http://localhost:3000](http://localhost:3000) (or whatever port/domain your reverse proxy is configured for).

### 4. First-time setup

The Docker entrypoint automatically runs `db:prepare` on each startup, so the database is always initialised before the server starts. No manual step needed.

### Updating

```bash
docker compose pull && docker compose up -d
```

---

## Docker Images

Multi-platform images (`linux/amd64` and `linux/arm64`) are published automatically to GitHub Container Registry on every tagged release.

```bash
# Latest stable
docker pull ghcr.io/YOUR_HANDLE/lumen-rails:latest

# Specific version
docker pull ghcr.io/YOUR_HANDLE/lumen-rails:v1.2.3
```

---

## Configuration Reference

| Variable | Default | Description |
|---|---|---|
| `SECRET_KEY_BASE` | *(auto-fallback)* | Optional. Secret key for cookie/session encryption. A secure default is used if blank |
| `LUMEN_USERNAME` | `lumen` | HTTP basic auth username (auth disabled if `LUMEN_PASSWORD` is blank) |
| `LUMEN_PASSWORD` | _(blank)_ | HTTP basic auth password. Leave blank to disable auth |
| `RAILS_ENV` | `production` | Set to `production` in Docker / server deployments |
| `DATABASE_URL` | _(SQLite)_ | Override to use a different database adapter |
| `PORT` | `80` (Docker) / `3000` (local) | Listening port |

---

## Development

```bash
# Run tests
bin/rails test

# Run with hot-reloading CSS (if using a watcher)
bin/rails server

# Interactive console
bin/rails console

# Database schema inspection
bin/rails db:schema:dump
```

### Versioning

Versions follow [Semantic Versioning](https://semver.org). Use the `make` commands to bump:

```bash
make bump-patch   # 1.0.0 → 1.0.1
make bump-minor   # 1.0.0 → 1.1.0
make bump-major   # 1.0.0 → 2.0.0
```

Each command:
1. Updates `VERSION` file
2. Commits the change
3. Creates a signed git tag
4. Pushes the tag — triggering the CI/CD Docker build & release

---

## Project Structure

```
lumen-rails/
├── app/
│   ├── controllers/        # ProjectsController, ArtifactsController, …
│   ├── models/             # Project, Artifact, ArtifactTag, ArtifactLink, …
│   ├── views/              # ERB templates with Turbo Streams
│   ├── javascript/
│   │   └── controllers/    # Stimulus: reader, tag-editor, add-form, …
│   └── assets/stylesheets/ # Vanilla CSS design system
├── db/migrate/             # ActiveRecord migrations
├── config/routes.rb        # RESTful route definitions
├── .github/workflows/      # CI: Docker build + release
├── Makefile                # Version bumping helpers
└── VERSION                 # Single source of truth for the app version
```

---

## License

MIT — see [LICENSE](LICENSE).

---

*Originally a Flutter desktop app. Ported to Ruby on Rails 8 for true cross-platform self-hosting without requiring Dart/Flutter toolchain knowledge.*
