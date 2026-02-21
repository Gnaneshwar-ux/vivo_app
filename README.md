# vivo_app

## Local dev

```bash
npm install
npm run dev
```

Vite will print the local URL (typically `http://localhost:5173/vivo_app/`).

> If PowerShell blocks `npm` due to execution policy, run via CMD:
>
> ```bat
> cmd /c "npm.cmd install"
> cmd /c "npm.cmd run dev"
> ```

## Redeploy (Termux)

The repo includes a Termux-friendly `redeploy.sh` script that:

1. Stops the previous Node server (using `server.pid`)
2. Pulls latest code
3. Installs dependencies
4. Builds (`npm run build`)
5. Starts `node server.js` in the background

### Optional: Cloudflare Tunnel (public URL)

If you want a public URL (HTTPS) accessible from anywhere, you can enable a Cloudflare Tunnel.

Install in Termux:

```bash
pkg install cloudflared
```

Run redeploy and start tunnel:

```bash
START_TUNNEL=1 ./redeploy.sh
```

Performance / control flags:

```bash
# Skip dependency install (faster when nothing changed)
INSTALL=0 ./redeploy.sh

# Skip build (only if you know dist/ is already up to date)
BUILD=0 ./redeploy.sh
```

### Detailed redeploy logs + time taken

Each redeploy run writes a timestamped log file:

- `~/vivo_app/logs/redeploy-YYYYmmdd-HHMMSS.log`

The log includes the full output, plus:

- local URL (`http://localhost:5173/vivo_app/`)
- LAN URL (example `http://100.99.24.3:5173/vivo_app/` if IP is detected)
- optional Cloudflare public URL (saved to `tunnel.url`)
- total time taken (seconds)

Where it stores tunnel info:

- Tunnel PID: `~/vivo_app/tunnel.pid`
- Public URL: `~/vivo_app/tunnel.url`
- Tunnel log: `~/vivo_app/logs/cloudflared.log`

Every time you run redeploy again, the script will:

- stop any previous tunnel using `tunnel.pid`
- start a new tunnel
- detect the new `https://*.trycloudflare.com` URL from logs and overwrite `tunnel.url`

