;;; lisp/init.el -*- lexical-binding: t; -*-
;;; Commentary:
;;
;; :doom is now treated like a normal module, and this is its (temporary) init
;; file, which will be removed once we've resolved our `use-package' dependency
;; (which will soon be moved to its own module), then these will be returned to
;; the profile init file.
;;
;;; Code:

(doom-require 'doom-keybinds)
(doom-require 'doom-ui)
(doom-require 'doom-projects)
(doom-require 'doom-editor)

;; Ensure .dir-locals.el in $EMACSDIR and $DOOMDIR are always respected
(add-to-list 'safe-local-variable-directories doom-emacs-dir)
(add-to-list 'safe-local-variable-directories doom-user-dir)

;;; Support for Doom-specific file extensions
(add-to-list 'auto-mode-alist '("/\\.doom\\(?:project\\|module\\|profile\\)?\\'" . lisp-data-mode))
(add-to-list 'auto-mode-alist '("/\\.doomrc\\'" . emacs-lisp-mode))

(add-hook 'evil-mode-hook
          (lambda ()
            (define-key evil-normal-state-map (kbd "w") 'ace-window)
            (define-key evil-normal-state-map (kbd "q") 'evil-delete-buffer)
            (define-key evil-normal-state-map (kbd "<f2>") 'save-buffer)
            (define-key evil-insert-state-map (kbd "<f2>") 'save-buffer)
            (define-key evil-normal-state-map (kbd "fd") 'xref-find-definitions)
            (define-key evil-normal-state-map (kbd "fr") 'xref-find-references)
            (define-key evil-normal-state-map (kbd "ff") 'project-find-file)
            (define-key evil-normal-state-map (kbd "ft") 'consult-ripgrep)
            (define-key evil-normal-state-map (kbd "fb") 'pop-tag-mark)
            ))
(require 'aweshell)

(global-set-key (kbd "M-y") 'evil-yank-line)
(global-set-key (kbd "M-p") 'evil-paste-after)

;(require ‘xcscope)
(cscope-setup)

(use-package lsp-mode
  :hook ((c-mode          ; clangd
          c++-mode        ; clangd
          c-or-c++-mode   ; clangd
          ) . lsp)
  :commands lsp
  :config
  (setq lsp-auto-guess-root t)
  (setq lsp-diagnostic-package :none)
  (setq lsp-enable-symbol-highlighting nil)
  (setq lsp-enable-on-type-formatting nil)
  (setq lsp-signature-auto-activate nil)
  (setq lsp-enable-folding nil)
  (setq lsp-enable-snippet nil)
  (setq lsp-enable-completion-at-point nil)
  (setq read-process-output-max (* 1024 1024)) ;; 1mb
  (setq lsp-idle-delay 0.5)
  (setq lsp-prefer-capf t)) ; prefer lsp's company-capf over company-lsp

(use-package company
  :hook (prog-mode . company-mode)
  :config
  (setq company-minimum-prefix-length 1)
  (setq company-idle-delay 0.3)
  (setq company-selection-wrap-around t)
  (setq company-tooltip-align-annotations t))
;;; init.el ends here
