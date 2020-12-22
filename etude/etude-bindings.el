
(require 'etude-lang)
(require 'etude-core-code)
(require 'etude-core-git)
(require 'etude-core-global)
(require 'etude-core-lisp)
(require 'etude-core-management)
(require 'etude-core-shell)
(require 'etude-core-util)

;;
;; (Command)
;;
(defun e/no-action () (interactive))

(e/bind [*]
  ::no-action       ()                          'e/no-action
  ::which-key       ("C-x C-h" "C-x h")         'which-key-show-major-mode
  ::main-menu       ("C-p" "M-p" "M-x" "ESC p" "ESC x")   'counsel-M-x
  ::quit            ("ESC q" "M-q")             'save-buffers-kill-terminal
  ::help-key        ("ESC <f1>")                'helpful-key
  ::eval-elisp      ("ESC l")                   'eval-last-sexp)

(defun e/paredit-copy-context ()
  (interactive)
  (paredit-kill)
  (save-excursion (yank)))

(defun e/paredit-duplicate-context ()
  (interactive)
  (save-excursion
    (paredit-kill)
    (yank)
    (insert "\n")
    (yank)))



(e/bind []
  ::select-all      ("C-x a" "C-x C-a")           'mark-page
  ::cut             ("C-a")                       'kill-region)

(e/bind [*]
  ::copy            ("C-o")                       'copy-region-as-kill
  ::cut-context     ("C-k")                       'paredit-kill
  ::copy-context    ("C-x k" "C-x C-k")           'e/paredit-copy-context
  ::paste-context   ("C-x C-o" "C-x o")
  'e/paredit-duplicate-context
  ::paste           ("C-v" "M-v" "C-y")           'yank
  ::paste-menu      ("C-x C-v" "C-x v" "C-x y" "C-x C-y")
  'counsel-yank-pop
  ::undo            ("C-w")                       'undo-tree-undo
  ::redo            ("C-x w" "C-x C-w")           'undo-tree-redo
  ::comment         ("ESC ;" "C-x ;" "C-x C-;")   'comment-or-uncomment-region)

;;
;; (Buffers and Jumps)
;;


(defun e/last-used-buffer ()
  (interactive)
  (switch-to-buffer (other-buffer)))

(defun e/revert-buffer ()
  (interactive)
  (revert-buffer :ignore-auto :noconfirm)
  (message "Buffer reverted:" ))

(defun e/bufler-toggle ()
  (interactive)
  (if (equal "*Bufler*" (buffer-name (current-buffer)))
      (progn (other-window 1)
             (if (equal "*Bufler*" (buffer-name (current-buffer)))
                 (e/close-buffer)
               (delete-other-windows)))
    (bufler 0)))

(e/bind [*]
  ::jump-buffer       ("ESC b" "M-b" "C-b")   'counsel-switch-buffer)

(e/bind []
  ::list-buffers      ("C-x b" "C-x C-b")     'e/bufler-toggle
  ::revert-buffer     ("C-x r" "C-x C-r")     'e/revert-buffer
  ::last-used-buffer  ("ESC \\" "M-\\" "C-\\" "C-x \\")   'e/last-used-buffer

  ::prev-buffer
  ("M-/" "ESC /" "C-x /" "C-x C-/" "C-S-<left>" "C-x C-<left>" "C-x <left>")
  'previous-buffer

  ::next-buffer
  ("M-=" "ESC =" "C-x =" "C-x C-=" "C-S-<right>" "C-x C-<right>" "C-x <right>")
  'next-buffer)

(e/bind []
  ::goto-line            ("C-x C-g" "C-x g")   'goto-line
  ::goto-start           ()   'beginning-of-buffer
  ::goto-end             ()   'end-of-buffer

  ::jump-search          ("C-l")      'swiper
  ::jump-same            ("C-x i" "C-x C-i") 'swiper-thing-at-point
  ::jump-bookmark        ()           'counsel-bookmark
  ::jump-search-project  ("C-f")      'counsel-rg) 

;;;
;; (System and Files)
;;


(defun e/close-buffer ()
  (interactive)
  (if (buffer-file-name (current-buffer))
      (save-buffer))
  (kill-buffer (current-buffer)))

(defun e/close-all-buffers ()
  (interactive)
  (save-some-buffers)
  (mapc 'kill-buffer (buffer-list)))

(e/bind []
  ::open              ("C-x C-f" "C-x f")          'find-file
  ::open-recent       ("C-r")                      'counsel-recentf
  ::open-project      ("ESC t" "M-t" "C-t" "s-t")  'projectile-find-file-dwim
  ::save              ("ESC s" "C-s" "M-s")        'save-buffer
  ::save-as           ()                           'write-file
  ::save-all          ("C-x C-s" "C-x s")          'save-some-buffers
  ::close             ("ESC `" "M-`" "C-`")        'e/close-buffer
  ::close-all         ()                           'e/close-all-buffers)

;;
;; (Window Movement)
;;

(e/bind []
  ::window-delete
  ("C-x C-d" "C-x d")
  'e/close-buffer
  
  ::window-close
  ("ESC DEL" "M-DEL" "C-<backspace>" "C-x DEL" "C-x C-<down>" "C-x <down>")
  'delete-window      

  ::window-focus
  ("ESC RET" "M-RET" "C-<return>" "C-x RET" "C-x C-<up>" "C-x <up>" "C-x t" "C-x C-t")
  'delete-other-windows
  
  ::window-move-left     ("<M-left>"  "ESC <left>")
  'windmove-left
  ::window-move-right    ("<M-right>" "ESC <right>")
  'windmove-right
  ::window-move-up       ("<M-up>"    "ESC <up>")
  'windmove-up
  ::window-move-down     ("<M-down>"  "ESC <down>")
  'windmove-down)

(setq e/*back-buffer* nil)

(defun e/jump-back ()
  (interactive)
  (when e/*back-buffer*
    (switch-to-buffer e/*back-buffer*)
    (setq e/*back-buffer* nil)))

(defun e/jump-to-bindings ()
  (interactive)
  (if e/*back-buffer*
      (e/jump-back)
    (progn (setq e/*back-buffer* (current-buffer))
           (find-library "etude-bindings"))))

(defun e/jump-to-buffer (bname command &rest args)
  (if (not (equal (buffer-name (current-buffer))
                  bname))
      (funcall 'apply command args)
    (previous-buffer)))

(defun e/jump-to-terminal ()
  (interactive)
  (e/jump-to-buffer "vterm" 'vterm))

(defun e/jump-to-start-screen ()
  (interactive)
  (e/jump-to-buffer "*dashboard*" 'e/start-screen))

(defun e/jump-to-scratch ()
  (interactive)
  (e/jump-to-buffer "*scratch*"
                    (lambda () (switch-to-buffer "*scratch*"))))

(defun e/toggle-treemacs ()
  (interactive)
  (if hydra-base-map (hydra-keyboard-quit))
  (if (equal major-mode 'ranger-mode)
      (e/window-delete)
    (treemacs)))

(defun e/jump-to-ranger ()
  (interactive)
  (if hydra-base-map (hydra-keyboard-quit))
  (if (equal (treemacs-current-visibility) 'visible)
      (delete-window (treemacs-get-local-window)))
  (if (equal major-mode 'ranger-mode)
      (e/window-delete)
    (ranger)))

(e/bind []
  ::toggle-dashboard       ("ESC 1" "M-1")   'e/jump-to-start-screen
  ::toggle-terminal        ("ESC 2" "M-2")   'e/jump-to-terminal
  ::toggle-scratch         ("ESC 3" "M-3")   'e/jump-to-scratch
  ::toggle-bindings        ("ESC 4" "M-4")   'e/jump-to-bindings)


;;
;; (F1) Command
;;

(defun e/insert-input ()
  "Prompt user to enter a file name, with completion and history support."
  (interactive)
  (insert-for-yank (read-string ":")))

(defun e/window-alternate ()
  (seq-find (lambda (w)
              (not (equal w (selected-window))))
            (window-list)))

(defun e/window-set-buffer (w buff)
  (save-selected-window
    (select-window w)
    (switch-to-buffer buff)))

(defun e/split-window-toggle ()
  (interactive)
  (e/let [cnt  (seq-length (window-list))]
    (cond ((equal cnt 1)
	   (progn (split-window-below)
                  (e/window-set-buffer (e/window-alternate)
                                        (other-buffer 1))))
        
          ((not (window-full-height-p))
           (progn (delete-other-windows)
                  (split-window-right)
                  (e/window-set-buffer (e/window-alternate)
                                        (other-buffer 1))))
          (:else
           (delete-other-windows)))))

(pretty-hydra-define e/menu-fn::start-menu
  (:title "<F1> Start" :quit-key "z"  :exit nil :foreign-keys run)
  ("Application"
   (("1" e/jump-to-start-screen "Dashboard" :exit t)
    ("2" e/jump-to-terminal     "Terminal" :exit t)
    ("3" e/jump-to-scratch      "Scratch" :exit t)
    ("4" e/jump-to-bindings    "Bindings" :exit t)
    ("Q" save-buffers-kill-terminal "Exit Emacs" :exit t))
   ""
   (("r d" dash "Dash Docs" :exit t)
    ("r t" tldr "TLDR" :exit t)
    ("r l" wm3          "Browser" :exit t))
   "File"
   (("o o"  counsel-projectile-find-file-dwim   "Open" :exit t)
    ("o r"  counsel-recentf      "Open Recent" :exit t)
    ("o p"  counsel-projectile   "Open Project" :exit t)
    ("s a"  save-some-buffers    "Save As" :exit t)
    ("s s"  save-some-buffers    "Save All"))
   ""
   (("f"  counsel-rg             "Find" :exit t)
    ("c c"  e/close-buffer       "Close" :exit t)
    ("c A"  e/close-all-buffers  "Close All"))
   "Package"
   (("P" package-install "Install" :exit t)
    ("p h" describe-package  "Describe" :exit t)
    ("p r" package-refresh-contents "Refresh")
    ("p l" package-list-packages  "List" :exit t)
    ("p d" package-delete "Delete" :exit t))
   "Customise"
   (("C" customize "all" :exit t)
    ("c f" customize-face  "face" :exit t)
    ("c t" customize-themes "theme" :exit t))
   "Help"
   (("h a" about-emacs   "About Emacs")
    ("h h" help-for-help "About Help")
    ("h b" describe-bindings  "Bound Keys")
    ("h m" describe-mode      "Current Mode"))))

(progn
  (defhydra+ e/menu-fn::start-menu
    ()
    ("i"       e/insert-input))
  
  (e/bind [] ::f1-menu   ("<f1>")
          (lambda ()
            (interactive)
            (if (eq hydra-curr-map e/menu-fn::start-menu/keymap)
                (hydra-keyboard-quit)
              (e/menu-fn::start-menu/body)))))

(pretty-hydra-define e/menu-fn::edit-menu
  (:title "<F2> Edit" :quit-key "z" :exit nil :foreign-keys run)
  ("Find/Replace"
   (("f"    counsel-rg             "Find" :exit t)
    ("r"    replace-string         "Replace" :exit t)
    ("R"    replace-regexp         "Replace Regex" :exit t)
    ("e"    iedit-mode             "Multi Edit" :exit t))
   ""
   ()

   "Navigation"
   (("l" goto-line "Goto Line")
    ("c" goto-last-change "Goto Changed")
    ("t" swiper-thing-at-point "Similar"))
   "Git"
   (("s"  magit-status  "Status" :exit t)
    ("g l"  magit-log-all "Log" :exit t)
    ("g d"  magit-diff    "Diff" :exit t)
    ("g t"  git-timemachine "Timemachine" :exit t))
   ""
   (("g c"  magit-commit  "Commit" :exit t)
    ("g f"  magit-pull    "Pull" :exit t) 
    ("g p"  magit-push    "Push" :exit t))
   "Hunks"
   (("H"  git-gutter:toggle  "On/Off" :toggle git-gutter-mode)
    ("h s" git-gutter:clear  "Select")
    ("h c" git-gutter:clear  "Clear")
    ("h n" git-gutter:next-hunk      "Next")
    ("h p" git-gutter:previous-hunk  "Prev"))
   ""
   (("h i" git-gutter:statistic   "Stats")
    ("h d" git-gutter:popup-hunk   "Diff")
    ("h r" git-gutter:revert-hunk  "Revert")
    ("h s" git-gutter:stage-hunk   "Stage"))
   "History"
   (("h h"  undo-tree-visualize "Undo")
    ("h x"  command-history "Command")
    ("h v"  vc-annotate "Changes"))))

(progn
  (defhydra+ e/menu-fn::edit-menu () ("i"  e/insert-input nil))
  (e/bind [] ::f2-menu   ("<f2>")
          (lambda ()
            (interactive)
            (if (eq hydra-curr-map e/menu-fn::edit-menu/keymap)
                (hydra-keyboard-quit)
              (e/menu-fn::edit-menu/body)))))

(pretty-hydra-define e/menu-fn::meta-menu
  (:title "<F5> Meta" :quit-key "z" :exit nil :foreign-keys run)
  ("Window"
   (("H"   split-window-right   "Split H" :exit nil)
    ("V"   split-window-below   "Split V" :exit nil)
    ("9"   delete-window   "Hide")
    ("0"   delete-other-windows "Focus"))
   ""
   (("B"   balance-windows-area "Balance")
    ("D"   e/window-delete "Delete")
    ("T"   e/split-window-toggle "Toggle")
    ("W"   ace-swap-window "Swap"))
   ""
   (("↑"   shrink-window  "V-")
    ("↓"   enlarge-window "V+")
    ("←"   shrink-window-horizontally "H-")
    ("→"  enlarge-window-horizontally "H+"))
   "Toggle"
   (("L" display-line-numbers-mode "Line Numbers" :toggle t)
    ("V" visual-line-mode "Visual Line" :toggle t)
    ("W" whitespace-mode "Whitespace" :toggle t)
    ("H" auto-highlight-symbol-mode "Highlight Symbol" :toggle t)
    ("K" which-key-mode "Which Key" :toggle t))
   ""
   (("f s" flyspell-mode "Flyspell" :toggle t)
    ("f c" flycheck-mode "Flycheck" :toggle t)
    ("s p" smartparens-mode "Smartparens" :toggle t)
    ("s t" smartparens-strict-mode "Smartparens strict" :toggle t))
   "Annotate"
   (("A"    annotate-mode "On/Off" :toggle t)
    ("a a"  annotate-annotate "Add")
    ("a p"  annotate-goto-previous-annotation "Next")
    ("a n"  annotate-goto-next-annotation "Prev")
    ("a s"  annotate-show-annotation-summary "Summary"))
   ""
   (("a I"  annotate-integrate-annotations "Integrate")
    ("a X"  annotate-export-annotations "Export")
    ("a S"  annotate-save-annotations "Save")
    ("a C"  annotate-clear-annotations "Clear")
    ("a P"  annotate-purge-annotations "Purge"))))

(progn
  (defhydra+ e/menu-fn::meta-menu ()
    ("i"  e/insert-input nil)
    ("<up>"    shrink-window)
    ("<down>"  enlarge-window)
    ("<left>"  shrink-window-horizontally)
    ("<right>" enlarge-window-horizontally))
  (e/bind [] ::f5-menu   ("<f5>")
          (lambda ()
            (interactive)
            (if (eq hydra-curr-map e/menu-fn::meta-menu/keymap)
                (hydra-keyboard-quit)
              (e/menu-fn::meta-menu/body)))))

;;
;; File and Directory Support
;;

(e/bind []
  ::f3-menu   ("<f3>")   'e/jump-to-ranger
  ::f4-menu   ("<f4>")   'e/toggle-treemacs)


(pretty-hydra-define e/menu-fn::ranger-menu
  (:title "<F8> Ranger" :quit-key "z" :exit nil :foreign-keys run)
  ("File"
   (
    ("+" dired-create-directory "New Folder")
    ("S" dired-do-symlink "New Link"))
   "Change"
   (("c n" dired-do-rename "Filename")
    ("c t" dired-do-touch  "Timestamp")
    ("c g" dired-do-chgrp  "Group")
    ("c o" dired-do-chown  "Owner")
    ("c x" dired-do-chmod  "Modifiers"))))


(defun e/ranger-mode-menu ()
     (interactive)
     (if (eq hydra-curr-map e/menu-fn::ranger-menu/keymap)
         (hydra-keyboard-quit)
       (e/menu-fn::ranger-menu/body)))

(add-hook 'ranger-mode-hook
          (lambda ()
            (e/mode [::ranger   ranger-mode "etude-core-bindings"]
              ::mode-menu  'e/ranger-mode-menu)))

(provide 'etude-bindings)

;; tweak binding to taste
;;(define-key org-mode-map (kbd "C-c C-v") #'org-babel-mode)
