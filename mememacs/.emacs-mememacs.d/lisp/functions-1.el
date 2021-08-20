;;; Functions-1

;;; -*- lexical-binding: t; -*-

(defvar mememacs/config-dir
  (expand-file-name "~/.emacs-mememacs.d/"))

(defun mememacs/find-init-file ()
  "Open current init file."
  (interactive)
  (find-file
   (expand-file-name
    (concat mememacs/config-dir "init.el"))))

(defun mememacs/copy-dir-name-name-as-kill-dwim ()
  ""
  (interactive)
  (kill-new
   (file-name-directory (expand-file-name default-directory))))

(mememacs/leader-def
  "fe" #'mememacs/find-init-file
  "fD" #'mememacs/copy-dir-name-name-as-kill-dwim)


(defun mememacs/lispy-eval-line ()
  (interactive)
  (save-excursion
    (goto-char (line-end-position))
    (special-lispy-eval)))

(defun mememacs/cancel-debugs ()
  (interactive)
  (cancel-debug-on-entry)
  (cancel-debug-on-variable-change)
  (untrace-all))

(defun mememacs/mkstr (obj)
  (with-output-to-string
    (prin1 obj)))

(defun mememacs/eval-and-set-test-fn (arg)
  "Eval and bind defun to leader-tt. With ARG ask for key "
  (interactive "P")
  (general-define-key
   :keymaps
   '(normal insert visual emacs)
   :prefix "SPC" :global-prefix "C-SPC"
   (concat
    "t"
    (if arg
	(read-from-minibuffer
	 "Test key bind: ")
      "t"))
   (eval-defun nil)))

(defun mememacs/eval-last-sexp-dwim (arg)
  "Eval last sexp.
If it is a quoted symbol, eval symbol value instead.
See `eval-last-sexp'."
  (interactive "P")
  (let ((s (sexp-at-point)))
    (if (eq 'quote (car-safe s))
	(with-temp-buffer
	  (insert (mememacs/mkstr (cadr s)))
	  (goto-char (point-max))
	  (eval-last-sexp arg))
      (eval-last-sexp arg))))

;; local eval
(general-def
  :states '(normal motion)
  "," nil
  ",e" '(:ignore t :which-key "eval")
  ",el" #'mememacs/lispy-eval-line
  ",ef" #'eval-defun
  ",eb" #'eval-buffer
  ",ed" #'edebug-defun
  ",ee" #'mememacs/eval-last-sexp-dwim
  ",et" #'toggle-debug-on-error
  ",eq" #'toggle-debug-on-quit
  ",eo" #'mememacs/eval-and-set-test-fn
  ",d" '(:ignore t :which-key "devel")
  ",dv" #'debug-on-variable-change
  ",dd" #'debug-on-entry
  ",dt" #'trace-function
  ",dx" #'mememacs/cancel-debugs

  ;; `(,(let ((map (make-sparse-keymap "find elisp stuff")))
  ;;      (define-key map "v" #'find-variable)
  ;;      (define-key map "V" #'apropos-value)
  ;;      (define-key map "l" #'apropos-library)
  ;;      (define-key map "L" #'apropos-local-value)
  ;;      (define-key map "d" #'apropos-documentation)
  ;;      (define-key map "D" #'apropos-documentation-property)
  ;;      (define-key map "f" #'apropos-command)
  ;;      (define-key map "r" #'apropos-read-pattern)
  ;;      (define-key map "u" #'apropos-user-option)
  ;;      map)
  ;;   :which-key "find")
  )

(defun mememacs/switch-to-message-buffer ()
  ""
  (interactive)
  (switch-to-buffer "*Messages*"))

(defun mememacs/ghetto-kill-and-open-buffer ()
  "Kill buffer and open again."
  (interactive)
  (when-let ((p (point))
	     (f (buffer-file-name)))
    (kill-this-buffer)
    (find-file f)
    (goto-char p)))

(mememacs/leader-def
  "bm" #'mememacs/switch-to-message-buffer
  "bR" #'mememacs/ghetto-kill-and-open-buffer
  "br" #'revert-buffer)



(defvar mememacs/escape-functions '())
(defun mememacs/escape ()
  "Run `mememacs/escape-functions'"
  (interactive)
  (run-hooks 'mememacs/escape-functions))

(general-def
  "S-<escape>"
  #'mememacs/escape)



(defun mm/toggle-when-unless ()
  (interactive)
  (skip-chars-backward "^(")
  (forward-char -1)
  (when-let* ((lst (sexp-at-point))
	      (lst
	       (cond
		((eq (car-safe lst) 'when)
		 (pop lst)
		 `(unless ,(cadar lst) ,@(cdr lst)))
		((eq (car-safe lst) 'unless)
		 (pop lst)
		 `(when (not ,(car lst)) ,@(cdr lst))))))
    (delete-region
     (point)
     (save-excursion
       (forward-list)))
    (insert (mememacs/mkstr lst))))


(defvar mememacs/lisp-map
  (make-sparse-keymap "lisp"))

(general-create-definer
  mememacs/lisp-def
  :keymapcs '(normal insert visual emacs)
  :prefix ",k"
  :global-prefix "C-,k"
  mememacs/lisp-map)

(defun mememacs/jump-eshell ()
  (interactive)
  (let* ((dir default-directory)
	 (cd-shell
	  (lambda ()
            (goto-char (point-max))
	    (insert
	     (format "cd %s" (shell-quote-argument dir)))
	    (eshell-send-input))))
    (eshell)
    (funcall cd-shell)))

(mememacs/leader-def "je" #'mememacs/jump-eshell)

(defun mm/magit-kill-origin-url (&optional arg)
  (interactive "p")
  (kill-new
   (magit-git-string
    "remote"
    "get-url"
    (if arg
	(magit-read-remote "kill url from: ")
      "origin"))))

;; thanks john https://github.com/jwiegley/dot-emacs.git

(defun scratch ()
  (interactive)
  (let ((current-mode major-mode))
    (switch-to-buffer-other-window (get-buffer-create "*scratch*"))
    (goto-char (point-min))
    (when (looking-at ";")
      (forward-line 4)
      (delete-region (point-min) (point)))
    (goto-char (point-max))
    (when (memq current-mode '(emacs-lisp-mode))
      (funcall current-mode))))

(mememacs/leader-def "bs" #'scratch)

(defun mememacs/process-menu-switch-to-buffer ()
  (interactive)
  (-some->>
      (tabulated-list-get-id)
    (process-buffer)
    (switch-to-buffer)))

(general-def
  :states '(normal motion)
  :keymaps '(process-menu-mode-map)
  "b"
  #'mememacs/process-menu-switch-to-buffer)

(provide 'functions-1)
