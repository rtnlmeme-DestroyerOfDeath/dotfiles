;;; init-helm-ag.el ---


(define-key helm-ag-map (kbd "C-c C-o") #'benj/helm-ag-dwim-kill-selection)

;; todo i need something to disable follow, if the file would be big

(custom-set-variables
 '(helm-ag-base-command "rg --no-heading --max-columns 124")
 `(helm-ag-success-exit-status '(0 2))
 '(helm-ag-use-grep-ignore-list 't)
 '(helm-candidate-number-limit 100)
 ;; helm-ag-base-command "rg --color=never --no-heading"
 ;; helm-grep-ag-command "rg --color=always --smart-case --no-heading --line-number %s %s %s"
 )

;; todo
;; (assq 'follow  helm-ag-source)

(setf
 helm-source-names-using-follow
 (remove
  "Git-Grep"
  (remove
   "AG"
   helm-source-names-using-follow)))

(defun mememacs/helm-ag-this-dir ()
  (interactive)
  (when default-directory
    (helm-do-ag default-directory)))

(defun benj/helm-ag-dwim-kill-selection (arg)
  (interactive "P")
  (benj/helm-make-kill-selection-and-quit
   (lambda (el)
     (-last-item
      (s-split-up-to ":" el 2)))
   arg))

(mememacs/leader-def
  "/" #'helm-projectile-ag
  "sd" #'mememacs/helm-ag-this-dir
  "sb" #'helm-do-ag-buffers)


(provide 'init-helm-ag)

;;; init-helm-ag.el ends here
