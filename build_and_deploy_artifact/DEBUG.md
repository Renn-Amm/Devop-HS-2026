## Hypotheses

1. **Process died when SSH session closed** — the app was launched as a
   child of the SSH session; when the session exits, SIGHUP kills it.
2. **Port binding failure on restart** — a previous instance left the port
   in TIME_WAIT, causing the new process to fail silently.

## Verification

1. `ssh target './main &'`, exit, then `ssh target 'pgrep main'` —
   if empty, hypothesis 1 confirmed.
2. `ssh target 'ss -tlnp | grep 4444'` after pipeline —
   if no listener, port never bound.

## Fix

Use systemd: `sudo systemctl restart myapp` instead of `ssh target './main &'`

## Lesson

"Process exists right now" means it runs inside the current SSH session.
"Process is supervised" means systemd owns it, restarts on failure,
and survives session disconnection.
