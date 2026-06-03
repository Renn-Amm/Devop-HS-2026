# PROMPTS.md — Challenge 5: Deploy to AWS EC2

## How I Used This Session

Same approach as previous challenges — formed a view on the moving parts
first, then used AI to fill gaps and check assumptions.

---

## AWS Setup

I had not used EC2 before so I asked for the minimal setup needed:

> "What is the minimum AWS setup to get a t2.micro running and reachable
> on port 4444 — I don't need anything production-grade, just enough for
> the challenge?"

AI walked through: Launch instance with Ubuntu 22.04, t2.micro, generate
key pair, add inbound rules for tcp/22 and tcp/4444. The key insight was
that AWS Security Groups default to deny all inbound — you have to
explicitly open every port you want reachable.

---

## SSH Key in Jenkins

I asked:

> "The .pem file from AWS — where does it go in Jenkins and how does
> the pipeline reference it?"

AI explained to store it as SSH Username with private key credential,
not as a file or secret text. The sshUserPrivateKey binding in
withCredentials then exposes it as a temp file path the pipeline can
pass to ssh -i.

---

## Stretch Task — Instance Tagging

I tagged the instance with Cohort=CS411-2026 and Owner=Renn-Amm at
launch time. I asked:

> "Why do cloud teams tag every resource at creation rather than adding
> tags later?"

AI explained: on a real team, resources without tags become orphaned
within weeks. No one knows who owns them, which environment they belong
to, or whether they are safe to delete. Cost allocation also breaks down
— you cannot split the AWS bill by team or project without tags. Adding
tags after the fact requires tracking down the owner first, which often
means the resource just stays untagged forever.

---

## Security Group Behaviour

I noticed that a missing SG rule causes a hang rather than connection
refused. I asked:

> "Why does a blocked Security Group cause a hang rather than connection
> refused — shouldn't the host send something back?"

AI explained: Security Groups drop packets silently at the AWS network
layer before they reach the instance. The TCP SYN never gets a response
so the client just waits. Connection refused requires the packet to reach
the host and get a RST back from the OS. The shape of the error — hang
vs refused — tells you where the block is.
