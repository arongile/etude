;; Boot
(setq gc-cons-threshold (* 50 1000 1000))

(progn (setq emacs-d
             (file-name-directory
              (or (buffer-file-name) 
                  (file-chase-links load-file-name))))
       (add-to-list 'load-path (concat emacs-d "etude"))
       (require 'etude-boot))

(setq use-package-always-ensure nil)

;; Core
(require 'etude-lang)
(require 'etude-core)
(require 'etude-module-lisp)
(require 'etude-module-jvm)
(require 'etude-module-native)
(require 'etude-module-text)

(server-force-delete)
(server-start)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(ede-project-directories
   (quote
    ("/Users/chris/Development/caudata/base/src/hara/lang/c")))
 '(package-selected-packages
   (quote
    (flycheck-pos-tip flycheck-clojure flycheck-joker paradox aggressive-indent slime-company slime geiser geiser-mode jdee javap-mode yaml-mode opencl-mode f ht esup counsel-dash wgrep wakatime-mode use-package-chords undo-tree solarized-theme smex smartparens smart-mode-line rainbow-delimiters paredit neotree multiple-cursors midje-mode magit lsp-ui lsp-rust lsp-clangd ivy-rich ivy-hydra git-timemachine git-gutter exec-path-from-shell diminish diff-hl dashboard counsel-projectile company-lsp cargo auto-highlight-symbol ace-window))))

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(hl-line ((t (:background "#222"))))
 '(ivy-action ((t (:inherit font-lock-builtin-face :foreground "red2"))))
 '(ivy-current-match ((t (:background "dark green" :foreground "light green" :weight normal))))
 '(ivy-cursor ((t (:background "gray20" :foreground "white"))))
 '(ivy-highlight-face ((t (:inherit highlight :foreground "dark magenta"))))
 '(ivy-minibuffer-match-face-1 ((t (:foreground "dark cyan" :height 0.8))))
 '(ivy-minibuffer-match-highlight ((t (:inherit highlight :foreground "purple4"))))
 '(ivy-modified-buffer ((t (:inherit default :foreground "LightSalmon1"))))
 '(ivy-modified-outside-buffer ((t (:inherit default :foreground "DodgerBlue2"))))
 '(ivy-prompt-match ((t (:inherit default :foreground "firebrick"))))
 '(line-number ((t (:background "black" :foreground "#586e75" :underline nil :weight ultra-light :height 0.7)))))

(setq gc-cons-threshold (* 2 1000 1000))
