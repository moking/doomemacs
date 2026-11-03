;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.


;;; Editing and navigation keys

(defun save-and-normal-mode ()
  "Save the current file and switch to normal mode."
  (interactive)
  (save-buffer)
  (evil-normal-state))

(after! evil
  (define-key evil-normal-state-map (kbd "w") 'ace-window)
  (define-key evil-normal-state-map (kbd "q") 'evil-delete-buffer)
  (define-key evil-normal-state-map (kbd "<f2>") 'save-buffer)
  (define-key evil-insert-state-map (kbd "<f2>") 'save-and-normal-mode)
  (define-key evil-normal-state-map (kbd "fd") 'xref-find-definitions)
  (define-key evil-normal-state-map (kbd "fr") 'xref-find-references)
  (define-key evil-normal-state-map (kbd "ff") 'project-find-file)
  (define-key evil-normal-state-map (kbd "ft") 'consult-ripgrep)
  (define-key evil-normal-state-map (kbd "fb") 'pop-tag-mark))

(global-set-key (kbd "M-y") 'evil-yank-line)
(global-set-key (kbd "M-p") 'evil-paste-after)
(global-set-key (kbd "<f5>") 'diff-hl-show-hunk)
(global-set-key (kbd "<f4>") 'global-whitespace-mode)

(setq-default case-fold-search nil)
(setq evil-ex-search-case 'sensitive)

(use-package! aweshell
  :commands (aweshell-new aweshell-toggle aweshell-dedicated-toggle))

(add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh)


;;; Code navigation: clangd (lsp-mode) + cscope

;; Never let xcscope rebuild cscope.out; kernel databases are >1 GB and are
;; rebuilt explicitly with `make cscope'.
(setq cscope-option-do-not-update-database t)
(cscope-setup)

(setq read-process-output-max (* 1024 1024))

(after! lsp-mode
  (setq lsp-auto-guess-root t
        lsp-diagnostics-provider :none
        lsp-enable-symbol-highlighting nil
        lsp-enable-on-type-formatting nil
        lsp-signature-auto-activate nil
        lsp-enable-folding nil
        lsp-enable-snippet nil
        lsp-idle-delay 0.5
        ;; Watching a kernel tree means tens of thousands of directories.
        lsp-enable-file-watchers nil))

(after! corfu
  (setq corfu-auto-prefix 1
        corfu-auto-delay 0.3
        corfu-cycle t))


;;; ECB-like code browsing: project tree (left), symbol outline (right)

(add-hook 'lsp-mode-hook #'lsp-headerline-breadcrumb-mode)

(defun +ide/toggle-layout ()
  "Toggle the project tree on the left and the LSP symbol outline on the right."
  (interactive)
  (require 'treemacs)
  (let ((symbols (get-buffer-window "*LSP Symbols List*"))
        (tree (eq (treemacs-current-visibility) 'visible)))
    (if (or symbols tree)
        (progn
          (when symbols (delete-window symbols))
          (when tree (delete-window (treemacs-get-local-window))))
      (when (bound-and-true-p lsp-mode)
        (save-selected-window (lsp-treemacs-symbols)))
      (save-selected-window (+treemacs/toggle)))))

(global-set-key (kbd "<f8>") '+ide/toggle-layout)
(global-set-key (kbd "<f7>") 'lsp-treemacs-call-hierarchy)
(global-set-key (kbd "<f6>") '+lookup/references)


;;; Org publishing

(setq org-publish-project-alist
      '(("org"
         :base-directory "~/vimwiki/org/"
         :publishing-function org-html-publish-to-html
         :publishing-directory "~/vimwiki_html/"
         :section-numbers nil
         :with-toc nil
         :html-head "<link rel=\"stylesheet\"
                    href=\"../other/mystyle.css\"
                    type=\"text/css\"/>")))


;;; Markdown notes

;; Hide **, `, # and link URLs so notes read like rendered Markdown.
;; Toggle with SPC m t m (markup) and SPC m t l (URLs).
(after! markdown-mode
  (setq-default markdown-hide-markup t
                markdown-hide-urls t))

(add-hook 'markdown-mode-hook #'visual-line-mode)

;; Box-drawing table borders; toggle with SPC m t b.
(load! "markdown-table-box")
(add-hook 'markdown-mode-hook #'+markdown-table-box-mode)
(custom-set-faces! '(markdown-table-face :inherit default))
(map! :after markdown-mode
      :map markdown-mode-map
      :localleader
      (:prefix "t" :desc "Table borders" "b" #'+markdown-table-box-mode))


;;; Cursor Agent CLI, run inside a vterm terminal

(defvar +agent-program "agent"
  "Command used to start the agent.")

(defun +agent--root ()
  (or (doom-project-root) default-directory))

(defun +agent--buffer-name (dir)
  (format "agent: %s" (file-name-nondirectory (directory-file-name dir))))

(defun +agent/open (&optional dir)
  "Open (or switch to) the agent session for DIR, defaulting to the project root."
  (interactive)
  (require 'vterm)
  (let* ((default-directory (file-name-as-directory (or dir (+agent--root))))
         (name (format "*%s*" (+agent--buffer-name default-directory)))
         (buf (get-buffer name)))
    (unless (buffer-live-p buf)
      (let ((vterm-shell +agent-program))
        (setq buf (save-window-excursion (vterm name))))
      ;; Emacs state so ESC and other keys reach the agent TUI; C-z toggles
      ;; evil, C-c C-t enters vterm-copy-mode to scroll back.
      (with-current-buffer buf (evil-emacs-state)))
    (pop-to-buffer buf)))

(defun +agent/toggle ()
  "Toggle the agent window for the current project."
  (interactive)
  (let* ((name (format "*%s*" (+agent--buffer-name (+agent--root))))
         (win (get-buffer-window name)))
    (if win
        (delete-window win)
      (+agent/open))))

(defun +agent/open-here ()
  "Start an agent session in the current directory."
  (interactive)
  (+agent/open default-directory))

(set-popup-rule! "^\\*agent: " :side 'right :size 0.45 :select t :quit nil :ttl nil)

(global-set-key (kbd "C-c a") '+agent/toggle)
(map! :leader
      (:prefix "o"
       :desc "Toggle agent"    "c" #'+agent/toggle
       :desc "Open agent here" "C" #'+agent/open-here))
