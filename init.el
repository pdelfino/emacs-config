;;; init.el --- Emacs configuration -*- lexical-binding: t -*-

;; Increase GC threshold for faster startup (reset later)
(setq gc-cons-threshold (* 100 1000 1000))

;;; ============================================================================
;;; emacs-mac settings for macOS
;;; ============================================================================

;; Karabiner swaps Cmd↔Option at OS level
;; Physical Cmd → Option → Meta (for M-x, M-w, etc.)
;; Physical Option → Command → Super (disabled/passthrough)
;; Caps Lock → Control (for C-y, C-x, etc.)
(setq mac-option-modifier 'meta)
(setq mac-command-modifier nil)

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
(setq blink-cursor-mode nil)

;; Launch maximized
(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; Font size
(set-face-attribute 'default nil :height 160)
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
                vterm-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

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
      (bootstrap-version 5))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(straight-use-package 'use-package)
(setq straight-use-package-by-default t)

;;; ============================================================================
;;; exec-path (important for macOS)
;;; ============================================================================

(use-package exec-path-from-shell
  :if (memq window-system '(mac ns x))
  :config
  (exec-path-from-shell-initialize))

;;; ============================================================================
;;; UI packages
;;; ============================================================================

(use-package command-log-mode)

(use-package nerd-icons
  :if (display-graphic-p))

(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :custom ((doom-modeline-height 15)
           (doom-modeline-icon t)
           (doom-modeline-major-mode-icon t)))

(use-package spacemacs-theme
  :init (load-theme 'spacemacs-light t))

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
         ("M-y" . counsel-yank-pop)
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

(use-package general)

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

;;; ============================================================================
;;; Terminal emulators
;;; ============================================================================

(use-package term
  :config
  (setq explicit-shell-file-name "bash")
  (setq term-prompt-regexp "^[^#$%>\n]*[#$%>] *"))

(use-package vterm
  :commands vterm
  :config
  (setq term-prompt-regexp "^[^#$%>\n]*[#$%>] *")
  (setq vterm-max-scrollback 10000))

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

(global-set-key [(super return)] 'eshell)

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
;;; Claude Code IDE
;;; ============================================================================

(use-package claude-code-ide
  :straight (:type git :host github :repo "manzaltu/claude-code-ide.el")
  :bind ("C-c C-'" . claude-code-ide-menu)
  :config
  (setq claude-code-ide-terminal-backend 'vterm)
  (setq claude-code-ide-diagnostics-backend 'flycheck)
  (claude-code-ide-emacs-tools-setup))

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
  :config (clj-refactor-mode 1)
  :bind ("C-c C-m" . cljr-add-keybindings-with-prefix))

(customize-set-variable 'cider-shadow-cljs-command "shadow-cljs")

;;; ============================================================================
;;; Common Lisp / SLIME
;;; ============================================================================

(use-package slime
  :config
  (setq slime-lisp-implementations
        '((sbcl ("/Users/pedro/projects/nyxt.sh" ""))))
  (slime-setup '(slime-fancy slime-asdf slime-indentation slime-sbcl-exts slime-scratch)))

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

(use-package simple-httpd)

(use-package clipmon)

;;; ============================================================================
;;; WakaTime (load API key from file)
;;; ============================================================================

(use-package wakatime-mode
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
;;; GPTel (ChatGPT in Emacs)
;;; ============================================================================

(defun pmd/read-openai-key ()
  (with-temp-buffer
    (insert-file-contents "~/key.txt")
    (string-trim (buffer-string))))

(use-package gptel
  :init
  (setq-default gptel-model "gpt-4"
                gptel-playback t
                gptel-default-mode 'org-mode
                gptel-api-key #'pmd/read-openai-key)
  (add-hook 'gptel-post-response-functions
            (lambda (&rest _)
              (when (string= (buffer-name) "*chatGPT*")
                (visual-line-mode 1)))))

;;; ============================================================================
;;; Centered point mode
;;; ============================================================================

(defun pmd/line-change ()
  (when (eq (get-buffer-window) (selected-window))
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

;; macOS keyboard hacks (Portuguese input + US keyboard)
(defun pmd/insert-slash ()
  "Insert forward slash."
  (interactive)
  (insert "/"))
(global-set-key (kbd "C-x C-M-q") 'pmd/insert-slash)

(defun pmd/insert-backslash ()
  "Insert backslash."
  (interactive)
  (insert "\\"))

(defun pmd/insert-question-mark ()
  "Insert question mark."
  (interactive)
  (insert "?"))

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

;; Nyxt/Lisp helpers
(defun pmd/nyxt-quickload-gi-gtk ()
  "Insert snippet to load Nyxt."
  (interactive)
  (insert "(ql:quickload :nyxt/gi-gtk)"))
(global-set-key (kbd "C-x C-M-n") 'pmd/nyxt-quickload-gi-gtk)

(defun pmd/nyxt-inside-package ()
  "Insert snippet to enter the nyxt package."
  (interactive)
  (insert "(in-package :nyxt)"))
(global-set-key (kbd "C-x C-M-p") 'pmd/nyxt-inside-package)

(defun pmd/hermes-inside-package ()
  "Insert snippet to enter the hermes package."
  (interactive)
  (insert "(in-package :hermes)"))
(global-set-key (kbd "C-x C-M-h") 'pmd/hermes-inside-package)

(defun pmd/nyxt-start-package ()
  "Insert snippet to start Nyxt."
  (interactive)
  (insert "(start)"))
(global-set-key (kbd "C-x C-M-s") 'pmd/nyxt-start-package)

(defun pmd/slime-repl-back-CL-USER-package ()
  "Insert snippet to get back to the CL-USER package."
  (interactive)
  (insert "(cl:in-package :cl-user)"))

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
