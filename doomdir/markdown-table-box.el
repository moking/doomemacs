;;; markdown-table-box.el -*- lexical-binding: t; -*-

;; Draw GFM pipe tables with box-drawing borders in markdown-mode.  Only
;; overlays are added; the buffer text is left unchanged.

(require 'cl-lib)

(defface +markdown-table-box-border '((t :inherit shadow))
  "Face for table borders drawn by `+markdown-table-box-mode'.")

(defface +markdown-table-box-header '((t :inherit bold))
  "Face for table header cells drawn by `+markdown-table-box-mode'.")

(defconst +markdown-table-box--row-re "^[ \t]*|.*|[ \t]*$")
(defconst +markdown-table-box--sep-re
  "^[ \t]*|\\(?:[ \t]*:?-+:?[ \t]*|\\)+[ \t]*$")

(defvar-local +markdown-table-box--timer nil)

(defun +markdown-table-box--clear ()
  (remove-overlays (point-min) (point-max) '+markdown-table-box t))

(defun +markdown-table-box--overlay (beg end &rest props)
  (let ((ov (make-overlay beg end nil t nil)))
    (overlay-put ov '+markdown-table-box t)
    (overlay-put ov 'evaporate t)
    (while props
      (overlay-put ov (pop props) (pop props)))))

(defun +markdown-table-box--pipes ()
  "Return positions of the unescaped pipes from point to end of line."
  (let ((eol (line-end-position)) pipes)
    (save-excursion
      (while (search-forward "|" eol t)
        (unless (eq (char-before (1- (point))) ?\\)
          (push (1- (point)) pipes))))
    (nreverse pipes)))

(defun +markdown-table-box--rule (sep left mid right)
  "Turn separator row SEP, from its first to last pipe, into a border line."
  (let ((inner (replace-regexp-in-string "[-: \t]" "─" (substring sep 1 -1))))
    (propertize (concat left (replace-regexp-in-string "|" mid inner) right)
                'face '+markdown-table-box-border)))

(defun +markdown-table-box--draw (lines)
  "Draw borders over the table whose line beginnings are LINES."
  (save-excursion
    (goto-char (nth 1 lines))
    (when (looking-at-p +markdown-table-box--sep-re)
      (let* ((sep-bol (nth 1 lines))
             (sep-pipes (+markdown-table-box--pipes))
             (sep-beg (car sep-pipes))
             (sep-end (1+ (car (last sep-pipes))))
             (sep (buffer-substring-no-properties sep-beg sep-end))
             (indent (buffer-substring-no-properties sep-bol sep-beg))
             (bar (propertize "│" 'face '+markdown-table-box-border))
             (top (+markdown-table-box--rule sep "┌" "┬" "┐"))
             (bottom (+markdown-table-box--rule sep "└" "┴" "┘"))
             (first-bol (car lines))
             (last-bol (car (last lines))))
        (+markdown-table-box--overlay
         sep-beg sep-end 'display
         (if (= last-bol sep-bol)
             bottom
           (+markdown-table-box--rule sep "├" "┼" "┤")))
        (dolist (bol lines)
          (unless (= bol sep-bol)
            (goto-char bol)
            (let* ((pipes (+markdown-table-box--pipes))
                   (first-pipe (car pipes))
                   (last-pipe (car (last pipes))))
              (dolist (p pipes)
                (+markdown-table-box--overlay
                 p (1+ p) 'display
                 (cond ((and (= bol first-bol) (= p first-pipe))
                        (concat top "\n" indent bar))
                       ((and (= bol last-bol) (= p last-pipe))
                        (concat bar "\n" indent bottom))
                       (t bar))))
              (when (= bol first-bol)
                (cl-loop for (a b) on pipes while b
                         do (+markdown-table-box--overlay
                             (1+ a) b 'face '+markdown-table-box-header))))))))))

(defun +markdown-table-box-refresh ()
  "Redraw table borders in the current buffer."
  (interactive)
  (save-excursion
    (save-match-data
      (+markdown-table-box--clear)
      (goto-char (point-min))
      (while (re-search-forward +markdown-table-box--row-re nil t)
        (let (lines)
          (beginning-of-line)
          (while (and (not (eobp)) (looking-at-p +markdown-table-box--row-re))
            (push (point) lines)
            (forward-line 1))
          (setq lines (nreverse lines))
          (when (and (cdr lines)
                     (not (markdown-code-block-at-pos (car lines))))
            (+markdown-table-box--draw lines)))))))

(defun +markdown-table-box--schedule (&rest _)
  (when (timerp +markdown-table-box--timer)
    (cancel-timer +markdown-table-box--timer))
  (setq +markdown-table-box--timer
        (run-with-idle-timer
         0.3 nil
         (let ((buf (current-buffer)))
           (lambda ()
             (when (buffer-live-p buf)
               (with-current-buffer buf
                 (when +markdown-table-box-mode
                   (+markdown-table-box-refresh)))))))))

(define-minor-mode +markdown-table-box-mode
  "Draw Markdown pipe tables with box-drawing borders."
  :lighter nil
  (if +markdown-table-box-mode
      (progn
        (add-hook 'after-change-functions #'+markdown-table-box--schedule nil t)
        (+markdown-table-box-refresh))
    (remove-hook 'after-change-functions #'+markdown-table-box--schedule t)
    (+markdown-table-box--clear)))

(provide 'markdown-table-box)
