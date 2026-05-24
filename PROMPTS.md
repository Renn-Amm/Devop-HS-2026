**Q1:** "I built a Go binary on iximiuz (Ubuntu 24.04) and copied to Ubuntu 18.04. It says GLIBC_2.34 not found. How do I fix this in my local VS Code terminal?"

**A1:** Rebuild with `CGO_ENABLED=0 go build -o main main.go`. That disables CGO and makes a truly static binary.

**Q2:** "Why does that work? What is CGO doing?"

**A2:** CGO lets Go call C libraries. The `net` package uses it for DNS by default, which pulls in glibc. Disabling CGO replaces that with pure Go code.

**Q3:** "How do I verify the fix works?"

**A3:** Run `ldd ./main` – if it says "not a dynamic executable", you're good.

**Q4:** "The tutorial showed Go and Ruby doing the same thing (JSON output on port 4444). But under the hood, what's the actual difference when deploying?"

**A4:** Go compiles to a standalone binary. You copy that file to any Linux machine (with same architecture) and run it – nothing else needed. Ruby requires the interpreter (`ruby` command) and all gems (libraries) installed on the target machine. So Go deploy is one file; Ruby deploy is the script + runtime + dependencies.

**Q5:** "So which one is better?"

**A5:** Depends. Go is easier to ship (single binary) but compilation takes time. Ruby is faster to write and test (no compile step) but you have to manage the runtime environment on every server.