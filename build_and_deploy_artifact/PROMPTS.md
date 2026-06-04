# PROMPTS.md — Challenge 2: First Deployment Pipeline

## How I Used This Session

I worked through this challenge by identifying what was breaking, forming
a theory on why, then checking it with the AI. Where I had two possible
fixes I picked the one that made more sense for the setup and asked the
AI to confirm the reasoning. The AI mostly corrected direction or caught
edge cases I missed.

---

## Stage 1: Pipeline Failing at Deploy

The first run failed with:
`jenkins@target: Permission denied (publickey)`

I knew straight away this was SSH auth — Jenkins had no key pair so target
was rejecting the connection entirely. I asked:

> "The Jenkins pipeline is failing with permission denied on scp to target.
> I think it needs an SSH key set up for the jenkins user — how do I do that
> without breaking anything else?"

AI confirmed and walked me through generating the key as the jenkins user:
`sudo -u jenkins ssh-keygen -t ed25519 -f /var/lib/jenkins/.ssh/id_ed25519 -N ""`

---

## Stage 2: ssh-copy-id Also Failing

I tried ssh-copy-id to push the public key to target but got the same
permission denied error. I asked:

> "ssh-copy-id is also failing with publickey denied — does that mean
> target has password auth disabled? If so how do I bootstrap the key
> at all?"

AI confirmed: target only allows publickey auth, so ssh-copy-id cannot
authenticate itself to install the key. The fix was to SSH into target
directly as laborant (which works via the iximiuz conductor key) and
append the jenkins public key to authorized_keys manually.

---

## Stage 3: authorized_keys Permission Errors

On target, writing to authorized_keys kept failing:
`bash: /home/laborant/.ssh/authorized_keys: Permission denied`

I had a feeling the file was root-owned from a previous failed attempt.
I asked:

> "The authorized_keys file on target is refusing writes even as laborant.
> I think the file ownership got messed up earlier — how do I write to it
> and fix ownership in one go?"

AI suggested using sudo bash -c to wrap the echo and chown together:
```bash
sudo bash -c 'echo "ssh-ed25519 AAAA...jenkins@jenkins" \
  >> /home/laborant/.ssh/authorized_keys && \
  chown laborant:laborant /home/laborant/.ssh/authorized_keys && \
  chmod 600 /home/laborant/.ssh/authorized_keys'
```

---

## Stage 4: Key Was There But SSH Still Failing

After adding the key, the ssh test still returned permission denied. I
catted the authorized_keys file and spotted the issue myself — the jenkins
key had merged onto the same line as the previous entry because there was
no newline separator. SSH could not parse it.

I asked:

> "I can see the key is in authorized_keys but it looks like it got
> appended without a newline so it merged with the previous key entry.
> Would SSH just skip an unparseable line or would it fail entirely?"

AI confirmed SSH skips malformed lines silently, which is why the key was
present but not working. Fixed by rewriting the file cleanly from a backup
using grep -v to strip the bad entry and re-appending the key properly.

---

## Stage 5: Process Dying After SSH Session Closes

Early version of the deploy stage was backgrounding the process over SSH.
I noticed the app would die the moment the SSH session closed and asked:

> "If I run './main &' over SSH and then the session closes, does the &
> actually protect the process or does it still get killed?"

AI explained that & only backgrounds within the session — the process is
still a child of the SSH session and gets SIGHUP when it closes. The fix
was to hand ownership to systemd entirely and call systemctl restart myapp
from the pipeline instead. That way the process lifecycle is completely
detached from the SSH session.

---

## Stage 6: Stretch Tasks

I decided to do all three stretch tasks. My reasoning was that I wanted
to actually understand what each one does rather than just picking the
easiest — doing all three meant I had to think about process supervision,
idempotency, and pipeline correctness as separate problems.

I asked the AI to explain what each one was really testing before I
implemented it:

> "Can you explain what each stretch task is actually checking for — not
> how to do it, but what problem it solves?"

AI's answers in brief:

- **Production systemd unit** — tests whether you understand process
  supervision. A process that just starts is not the same as one that
  recovers from failure. User=myapp and Restart=on-failure are the
  difference between a toy setup and something you'd run in production.

- **Idempotent deploy** — tests whether your pipeline is safe to re-run.
  Most real pipelines run multiple times. If the second run fails because
  a port is already bound or an old process is still running, the pipeline
  is fragile. systemctl restart solves this because stop+start is safe to
  call any number of times.

- **Health check gate** — tests whether a green pipeline actually means
  the app is working. systemctl restart returns exit code 0 as soon as
  it hands off to the service manager — it does not wait to confirm the
  process stayed up. Without a curl poll after deploy, the pipeline can
  show green while the app crashed on startup and no traffic is being served.

I implemented all three and verified each one on target before pushing.
For the systemd unit I killed the process manually with sudo pkill main
and confirmed via journalctl that systemd brought it back without
intervention. For idempotency I triggered the Jenkins job twice back to
back and both runs completed green. For the health check I intentionally
broke the binary path once to confirm the pipeline would fail rather than
silently report success.
