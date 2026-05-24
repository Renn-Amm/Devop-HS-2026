# Reflection — introduction-to-builds

## What did I do?

I followed the instructions on the iximiuz lab. It was pretty similar to the previous tutorials (the build fundamentals one). I created `main.go`, installed Go with `apt`, built it with `go build`, ran `./main`, saw the JSON on port 4444. For the stretch I picked cross‑compile: `GOOS=linux GOARCH=arm64 go build -o main-arm64 main.go`. Then to commit to GitHub I switched to my local VS Code terminal, cloned my repo, copied the files over, and pushed.

## What was most surprising?

The fact that Go and Ruby can produce the exact same JSON output but work completely differently under the hood. Go compiles to a standalone binary – you copy it and run. Ruby needs the interpreter and all the gems installed. Same result, totally different deployment story. That was the whole point of the tutorial and it actually clicked.

## What's still unclear?

Cross‑compile and strip binary. I did the commands and they worked, but I'm not 100% sure what's happening. I asked the AI and got a basic grasp – cross‑compile makes a binary for a different CPU/OS, strip removes debug symbols to shrink size – but I'd still need to look up the flags if I had to do it again.