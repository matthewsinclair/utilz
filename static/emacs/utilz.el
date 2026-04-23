;;; utilz.el --- Bridge between Emacs and Utilz utilities -*- lexical-binding: t; -*-

;; Author: Matthew Sinclair
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: tools, convenience

;;; Commentary:
;;
;; Thin coordinator between Emacs and the Utilz utility framework.
;; `M-x utilz' offers a completing-read menu of every utility that
;; declares an `integration:' block in its YAML, resolves input per
;; the declared kind (stdin | file | path | none), runs the utility,
;; and dispatches output per the declared kind (replace | buffer |
;; message | discard).
;;
;; The TSV emitted by `utilz integration commands' is the only
;; cross-boundary contract.  This file never parses YAML.

;;; Code:

(defgroup utilz nil
  "Bridge between Emacs and the Utilz utility framework."
  :group 'tools
  :prefix "utilz-")

(defcustom utilz-executable "utilz"
  "Name of the utilz dispatcher on PATH."
  :type 'string
  :group 'utilz)

(defvar utilz--commands-alist nil
  "Alist of (NAME . PLIST) built from `utilz integration commands'.
PLIST keys: :description :input :output :flags.")

;; --- Manifest ---------------------------------------------------------------

(defun utilz--parse-tsv (text)
  "Parse TSV TEXT into an alist of (NAME . PLIST)."
  (let (result)
    (dolist (line (split-string text "\n" t))
      (let ((fields (split-string line "\t")))
        (when (>= (length fields) 4)
          (push (cons (nth 0 fields)
                      (list :description (nth 1 fields)
                            :input (intern (nth 2 fields))
                            :output (intern (nth 3 fields))
                            :flags (or (nth 4 fields) "")))
                result))))
    (nreverse result)))

;;;###autoload
(defun utilz-refresh ()
  "Re-read the Utilz integration manifest via `utilz integration commands'."
  (interactive)
  (let* ((cmd (format "%s integration commands"
                      (shell-quote-argument utilz-executable)))
         (output (shell-command-to-string cmd)))
    (setq utilz--commands-alist (utilz--parse-tsv output))
    (when (called-interactively-p 'any)
      (message "Utilz: %d command(s) loaded" (length utilz--commands-alist)))
    utilz--commands-alist))

;; --- Input resolvers --------------------------------------------------------

(defun utilz--input-stdin ()
  "Resolve stdin input: region if active, else whole buffer."
  (if (use-region-p)
      (list :kind 'stdin :begin (region-beginning) :end (region-end))
    (list :kind 'stdin :begin (point-min) :end (point-max))))

(defun utilz--input-file ()
  "Resolve file input: current buffer's file, else prompt."
  (list :kind 'file
        :path (or (buffer-file-name)
                  (read-file-name "File: "))))

(defun utilz--input-path ()
  "Resolve path input: prompt for a directory."
  (list :kind 'path
        :path (read-directory-name "Directory: " default-directory)))

(defun utilz--input-none ()
  "No input resolution needed."
  (list :kind 'none))

(defconst utilz--input-dispatch
  '((stdin . utilz--input-stdin)
    (file  . utilz--input-file)
    (path  . utilz--input-path)
    (none  . utilz--input-none))
  "Alist mapping input kind symbol to resolver function.")

;; --- Execution --------------------------------------------------------------

(defun utilz--build-cmdline (name flags extra-flags input-spec)
  "Build the shell command line for NAME with FLAGS and EXTRA-FLAGS.
Append a path argument when INPUT-SPEC is a file or path kind."
  (let ((parts (list (shell-quote-argument utilz-executable)
                     (shell-quote-argument name))))
    (when (and flags (not (string-empty-p flags)))
      (setq parts (append parts
                          (mapcar #'shell-quote-argument
                                  (split-string flags "," t)))))
    (when (and extra-flags (not (string-empty-p extra-flags)))
      (setq parts (append parts (list extra-flags))))
    (pcase (plist-get input-spec :kind)
      ((or 'file 'path)
       (setq parts (append parts
                           (list (shell-quote-argument
                                  (plist-get input-spec :path)))))))
    (mapconcat #'identity parts " ")))

(defun utilz--pop-stderr (name stderr)
  "Pop a buffer showing STDERR for utility NAME."
  (let ((buf (get-buffer-create (format "*utilz-stderr: %s*" name))))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert stderr))
      (goto-char (point-min))
      (special-mode))
    (pop-to-buffer buf)))

(defun utilz--run (cmdline input-spec name)
  "Run CMDLINE with INPUT-SPEC for utility NAME.
Return (EXIT . STDOUT) on success, nil on failure (after popping stderr)."
  (let ((stdout-buf (generate-new-buffer " *utilz-stdout*"))
        (stderr-file (make-temp-file "utilz-stderr-"))
        exit stdout stderr)
    (unwind-protect
        (progn
          (setq exit
                (pcase (plist-get input-spec :kind)
                  ('stdin
                   (call-process-region
                    (plist-get input-spec :begin)
                    (plist-get input-spec :end)
                    shell-file-name nil
                    (list stdout-buf stderr-file) nil
                    shell-command-switch cmdline))
                  (_
                   (call-process
                    shell-file-name nil nil
                    (list stdout-buf stderr-file) nil
                    shell-command-switch cmdline))))
          (setq stdout (with-current-buffer stdout-buf (buffer-string)))
          (if (and (numberp exit) (= exit 0))
              (cons exit stdout)
            (setq stderr (with-temp-buffer
                           (insert-file-contents stderr-file)
                           (buffer-string)))
            (utilz--pop-stderr
             name
             (if (string-empty-p stderr)
                 (format "utilz %s exited with status %s\n(no stderr output)\n"
                         name exit)
               stderr))
            nil))
      (when (buffer-live-p stdout-buf) (kill-buffer stdout-buf))
      (when (file-exists-p stderr-file) (delete-file stderr-file)))))

;; --- Output handlers --------------------------------------------------------

(defun utilz--output-replace (result input-spec name)
  "Replace region/buffer with RESULT stdout on success."
  (when result
    (let ((stdout (cdr result))
          (begin (plist-get input-spec :begin))
          (end (plist-get input-spec :end)))
      (save-excursion
        (undo-boundary)
        (goto-char begin)
        (delete-region begin end)
        (insert stdout))
      (message "utilz %s: replaced %d char(s)" name (length stdout)))))

(defun utilz--output-buffer (result _input-spec name)
  "Show RESULT stdout in a dedicated `*utilz-NAME*' buffer."
  (when result
    (let ((buf (get-buffer-create (format "*utilz-%s*" name))))
      (with-current-buffer buf
        (let ((inhibit-read-only t))
          (erase-buffer)
          (insert (cdr result)))
        (goto-char (point-min))
        (special-mode))
      (pop-to-buffer buf))))

(defun utilz--output-message (result _input-spec name)
  "Echo RESULT stdout as a single-line message."
  (when result
    (let ((stdout (string-trim
                   (replace-regexp-in-string "\n+" " " (cdr result)))))
      (message "utilz %s: %s" name
               (if (string-empty-p stdout) "done" stdout)))))

(defun utilz--output-discard (result _input-spec name)
  "Discard RESULT stdout; echo exit status only."
  (when result
    (message "utilz %s: done" name)))

(defconst utilz--output-dispatch
  '((replace . utilz--output-replace)
    (buffer  . utilz--output-buffer)
    (message . utilz--output-message)
    (discard . utilz--output-discard))
  "Alist mapping output kind symbol to handler function.")

;; --- Command picker ---------------------------------------------------------

(defun utilz--read-command ()
  "Prompt for a Utilz command via `completing-read' with annotations."
  (let* ((names (mapcar #'car utilz--commands-alist))
         (annot
          (lambda (cand)
            (let ((entry (cdr (assoc cand utilz--commands-alist))))
              (when entry
                (format "  %s [%s -> %s]"
                        (plist-get entry :description)
                        (plist-get entry :input)
                        (plist-get entry :output))))))
         (table
          (lambda (string pred action)
            (if (eq action 'metadata)
                `(metadata (annotation-function . ,annot))
              (complete-with-action action names string pred)))))
    (completing-read "Utilz: " table nil t)))

;; --- Entry point ------------------------------------------------------------

;;;###autoload
(defun utilz (&optional prefix)
  "Run a Utilz utility via a completing-read menu.
With a single prefix arg (\\[universal-argument]) prompt for extra flags.
With a double prefix arg (\\[universal-argument] \\[universal-argument])
confirm the full command line before running."
  (interactive "p")
  (unless utilz--commands-alist
    (utilz-refresh))
  (unless utilz--commands-alist
    (user-error "Utilz: no commands available.  Is `%s' on PATH?"
                utilz-executable))
  (let* ((prefix (or prefix 1))
         (name (utilz--read-command))
         (entry (cdr (assoc name utilz--commands-alist)))
         (input-kind (plist-get entry :input))
         (output-kind (plist-get entry :output))
         (flags (plist-get entry :flags))
         (extra-flags (when (>= prefix 4)
                        (read-string (format "Extra flags for %s: " name))))
         (input-resolver (cdr (assq input-kind utilz--input-dispatch)))
         (output-handler (cdr (assq output-kind utilz--output-dispatch))))
    (unless input-resolver
      (user-error "Utilz %s: unknown input kind `%s'" name input-kind))
    (unless output-handler
      (user-error "Utilz %s: unknown output kind `%s'" name output-kind))
    (let* ((input-spec (funcall input-resolver))
           (cmdline (utilz--build-cmdline name flags extra-flags input-spec)))
      (when (>= prefix 16)
        (unless (yes-or-no-p (format "Run: %s ? " cmdline))
          (user-error "Utilz: aborted")))
      (funcall output-handler
               (utilz--run cmdline input-spec name)
               input-spec name))))

;; --- Keybinding -------------------------------------------------------------

(global-set-key (kbd "C-c u") #'utilz)

(provide 'utilz)

;;; utilz.el ends here
