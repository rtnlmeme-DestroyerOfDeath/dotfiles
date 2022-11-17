;;; Functions-1  -*- lexical-binding: t; -*-

(defun mememacs/native-compile-config ()
  (interactive)
  (native-compile-async (expand-file-name "lisp" mememacs/config-dir)))

(defun mememacs/find-init-file ()
  "Open current init file."
  (interactive)
  (find-file
   (expand-file-name "init.el" mememacs/config-dir)))

(defun mememacs/kill-buffer-name ()
  (interactive)
  (let ((s (buffer-name)))
    (kill-new s)
    (message "%s" s)))

(defun mememacs/cancel-debugs ()
  (interactive)
  (cancel-debug-on-entry)
  (cancel-debug-on-variable-change)
  (untrace-all)
  (-some-->
      (get-buffer "*trace-output*")
    (with-current-buffer
	it
	(kill-buffer-and-window)))
  (message ""))

(defun mememacs/eval-last-sexp-dwim (arg)
  "Eval last sexp.
If it is a quoted symbol, eval symbol value instead.
See `eval-last-sexp'."
  (interactive "P")
  (let ((s (sexp-at-point)))
    (if (eq 'quote (car-safe s))
	(with-temp-buffer
	  (insert
	   (with-output-to-string
	     (print (cadr s))))
	  (goto-char (point-max))
	  (eval-last-sexp arg))
      (eval-last-sexp arg))))

(defun mm/identifier-unquote (s)
  ""
  (let ((sexp (car (read-from-string s))))
    (if (eq 'quote (car-safe sexp))
	(with-temp-buffer
	  (insert
	   (with-output-to-string
	     (print (cadr sexp))))
	  (s-trim
	   (buffer-string)))
      s)))

(defvar mememacs/escape-functions '())
(defun mememacs/escape ()
  "Run `mememacs/escape-functions'"
  (interactive)
  (run-hook-wrapped 'mememacs/escape-functions
		    (lambda (f)
		      (progn (ignore-errors (funcall f)) nil))))

(define-key global-map (kbd "S-<escape>") #'mememacs/escape)

(add-hook 'mememacs/escape-functions #'widen)



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

(mememacs/leader-def "jE" #'mememacs/jump-eshell)

(defun mememacs/eshell-hist ()
  (interactive)
  (goto-char (point-max))
  (insert
   (completing-read
    "hist: "
    (ring-elements
     eshell-history-ring))))

(mememacs/local-def
  :states '(insert normal)
  :keymaps '(eshell-mode-map)
  "h" #'mememacs/eshell-hist)

(defun mememacs/magit-kill-origin-url (&optional arg)
  (interactive "p")
  (-->
   (magit-git-string
    "remote"
    "get-url"
    (if arg
	(magit-read-remote "kill url from: ")
      "origin"))
   (progn
     (message  "Kill %s" it)
     (kill-new it))))

(defvar mememacs/scratch-dir (expand-file-name "~/scratch"))
(defun mememacs/latest-scratch (suffix)
  (unless (file-exists-p mememacs/scratch-dir)
    (make-directory mememacs/scratch-dir))
  (when-let
      ((f
	(car
	 (cl-remove-if-not
	  (lambda (it)
	    (and (string-suffix-p suffix it)
		 (not (string-match-p "#" it))))
	  (process-lines
	   "ls"
	   "-A"
	   "-t"
	   mememacs/scratch-dir)))))
    (expand-file-name f mememacs/scratch-dir)))

(defun mememacs/new-scratch-name (suffix)
  (unless (file-exists-p
	   mememacs/scratch-dir)
    (make-directory
     mememacs/scratch-dir))
  (expand-file-name
   (format "%s.%s" (make-temp-name "scratch-") suffix)
   mememacs/scratch-dir))

(declare
 (mememacs/new-scratch-name "el")
 (mememacs/latest-scratch "el")
 (mememacs/latest-scratch "clj"))

(defun mm/scratch
    (&optional create-new suffix)
  "Visit the latest scratch file with `suffix` (a file extension).
With prefix arg make a new file."
  (interactive
   (list current-prefix-arg
	 (completing-read "scratch filetype: " '("cljs" "clj"))))
  (let* ((latest (mememacs/latest-scratch suffix))
	 (buff
	  (find-file-noselect
	   (if (or create-new (not latest))
	       (mememacs/new-scratch-name suffix)
	     latest))))
    (pop-to-buffer-same-window buff)
    (when (eq major-mode 'emacs-lisp-mode)
      (elisp-enable-lexical-binding))
    buff))

(defun mm/scratch-el (&optional arg)
  (interactive "P")
  (mm/scratch arg "el"))

(mememacs/leader-def
  "bs" #'mm/scratch-el
  "bS" #'mm/scratch)

(defun mememacs/process-menu-switch-to-buffer ()
  (interactive)
  (when-let*
      ((id (tabulated-list-get-id))
       (b (process-buffer id)))
    (switch-to-buffer b)))

(define-key
  process-menu-mode-map
  (kbd "b") #'mememacs/process-menu-switch-to-buffer)

(defun mememacs/create-script* (file bang setup)
  (find-file file)
  (insert bang)
  (save-buffer)
  (set-file-modes file #o751)
  (funcall setup))

(defun mememacs/create-script (file)
  (interactive "Fnew script: ")
  (mememacs/create-script*
   file
   "#!/bin/sh\n"
   #'shell-script-mode))

(defun mememacs/create-bb-script (file)
  (interactive "Fnew bb: ")
  (mememacs/create-script*
   file
   "#!/usr/bin/env bb\n"
   #'clojure-mode))

(mememacs/comma-def
  :keymaps 'dired-mode-map
  "ns" #'mememacs/create-script
  "nS" #'mememacs/create-bb-script)

(defun mememacs/toggle-debug-on-quit (arg)
  (interactive "P")
  (if arg
    (setf ebug-on-quit
	  (not ebug-on-quit))
    (setf debug-on-quit
	  (not debug-on-quit))))

(general-def "C-x C-q" #'mememacs/toggle-debug-on-quit)

(defun mememacs/copy-file-name-dwim (arg)
  (interactive "P")
  (-->
   (cond ((eq major-mode 'dired-mode)
	  (dired-copy-filename-as-kill
	   (when arg 0))
	  (pop kill-ring))
	 ((or arg (in major-mode 'eshell-mode))
	  default-directory)
	 (t
	  (or
	   buffer-file-name
	   (progn
	     (kill-new
	      (buffer-name))
	     (user-error
	      "Killed %s instead of file name" (buffer-name))))))
   (if arg
       (file-name-directory it)
     it)
   (progn (kill-new it)
	  (message "Copied %s" it))))

(defun mm/force-clear-buff ()
  (interactive)
  (let ((inhibit-read-only t))
    (erase-buffer)))

(defhydra hydra-buffer ()
  "buffer"
  ("d" #'kill-current-buffer)
  ("k" #'previous-buffer)
  ("j" #'next-buffer)
  ("b" #'consult-buffer :exit t)
  ("a" #'mark-whole-buffer)
  ("y" #'mememacs/kill-buffer-name :exit t))

(mememacs/comma-def
  :states '(normal motion)
  "b" #'hydra-buffer/body
  "w" #'evil-window-map
  "E" #'mm/force-clear-buff)

(defhydra outline-hydra ()
  ("c" #'counsel-outline :exit t)
  ("J" #'outline-forward-same-level)
  ("K" #'outline-backward-same-level)
  ("L" #'outline-demote)
  ("H" #'outline-promote)
  ("M-j" #'outline-move-subtree-down)
  ("M-k" #'outline-move-subtree-up)
  ("g" #'outline-back-to-heading)
  ("i" #'outline-cycle)
  ("m" #'outline-hide-other)
  ("o" #'outline-show-all))

(defhydra scroll-hydra
  (:pre (set-cursor-color "Red") :post (set-cursor-color mindsape/cursor-default))
  "scroll"
  ("j" (evil-scroll-down 20) "down")
  ("k" (evil-scroll-up 20) "up")
  ("J" (evil-scroll-down 150))
  ("K" (evil-scroll-up 150))
  ("h" #'evil-window-top)
  ("l" #'evil-window-bottom)
  ("z" #'evil-scroll-line-to-center)
  ("H" #'evil-scroll-line-to-top)
  ("L" #'evil-scroll-line-to-bottom)
  ("g" #'evil-goto-first-line)
  ("G" #'evil-goto-line)
  ("a" #'mark-whole-buffer)
  ("o" #'outline-hydra/body "outline" :exit t)
  ("y" #'mm/kill-whole-buffer "kill-whole" :exit t))

(mememacs/comma-def
  "jo" #'outline-hydra/body
  "jj" #'scroll-hydra/body
  "jk" #'scroll-hydra/lambda-k
  "jJ" #'scroll-hydra/lambda-J
  "jK" #'scroll-hydra/lambda-K)

(defun mememacs/kill-dangling-buffs (&rest args)
  "Kill all buffers that are connected to a file,
where the file does not exist."
  (interactive)
  (let ((bfs (cl-loop for b in (buffer-list)
		      for f = (buffer-file-name b)
		      when (and f (not (file-exists-p f)))
		      collect b)))
    (when bfs
      (message
       "Kill %d buffers"
       (length bfs)))
    (mapc #'kill-buffer bfs)))

(dolist (fn '(dired-internal-do-deletions
	      dired-do-rename
	      dired-do-rename-regexp))
  (advice-add fn :after #'mememacs/kill-dangling-buffs))

(general-def
  "C-x k"
  (defun mememacs/kill-minibuff-contents ()
    (interactive)
    (let ((s (minibuffer-contents)))
      (kill-new s))
    (keyboard-quit)
    (message "%s" s)))

(general-def
  :keymaps '(emacs-lisp-mode-map)
  "C-c C-k" #'eval-buffer
  "C-c C-c" #'eval-defun)

(general-def
  :keymaps '(compilation-mode-map)
  "M-<return>"
  (defun mm/send-y ()
    (interactive)
    (when-let
	((p
	  (get-buffer-process
	   (current-buffer))))
      (process-send-string p "n\n"))))

(defun mm/completing-read-commit-msg ()
  (interactive)
    (insert
     (s-trim
      (completing-read
       "Commit msg: "
       (ring-elements log-edit-comment-ring)))))

(mememacs/local-def
  :keymaps '(git-commit-mode-map)
  "i" #'mm/completing-read-commit-msg)

;; from https://www.emacswiki.org/emacs/CopyingWholeLines
(defun mm/duplicate-line-or-region (&optional n)
  "Duplicate current line, or region if active.
With argument N, make N copies.
With negative N, comment out original line and use the absolute value."
  (interactive "*p")
  (let ((use-region (use-region-p)))
    (save-excursion
      (let ((text (if use-region
		      (buffer-substring
		       (region-beginning)
		       (region-end))
		    (prog1
			(thing-at-point 'line)
		      (end-of-line)
		      ;; Go to beginning of next line, or make a new one
		      (when (< 0 (forward-line 1))
			  (newline))))))
	(dotimes (i (abs (or n 1)))
	  (insert text))))
    (unless use-region
      (let ((pos (-
		  (point)
		  (line-beginning-position))))
	(when (> 0 n)
	    (comment-region
	     (line-beginning-position)
	     (line-end-position)))
	(forward-line 1)
	(forward-char pos)))))

(defun mm/copy-word-above ()
  (interactive)
  (insert
   (save-excursion
     (evil-previous-line 1)
     (thing-at-point 'evil-WORD))))

(defun github-pull-readme (&optional url)
  (interactive (list (read-from-kill-ring "find github readme: ")))
  (find-file-other-window
   (string-trim
    (shell-command-to-string
     (concat "github-readme.clj " url)))))

(defun mm/trim-string-for-yank-when-inserting-in-quotes (s)
  (if
      (and
       (eq (char-before) 34)
       (eq (char-after) 34))
      (thread-last
	s
	(s-chop-prefix "\"")
	(s-chop-suffix "\""))
    s))

(add-hook 'yank-transform-functions #'mm/trim-string-for-yank-when-inserting-in-quotes)

;; thanks https://github.com/NicolasPetton/noccur.el
(defun noccur-dired (regexp &optional nlines)
  "Perform `multi-occur' with REGEXP in all dired marked files.
When called with a prefix argument NLINES, display NLINES lines before and after."
  (interactive (occur-read-primary-args))
  (multi-occur (mapcar #'find-file (dired-get-marked-files)) regexp nlines))

;; thanks Gavin
(defun mm/shell-command-on-file (command)
  "Execute COMMAND asynchronously on the current file."
  (interactive (list (read-shell-command
                      (concat "Async shell command on " (buffer-name) ": "))))
  (let ((filename (if (equal major-mode 'dired-mode)
                      default-directory
                    (buffer-file-name))))
    (async-shell-command (concat command " " filename))))

(provide 'functions-1)
