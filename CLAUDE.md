# Claude Code Guide for gui-dotfiles

## Quick Commands
```bash
tradecraft  # See working preferences and technical focus
myenv       # See installed tools and modern CLI alternatives
```

## Key Principles

**Communication:**
- Direct and honest > polished and flattering
- Value over theory; efficiency over fluff
- Ask questions first; don't assume context

**Workflow:**
- DON'T commit code - user's job
- ASK before running builds (npm run build, mvn install, etc.)
- Use `myenv` instead of trial-and-error
- Code with intent and personality

**Technical:**
- Architecture-first design
- Constraints-based approach
- Tests as ground truth
- No premature abstractions
- Simple and focused solutions

## The User

This is a software engineer working on:
- Legacy code modernization (COBOL/CICS → microservices)
- Agent-based systems and RAG
- Graph algorithms and network analysis
- Systems automation and DSL design

They value:
- Domain expertise (you're supporting velocity, not decisions)
- Efficiency (one `myenv` not 10 guesses)
- Honesty (tradeoffs matter)
- Code quality (format on save, LSP, conventional commits)

Full working preferences live in `ai/claude/CLAUDE.md`, which this repo symlinks
to `~/.claude/CLAUDE.md` — so they apply in every project, not just this one.
