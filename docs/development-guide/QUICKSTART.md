# Running HaruNeko from Source

Requires Node.js >= 22.13 and npm >= 10.9.

## Install dependencies

```sh
npm install
```

## Run the desktop app (Electron version)

Two terminals needed:

**Terminal 1** - start the web dev server:

```sh
npm run serve:dev --workspace=web
```

**Terminal 2** - build and launch Electron:

```sh
npm run launch:dev --workspace=app/electron
```

## Run the desktop app (NW.js version)

Two terminals needed:

**Terminal 1** - start the web dev server:

```sh
npm run serve:dev --workspace=web
```

**Terminal 2** - build and launch NW.js:

```sh
npm run launch:dev --workspace=app/nw
```

## Production build

Build all workspaces:

```sh
npm run build --workspaces
```

Create a distributable bundle:

```sh
npm run bundle --workspace=app/electron
npm run bundle --workspace=app/nw
```

## Local production build (convenience scripts)

By default, a production build loads its frontend from a remote URL (`https://app.hakuneko.download`), not from your local code. The `scripts/` directory has `.cmd` and `.sh` convenience scripts that build a production app with your local webapp bundled in, so you can run your own changes as a standalone app without a dev server.

### Build

Double-click or run from a terminal:

- `scripts/build-local-electron.cmd` / `scripts/build-local-electron.sh`
- `scripts/build-local-nw.cmd` / `scripts/build-local-nw.sh`

These run the full build pipeline, then extract the bundle zip into `app/<platform>/.local-run/current/`. User data is preserved across rebuilds.

### Launch

- `scripts/launch-local-electron.cmd`
- `scripts/launch-local-nw.cmd`

These launch the installed app with `--local`, serving the bundled webapp from disk instead of loading from a remote URL.

## Run Tests

```sh
npm run test --workspaces
npm run test --workspace=web
npm run test --workspace=app/electron
npm run test --workspace=app/nw
```
