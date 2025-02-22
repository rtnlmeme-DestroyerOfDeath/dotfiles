(setq vertico-cycle t)
(setq read-file-name-completion-ignore-case t
      read-buffer-completion-ignore-case t
      completion-ignore-case t)

(defun crm-indicator (args)
  (cons (concat "[CRM] " (car args)) (cdr args)))
  (advice-add #'completing-read-multiple :filter-args #'crm-indicator)

(setq minibuffer-prompt-properties
      '(read-only t cursor-intangible t face minibuffer-prompt))
  (add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)

  ;; Emacs 28: Hide commands in M-x which do not work in the current mode.
  ;; Vertico commands are hidden in normal buffers.
  ;; (setq read-extended-command-predicate
  ;;       #'command-completion-default-include-p)

(setq enable-recursive-minibuffers t)

(bind-keys
  :map vertico-map
  ("M-k" . backward-paragraph)
  ("M-j" . forward-paragraph)
  ("M-f" . nil)
  ("M-f g" . beginning-of-buffer)
  ("M-f G" . end-of-buffer))

(require 'vertico-directory)

(add-hook 'rfn-eshadow-update-overlay #'vertico-directory-tidy)

(require 'vertico-quick)

(bind-keys
 :map vertico-map
 ("RET" . vertico-directory-enter)
 ("DEL" . vertico-directory-delete-char)
 ("M-DEL" . vertico-directory-delete-word)
 ("C-l" . vertico-quick-exit)
 ("C-k" . kill-line)
 ("M-q" . vertico-quick-insert)
 ("M-a" . vertico-quick-jump))

(setq vertico-quick1
      "adf"
      vertico-quick2
      "jkl")

(require 'vertico-repeat)

(add-hook 'minibuffer-setup-hook #'vertico-repeat-save)

;; (add-hook 'minibuffer-setup-hook (defun mm/insert-region-when-active ()))

(provide 'init-vertico)


