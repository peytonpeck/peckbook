# Development Guide

## Purpose and scope

This is Peyton Peck's personal-finance app, forked from Plaid Pattern. It is a
single-user product, not a reusable Plaid reference implementation. Prefer
simple, maintainable product decisions over preserving upstream demo behavior.
Keep Plaid integration and financial data handling secure; do not expose
access tokens, secrets, or database credentials to the client or commit them.

## Repository index

| Path | Responsibility |
| --- | --- |
| `client/` | React 18 + TypeScript SPA, built and served by Vite on port 3001. |
| `client/src/components/` | Views and reusable UI; `ui/` contains shared primitives. |
| `client/src/services/` | API clients and React context providers for accounts, items, users, transactions, assets, Link, and errors. |
| `client/src/App.tsx` | Provider composition and app routes: `/`, `/user/:userId`, `/oauth-link`, and `/admin`. |
| `server/` | Express + Socket.IO application, normally on the `PORT` from `.env` (port 5001 in local setup). |
| `server/routes/` | HTTP routes grouped by domain; register new routers in `server/routes/index.js` and `server/index.js`. |
| `server/db/queries/` | PostgreSQL access layer. Keep SQL and persistence logic here rather than in route handlers. |
| `server/webhookHandlers/` | Plaid webhook dispatch and handlers. |
| `server/update_transactions.js` | Transactions Sync reconciliation. Preserve its idempotent behavior when changing transaction data. |
| `database/init/create.sql` | Canonical local PostgreSQL schema and initialization script. |
| `docs/` | Troubleshooting and image assets. |
| `.env.template` | Safe template for required configuration; `.env` is local-only and ignored. |
| `Makefile` / root `package.json` | Top-level setup, development, and database commands. |

## Architecture and data flow

The browser calls `client/src/services/api.tsx`, which calls the Express routes.
Routes coordinate the Plaid SDK (`server/plaid.js`) and query modules, which
persist to PostgreSQL. Plaid webhooks reach `server/routes/services.js`, are
handled in `server/webhookHandlers/`, and notify the SPA through Socket.IO.

The primary persisted tables are `users_table`, `items_table`, `accounts_table`,
`transactions_table`, `assets_table`, `link_events_table`, and
`plaid_api_events_table`. Access tokens and Plaid request identifiers are
sensitive operational data: keep them server-side and avoid logging them.

## Local workflow

Prerequisites: Node.js 20+, Docker Desktop (or Docker Engine with Compose),
Plaid Sandbox credentials, and ngrok when testing webhooks.

```sh
cp .env.template .env             # fill in local values; never commit this file
npm run install:all               # or: make install
npm run db:create                 # starts containerized Postgres and initializes it once
npm run server                    # port 5001 by default
npm run client                    # port 3001 by default
ngrok http 5001                   # needed for Plaid webhooks
```

Useful checks:

```sh
npm run lint --prefix client
npm run lint --prefix server
npm run build --prefix client
```

Use `npm run db:reset` or `make db-reset` only when a destructive local
database reset is intended. It deletes the Docker database volume.

## Change guidelines

- Make product-specific changes freely; remove or simplify upstream demo-only
  paths when they no longer serve the personal app, but do not mix broad
  cleanup with unrelated feature work.
- Keep client API access in `client/src/services/`. Update the matching service,
  provider/types, and consuming UI together when an API contract changes.
- Add server endpoints by domain. Validate input, use the query layer for
  database work, and let the shared error middleware handle consistent errors.
- For schema changes, update `database/init/create.sql` and the affected query
  modules in the same change. Treat existing financial records as valuable;
  provide a migration plan before changing a populated local database.
- Preserve Plaid's transaction-sync cursor semantics and handle added, modified,
  and removed transactions. Prefer webhook-driven sync over client polling.
- Keep the explicit CORS origin and Socket.IO behavior aligned with the Vite
  development URL when changing local ports or deployment configuration.
- Client code is mostly TypeScript, but `Sockets.jsx` and `services/index.js`
  are JavaScript. Follow the existing extension and lint configuration in the
  file you touch; do not perform a language conversion incidentally.
- Follow `.editorconfig`: two-space indentation, LF line endings, UTF-8, and a
  final newline.

## Security and privacy

- Never commit `.env`, Plaid client IDs/secrets/access tokens, PostgreSQL
  credentials, webhook URLs, or real transaction exports.
- Never return Plaid access tokens to the browser. Sanitize logs and errors so
  they do not leak sensitive financial or authentication data.
- Use Plaid Sandbox for development. Treat production credentials and a live
  database as explicitly scoped operational changes.

## Before handoff

Run the relevant client lint/build and server lint checks. For work that
touches accounts, items, transactions, Link, or webhooks, manually exercise
the affected flow in Sandbox and verify that the client refreshes correctly.
