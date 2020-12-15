(ns: etude-core-style)

;; Remove menu, tool, and scrolls
;;(set-cursor-color "light green")
(show-paren-mode t)
(global-hl-line-mode t)
(setq redisplay-dont-pause t)

;; When not in a terminal, configure a few window system specific things.
(when window-system
  (setq frame-title-format '(buffer-file-name "%f" ("%b")))
  (tooltip-mode false)
  (mouse-wheel-mode t)
  (blink-cursor-mode false))

(dolist (mode '(menu-bar-mode tool-bar-mode scroll-bar-mode))
  (when (fboundp mode) (funcall mode false)))

(use-package nord-theme
  :ensure t
  :init (load-theme 'nord t))

;; Use smart mode line


(progn (global-display-line-numbers-mode t)
       (setq display-line-numbers "%4d \u2502 ")
       
       ;; Show column numbers in modeline.
       (setq column-number-mode t)

       ;; Show current function in modeline.
       (which-function-mode t))

(use-package auto-highlight-symbol
  :ensure t
  :diminish 'auto-highlight-symbol-mode
  :config   (progn (setq ahs-idle-interval 0.0)
                   (global-auto-highlight-symbol-mode t)))
 
(provide 'etude-core-style)
