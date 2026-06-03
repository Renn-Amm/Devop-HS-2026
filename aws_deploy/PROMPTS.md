# PROMPTS.md — Challenge 5: Deploy to AWS EC2

## How I Used This Session

Worked through setting up EC2, fixing SSH key issues, and getting the
pipeline to deploy the binary. Used AI to debug specific errors rather
than to generate the whole solution.

---

## SSH Key Issues

The .pem file kept failing with `error in libcrypto`. I knew it was a
key format problem but wasn't sure where it got corrupted. I asked:

> "I'm getting error in libcrypto when SSH tries to load my .pem file
> — the file exists and has correct permissions. What would cause that?"

AI pointed out to check `wc -l` on the file. When I ran it I found the
key had been pasted twice — there were two BEGIN/END blocks in the file.
The second empty block was confusing the crypto library. Fixed by opening
the file in nano and deleting everything after the first END block.

The lesson here: always verify `head -1` and `tail -1` after pasting a
key. A key that looks right visually can still be broken if there are
extra lines at the end.

---

## Security Group Setup

I initially opened both port 22 and 4444 to 0.0.0.0/0. I asked:

> "Is opening port 22 to 0.0.0.0/0 actually a problem for this challenge
> or is it fine since it requires a key pair anyway?"

AI explained that even with key-based auth, an open :22 is a constant
target for automated scanners and brute force attempts. Every SSH server
exposed to the internet gets hit within minutes. The key pair protects
against login but not against the noise and log spam from constant
probing, and there is always the risk of a future misconfiguration or
vulnerability being exploited.

For this challenge it is acceptable but on a real team you would restrict
:22 to your office IP or use AWS Systems Manager Session Manager to
eliminate SSH exposure entirely.

---

## Stretch Task — Instance Tagging

I added Cohort=CS411-2026 and Owner=Renn-Amm tags to the instance after
launch via the Tags tab in the EC2 console. I asked:

> "Why do cloud teams care about tagging every resource at creation — 
> is it just for organization or does it actually matter operationally?"

The answer was more concrete than I expected. On a real team with dozens
of engineers and hundreds of resources, untagged resources become
orphaned within weeks. No one knows who created them, which project they
belong to, or whether they are safe to delete. The practical consequences:

First, cost allocation breaks. AWS bills per resource but without tags
you cannot split the bill by team, project, or environment. A $500
monthly EC2 bill is impossible to attribute without Owner and Environment
tags on every instance.

Second, cleanup becomes guesswork. When an engineer leaves or a project
ends, untagged resources just sit there running. Teams end up paying for
instances nobody knows the purpose of because no one wants to be the
person who deleted something important.

Third, security audits get painful. If you need to find all production
instances or all instances running a particular workload, tags are the
only reliable way to do it at scale. Without them you are reading through
instance names and guessing.

I decided to add the tags right after launch rather than at creation
because the launch page layout made it unclear where the tag section was.
On a real project I would add tags at creation time in the launch config
or Terraform so they are never forgotten.

---

## Systemd on EC2

Same pattern as the first deployment challenge — created a dedicated
myapp user with no shell, set Restart=on-failure. I did not ask the AI
about this since I had already worked through it in challenge 2.

One thing I noticed: on EC2 Ubuntu the default user is ubuntu not
laborant like in iximiuz. The scp and ssh commands in the Jenkinsfile
needed ubuntu@<ip> not laborant@<ip>. Small thing but would have caused
a permission denied if I had copy-pasted from the previous challenge
without checking.

AI explained: Security Groups drop packets silently at the AWS network
layer before they reach the instance. The TCP SYN never gets a response
so the client just waits. Connection refused requires the packet to reach
the host and get a RST back from the OS. The shape of the error — hang
vs refused — tells you where the block is.
