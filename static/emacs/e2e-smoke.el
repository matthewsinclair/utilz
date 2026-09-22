;;; e2e-smoke.el --- Batch smoke test for the Utilz Emacs bridge -*- lexical-binding: t; -*-

;; Standalone end-to-end smoke test for static/emacs/utilz.el. Loads the
;; bridge, refreshes the manifest, asserts that every declared input /
;; output kind has a registered resolver / handler, runs cleanz on a
;; scratch buffer containing a zero-width space, and exercises the
;; No-Silent-Errors failure path.
;;
;; Run from the Utilz repo root:
;;
;;   UTILZ_HOME=$PWD emacs -Q --batch -l static/emacs/e2e-smoke.el
;;
;; Exits 0 on full pass, 1 on any failure. Complements the BATS bridge
;; suite (which covers the bash-side dispatcher surface) by covering
;; the elisp side end-to-end.

(let ((utilz-src (expand-file-name "static/emacs/utilz.el"
                                   (or (getenv "UTILZ_HOME")
                                       default-directory))))
  (load utilz-src))

(defvar e2e-failures 0)

(defun e2e-check (label ok &optional detail)
  (if ok
      (message "PASS: %s%s" label (if detail (format " — %s" detail) ""))
    (setq e2e-failures (1+ e2e-failures))
    (message "FAIL: %s%s" label (if detail (format " — %s" detail) ""))))

;; 1. Manifest refresh: one alist entry per row the manifest emits. The
;;    expectation is READ, never written here: the menu is whatever the YAML
;;    declares, and a hardcoded count went stale when issue 0009 cut the menu
;;    to six (issue 0048).
(utilz-refresh)
(let ((rows (length (process-lines utilz-executable "integration" "commands"))))
  (e2e-check "utilz-refresh populates alist, one entry per manifest row"
             (and (> rows 0) (= (length utilz--commands-alist) rows))
             (format "%d commands loaded, %d manifest rows"
                     (length utilz--commands-alist) rows)))

;; 2. cleanz entry has expected shape
(let ((entry (cdr (assoc "cleanz" utilz--commands-alist))))
  (e2e-check "cleanz is in manifest" entry)
  (e2e-check "cleanz input is stdin"
             (eq (plist-get entry :input) 'stdin)
             (format "got %s" (plist-get entry :input)))
  (e2e-check "cleanz output is replace"
             (eq (plist-get entry :output) 'replace)
             (format "got %s" (plist-get entry :output))))

;; 3. Every declared input/output kind has a registered resolver/handler
(dolist (entry utilz--commands-alist)
  (let* ((name (car entry))
         (plist (cdr entry))
         (ikind (plist-get plist :input))
         (okind (plist-get plist :output)))
    (e2e-check (format "%s: input resolver registered" name)
               (assq ikind utilz--input-dispatch)
               (format "kind=%s" ikind))
    (e2e-check (format "%s: output handler registered" name)
               (assq okind utilz--output-dispatch)
               (format "kind=%s" okind))))

;; 4. End-to-end: cleanz strips a zero-width space via the replace handler
(with-temp-buffer
  (insert "hello​world\n")
  (let* ((entry (cdr (assoc "cleanz" utilz--commands-alist)))
         (input-spec (list :kind 'stdin
                           :begin (point-min)
                           :end (point-max)))
         (cmdline (utilz--build-cmdline "cleanz"
                                        (plist-get entry :flags)
                                        nil
                                        input-spec))
         (before (buffer-string))
         (result (utilz--run cmdline input-spec "cleanz")))
    (e2e-check "utilz--run returned success" (and result (eq (car result) 0)))
    (when result
      (utilz--output-replace result input-spec "cleanz")
      (let ((after (buffer-string)))
        (e2e-check "cleanz stripped ZWSP"
                   (not (string-match-p "​" after))
                   (format "before=%S after=%S" before after))
        (e2e-check "buffer content matches expected"
                   (string= after "helloworld\n")
                   (format "got %S" after))))))

;; 5. No Silent Errors: a failing cmdline returns nil and leaves the buffer
(let ((orig-buf (generate-new-buffer " *utilz-e2e-test*")))
  (unwind-protect
      (with-current-buffer orig-buf
        (insert "x")
        (let* ((input-spec (list :kind 'stdin :begin (point-min) :end (point-max)))
               (result (utilz--run "false" input-spec "bogus")))
          (e2e-check "non-zero exit returns nil from utilz--run"
                     (null result))
          (e2e-check "buffer untouched on failure"
                     (string= (with-current-buffer orig-buf (buffer-string))
                              "x"))))
    (when (buffer-live-p orig-buf) (kill-buffer orig-buf))))

;; 6. Path-kind cmdline appends the shell-quoted path argument
(let* ((input-spec (list :kind 'path :path "/tmp/example dir"))
       (cmdline (utilz--build-cmdline "gitz" "" nil input-spec)))
  (e2e-check "build-cmdline appends path arg (shell-quoted)"
             (string-match-p "'/tmp/example dir'\\|/tmp/example\\\\ dir" cmdline)
             cmdline))

;; 7. Extra flags (C-u) come after the path, so a declared flag keeps the
;;    path it takes (issue 0047): todo declares --file, and `done 2' landing
;;    between --file and the file is a command todo refuses.
(let ((input-spec (list :kind 'file :path "/tmp/todo.md")))
  (let ((cmdline (utilz--build-cmdline "todo" "--file" "done 2" input-spec)))
    (e2e-check "build-cmdline keeps a declared flag next to the path, extras last"
               (string-match-p "todo --file /tmp/todo\\.md done 2\\'" cmdline)
               cmdline))
  (let ((cmdline (utilz--build-cmdline "todo" "--file" nil input-spec)))
    (e2e-check "build-cmdline without extras is the declared flags then the path"
               (string-match-p "todo --file /tmp/todo\\.md\\'" cmdline)
               cmdline)))

(message "--- %d failure(s) ---" e2e-failures)
(kill-emacs (if (zerop e2e-failures) 0 1))

;;; e2e-smoke.el ends here
