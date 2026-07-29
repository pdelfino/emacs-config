;;; init.el --- Emacs configuration -*- lexical-binding: t -*-

;; Increase GC threshold for faster startup (reset later)
(setq gc-cons-threshold (* 100 1000 1000))

;;; ============================================================================
;;; emacs-mac settings for macOS
;;; ============================================================================

;; Karabiner swaps Cmd↔Option at OS level
;; Physical Cmd → Option → Meta (for M-x, M-w, etc.)
;; Physical Option → Command → Super (for Maccy paste via Cmd+V → s-v)
;; Caps Lock → Control (for C-y, C-x, etc.)
(setq mac-option-modifier 'meta)
(setq mac-command-modifier 'super)
(global-set-key (kbd "s-v") 'yank)

;; Smooth scrolling
(setq mac-mouse-wheel-smooth-scroll t)

;; Native fullscreen
(setq ns-use-native-fullscreen t)

;; Pixel-based scrolling (Emacs 29+)
(pixel-scroll-precision-mode 1)

;;; ============================================================================
;;; Basic UI and UX settings
;;; ============================================================================

;; No startup screen
(setq inhibit-startup-screen t)

;; Disable UI elements
(scroll-bar-mode -1)
(tool-bar-mode -1)
(tooltip-mode -1)
(menu-bar-mode -1)

;; Disable bells
(setq visible-bell nil)
(setq ring-bell-function 'ignore)

;; Set fringe size
(set-fringe-mode 10)

;; Prevent UI dialogs for prompts
(setq use-dialog-box nil)

;; Use y/n instead of yes/no (Emacs 28+)
(setq use-short-answers t)

;; Use spaces, not tabs
(setq-default indent-tabs-mode nil)

;; Truncate long lines
(setq-default truncate-lines t)

;; Single space sentences
(setq sentence-end-double-space nil)

;; Stable cursor (no blinking)
(blink-cursor-mode -1)

;; Prevent font cache compaction during GC (reduces micro-stutters)
(setq inhibit-compacting-font-caches t)

;; Launch maximized
(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; Font size + family. Family is explicit (was falling back to Monaco,
;; which lacks box-drawing/arrow glyphs the claude-code TUI uses; Emacs
;; rendered those from a different-width fallback font, drifting vterm's
;; cell math and garbling earlier lines). Menlo has full coverage, so
;; every cell renders from one font and vterm stays aligned.
(set-face-attribute 'default nil :family "Menlo" :height 160)
(set-face-attribute 'variable-pitch nil :font "Cantarell" :weight 'regular)

;;; ============================================================================
;;; Built-in modes and features
;;; ============================================================================

;; Auto-revert buffers
(global-auto-revert-mode 1)
(setq global-auto-revert-non-file-buffers t)

;; Remember recently edited files
(recentf-mode 1)

;; Remember minibuffer history
(savehist-mode 1)

;; Remember cursor position
(save-place-mode 1)

;; Display column numbers
(column-number-mode)

;; Display line numbers
(global-display-line-numbers-mode t)

;; Disable line numbers for some modes
(dolist (mode '(org-mode-hook
                term-mode-hook
                shell-mode-hook
                eshell-mode-hook
                vterm-mode-hook
                eat-mode-hook
                pdf-view-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

;; --- Org readability: soft-wrap long lines -------------------------------
;; Claude Code transcripts (render-transcript.py) put each turn's prose in a
;; #+begin_example block as one very long logical line. With the global
;; `truncate-lines' default (t, set above for code), everything past the
;; window edge is clipped off the right and unreadable. Make Org buffers wrap
;; instead. `org-startup-truncated nil' is Org's own knob for this; `word-wrap'
;; breaks at whitespace rather than mid-word. No visual-line motion remap, so
;; C-a / C-e / C-k keep their logical-line meaning.
(setq org-startup-truncated nil)
(add-hook 'org-mode-hook (lambda () (setq-local word-wrap t)))
;; Transcripts now render Claude's prose as native Org (tables become real,
;; TAB-alignable Org tables). Side effect: bare `snake_case` could display as a
;; subscript. Require braces (`x_{i}`) for sub/superscripts so identifiers and
;; file_names in prose render literally.
(setq org-use-sub-superscripts '{})

;; --- Streaming-output redisplay tuning -----------------------------------
;; Default `read-process-output-max' is 4 KB, which makes Emacs do a full
;; redisplay cycle ~10-20×/sec on LLM streaming output (gptel, claude-code-ide,
;; etc.). Bumping to 4 MB collapses each stream into a handful of redraws.
;; Combined with bidi + jit-lock + scroll tweaks, this is the standard
;; modern config for streaming-heavy workflows.
(setq read-process-output-max (* 4 1024 1024))

;; Skip bidirectional-paragraph analysis on long lines (Claude responses can
;; have 2000-char paragraphs that hit this hard).
(setq-default bidi-paragraph-direction 'left-to-right)
(setq bidi-inhibit-bpa t)

;; Don't pause-and-recompute when scrolling fast.
(setq fast-but-imprecise-scrolling t)
(setq jit-lock-defer-time 0.05)

;; In chat / streaming buffers, also turn off flycheck (it re-checks on every
;; change and amplifies the redraw storm) and line numbers (which recompute
;; per insertion). Mirrors the vterm/eat/pdf-view exemption above.
(dolist (mode '(gptel-mode-hook
                ellama-mode-hook
                comint-mode-hook))
  (add-hook mode (lambda ()
                   (display-line-numbers-mode 0)
                   (when (bound-and-true-p flycheck-mode)
                     (flycheck-mode 0)))))
;; -------------------------------------------------------------------------

;; Show matching parens
(show-paren-mode t)
(setq show-paren-delay 0)

;; Delete selection when typing
(delete-selection-mode 1)

;; Tab completion
(setq tab-always-indent 'complete)

;; Mark ring size
(setq mark-ring-max 100)

;; Sync Emacs kill ring with system clipboard
(setq save-interprogram-paste-before-kill t)
(setq select-enable-clipboard t)
(setq select-enable-primary nil)

;; For emacs-mac: ensure clipboard integration
(when (eq system-type 'darwin)
  (setq mac-select-enable-clipboard t))

;; Recursive minibuffers
(setq enable-recursive-minibuffers t)

;; Ediff in same frame (for tiling WMs)
(setq ediff-window-setup-function 'ediff-setup-windows-plain)

;; Custom file location (keep handcrafted init.el clean)
(setq custom-file (locate-user-emacs-file "custom-vars.el"))
(load custom-file 'noerror 'nomessage)

;;; ============================================================================
;;; Package management (straight.el)
;;; ============================================================================

;; Bring straight.el package manager
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 6))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(straight-use-package 'use-package)
(setq straight-use-package-by-default t)

;; Load straight.el's transient (0.13+) BEFORE anything else can pull in the
;; stale built-in transient that ships with Emacs 29.4. Magit's autoloads (and
;; claude-code-ide's menu) trigger `require'd transient early; if the built-in
;; loads first it wins, and `transient--set-layout' (only in 0.7+) is void —
;; which is exactly the error claude-code-ide's [o] open/start menu throws.
;; Installing + `demand'ing it here makes straight's copy the one in memory.
(use-package transient :straight t :demand t)
(require 'transient)

;;; Weekly auto-update WITH a version-controlled lockfile ("best of both").
;; Riding bleeding-edge git (straight-pull-all weekly) stays hands-off, but
;; every update first freezes the CURRENT (known-good, already-booted)
;; package commits into a lockfile kept IN this repo and commits it. That
;; buys reproducibility (a fresh clone can `pmd/straight-rollback' to a
;; known-good set), a dated git history of package versions, and per-week
;; revertability, without giving up the automatic refresh. Commits are
;; LOCAL (no auto-push); push emacs-config when you next work in it.
(defvar pmd/emacs-config-dir
  (file-name-directory (file-truename user-init-file))
  "The emacs-config git repo (init.el is symlinked into ~/.emacs.d/).")

(defvar pmd/straight-lockfile
  (expand-file-name "straight-lockfile.el" pmd/emacs-config-dir)
  "Version-controlled copy of straight's version lockfile.")

(defun pmd/straight-snapshot (&optional label)
  "Freeze straight package versions, mirror the lockfile into emacs-config,
and commit it locally if it changed. LABEL tags the commit message. Run
interactively anytime to capture the current versions (e.g. to seed it)."
  (interactive)
  (straight-freeze-versions t)
  (let ((generated (expand-file-name "straight/versions/default.el"
                                     user-emacs-directory))
        (default-directory pmd/emacs-config-dir))
    (when (file-exists-p generated)
      (copy-file generated pmd/straight-lockfile t)
      (call-process "git" nil nil nil "add" "straight-lockfile.el")
      ;; Commit only when the lockfile actually changed, and only that
      ;; path, so a background snapshot never sweeps up unrelated edits.
      (when (/= 0 (call-process "git" nil nil nil
                                "diff" "--cached" "--quiet"
                                "--" "straight-lockfile.el"))
        (call-process "git" nil nil nil "commit" "-m"
                      (format "straight: package lockfile %s%s"
                              (format-time-string "%Y-%m-%d")
                              (if label (concat " (" label ")") ""))
                      "--" "straight-lockfile.el")
        (message "straight.el: lockfile committed to emacs-config.")))))

(defun pmd/straight-rollback ()
  "Restore packages to the committed lockfile, then thaw. Run after a bad
update and restart Emacs. To go further back, first
`git checkout <older-commit> -- straight-lockfile.el' in emacs-config."
  (interactive)
  (copy-file pmd/straight-lockfile
             (expand-file-name "straight/versions/default.el"
                               user-emacs-directory)
             t)
  (straight-thaw-versions)
  (message "Rolled back to lockfile. Restart Emacs to load the pinned versions."))

(defun pmd/straight-weekly-update ()
  "If 7+ days since the last run: commit the current known-good versions,
then pull all packages to latest. The pre-pull snapshot is a
guaranteed-startable rollback point (see `pmd/straight-rollback')."
  (let ((timestamp-file (expand-file-name "straight-last-update"
                                          user-emacs-directory)))
    (when (or (not (file-exists-p timestamp-file))
              (> (float-time (time-subtract (current-time)
                                            (nth 5 (file-attributes timestamp-file))))
                 (* 7 24 60 60)))
      (message "straight.el: weekly update started...")
      ;; Snapshot + commit the versions Emacs booted with this session
      ;; (known-good), THEN move to latest. If the pull breaks things, the
      ;; committed lockfile is a state that definitely worked.
      (pmd/straight-snapshot "pre-update known-good")
      (straight-pull-all)
      (straight-rebuild-all)
      (with-temp-file timestamp-file
        (insert (format-time-string "%Y-%m-%d %H:%M:%S")))
      (message "straight.el: weekly update complete."))))

(run-with-idle-timer 30 nil #'pmd/straight-weekly-update)

;;; ============================================================================
;;; exec-path (important for macOS)
;;; ============================================================================

(use-package exec-path-from-shell
  :if (memq window-system '(mac ns x))
  :config
  (exec-path-from-shell-initialize)
  ;; Copy named Anthropic keys from ~/.secure_env_vars so they are available
  ;; in the Emacs environment for subprocesses that explicitly need API
  ;; billing (e.g., a future gptel setup, custom API scripts).
  ;;
  ;; IMPORTANT: do NOT alias one of these as `ANTHROPIC_API_KEY' by default.
  ;; The `claude' CLI prefers `ANTHROPIC_API_KEY' over the claude.ai session
  ;; token, which silently switches `claude-code-ide' from the Max-plan
  ;; subscription to per-token API billing. Set the alias only inside the
  ;; specific subprocess that needs it, e.g.:
  ;;
  ;;   (let ((process-environment
  ;;          (cons (concat "ANTHROPIC_API_KEY="
  ;;                        (getenv "ANTHROPIC_API_KEY_PEDRO"))
  ;;                process-environment)))
  ;;     (call-process ...))
  (dolist (var '("ANTHROPIC_API_KEY_PEDRO" "ANTHROPIC_API_KEY_TALLYFOR"))
    (exec-path-from-shell-copy-env var)))

;;; ============================================================================
;;; UI packages
;;; ============================================================================

(use-package nerd-icons
  :if (display-graphic-p))

(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :custom ((doom-modeline-height 15)
           (doom-modeline-icon t)
           (doom-modeline-major-mode-icon t)))

(use-package doom-themes
  :config
  ;; doom-flatwhite: warm paper-white, low-contrast light theme. Whitey
  ;; and easy on the eyes, and it echoes the Le Day Club off-white brand
  ;; (#fbfaf6) rather than a stark clinical pure-white.
  (load-theme 'doom-flatwhite t)
  (doom-themes-org-config))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package which-key
  :init (which-key-mode)
  :diminish which-key-mode
  :config
  (setq which-key-idle-delay 5))

;;; ============================================================================
;;; Ivy, Counsel, Swiper
;;; ============================================================================

(use-package ivy
  :diminish
  :bind (("C-s" . swiper)
         :map ivy-minibuffer-map
         ("C-l" . ivy-alt-done)
         ("C-j" . ivy-next-line)
         ("C-k" . kill-line)
         :map ivy-switch-buffer-map
         ("C-k" . ivy-previous-line)
         ("C-l" . ivy-done)
         ("C-d" . ivy-switch-buffer-kill)
         :map ivy-reverse-i-search-map
         ("C-k" . ivy-previous-line)
         ("C-d" . ivy-reverse-i-search-kill))
  :config
  (ivy-mode 1))

(use-package swiper)

(use-package ivy-rich
  :after counsel
  :init (ivy-rich-mode 1))

(use-package ivy-prescient
  :after ivy
  :init (ivy-prescient-mode 1))

(use-package counsel
  :bind (("M-x" . counsel-M-x)
         ("C-x C-b" . counsel-ibuffer)
         ("C-x C-f" . counsel-find-file)
         ("C-x b" . counsel-switch-buffer)
         :map minibuffer-local-map
         ("C-r" . counsel-minibuffer-history)))

;; Fix counsel-rg with ivy-prescient
(setq ivy-re-builders-alist '((counsel-rg . ivy--regex-plus)
                              (t . ivy-prescient-re-builder)))

;;; ============================================================================
;;; Helpful
;;; ============================================================================

(use-package helpful
  :custom
  (counsel-describe-function-function #'helpful-callable)
  (counsel-describe-variable-function #'helpful-variable)
  :bind
  ([remap describe-function] . counsel-describe-function)
  ([remap describe-command] . helpful-command)
  ([remap describe-variable] . counsel-describe-variable)
  ([remap describe-key] . helpful-key))

;;; ============================================================================
;;; General and Hydra
;;; ============================================================================

(use-package hydra)

(defhydra hydra-text-scale (:timeout 4)
  "Scale text."
  ("j" text-scale-increase "in")
  ("k" text-scale-decrease "out")
  ("f" nil "finished" :exit t))

(defhydra window-scale (:timeout 4)
  "Enlarge or shrink window size."
  ("j" enlarge-window "enlarge")
  ("k" shrink-window "shrink")
  ("f" nil "finished" :exit t))

;;; ============================================================================
;;; Projectile
;;; ============================================================================

(use-package projectile
  :diminish projectile-mode
  :config (projectile-mode)
  :custom ((projectile-completion-system 'ivy))
  :bind-keymap
  ("C-c p" . projectile-command-map)
  :init
  (when (file-directory-p "~/projects")
    (setq projectile-project-search-path '("~/projects")))
  (setq projectile-switch-project-action #'projectile-dired))

(use-package counsel-projectile
  :config (counsel-projectile-mode))

;;; ============================================================================
;;; Magit
;;; ============================================================================

(use-package magit
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)
  :hook ((git-commit-setup . git-commit-turn-on-flyspell)))

;;; ============================================================================
;;; Org-mode
;;; ============================================================================

(use-package org
  :config
  (setq org-latex-pdf-process
        '("pdflatex -interaction nonstopmode -output-directory %o %f"
          "pdflatex -interaction nonstopmode -output-directory %o %f"
          "pdflatex -interaction nonstopmode -output-directory %o %f"))
  (setq org-ellipsis " ▾"))

(dolist (face '((org-level-1 . 1.2)
                (org-level-2 . 1.1)
                (org-level-3 . 1.05)
                (org-level-4 . 1.0)
                (org-level-5 . 1.1)
                (org-level-6 . 1.1)
                (org-level-7 . 1.1)
                (org-level-8 . 1.1)))
  (set-face-attribute (car face) nil :font "Cantarell" :weight 'regular :height (cdr face)))

(use-package org-bullets
  :after org
  :hook (org-mode . org-bullets-mode)
  :custom
  (org-bullets-bullet-list '("◉" "○" "●" "○" "●" "○" "●")))

(use-package visual-fill-column
  :hook (org-mode . (lambda ()
                      (setq visual-fill-column-width 100
                            visual-fill-column-center-text t)
                      (visual-fill-column-mode 1))))

(use-package org-make-toc)

(use-package org-drill)

(use-package ox-gfm)

(defun pmd/org-export-pdf-and-open ()
  "Export current org buffer to PDF and open it."
  (interactive)
  (org-latex-export-to-pdf nil nil nil nil nil)
  (let ((pdf (concat (file-name-sans-extension (buffer-file-name)) ".pdf")))
    (start-process "open-pdf" nil "open" pdf)))

(defhydra hydra-org-export (:exit t)
  "Org Export"
  ("p" pmd/org-export-pdf-and-open "PDF & preview")
  ("l" org-latex-export-to-pdf "PDF (no preview)")
  ("h" org-html-export-to-browser "HTML in browser")
  ("q" nil "quit"))

(with-eval-after-load 'org
  (define-key org-mode-map (kbd "C-c e") 'hydra-org-export/body))

;;; ============================================================================
;;; PDF viewing
;;; ============================================================================

(use-package pdf-tools
  :mode ("\\.pdf\\'" . pdf-view-mode)
  :config
  (pdf-tools-install :no-query))

(use-package image-roll
  :straight (:host github :repo "dalanicolai/image-roll.el")
  :after pdf-tools
  :hook (pdf-view-mode . pdf-view-roll-minor-mode))

;;; ============================================================================
;;; Terminal emulators
;;; ============================================================================

(use-package term
  :config
  (setq explicit-shell-file-name "bash")
  (setq term-prompt-regexp "^[^#$%>\n]*[#$%>] *"))

;; vterm is the "real terminal" for TUIs (libvterm, same engine as NeoVim's
;; terminal). Box-drawing/arrow glyphs render correctly because the default
;; font is Menlo (see top of file): with the old Monaco fallback those glyphs
;; came from a different-width font and broke vterm's cell math.
(use-package vterm
  :commands vterm
  :config
  (setq vterm-max-scrollback 10000)
  ;; Force a TERM value Claude Code recognizes as a full TUI terminal
  ;; (so it engages the alternate screen instead of streaming frames
  ;; into scrollback, which causes duplicate "Pouncing..." status lines).
  (setq vterm-term-environment-variable "xterm-256color"))

(use-package eat
  :commands eat
  :hook (eat-mode . (lambda ()
                      (setq-local cursor-in-non-selected-windows nil)))
  :config
  ;; Force programs in eat (Claude Code, etc.) to emit 256-color, not 24-bit
  ;; truecolor. With truecolor, programs send raw RGB escapes that bypass
  ;; the palette below, so we lose theme control over diff/UI colors.
  (setq eat-term-name "xterm-256color")

  ;; Palette tuned for doom-one's dark bg (~#282c34).
  (set-face-attribute 'eat-term-color-1  nil :foreground "#ff6c6b")  ; red
  (set-face-attribute 'eat-term-color-2  nil :foreground "#98be65")  ; green
  (set-face-attribute 'eat-term-color-3  nil :foreground "#ECBE7B")  ; yellow
  (set-face-attribute 'eat-term-color-4  nil :foreground "#51afef")  ; blue
  (set-face-attribute 'eat-term-color-5  nil :foreground "#c678dd")  ; magenta
  (set-face-attribute 'eat-term-color-6  nil :foreground "#46D9FF")  ; cyan
  (set-face-attribute 'eat-term-color-9  nil :foreground "#ff7b72")  ; bright red
  (set-face-attribute 'eat-term-color-10 nil :foreground "#a3d977")  ; bright green
  (set-face-attribute 'eat-term-color-11 nil :foreground "#f7d27a")  ; bright yellow
  (set-face-attribute 'eat-term-color-12 nil :foreground "#6cc8ff")  ; bright blue
  (set-face-attribute 'eat-term-color-13 nil :foreground "#d885e8")  ; bright magenta
  (set-face-attribute 'eat-term-color-14 nil :foreground "#5ee0ff")  ; bright cyan

  ;; Force the eat terminal to repaint by toggling a window split.
  ;; Useful when the Claude Code TUI gets visually corrupted (stale
  ;; characters, mis-wrapped lines after a resize) without losing the
  ;; underlying process. Bound to C-c r in eat-semi-char-mode-map.
  (defun pmd/eat-redraw ()
    "Force the eat terminal in this buffer to repaint."
    (interactive)
    (split-window-below)
    (delete-other-windows))
  (define-key eat-semi-char-mode-map (kbd "C-c r") #'pmd/eat-redraw))

(defun pmd/configure-eshell ()
  (add-hook 'eshell-pre-command-hook 'eshell-save-some-history)
  (add-to-list 'eshell-output-filter-functions 'eshell-truncate-buffer)
  (setq eshell-history-size         10000
        eshell-buffer-maximum-lines 10000
        eshell-hist-ignoredups t
        eshell-scroll-to-bottom-on-input t))

(use-package eshell-git-prompt)

(use-package eshell
  :hook (eshell-first-time-mode . pmd/configure-eshell)
  :config
  (with-eval-after-load 'esh-opt
    (setq eshell-destroy-buffer-when-process-dies t)
    (setq eshell-visual-commands '("htop" "zsh" "vim")))
  (eshell-git-prompt-use-theme 'powerline))

;; Term tab completion
(defun term-send-tab ()
  "Send tab in term line mode for auto-completion."
  (interactive)
  (let ((term-state (term-in-line-mode)))
    (when term-state (term-char-mode))
    (term-send-raw-string "\t")
    (when term-state (term-line-mode))))

(add-hook 'term-mode-hook
          (lambda ()
            (define-key term-mode-map (kbd "TAB") #'term-send-tab)))

;;; ============================================================================
;;; Claude Code IDE (run Claude inside Emacs, vterm backend)
;;; ============================================================================

(use-package claude-code-ide
  :straight (:type git :host github :repo "manzaltu/claude-code-ide.el")
  :bind (("C-c C-'" . claude-code-ide-menu)
         ("C-c RET" . claude-code-ide-send-prompt))
  :config
  (setq claude-code-ide-terminal-backend 'vterm)
  (setq claude-code-ide-diagnostics-backend 'flycheck)
  (setq claude-code-ide-window-side 'bottom)
  (setq claude-code-ide-window-height 28)
  (claude-code-ide-emacs-tools-setup)

  ;; Optional: redirect printable keystrokes to the send-prompt minibuffer.
  ;; Disabled by default — auto-enabling it caused point to drift off the
  ;; vterm process mark on every keystroke (each redirect opens a recursive
  ;; minibuffer), which made vterm stop auto-scrolling and the buffer appear
  ;; "stuck" on stale content. Type directly into vterm instead, and use
  ;; `C-c RET' (claude-code-ide-send-prompt) when you want a structured prompt.
  ;; The minor mode is left defined so it can still be toggled on manually
  ;; via `M-x pmd/claude-code-redirect-mode' if you want to experiment.
  (defun pmd/claude-code-redirect-to-prompt ()
    "Open send-prompt with the typed character as initial input."
    (interactive)
    (let ((char (string last-command-event)))
      (claude-code-ide-send-prompt
       (read-string "Claude prompt: " char))))

  (defvar pmd/claude-code-redirect-mode-map
    (let ((map (make-sparse-keymap)))
      (dolist (c (number-sequence ?  ?~))
        (unless (= c ?/)
          (define-key map (string c) #'pmd/claude-code-redirect-to-prompt)))
      map)
    "Keymap active when `pmd/claude-code-redirect-mode' is on.")

  (define-minor-mode pmd/claude-code-redirect-mode
    "Redirect printable keys to claude-code-ide-send-prompt."
    :lighter nil
    :keymap pmd/claude-code-redirect-mode-map))

(defun pmd/claude-code-toggle-copy-mode ()
  "Toggle vterm-copy-mode in the current Claude Code buffer."
  (interactive)
  (vterm-copy-mode 'toggle))

;; Free mouse scroll in vterm: wheel-up auto-enters copy-mode,
;; wheel-down auto-exits when back at the bottom of the buffer.
(with-eval-after-load 'vterm
  (defun pmd/vterm-mouse-scroll-up (event)
    "Wheel up: enter `vterm-copy-mode' if needed, then scroll."
    (interactive "e")
    (unless vterm-copy-mode (vterm-copy-mode 1))
    (mwheel-scroll event))

  (defun pmd/vterm-mouse-scroll-down (event)
    "Wheel down: scroll; if back at bottom, exit `vterm-copy-mode'."
    (interactive "e")
    (if vterm-copy-mode
        (progn (mwheel-scroll event)
               (when (eobp) (vterm-copy-mode -1)))
      (mwheel-scroll event)))

  (dolist (ev '([wheel-up] [double-wheel-up] [triple-wheel-up]))
    (define-key vterm-mode-map ev #'pmd/vterm-mouse-scroll-up))
  (dolist (ev '([wheel-down] [double-wheel-down] [triple-wheel-down]))
    (define-key vterm-mode-map ev #'pmd/vterm-mouse-scroll-down))

  ;; Redraw a garbled vterm/Claude buffer. Two layers: `redraw-display'
  ;; repaints Emacs's frame, then C-l is sent into the child process so a
  ;; full-screen TUI (claude-code) repaints itself from scratch. Bound to
  ;; C-c r to match the old eat-backend muscle memory (pmd/eat-redraw).
  ;; Note: if garble persists, the buffer predates a font change and its
  ;; vterm cell geometry is stale, kill it and reopen claude-code (or
  ;; restart Emacs) so the new buffer sizes itself to the current font.
  (defun pmd/vterm-redraw ()
    "Repaint this vterm buffer and tell the TUI inside it to redraw."
    (interactive)
    (redraw-display)
    (when (derived-mode-p 'vterm-mode)
      (vterm-send-key "l" nil nil t)))
  (define-key vterm-mode-map (kbd "C-c r") #'pmd/vterm-redraw))

;;; ============================================================================
;;; Claude transcript viewer (read-only)
;;; ============================================================================
;; Complement to claude-code-ide: `pmd/tail-transcript' renders the current
;; project's newest session JSONL to one readable Org file and auto-reverts it
;; as the chat grows — works whether the session runs in Emacs (vterm) or
;; iTerm2. One command, one file, one timer. Nothing auto-starts.

(defvar pmd/transcript-script
  (expand-file-name "~/.claude/bin/render-transcript.py")
  "Python renderer: a session's JSONL -> readable Org.")

(defvar pmd/transcript-timer nil
  "Active re-render timer for `pmd/tail-transcript' (only one at a time).")

(defun pmd/claude-project-dir (&optional dir)
  "Return the ~/.claude/projects/ dir for DIR (default `default-directory')."
  (let ((slug (replace-regexp-in-string
               "/" "-" (directory-file-name
                        (expand-file-name (or dir default-directory))))))
    (expand-file-name slug "~/.claude/projects/")))

(defun pmd/newest-session-jsonl (&optional dir)
  "Return the most recently modified session .jsonl for DIR's project."
  (let* ((pdir (pmd/claude-project-dir dir))
         (files (and (file-directory-p pdir)
                     (directory-files pdir t "\\.jsonl\\'"))))
    (car (sort files (lambda (a b)
                       (time-less-p (nth 5 (file-attributes b))
                                    (nth 5 (file-attributes a))))))))

(defun pmd/transcript-show-all ()
  "Expand the whole transcript buffer (Org-version agnostic)."
  (if (fboundp 'org-fold-show-all) (org-fold-show-all) (org-show-all)))

(defun pmd/tail-transcript (&optional no-select)
  "Render this project's newest Claude session to ~/<project>-claude.org and tail it.
Reads the session's on-disk JSONL (works whether Claude runs in an Emacs vterm
or in iTerm2), re-renders every 3s so the file grows as you chat, and keeps the
Org fully expanded so it reads top-to-bottom. `pmd/tail-transcript-stop' (C-c c k)
stops it. With NO-SELECT (used by the auto-start hook) the buffer is shown
without stealing focus from the Claude window."
  (interactive)
  (let* ((proj-dir default-directory)
         (jsonl (pmd/newest-session-jsonl proj-dir)))
    (unless jsonl
      (user-error "No Claude session .jsonl found for this project"))
    (let* ((txt (expand-file-name
                 (format "~/%s-claude.org"
                         (file-name-nondirectory
                          (directory-file-name proj-dir)))))
           (_ (call-process "python3" nil nil nil pmd/transcript-script jsonl txt))
           (buf (find-file-noselect txt)))
      (with-current-buffer buf
        (auto-revert-mode 1)
        ;; Keep the transcript fully expanded across every 3s refresh so it
        ;; reads top-to-bottom (the old startup-visibility hook re-folded it
        ;; on every revert, which fought the reader).
        (remove-hook 'after-revert-hook #'org-set-startup-visibility t)
        (add-hook 'after-revert-hook #'pmd/transcript-show-all nil t)
        (pmd/transcript-show-all)
        (pmd/transcript-goto-last))
      (if no-select
          (display-buffer buf)
        (pop-to-buffer-same-window buf))
      (when (timerp pmd/transcript-timer) (cancel-timer pmd/transcript-timer))
      (setq pmd/transcript-timer
            (run-at-time 3 3 (lambda ()
                               (call-process "python3" nil nil nil
                                             pmd/transcript-script jsonl txt))))
      (message "Tailing -> %s  (C-c c k to stop)" txt))))

(defun pmd/transcript-goto-last ()
  "Put point on the newest conversation (last top-level heading)."
  (goto-char (point-max))
  (when (re-search-backward "^\\* " nil t)
    ;; `recenter' errors if this buffer is not in the selected window
    ;; (the no-select / auto-start path), so make it best-effort.
    (ignore-errors (recenter 0))))

(defun pmd/tail-transcript-stop ()
  "Stop the `pmd/tail-transcript' re-render timer."
  (interactive)
  (when (timerp pmd/transcript-timer)
    (cancel-timer pmd/transcript-timer)
    (setq pmd/transcript-timer nil))
  (message "Transcript tailing stopped"))

;; --- Auto-start the transcript tail when a Claude session opens in Emacs ---
(defvar pmd/claude-auto-tail t
  "When non-nil, auto-start the Org transcript tail whenever a Claude Code
session opens in Emacs (see `pmd/tail-transcript'). Set to nil to disable.")

(defun pmd/claude-auto-tail-maybe (&rest _)
  "Auto-start `pmd/tail-transcript' after a Claude Code session opens.
Captures the project dir now, waits for the new session's JSONL to hit disk,
then tails it without stealing focus from the Claude window."
  (when pmd/claude-auto-tail
    (let ((proj default-directory))
      (run-at-time
       2.5 nil
       (lambda ()
         (let ((default-directory proj))
           (when (ignore-errors (pmd/newest-session-jsonl proj))
             (save-selected-window
               (ignore-errors (pmd/tail-transcript 'no-select))))))))))

;; claude-code-ide's `claude-code-ide' / -continue / -resume all funnel through
;; this internal starter, so advising it covers every entry point.
(with-eval-after-load 'claude-code-ide
  (advice-add 'claude-code-ide--start-session :after #'pmd/claude-auto-tail-maybe))


(defun pmd/claude-region (start end)
  "Send the active region (or whole buffer) to `claude --print'.
Inserts the response below the region as a fenced block.
Asynchronous; non-blocking. Uses `ANTHROPIC_API_KEY' from the
environment (set via init.el to `ANTHROPIC_API_KEY_PEDRO' by default).

Use cases: explain code, translate prose, summarize an org subtree,
\"what's wrong with this regex,\" etc. — without spinning up a full
claude-code-ide session."
  (interactive
   (if (use-region-p)
       (list (region-beginning) (region-end))
     (list (point-min) (point-max))))
  (unless (executable-find "claude")
    (user-error "`claude' CLI not on PATH; install Claude Code"))
  (let* ((prompt (buffer-substring-no-properties start end))
         (origin-buf (current-buffer))
         (anchor (with-current-buffer origin-buf
                   (save-excursion
                     (goto-char end)
                     (end-of-line)
                     (insert "\n\n--- Claude (running...) ---\n")
                     (point-marker)))))
    (set-marker-insertion-type anchor t)
    (make-process
     :name "pmd-claude-region"
     :buffer (generate-new-buffer " *pmd-claude-region*")
     :command (list "claude" "--print" prompt)
     :sentinel
     (lambda (proc _event)
       (when (memq (process-status proc) '(exit signal))
         (let* ((status (process-exit-status proc))
                (out (with-current-buffer (process-buffer proc)
                       (buffer-string)))
                (origin (marker-buffer anchor)))
           (when (buffer-live-p origin)
             (with-current-buffer origin
               (save-excursion
                 (goto-char anchor)
                 (forward-line -1)
                 (delete-region (line-beginning-position) (line-end-position))
                 (insert (if (zerop status)
                             "--- Claude ---"
                           (format "--- Claude (exit %d) ---" status)))
                 (goto-char anchor)
                 (insert (string-trim out) "\n--- end ---\n"))))
           (kill-buffer (process-buffer proc))
           (set-marker anchor nil)
           (message "[pmd/claude-region] %s"
                    (if (zerop status) "done" "failed"))))))
    (message "[pmd/claude-region] sent %d chars to claude --print"
             (- end start))))

(defhydra hydra-claude (:exit t)
  "Claude Code"
  ("o" claude-code-ide "open/start")
  ("s" claude-code-ide-send-prompt "send prompt")
  ("t" claude-code-ide-toggle "toggle window")
  ("y" pmd/claude-code-toggle-copy-mode "toggle copy mode")
  ("m" claude-code-ide-insert-at-mentioned "send selection")
  ("c" claude-code-ide-continue "continue")
  ("r" claude-code-ide-resume "resume")
  ("p" pmd/claude-region "ask region (claude --print, inline)")
  ("l" pmd/tail-transcript "tail transcript (org)")
  ("k" pmd/tail-transcript-stop "stop tailing")
  ("q" nil "quit"))

(global-set-key (kbd "C-c c") 'hydra-claude/body)
;; Direct one-key shortcut for the transcript viewer (no hydra hop needed).
(global-set-key (kbd "C-c t") #'pmd/tail-transcript)

;;; ============================================================================
;;; Paredit
;;; ============================================================================

(use-package paredit
  :hook ((emacs-lisp-mode . enable-paredit-mode)
         (eval-expression-minibuffer-setup . enable-paredit-mode)
         (ielm-mode . enable-paredit-mode)
         (lisp-mode . enable-paredit-mode)
         (lisp-interaction-mode . enable-paredit-mode)
         (scheme-mode . enable-paredit-mode)
         (slime-repl-mode . enable-paredit-mode)
         (clojure-mode . enable-paredit-mode)
         (clojurescript-mode . enable-paredit-mode)
         (cider-repl-mode . enable-paredit-mode)
         (cider-mode . enable-paredit-mode))
  :config
  (show-paren-mode t)
  :bind (("C->" . paredit-forward-slurp-sexp)
         ("C-<" . paredit-forward-barf-sexp)
         ("C-M-<" . paredit-backward-slurp-sexp)
         ("C-M->" . paredit-backward-barf-sexp)
         ("M-[" . paredit-wrap-square)
         ("M-{" . paredit-wrap-curly)))

;;; ============================================================================
;;; Clojure
;;; ============================================================================

(use-package clojure-mode
  :after flycheck-clj-kondo)

(use-package cider
  :config
  (setq cider-use-overlays nil)
  (setq cider-repl-use-pretty-printing t)
  (setq cider-print-fn 'pprint))

(use-package clj-refactor
  :hook (clojure-mode . clj-refactor-mode)
  :bind ("C-c C-m" . cljr-add-keybindings-with-prefix))

(customize-set-variable 'cider-shadow-cljs-command "shadow-cljs")

;;; ============================================================================
;;; JavaScript
;;; ============================================================================

(setq js-indent-level 2)

(use-package js2-mode
  :hook (js2-mode . js2-imenu-extras-mode)
  :init
  (add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode)))

(use-package js2-refactor)

(use-package xref-js2)

;;; ============================================================================
;;; LSP
;;; ============================================================================

(use-package lsp-mode
  :hook ((clojure-mode . lsp)
         (clojurescript-mode . lsp))
  :commands lsp)

;;; ============================================================================
;;; Flycheck
;;; ============================================================================

(use-package flycheck
  :init (global-flycheck-mode))

(use-package flycheck-clj-kondo)

(flycheck-define-checker clojure-edn
  "A syntax checker for EDN files using Clojure CLI."
  :command ("clojure" "-e"
            "(try (clojure.edn/read-string (slurp \"" source "\"))
                   (println \"EDN is valid.\")
                   (catch Exception e
                     (println \"Invalid EDN:\" (.getMessage e))
                     (System/exit 1)))")
  :error-patterns
  ((warning line-start (message "Invalid EDN:") (id (one-or-more not-newline)) line-end))
  :modes edn-mode)

(add-to-list 'flycheck-checkers 'clojure-edn)

;;; ============================================================================
;;; Other languages and modes
;;; ============================================================================

(use-package markdown-mode
  :mode ("README\\.md\\'" . gfm-mode)
  :init (setq markdown-command "multimarkdown"))

(use-package yaml-mode)

(use-package restclient
  :mode ("\\.http\\'" . restclient-mode))

(use-package auctex
  :defer t
  :mode ("\\.tex\\'" . LaTeX-mode)
  :config
  (setq TeX-auto-save t
        TeX-parse-self t
        TeX-master nil)
  (add-hook 'LaTeX-mode-hook 'turn-on-reftex)
  (setq reftex-plug-into-AUCTeX t))

;;; ============================================================================
;;; Utility packages
;;; ============================================================================

(use-package ace-window)

(use-package transpose-frame)

(use-package wrap-region
  :config
  (wrap-region-add-wrapper "*" "*")
  (wrap-region-add-wrapper "/" "/")
  (wrap-region-add-wrapper "=" "="))

(use-package speed-type)

(use-package clipmon)

;;; ============================================================================
;;; WakaTime (load API key from file)
;;; ============================================================================

(use-package wakatime-mode
  :if (executable-find "wakatime-cli")
  :init
  (setq wakatime-api-key
        (let ((key-file "~/.wakatime-key"))
          (when (file-exists-p key-file)
            (string-trim (with-temp-buffer
                           (insert-file-contents key-file)
                           (buffer-string))))))
  :config
  (global-wakatime-mode))


;;; ============================================================================
;;; Centered point mode
;;; ============================================================================

(defun pmd/line-change ()
  (when (and (eq (get-buffer-window) (selected-window))
             (not (derived-mode-p 'eat-mode))
             (not (derived-mode-p 'vterm-mode))
             (not (string= (buffer-name) "*claude-config*")))
    (recenter)))

(define-minor-mode centered-point-mode
  "Always center the cursor in the middle of the screen."
  :lighter " center"
  (if centered-point-mode
      (add-hook 'post-command-hook 'pmd/line-change)
    (remove-hook 'post-command-hook 'pmd/line-change)))

(centered-point-mode t)

;;; ============================================================================
;;; Custom keybindings
;;; ============================================================================

(global-set-key (kbd "C-x C-M-b") 'bookmark-jump)
(global-set-key (kbd "C-x C-M-r") 'revert-buffer)
(global-set-key (kbd "M-]") 'dabbrev-expand)
(global-set-key (kbd "C-x M-p") 'org-table-move-row-up)

;;; ============================================================================
;;; Custom functions
;;; ============================================================================

;; Clipboard helpers
(defun pmd/clipboard-copy-full-path ()
  "Copy the full path of the current buffer's file to the clipboard."
  (interactive)
  (let ((filename (if (equal major-mode 'dired-mode)
                      default-directory
                    (buffer-file-name))))
    (when filename
      (kill-new filename)
      (message "Copied full path '%s' to the clipboard." filename))))

(defun pmd/clipboard-copy-file-name ()
  "Copy the file name (without path) to the clipboard."
  (interactive)
  (let ((filename (if (equal major-mode 'dired-mode)
                      (file-name-nondirectory (directory-file-name default-directory))
                    (file-name-nondirectory (buffer-file-name)))))
    (when filename
      (kill-new filename)
      (message "Copied file name '%s' to the clipboard." filename))))

;; Org-mode helpers
(defun pmd/org-clock-sum-current-region (beg end)
  "Sum the total amount of time in the marked region."
  (interactive "r")
  (let ((s (buffer-substring-no-properties beg end)))
    (with-temp-buffer
      (insert "* foo\n")
      (insert s)
      (org-clock-sum)
      (message (format "%d" org-clock-file-total-minutes)))))

(defun pmd/org-table-current-cell-location ()
  "Display the current Org table cell location as @row$column."
  (interactive)
  (let* ((pos (org-table-current-dline))
         (col (org-table-current-column)))
    (message "@%d$%d" pos col)))

;; Markdown to org conversion
(defun pmd/markdown-convert-buffer-to-org ()
  "Convert the current buffer from markdown to org format."
  (interactive)
  (shell-command-on-region (point-min) (point-max)
                           (format "pandoc -f markdown -t org -o %s"
                                   (concat (file-name-sans-extension (buffer-file-name)) ".org"))))

;; DOS line ending removal
(defun pmd/remove-dos-eol ()
  "Replace DOS eolns CRLF with Unix eolns CR."
  (interactive)
  (goto-char (point-min))
  (while (search-forward "\r" nil t)
    (replace-match "")))

;; Align helper
(defun pmd/align-repeat (start end regexp &optional justify-right after)
  "Repeat alignment with respect to the given regular expression."
  (interactive "r\nsAlign regexp: ")
  (let* ((ws-regexp (if (string-empty-p regexp)
                        "\\(\\s-+\\)"
                      "\\(\\s-*\\)"))
         (complete-regexp (if after
                              (concat regexp ws-regexp)
                            (concat ws-regexp regexp)))
         (group (if justify-right -1 1)))
    (unless (use-region-p)
      (save-excursion
        (while (and
                (string-match-p complete-regexp (thing-at-point 'line))
                (= 0 (forward-line -1)))
          (setq start (point-at-bol))))
      (save-excursion
        (while (and
                (string-match-p complete-regexp (thing-at-point 'line))
                (= 0 (forward-line 1)))
          (setq end (point-at-eol)))))
    (align-regexp start end complete-regexp group 1 t)))

;;; ============================================================================
;;; Server (for Emacs Anywhere, etc.)
;;; ============================================================================

(add-hook 'after-init-hook #'server-start)

;;; ============================================================================
;;; Startup time display
;;; ============================================================================

(defun pmd/display-startup-time ()
  (message "Emacs loaded in %s with %d garbage collections."
           (format "%.2f seconds"
                   (float-time
                    (time-subtract after-init-time before-init-time)))
           gcs-done))

(add-hook 'emacs-startup-hook #'pmd/display-startup-time)

;; Reset GC threshold after startup
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 50 1000 1000))))

;;; ============================================================================
;;; Enable disabled commands
;;; ============================================================================

(put 'narrow-to-region 'disabled nil)
(put 'set-goal-column 'disabled nil)
(put 'downcase-region 'disabled nil)

;;; init.el ends here
(put 'dired-find-alternate-file 'disabled nil)
