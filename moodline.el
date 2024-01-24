;;; moodline.el --- Simple modeline customizations

(defun moodline/version ()
  (message "0.0.1"))


;; Active Window Tracking

(defun moodline/is-active ()
  (window-parameter (selected-window) 'moodline/active))

(defun moodline/walk-track-active ()
  (let* ((track (lambda (w)
                  (set-window-parameter w
                   'moodline/active
                   ;; If the minibuffer is active, the "active window'
                   ;; is actually the one the minbuffer will fall back to.
                   (eq w (if (minibufferp)
                             (minibuffer-selected-window)
                           (selected-window)))))))
    (walk-windows track nil t)))

(add-hook 'window-state-change-hook
          #'moodline/walk-track-active)

;; Custom faces

(defun moodline/declare-modeline-element-faces (sym)
  "Define a pair of modeline-* and modeline-*-inactive faces."
  (let* ((state-inactive (intern (format "modeline-%s-inactive" (symbol-name sym))))
         (state          (intern (format "modeline-%s" (symbol-name sym)))))
    (custom-declare-face
     state '((t :inherit mode-line-active))
     (format "Face for the %s modeline element." (symbol-name sym)))
    (custom-declare-face
     state-inactive '((t :inherit mode-line-inactive))
     (format "Face for the %s modeline element in inactive windows." (symbol-name sym)))))

(defmacro moodline/fallback-to-inactive (face)
  "An expression for use with :eval to add a 'face property that changes with the active window."
  `(if (moodline/is-active)
       (intern (format "modeline-%s" (symbol-name ,face)))
     (intern (format "modeline-%s-inactive" (symbol-name ,face)))))

;; Library of custom modeline elements

(moodline/declare-modeline-element-faces 'vi-cursor)

(defconst moodline/vi-cursor
  '(:eval
    (propertize " %l:%c "
                'face (moodline/fallback-to-inactive 'vi-cursor)))
  "Mode line construct for displaying the position of the point.")

(dolist (st '(normal insert visual replace motion emacs))
  (let* ((vi-state (intern (format "vi-state-%s" st))))
    (moodline/declare-modeline-element-faces vi-state)))

(defun moodline/format-evil-state ()
  "Print the current EVIL-state in a manner suitable for the mode-line."
  (if evil-mode
      (let* ((name (symbol-name evil-state))
             (abbr (substring name 0 1)))
        (format " %s " (capitalize abbr)))))

(defconst moodline/vi-state
  '(:eval (let* ((name (format "vi-state-%s" evil-state))
                 (face (moodline/fallback-to-inactive (intern-soft name))))
            (propertize (moodline/format-evil-state)
                        'face face)))
  "Mode line construct for displaying the EVIL Vi state")

;; https://emacs.stackexchange.com/a/7542
(defun moodline/render (left right)
  (let* ((available-width (- (window-width) (length left))))
    (format
     (format "%%s %%%ds" available-width)
     left
     right)))

(defvar moodline/left
  '((evil-mode moodline/vi-state)
    "%e "
    mode-line-front-space
    mode-line-mule-info

    mode-line-client
    mode-line-modified
    mode-line-remote

    mode-line-frame-identification
    mode-line-buffer-identification


    (vc-mode vc-mode)
    "  "
    mode-line-misc-info
    mode-line-end-spaces)
  "Left-hand side of custom modeline.")

(defvar moodline/right
  '((t moodline/vi-cursor)
    " "
    (t mode-name))
  "Right-hand side of custom modeline.")

(setq-default mode-line-format 
              '((:eval (moodline/render
                        (format-mode-line moodline/left)
                        (format-mode-line moodline/right)))))


(provide 'moodline)
