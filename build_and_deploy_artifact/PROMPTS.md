# PROMPTS.md

## What I asked
- How to fix Permission denied (publickey) when Jenkins SCP to target
- How to add jenkins SSH key to target authorized_keys when permissions were wrong
- Which stretch task to pick and why

## What I decided
- Chose production-quality systemd unit — overlaps with core, auto-checker verifies it
- Used User=myapp (dedicated non-root user) with Restart=on-failure

## What I pushed back on
- Replaced ssh target './main &' with systemctl restart myapp —
  process was dying when SSH session closed
- SSH key setup failed due to authorized_keys permissions —
  fixed with sudo bash -c on target

## Stretch task evidence
Kill process: `ssh laborant@target "sudo pkill main"`
Confirm restart: `ssh laborant@target "sudo journalctl -u myapp --no-pager | tail -5"`
