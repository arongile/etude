;; Skip the default splash screen.
(setq inhibit-startup-message true)

;; Make sure we always use UTF-8.
;; (require 'iso-transl)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(prefer-coding-system 'utf-8)

;; Always ask for y/n keypress instead of typing out 'yes' or 'no'
(defalias 'yes-or-no-p 'y-or-n-p)

;; Emacs writes backup files to `filename~` by default. This is messy,
;; so let's tell it to write them to `~/.emacs.d/backup` instead.
;; If you have an accident, check this directory - you might get lucky.
(setq backup-directory-alist    '(("." . "~/.emacs.d/backup"))
      backup-by-copying true    ; Don't delink hardlinks
      version-control true      ; Use version numbers on backups
      delete-old-versions true  ; Automatically delete excess backups
      kept-new-versions 20      ; how many of the newest versions to keep
      kept-old-versions 5)      ; and how many of the old

;; Automatically save buffers before launching M-x compile and friends,
;; instead of asking you if you want to save.
(setq compilation-ask-about-save nil)
(auto-save-mode true)

;; Make the selection work like most people expect.
(delete-selection-mode true)
(transient-mark-mode true)

;; Automatically update unmodified buffers whose files have changed.
(global-auto-revert-mode true)

;; Modern libraries
(use-package s)    ;; string
(use-package dash) ;; list
(use-package ht)   ;; maps
(use-package f)    ;; file

(defun let:fn (bindings &rest body)
  (-let [bargs (seq-reverse (seq-partition bindings 2))]
    (seq-reduce (lambda (body barg)
		  (list '-let barg body))
		bargs
		(cons 'progn body))))

(defmacro let: (bindings &rest body)
  (apply 'let:fn bindings body))

(defmacro comment: (&rest body))

;; Modern Menus and Unified Commands
(use-package hydra)

(setq etude/*commands* (ht-create))
(setq etude/*lock* nil)

(defun etude/put-command (key fn)
  (if (and etude/*lock*
	   (ht-get etude/*commands* key))
      (error (s-concat "key " (symbol-name key) " already exists"))
    (ht-set etude/*commands* key fn)))

(defun etude/get-command (key)
  (gethash key etude/*commands*))

(defun etude/no-action ()
  (interactive))

(defun bind:fn (bind-map? &rest specs)
  (let: [(bind-map specs) (if (s-starts-with? ":" (symbol-name bind-map?))
                              (list nil (cons bind-map? specs))
                            (list bind-map? specs))
	 body (seq-mapcat (lambda (spec)
				     (let: [(key bindings fn) spec]
					   (if fn
					       (progn (etude/put-command key (cadr fn))
						      (seq-map (lambda (binding)
								 (if bind-map
								     (list 'bind-key binding fn bind-map)
								   (list 'bind-key* binding fn)))
							       bindings)))))
			  (seq-partition specs 3))]
	(cons 'progn body)))

(defmacro bind: (bind-map &rest specs)
  (apply 'bind:fn bind-map specs))

(defun menu:fn (declaration &rest specs)
  (let: [[label name &rest more] declaration]
	`(defhydra ,name ()
	   ,(if (seq-empty-p more)
		label
	      (seq-elt more 0))
	   ,@(seq-map (lambda (spec)
			(let: [(bind key text . more) spec
			       fn (etude/get-command key)]
			      (apply 'list bind fn text more)))
		      specs))))

(defmacro menu: (name &rest specs)
  (apply 'menu:fn name specs))


;; Lisp Modes
(use-package smartparens
  :diminish 'smartparens-mode
  :config (progn (require 'smartparens-config)
	         (smartparens-global-mode true)
	         (show-paren-mode true)))

(use-package paredit
  :diminish 'paredit-mode
  :init  (define-key read-expression-map (kbd "TAB") 'completion-at-point))

(defun etude/paredit-copy-as-kill ()
  (interactive)
  (paredit-kill)
  (save-excursion (yank)))

(use-package rainbow-delimiters)

;; Undo tree
(use-package undo-tree
  :defer true
  :diminish 'undo-tree-mode
  :config (global-undo-tree-mode true))

(provide 'etude-global-base)
