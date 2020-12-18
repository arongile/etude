;; Helpful
(use-package helpful :ensure t)

(use-package goggles
  :ensure t
  :init   (setq-default goggles-pulse t)
  :config (goggles-mode))

(use-package undo-tree
  :ensure t
  :diminish 'undo-tree-mode
  :config (global-undo-tree-mode t))

(use-package no-littering :ensure t)

(use-package recentf
  :defer t
  :config (progn (setq recentf-max-saved-items 200
                       recentf-max-menu-items 15)
                 (recentf-mode t)))

(use-package ivy
  :ensure t
  :diminish 'ivy-mode
  :config (progn (ivy-mode t)
                 (setq ivy-initial-inputs-alist nil)
                 (setq ivy-use-virtual-buffers t)
                 (setq ivy-virtual-abbreviate 'abbreviate)     
                 (setq enable-recursive-minibuffers t)
                 (setq ivy-count-format "(%d/%d)")))

(use-package projectile
  :ensure t
  :diminish 'projectile-mode
  :config (setq projectile-completion-system 'ivy))

(use-package wgrep :ensure t)

(use-package swiper :ensure t)

(use-package counsel :ensure t)

(use-package counsel-etags :ensure t)

(use-package counsel-projectile
  :ensure t
  :init (add-hook 'after-init-hook 'counsel-projectile-mode))

(use-package counsel-tramp :ensure t)

(use-package ivy-rich
  :ensure t
  :config (ivy-rich-mode t))

(use-package ace-window :ensure t)

(defun e/start-screen ()
  (interactive)
  (dashboard-insert-startupify-lists)
  (redisplay)
  (switch-to-buffer "*dashboard*")
  (define-key dashboard-mode-map [down-mouse-1] nil))

(use-package dashboard
  :ensure t
  :init (progn (setq dashboard-startup-banner nil)
               (setq dashboard-items '((recents  . 15)
                                       (projects . 5)))
               (add-hook 'emacs-startup-hook 'e/start-screen)))

(use-package treemacs :ensure t
  :init (setq treemacs-no-png-images t))

(use-package treemacs-projectile :ensure t)
(use-package treemacs-magit :ensure t)

(use-package doom-modeline :ensure t
  :init (doom-modeline-mode))
  
(use-package diff-hl :ensure t)


(provide 'etude-core-management)
