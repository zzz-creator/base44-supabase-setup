# Base44 Supabase Setup

This repository brings together a self-hosted Supabase backend and five frontend
applications. The root Docker Compose configuration runs the shared backend;
the application projects are separate Git submodules configured to use it.

## Applications

- **[AstroSimNexus](https://github.com/zzz-creator/AstroSimNexus/blob/main/README.md)** — space-logistics and colony-management simulation, with fleet, colony, and economic operations.
- **[KwanPro](https://github.com/zzz-creator/KwanPro/blob/main/README.md)** — dojo management for students, classes, attendance, belt promotions, payments, and student services.
- **[OmniPOS Core](https://github.com/zzz-creator/OmniPOS-Core/blob/main/README.md)** — point-of-sale and management application.
- **[OpsGrid](https://github.com/zzz-creator/OpsGrid/blob/main/README.md)** — IT operations console for alerts, incidents, analytics, automation, and workspace control.
- **[ProdIntelStageOps](https://github.com/zzz-creator/ProdIntelStageOps/blob/main/README.md)** — production and stage-operations management for productions, crews, equipment, venues, schedules, and incidents.

Each app depends on the Supabase backend configured by this repository. For app
setup, environment variables, and development commands, see its README.

## Fresh setup

1. Install Git, Docker Engine, and the Docker Compose plugin. On Windows, use
   WSL 2 or another environment that provides a POSIX-compatible shell for the
   repository scripts.
2. Clone this repository and all of its app/backend submodules:

   ```sh
   git clone --recurse-submodules https://github.com/zzz-creator/base44-supabase-setup.git
   cd base44-supabase-setup
   ```

3. Create and configure the local environment file:

   ```sh
   cp .env.example .env
   ```

   Review the URLs, passwords, and keys in `.env`; replace example/default
   values and keep the file private. The root `.gitignore` excludes it.
4. Start the stack:

   ```sh
   sh run.sh start
   sh run.sh status
   ```

   The default API gateway is available at `http://localhost:8000`. Configure
   each frontend with that Supabase URL and the matching public anon key from
   `.env`; never put the service-role key in a frontend.

## Supabase setup and operations

This repository uses Supabase’s self-hosted Docker Compose deployment. For
prerequisites, security, configuration, and troubleshooting, see:

- [Supabase self-hosting with Docker](https://supabase.com/docs/guides/self-hosting/docker)
- [Supabase self-hosting overview](https://supabase.com/docs/guides/self-hosting)
- [Self-hosted deployment configuration reference](./CONFIG.md)
- [Update guide](https://supabase.com/docs/guides/self-hosting/updating)

Useful stack commands:

```sh
sh run.sh logs [service]
sh run.sh compose-config
sh run.sh stop
```

Back up the database before updates. `sh reset.sh` is destructive: it removes
containers and bind-mounted database/storage data.

## Working with submodules

The five apps and `supabase/` are independent Git repositories. After changing
an app, commit inside that app repository and then update its pointer in this
root repository. The helper performs those two commits in order:

```sh
sh scripts/commit-submodule.sh "AstroSimNexus" "feat: describe change"
```

Review the listed paths before confirming. For non-interactive use, pass
`--yes` after reviewing the paths. The helper does not push; push each changed
repository separately.
