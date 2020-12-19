(use-package magit :ensure t
  :config (add-hook 'git-commit-setup-hook
                    (lambda ()
                      (add-hook 'with-editor-post-finish-hook
                                (lambda ()
                        (call-interactively #'magit-push-current-to-upstream))
                                t t))))

(use-package git-gutter
  :ensure t
  :diminish 'git-gutter-mode
  :config   (global-git-gutter-mode t))

(use-package git-timemachine :ensure t)

(use-package diff-hl :ensure t)

(provide 'etude-core-git)

(comment

 (defhydra hydra-timemachine
   (:hint nil 
    :post (progn (message "in post") (git-timemachine-quit))
    :body-pre (git-timemachine)
    :foreign-keys run )
   "Time machine"
   ("<up>" #'git-timemachine-show-previous-revision "Previous revision"
    :column "Navigation")
   ("<down>" #'git-timemachine-show-next-revision "Next revision")
   ("C-c h" #'git-timemachine-show-current-revision "Current revision")
   ("C-c C-c" "Quit" :color blue )
   ("C-c b" #'git-timemachine-blame "Show culprits" :column "Operations")
   ("C-c r" #'git-timemachine-kill-revision "Yank revision")
   ("C-c s" #'git-timemachine-kill-abbreviated-revision "Yank abbreviated revision")))
