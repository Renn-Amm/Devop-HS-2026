# DEBUG.md — Challenge 5: Deploy to AWS EC2

## Scenario

Pipeline shows SUCCESS. SSH into EC2 and curl localhost:4444 returns
the expected JSON — app is running. From outside, curl http://<public-ip>:4444
hangs forever. Not connection refused — just hangs until Ctrl-C.

## My Initial Theory

My first thought was that the app was binding to localhost only instead
of 0.0.0.0, which would explain why it works locally but not externally.
I asked:

> "The app works on localhost but curl from outside hangs rather than
> getting connection refused — does that tell us something specific about
> where the block is?"

AI pointed out that the shape of the error matters: connection refused
means a packet reached the host and the port was closed. A hang means
the packet never got a response at all — it was dropped somewhere in the
network before reaching the app. That pointed at the Security Group
rather than the app itself.

## Hypotheses

### Hypothesis 1 — Security Group missing inbound rule for tcp/4444 (most likely)

AWS Security Groups default to deny all inbound traffic. If the tcp/4444
rule was not added or was added with the wrong port, packets are silently
dropped at the network layer before reaching the instance. This produces
a hang rather than connection refused because the TCP SYN never gets
a response.

Verification:
Go to AWS Console → EC2 → Security Groups → select the instance's SG →
Inbound rules. Check whether a rule exists for tcp/4444 from 0.0.0.0/0.
Or from the instance:
```bash
curl -v http://<public-ip>:4444/
```
If it hangs at `Trying <ip>...` the packet is being dropped at the SG.

### Hypothesis 2 — App is binding to 127.0.0.1 instead of 0.0.0.0

If the app listens only on loopback, external connections are refused
at the OS level — but on AWS the SG drop happens first so the symptom
is still a hang from outside.

Verification:
```bash
ssh ubuntu@<ec2-ip> "ss -tlnp | grep 4444"
```
If output shows `127.0.0.1:4444` the app is not binding to all interfaces.
If it shows `0.0.0.0:4444` the app is fine and the SG is the problem.

## Fix

Add the missing inbound rule in AWS Console:
- Go to EC2 → Security Groups → Inbound rules → Edit
- Add rule: Type Custom TCP, Port 4444, Source 0.0.0.0/0
- Save

Or if the app is binding to loopback, fix the listen address in the
Go source to bind to 0.0.0.0 instead of localhost.

## Lesson

A packet being dropped means it never reached the destination and got
no response — the connection just times out and hangs. A packet reaching
a closed port gets an immediate TCP RST back, which is connection refused.
The hang tells you the block is at the network layer, not the application.
