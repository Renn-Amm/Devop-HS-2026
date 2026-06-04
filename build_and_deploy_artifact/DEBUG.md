# DEBUG.md — Challenge 2: First Deployment Pipeline

## Scenario

Pipeline shows green. Deploy stage logs say it succeeded. Curling target
from outside gets Connection refused. SSH into target, run ./main in the
foreground — works fine, curl localhost:4444 returns the JSON. Exit the
SSH session and the app dies. Next pipeline run, same thing.

---

## My Initial Theory

My first thought was that the binary was not being copied correctly or
was landing in the wrong place. I checked /tmp/main on target and it was
there, executable, and ran fine manually. So the binary itself was not
the problem.

I then thought maybe the port 4444 was being blocked by a firewall rule
that only allows connections from localhost. I asked:

> "The app works when I run it manually on target and curl localhost:4444
> but dies when I exit the SSH session. Could this be a firewall issue
> blocking external connections to 4444?"

AI pushed back on this — if it were a firewall issue the app would still
be running after the session closed, just unreachable. The fact that the
process disappears entirely points elsewhere. That reframing helped me
think about it differently — the problem is not connectivity, it is that
the process does not survive the session at all.

---

## Hypotheses

### Hypothesis 1 — Process is a child of the SSH session (most likely)

When the pipeline runs `ssh target './main &'` the backgrounded process
is still a child of the SSH session. When the session closes, the kernel
sends SIGHUP to the process group and the app gets killed.

Verification:
```bash
ssh laborant@target './main &'
# exit the session, then reconnect and run:
ssh laborant@target 'pgrep -a main'
```
If the output is empty the process died with the session, confirming
hypothesis 1.

### Hypothesis 2 — Binary is being overwritten mid-run on the second pipeline execution

On a second pipeline run, scp copies the new binary to /tmp/main while
the old process might still be starting up, causing a race condition or
a corrupted binary in memory.

Verification:
```bash
ssh laborant@target 'ls -lh /tmp/main && pgrep -a main'
```
If the process exists but /tmp/main has a recent timestamp matching the
pipeline run, the overwrite race is the issue.

---

## How I Arrived at the Fix

After the AI corrected my firewall theory I asked:

> "So if the process is getting SIGHUP when the SSH session closes, would
> nohup fix it or is there a cleaner way to handle this?"

AI explained that nohup would work but only shields against SIGHUP — it
does not restart the process if it crashes, and it leaves the process
unmanaged with no logging. I pushed back:

> "For the challenge we need the process to stay running across pipeline
> runs and survive crashes — is nohup actually enough or should I use
> something else?"

AI confirmed that for the stretch task requirements (non-root user,
Restart=on-failure, journalctl visible) systemd is the right tool. nohup
is a quick fix, not a supervised solution.

---

## Fix

Replace the bare SSH execution in the pipeline with systemd ownership:

Instead of:
```bash
ssh laborant@target './main &'
```

Do:
```bash
ssh -i ~/.ssh/id_ed25519 laborant@target "
    sudo mv /tmp/main /opt/myapp/main &&
    sudo chown myapp:myapp /opt/myapp/main &&
    sudo chmod +x /opt/myapp/main &&
    sudo systemctl restart myapp
"
```

With the systemd unit file on target:
```ini
[Unit]
Description=My Go App
After=network.target

[Service]
User=myapp
ExecStart=/opt/myapp/main
Restart=on-failure
RestartSec=5
WorkingDirectory=/opt/myapp

[Install]
WantedBy=multi-user.target
```

systemctl restart hands the process to PID 1. The SSH session closing
has no effect on it.

---

## Verification After Fix

Kill the process manually to confirm systemd brings it back:
```bash
sudo pkill main
sleep 3
sudo journalctl -u myapp --no-pager | tail -10
```

Expected output shows the service stopping and then restarting
automatically without any manual intervention.

---

## Lesson

A process that exists right now is alive only because nothing has killed
it yet — it has no supervisor, no restart policy, and no independence from
the session that spawned it. A supervised process under systemd is owned
by PID 1, restarts according to its unit file policy, and survives
regardless of how or why it stopped.
