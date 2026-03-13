# emacs-config

![The Alchymist, in Search of the Philosopher's Stone](https://upload.wikimedia.org/wikipedia/commons/thumb/9/9c/Joseph_Wright_of_Derby_The_Alchemist.jpg/700px-Joseph_Wright_of_Derby_The_Alchemist.jpg)

*"The Alchymist, in Search of the Philosopher's Stone" (1771) by Joseph Wright of Derby — [Wikipedia](https://en.wikipedia.org/wiki/The_Alchymist)*

**A handcrafted, single-file Emacs configuration -- no frameworks, no layers, no generated code.**

## About

This is one person's opinionated `init.el`, evolved through years of daily use across NixOS and macOS. Everything lives in a single file because readability beats cleverness, and stability beats bleeding-edge. The cursor stays centered on screen, because the middle is where the action is.

## Highlights

- **Single-file config** -- one `init.el`, nothing else
- **straight.el + use-package** -- packages pulled from Git and built locally, no MELPA refresh dance
- **Doom One Light** theme with Doom Modeline and Nerd Icons
- **Ivy + Counsel + Swiper** for narrowing, searching, and completing everything, with frecency sorting via Ivy Prescient
- **Magit** for Git
- **Paredit** everywhere -- Emacs Lisp, Clojure, ClojureScript, Scheme, CIDER REPL
- **Claude Code IDE** -- full Claude Code CLI integration with MCP bridge, accessible via a Hydra menu (`C-c c`). Typing in the Claude buffer opens a minibuffer prompt automatically
- **gptel** for quick LLM chat from any buffer
- **Projectile** for jumping between projects in `~/projects`
- **LSP via lsp-mode** for Clojure/ClojureScript, with Flycheck globally enabled
- **Centered point mode** -- a custom minor mode that keeps the cursor vertically centered
- **WakaTime** for silent coding activity tracking (loads only if `wakatime-cli` is available)

### Language Support

| Language   | Packages                                     |
|------------|----------------------------------------------|
| Clojure    | clojure-mode, CIDER, clj-refactor, clj-kondo |
| JavaScript | js2-mode, js2-refactor, xref-js2             |
| Org-mode   | org-bullets, org-drill, ox-gfm, org-make-toc |
| LaTeX      | AUCTeX + RefTeX                               |
| Markdown   | markdown-mode (GFM for READMEs)              |
| YAML       | yaml-mode                                     |
| HTTP       | restclient-mode                               |

### Terminal Options

- **vterm** -- full terminal emulation (also powers Claude Code IDE)
- **eat** -- fast terminal emulator
- **eshell** -- Emacs-native shell with Git-aware powerline prompt
- **term** -- the classic

### macOS Integration

Tuned for macOS with [Karabiner-Elements](https://pqrs.org/osx/karabiner/): Caps Lock remapped to Control, Cmd and Option swapped so physical Cmd becomes Meta, pixel-smooth scrolling, and `exec-path-from-shell` so Emacs inherits your `$PATH`.

### Custom Utilities

- `pmd/clipboard-copy-full-path` / `pmd/clipboard-copy-file-name` -- copy file path or name to clipboard
- `pmd/org-clock-sum-current-region` -- sum clocked time in a selected region
- `pmd/markdown-convert-buffer-to-org` -- convert Markdown to Org via pandoc
- `pmd/align-repeat` -- align text by a regexp
- `pmd/remove-dos-eol` -- remove `\r` line endings

## Key Bindings

| Binding          | Action                           |
|------------------|----------------------------------|
| `C-c c`          | Claude hydra menu                |
| `C-c c o`        | Open/start Claude Code           |
| `C-c c s`        | Send prompt to Claude            |
| `C-c c t`        | Toggle Claude window             |
| `C-c p`          | Projectile command map           |
| `C-s`            | Swiper (search in buffer)        |
| `M-x`            | Counsel M-x (fuzzy command search) |
| `M-y`            | Counsel yank-pop (clipboard ring) |
| `C->` / `C-<`    | Paredit slurp / barf forward     |

## Requirements

- Emacs 29+
- `cmake` (for vterm's native module)

## Installation

```shell
# Clone
git clone git@github.com:pdelfino/emacs-config.git ~/projects/emacs-config

# Symlink
ln -sf ~/projects/emacs-config/init.el ~/.emacs.d/init.el

# Launch Emacs -- straight.el bootstraps itself and pulls all packages
emacs
```

## Related Configs

- [karabiner-config](https://github.com/pdelfino/karabiner-config) -- Emacs keybindings system-wide on macOS
- [claude-config](https://github.com/pdelfino/claude-config) -- Claude Code configuration
- [homerow-config](https://github.com/pdelfino/homerow-config) -- Click things without a mouse
- [iterm2-config](https://github.com/pdelfino/iterm2-config) -- iTerm2 terminal profile
- [zshrc](https://github.com/pdelfino/zshrc) -- Shell configuration with Emacs keybindings
- [macos-setup](https://github.com/pdelfino/macos-setup) -- The bootstrap that ties it all together
