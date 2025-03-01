;;; elisp-mode.el --- Emacs Lisp mode  -*- lexical-binding:t -*-

;; Copyright (C) 1985-1986, 1999-2014 Free Software Foundation, Inc.

;; Maintainer: emacs-devel@gnu.org
;; Keywords: lisp, languages
;; Package: emacs

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; The major mode for editing Emacs Lisp code.
;; This mode is documented in the Emacs manual.

;;; Code:

(require 'lisp-mode)

(defvar emacs-lisp-mode-abbrev-table nil)
(define-abbrev-table 'emacs-lisp-mode-abbrev-table ()
  "Abbrev table for Emacs Lisp mode.
It has `lisp-mode-abbrev-table' as its parent."
  :parents (list lisp-mode-abbrev-table))

(defvar emacs-lisp-mode-syntax-table
  (let ((table (make-syntax-table lisp--mode-syntax-table)))
    (modify-syntax-entry ?\[ "(]  " table)
    (modify-syntax-entry ?\] ")[  " table)
    table)
  "Syntax table used in `emacs-lisp-mode'.")

(defvar emacs-lisp-mode-map
  (let ((map (make-sparse-keymap "Emacs-Lisp"))
	(menu-map (make-sparse-keymap "Emacs-Lisp"))
	(lint-map (make-sparse-keymap))
	(prof-map (make-sparse-keymap))
	(tracing-map (make-sparse-keymap)))
    (set-keymap-parent map lisp-mode-shared-map)
    (define-key map "\e\t" 'completion-at-point)
    (define-key map "\e\C-x" 'eval-defun)
    (define-key map "\e\C-q" 'indent-pp-sexp)
    (bindings--define-key map [menu-bar emacs-lisp]
      (cons "Emacs-Lisp" menu-map))
    (bindings--define-key menu-map [eldoc]
      '(menu-item "Auto-Display Documentation Strings" eldoc-mode
		  :button (:toggle . (bound-and-true-p eldoc-mode))
		  :help "Display the documentation string for the item under cursor"))
    (bindings--define-key menu-map [checkdoc]
      '(menu-item "Check Documentation Strings" checkdoc
		  :help "Check documentation strings for style requirements"))
    (bindings--define-key menu-map [re-builder]
      '(menu-item "Construct Regexp" re-builder
		  :help "Construct a regexp interactively"))
    (bindings--define-key menu-map [tracing] (cons "Tracing" tracing-map))
    (bindings--define-key tracing-map [tr-a]
      '(menu-item "Untrace All" untrace-all
		  :help "Untrace all currently traced functions"))
    (bindings--define-key tracing-map [tr-uf]
      '(menu-item "Untrace Function..." untrace-function
		  :help "Untrace function, and possibly activate all remaining advice"))
    (bindings--define-key tracing-map [tr-sep] menu-bar-separator)
    (bindings--define-key tracing-map [tr-q]
      '(menu-item "Trace Function Quietly..." trace-function-background
		  :help "Trace the function with trace output going quietly to a buffer"))
    (bindings--define-key tracing-map [tr-f]
      '(menu-item "Trace Function..." trace-function
		  :help "Trace the function given as an argument"))
    (bindings--define-key menu-map [profiling] (cons "Profiling" prof-map))
    (bindings--define-key prof-map [prof-restall]
      '(menu-item "Remove Instrumentation for All Functions" elp-restore-all
		  :help "Restore the original definitions of all functions being profiled"))
    (bindings--define-key prof-map [prof-restfunc]
      '(menu-item "Remove Instrumentation for Function..." elp-restore-function
		  :help "Restore an instrumented function to its original definition"))

    (bindings--define-key prof-map [sep-rem] menu-bar-separator)
    (bindings--define-key prof-map [prof-resall]
      '(menu-item "Reset Counters for All Functions" elp-reset-all
		  :help "Reset the profiling information for all functions being profiled"))
    (bindings--define-key prof-map [prof-resfunc]
      '(menu-item "Reset Counters for Function..." elp-reset-function
		  :help "Reset the profiling information for a function"))
    (bindings--define-key prof-map [prof-res]
      '(menu-item "Show Profiling Results" elp-results
		  :help "Display current profiling results"))
    (bindings--define-key prof-map [prof-pack]
      '(menu-item "Instrument Package..." elp-instrument-package
		  :help "Instrument for profiling all function that start with a prefix"))
    (bindings--define-key prof-map [prof-func]
      '(menu-item "Instrument Function..." elp-instrument-function
		  :help "Instrument a function for profiling"))
    ;; Maybe this should be in a separate submenu from the ELP stuff?
    (bindings--define-key prof-map [sep-natprof] menu-bar-separator)
    (bindings--define-key prof-map [prof-natprof-stop]
      '(menu-item "Stop Native Profiler" profiler-stop
		  :help "Stop recording profiling information"
		  :enable (and (featurep 'profiler)
			       (profiler-running-p))))
    (bindings--define-key prof-map [prof-natprof-report]
      '(menu-item "Show Profiler Report" profiler-report
		  :help "Show the current profiler report"
		  :enable (and (featurep 'profiler)
			       (profiler-running-p))))
    (bindings--define-key prof-map [prof-natprof-start]
      '(menu-item "Start Native Profiler..." profiler-start
		  :help "Start recording profiling information"))

    (bindings--define-key menu-map [lint] (cons "Linting" lint-map))
    (bindings--define-key lint-map [lint-di]
      '(menu-item "Lint Directory..." elint-directory
		  :help "Lint a directory"))
    (bindings--define-key lint-map [lint-f]
      '(menu-item "Lint File..." elint-file
		  :help "Lint a file"))
    (bindings--define-key lint-map [lint-b]
      '(menu-item "Lint Buffer" elint-current-buffer
		  :help "Lint the current buffer"))
    (bindings--define-key lint-map [lint-d]
      '(menu-item "Lint Defun" elint-defun
		  :help "Lint the function at point"))
    (bindings--define-key menu-map [edebug-defun]
      '(menu-item "Instrument Function for Debugging" edebug-defun
		  :help "Evaluate the top level form point is in, stepping through with Edebug"
		  :keys "C-u C-M-x"))
    (bindings--define-key menu-map [separator-byte] menu-bar-separator)
    (bindings--define-key menu-map [disas]
      '(menu-item "Disassemble Byte Compiled Object..." disassemble
		  :help "Print disassembled code for OBJECT in a buffer"))
    (bindings--define-key menu-map [byte-recompile]
      '(menu-item "Byte-recompile Directory..." byte-recompile-directory
		  :help "Recompile every `.el' file in DIRECTORY that needs recompilation"))
    (bindings--define-key menu-map [emacs-byte-compile-and-load]
      '(menu-item "Byte-compile and Load" emacs-lisp-byte-compile-and-load
		  :help "Byte-compile the current file (if it has changed), then load compiled code"))
    (bindings--define-key menu-map [byte-compile]
      '(menu-item "Byte-compile This File" emacs-lisp-byte-compile
		  :help "Byte compile the file containing the current buffer"))
    (bindings--define-key menu-map [separator-eval] menu-bar-separator)
    (bindings--define-key menu-map [ielm]
      '(menu-item "Interactive Expression Evaluation" ielm
		  :help "Interactively evaluate Emacs Lisp expressions"))
    (bindings--define-key menu-map [eval-buffer]
      '(menu-item "Evaluate Buffer" eval-buffer
		  :help "Execute the current buffer as Lisp code"))
    (bindings--define-key menu-map [eval-region]
      '(menu-item "Evaluate Region" eval-region
		  :help "Execute the region as Lisp code"
		  :enable mark-active))
    (bindings--define-key menu-map [eval-sexp]
      '(menu-item "Evaluate Last S-expression" eval-last-sexp
		  :help "Evaluate sexp before point; print value in echo area"))
    (bindings--define-key menu-map [separator-format] menu-bar-separator)
    (bindings--define-key menu-map [comment-region]
      '(menu-item "Comment Out Region" comment-region
		  :help "Comment or uncomment each line in the region"
		  :enable mark-active))
    (bindings--define-key menu-map [indent-region]
      '(menu-item "Indent Region" indent-region
		  :help "Indent each nonblank line in the region"
		  :enable mark-active))
    (bindings--define-key menu-map [indent-line]
      '(menu-item "Indent Line" lisp-indent-line))
    map)
  "Keymap for Emacs Lisp mode.
All commands in `lisp-mode-shared-map' are inherited by this map.")

(defun emacs-lisp-byte-compile ()
  "Byte compile the file containing the current buffer."
  (interactive)
  (if buffer-file-name
      (byte-compile-file buffer-file-name)
    (error "The buffer must be saved in a file first")))

(defun emacs-lisp-byte-compile-and-load ()
  "Byte-compile the current file (if it has changed), then load compiled code."
  (interactive)
  (or buffer-file-name
      (error "The buffer must be saved in a file first"))
  (require 'bytecomp)
  ;; Recompile if file or buffer has changed since last compilation.
  (if (and (buffer-modified-p)
	   (y-or-n-p (format "Save buffer %s first? " (buffer-name))))
      (save-buffer))
  (byte-recompile-file buffer-file-name nil 0 t))

(defun emacs-lisp-macroexpand ()
  "Macroexpand the form after point.
Comments in the form will be lost."
  (interactive)
  (let* ((start (point))
         (exp (read (current-buffer)))
         ;; Compute it before, since it may signal errors.
         (new (macroexpand exp)))
    (if (equal exp new)
        (message "Not a macro call, nothing to expand")
      (delete-region start (point))
      (pp new (current-buffer))
      (if (bolp) (delete-char -1))
      (indent-region start (point)))))

(defcustom emacs-lisp-mode-hook nil
  "Hook run when entering Emacs Lisp mode."
  :options '(eldoc-mode imenu-add-menubar-index checkdoc-minor-mode)
  :type 'hook
  :group 'lisp)

;;;###autoload
(define-derived-mode emacs-lisp-mode prog-mode "Emacs-Lisp"
  "Major mode for editing Lisp code to run in Emacs.
Commands:
Delete converts tabs to spaces as it moves back.
Blank lines separate paragraphs.  Semicolons start comments.

\\{emacs-lisp-mode-map}"
  :group 'lisp
  (lisp-mode-variables nil nil 'elisp)
  (setq imenu-case-fold-search nil)
  (setq-local eldoc-documentation-function
              #'elisp-eldoc-documentation-function)
  (add-hook 'completion-at-point-functions
            #'elisp-completion-at-point nil 'local))

;;; Completion at point for Elisp

(defun elisp--local-variables-1 (vars sexp)
  "Return the vars locally bound around the witness, or nil if not found."
  (let (res)
    (while
        (unless
            (setq res
                  (pcase sexp
                    (`(,(or `let `let*) ,bindings)
                     (let ((vars vars))
                       (when (eq 'let* (car sexp))
                         (dolist (binding (cdr (reverse bindings)))
                           (push (or (car-safe binding) binding) vars)))
                       (elisp--local-variables-1
                        vars (car (cdr-safe (car (last bindings)))))))
                    (`(,(or `let `let*) ,bindings . ,body)
                     (let ((vars vars))
                       (dolist (binding bindings)
                         (push (or (car-safe binding) binding) vars))
                       (elisp--local-variables-1 vars (car (last body)))))
                    (`(lambda ,_args)
                     ;; FIXME: Look for the witness inside `args'.
                     (setq sexp nil))
                    (`(lambda ,args . ,body)
                     (elisp--local-variables-1
                      (append (remq '&optional (remq '&rest args)) vars)
                      (car (last body))))
                    (`(condition-case ,_ ,e) (elisp--local-variables-1 vars e))
                    (`(condition-case ,v ,_ . ,catches)
                     (elisp--local-variables-1
                      (cons v vars) (cdr (car (last catches)))))
                    (`(quote . ,_)
                     ;; FIXME: Look for the witness inside sexp.
                     (setq sexp nil))
                    ;; FIXME: Handle `cond'.
                    (`(,_ . ,_)
                     (elisp--local-variables-1 vars (car (last sexp))))
                    (`elisp--witness--lisp (or vars '(nil)))
                    (_ nil)))
          ;; We didn't find the witness in the last element so we try to
          ;; backtrack to the last-but-one.
          (setq sexp (ignore-errors (butlast sexp)))))
    res))

(defun elisp--local-variables ()
  "Return a list of locally let-bound variables at point."
  (save-excursion
    (skip-syntax-backward "w_")
    (let* ((ppss (syntax-ppss))
           (txt (buffer-substring-no-properties (or (car (nth 9 ppss)) (point))
                                                (or (nth 8 ppss) (point))))
           (closer ()))
      (dolist (p (nth 9 ppss))
        (push (cdr (syntax-after p)) closer))
      (setq closer (apply #'string closer))
      (let* ((sexp (condition-case nil
                       (car (read-from-string
                             (concat txt "elisp--witness--lisp" closer)))
                     (end-of-file nil)))
             (macroexpand-advice (lambda (expander form &rest args)
                                   (condition-case nil
                                       (apply expander form args)
                                     (error form))))
             (sexp
              (unwind-protect
                  (progn
                    (advice-add 'macroexpand :around macroexpand-advice)
                    (macroexpand-all sexp))
                (advice-remove 'macroexpand macroexpand-advice)))
             (vars (elisp--local-variables-1 nil sexp)))
        (delq nil
              (mapcar (lambda (var)
                        (and (symbolp var)
                             (not (string-match (symbol-name var) "\\`[&_]"))
                             ;; Eliminate uninterned vars.
                             (intern-soft var)
                             var))
                      vars))))))

(defvar elisp--local-variables-completion-table
  ;; Use `defvar' rather than `defconst' since defconst would purecopy this
  ;; value, which would doubly fail: it would fail because purecopy can't
  ;; handle the recursive bytecode object, and it would fail because it would
  ;; move `lastpos' and `lastvars' to pure space where they'd be immutable!
  (let ((lastpos nil) (lastvars nil))
    (letrec ((hookfun (lambda ()
                        (setq lastpos nil)
                        (remove-hook 'post-command-hook hookfun))))
      (completion-table-dynamic
       (lambda (_string)
         (save-excursion
           (skip-syntax-backward "_w")
           (let ((newpos (cons (point) (current-buffer))))
             (unless (equal lastpos newpos)
               (add-hook 'post-command-hook hookfun)
               (setq lastpos newpos)
               (setq lastvars
                     (mapcar #'symbol-name (elisp--local-variables))))))
         lastvars)))))

(defun elisp--expect-function-p (pos)
  "Return non-nil if the symbol at point is expected to be a function."
  (or
   (and (eq (char-before pos) ?')
        (eq (char-before (1- pos)) ?#))
   (save-excursion
     (let ((parent (nth 1 (syntax-ppss pos))))
       (when parent
         (goto-char parent)
         (and
          (looking-at (concat "(\\(cl-\\)?"
                              (regexp-opt '("declare-function"
                                            "function" "defadvice"
                                            "callf" "callf2"
                                            "defsetf"))
                              "[ \t\r\n]+"))
          (eq (match-end 0) pos)))))))

(defun elisp--form-quoted-p (pos)
  "Return non-nil if the form at POS is not evaluated.
It can be quoted, or be inside a quoted form."
  ;; FIXME: Do some macro expansion maybe.
  (save-excursion
    (let ((state (syntax-ppss pos)))
      (or (nth 8 state)   ; Code inside strings usually isn't evaluated.
          ;; FIXME: The 9th element is undocumented.
          (let ((nesting (cons (point) (reverse (nth 9 state))))
                res)
            (while (and nesting (not res))
              (goto-char (pop nesting))
              (cond
               ((or (eq (char-after) ?\[)
                    (progn
                      (skip-chars-backward " ")
                      (memq (char-before) '(?' ?`))))
                (setq res t))
               ((eq (char-before) ?,)
                (setq nesting nil))))
            res)))))

;; FIXME: Support for Company brings in features which straddle eldoc.
;; We should consolidate this, so that major modes can provide all that
;; data all at once:
;; - a function to extract "the reference at point" (may be more complex
;;     than a mere string, to distinguish various namespaces).
;; - a function to jump to such a reference.
;; - a function to show the signature/interface of such a reference.
;; - a function to build a help-buffer about that reference.
;; FIXME: Those functions should also be used by the normal completion code in
;; the *Completions* buffer.

(defun elisp--company-doc-buffer (str)
  (let ((symbol (intern-soft str)))
    ;; FIXME: we really don't want to "display-buffer and then undo it".
    (save-window-excursion
      ;; Make sure we don't display it in another frame, otherwise
      ;; save-window-excursion won't be able to undo it.
      (let ((display-buffer-overriding-action
             '(nil . ((inhibit-switch-frame . t)))))
        (ignore-errors
          (cond
           ((fboundp symbol) (describe-function symbol))
           ((boundp symbol) (describe-variable symbol))
           ((featurep symbol) (describe-package symbol))
           ((facep symbol) (describe-face symbol))
           (t (signal 'user-error nil)))
          (help-buffer))))))

(defun elisp--company-doc-string (str)
  (let* ((symbol (intern-soft str))
         (doc (if (fboundp symbol)
                  (documentation symbol t)
                (documentation-property symbol 'variable-documentation t))))
    (and (stringp doc)
         (string-match ".*$" doc)
         (match-string 0 doc))))

(declare-function find-library-name "find-func" (library))

(defun elisp--company-location (str)
  (let ((sym (intern-soft str)))
    (cond
     ((fboundp sym) (find-definition-noselect sym nil))
     ((boundp sym) (find-definition-noselect sym 'defvar))
     ((featurep sym)
      (require 'find-func)
      (cons (find-file-noselect (find-library-name
                                 (symbol-name sym)))
            0))
     ((facep sym) (find-definition-noselect sym 'defface)))))

(defun elisp-completion-at-point ()
  "Function used for `completion-at-point-functions' in `emacs-lisp-mode'."
  (with-syntax-table emacs-lisp-mode-syntax-table
    (let* ((pos (point))
	   (beg (condition-case nil
		    (save-excursion
		      (backward-sexp 1)
		      (skip-syntax-forward "'")
		      (point))
		  (scan-error pos)))
	   (end
	    (unless (or (eq beg (point-max))
			(member (char-syntax (char-after beg))
                                '(?\s ?\" ?\( ?\))))
	      (condition-case nil
		  (save-excursion
		    (goto-char beg)
		    (forward-sexp 1)
                    (skip-chars-backward "'")
		    (when (>= (point) pos)
		      (point)))
		(scan-error pos))))
           ;; t if in function position.
           (funpos (eq (char-before beg) ?\()))
      (when (and end (or (not (nth 8 (syntax-ppss)))
                         (eq (char-before beg) ?`)))
        (let ((table-etc
               (if (not funpos)
                   ;; FIXME: We could look at the first element of the list and
                   ;; use it to provide a more specific completion table in some
                   ;; cases.  E.g. filter out keywords that are not understood by
                   ;; the macro/function being called.
                   (cond
                    ((elisp--expect-function-p beg)
                     (list nil obarray
                           :predicate #'fboundp
                           :company-doc-buffer #'elisp--company-doc-buffer
                           :company-docsig #'elisp--company-doc-string
                           :company-location #'elisp--company-location))
                    ((elisp--form-quoted-p beg)
                     (list nil obarray
                           ;; Don't include all symbols
                           ;; (bug#16646).
                           :predicate (lambda (sym)
                                        (or (boundp sym)
                                            (fboundp sym)
                                            (symbol-plist sym)))
                           :annotation-function
                           (lambda (str) (if (fboundp (intern-soft str)) " <f>"))
                           :company-doc-buffer #'elisp--company-doc-buffer
                           :company-docsig #'elisp--company-doc-string
                           :company-location #'elisp--company-location))
                    (t
                     (list nil (completion-table-merge
                                elisp--local-variables-completion-table
                                (apply-partially #'completion-table-with-predicate
                                                 obarray
                                                 #'boundp
                                                 'strict))
                           :company-doc-buffer #'elisp--company-doc-buffer
                           :company-docsig #'elisp--company-doc-string
                           :company-location #'elisp--company-location)))
                 ;; Looks like a funcall position.  Let's double check.
                 (save-excursion
                   (goto-char (1- beg))
                   (let ((parent
                          (condition-case nil
                              (progn (up-list -1) (forward-char 1)
                                     (let ((c (char-after)))
                                       (if (eq c ?\() ?\(
                                         (if (memq (char-syntax c) '(?w ?_))
                                             (read (current-buffer))))))
                            (error nil))))
                     (pcase parent
                       ;; FIXME: Rather than hardcode special cases here,
                       ;; we should use something like a symbol-property.
                       (`declare
                        (list t (mapcar (lambda (x) (symbol-name (car x)))
                                        (delete-dups
                                         ;; FIXME: We should include some
                                         ;; docstring with each entry.
                                         (append
                                          macro-declarations-alist
                                          defun-declarations-alist)))))
                       ((and (or `condition-case `condition-case-unless-debug)
                             (guard (save-excursion
                                      (ignore-errors
                                        (forward-sexp 2)
                                        (< (point) beg)))))
                        (list t obarray
                              :predicate (lambda (sym) (get sym 'error-conditions))))
                       ((and ?\(
                             (guard (save-excursion
                                      (goto-char (1- beg))
                                      (up-list -1)
                                      (forward-symbol -1)
                                      (looking-at "\\_<let\\*?\\_>"))))
                        (list t obarray
                              :predicate #'boundp
                              :company-doc-buffer #'elisp--company-doc-buffer
                              :company-docsig #'elisp--company-doc-string
                              :company-location #'elisp--company-location))
                       (_ (list nil obarray
                                :predicate #'fboundp
                                :company-doc-buffer #'elisp--company-doc-buffer
                                :company-docsig #'elisp--company-doc-string
                                :company-location #'elisp--company-location
                                ))))))))
          (nconc (list beg end)
                 (if (null (car table-etc))
                     (cdr table-etc)
                   (cons
                    (if (memq (char-syntax (or (char-after end) ?\s))
                              '(?\s ?>))
                        (cadr table-etc)
                      (apply-partially 'completion-table-with-terminator
                                       " " (cadr table-etc)))
                    (cddr table-etc)))))))))

(define-obsolete-function-alias
  'lisp-completion-at-point 'elisp-completion-at-point "25.1")

;;; Elisp Interaction mode

(defvar lisp-interaction-mode-map
  (let ((map (make-sparse-keymap))
	(menu-map (make-sparse-keymap "Lisp-Interaction")))
    (set-keymap-parent map lisp-mode-shared-map)
    (define-key map "\e\C-x" 'eval-defun)
    (define-key map "\e\C-q" 'indent-pp-sexp)
    (define-key map "\e\t" 'completion-at-point)
    (define-key map "\n" 'eval-print-last-sexp)
    (bindings--define-key map [menu-bar lisp-interaction]
      (cons "Lisp-Interaction" menu-map))
    (bindings--define-key menu-map [eval-defun]
      '(menu-item "Evaluate Defun" eval-defun
		  :help "Evaluate the top-level form containing point, or after point"))
    (bindings--define-key menu-map [eval-print-last-sexp]
      '(menu-item "Evaluate and Print" eval-print-last-sexp
		  :help "Evaluate sexp before point; print value into current buffer"))
    (bindings--define-key menu-map [edebug-defun-lisp-interaction]
      '(menu-item "Instrument Function for Debugging" edebug-defun
		  :help "Evaluate the top level form point is in, stepping through with Edebug"
		  :keys "C-u C-M-x"))
    (bindings--define-key menu-map [indent-pp-sexp]
      '(menu-item "Indent or Pretty-Print" indent-pp-sexp
		  :help "Indent each line of the list starting just after point, or prettyprint it"))
    (bindings--define-key menu-map [complete-symbol]
      '(menu-item "Complete Lisp Symbol" completion-at-point
		  :help "Perform completion on Lisp symbol preceding point"))
    map)
  "Keymap for Lisp Interaction mode.
All commands in `lisp-mode-shared-map' are inherited by this map.")

(define-derived-mode lisp-interaction-mode emacs-lisp-mode "Lisp Interaction"
  "Major mode for typing and evaluating Lisp forms.
Like Lisp mode except that \\[eval-print-last-sexp] evals the Lisp expression
before point, and prints its value into the buffer, advancing point.
Note that printing is controlled by `eval-expression-print-length'
and `eval-expression-print-level'.

Commands:
Delete converts tabs to spaces as it moves back.
Paragraphs are separated only by blank lines.
Semicolons start comments.

\\{lisp-interaction-mode-map}"
  :abbrev-table nil)

;;; Emacs Lisp Byte-Code mode

(eval-and-compile
  (defconst emacs-list-byte-code-comment-re
    (concat "\\(#\\)@\\([0-9]+\\) "
            ;; Make sure it's a docstring and not a lazy-loaded byte-code.
            "\\(?:[^(]\\|([^\"]\\)")))

(defun elisp--byte-code-comment (end &optional _point)
  "Try to syntactically mark the #@NNN ....^_ docstrings in byte-code files."
  (let ((ppss (syntax-ppss)))
    (when (and (nth 4 ppss)
               (eq (char-after (nth 8 ppss)) ?#))
      (let* ((n (save-excursion
                  (goto-char (nth 8 ppss))
                  (when (looking-at emacs-list-byte-code-comment-re)
                    (string-to-number (match-string 2)))))
             ;; `maxdiff' tries to make sure the loop below terminates.
             (maxdiff n))
        (when n
          (let* ((bchar (match-end 2))
                 (b (position-bytes bchar)))
            (goto-char (+ b n))
            (while (let ((diff (- (position-bytes (point)) b n)))
                     (unless (zerop diff)
                       (when (> diff maxdiff) (setq diff maxdiff))
                       (forward-char (- diff))
                       (setq maxdiff (if (> diff 0) diff
                                       (max (1- maxdiff) 1)))
                       t))))
          (if (<= (point) end)
              (put-text-property (1- (point)) (point)
                                 'syntax-table
                                 (string-to-syntax "> b"))
            (goto-char end)))))))

(defun elisp-byte-code-syntax-propertize (start end)
  (elisp--byte-code-comment end (point))
  (funcall
   (syntax-propertize-rules
    (emacs-list-byte-code-comment-re
     (1 (prog1 "< b" (elisp--byte-code-comment end (point))))))
   start end))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.elc\\'" . elisp-byte-code-mode))
;;;###autoload
(define-derived-mode elisp-byte-code-mode emacs-lisp-mode
  "Elisp-Byte-Code"
  "Major mode for *.elc files."
  ;; TODO: Add way to disassemble byte-code under point.
  (setq-local open-paren-in-column-0-is-defun-start nil)
  (setq-local syntax-propertize-function
              #'elisp-byte-code-syntax-propertize))


;;; Globally accessible functionality

(defun eval-print-last-sexp (&optional eval-last-sexp-arg-internal)
  "Evaluate sexp before point; print value into current buffer.

Normally, this function truncates long output according to the value
of the variables `eval-expression-print-length' and
`eval-expression-print-level'.  With a prefix argument of zero,
however, there is no such truncation.  Such a prefix argument
also causes integers to be printed in several additional formats
\(octal, hexadecimal, and character).

If `eval-expression-debug-on-error' is non-nil, which is the default,
this command arranges for all errors to enter the debugger."
  (interactive "P")
  (let ((standard-output (current-buffer)))
    (terpri)
    (eval-last-sexp (or eval-last-sexp-arg-internal t))
    (terpri)))


(defun last-sexp-setup-props (beg end value alt1 alt2)
  "Set up text properties for the output of `elisp--eval-last-sexp'.
BEG and END are the start and end of the output in current-buffer.
VALUE is the Lisp value printed, ALT1 and ALT2 are strings for the
alternative printed representations that can be displayed."
  (let ((map (make-sparse-keymap)))
    (define-key map "\C-m" 'elisp-last-sexp-toggle-display)
    (define-key map [down-mouse-2] 'mouse-set-point)
    (define-key map [mouse-2] 'elisp-last-sexp-toggle-display)
    (add-text-properties
     beg end
     `(printed-value (,value ,alt1 ,alt2)
		     mouse-face highlight
		     keymap ,map
		     help-echo "RET, mouse-2: toggle abbreviated display"
		     rear-nonsticky (mouse-face keymap help-echo
						printed-value)))))


(defun elisp-last-sexp-toggle-display (&optional _arg)
  "Toggle between abbreviated and unabbreviated printed representations."
  (interactive "P")
  (save-restriction
    (widen)
    (let ((value (get-text-property (point) 'printed-value)))
      (when value
	(let ((beg (or (previous-single-property-change (min (point-max) (1+ (point)))
							'printed-value)
		       (point)))
	      (end (or (next-single-char-property-change (point) 'printed-value) (point)))
	      (standard-output (current-buffer))
	      (point (point)))
	  (delete-region beg end)
	  (insert (nth 1 value))
	  (or (= beg point)
	      (setq point (1- (point))))
	  (last-sexp-setup-props beg (point)
				 (nth 0 value)
				 (nth 2 value)
				 (nth 1 value))
	  (goto-char (min (point-max) point)))))))

(defun prin1-char (char)                ;FIXME: Move it, e.g. to simple.el.
  "Return a string representing CHAR as a character rather than as an integer.
If CHAR is not a character, return nil."
  (and (integerp char)
       (eventp char)
       (let ((c (event-basic-type char))
	     (mods (event-modifiers char))
	     string)
	 ;; Prevent ?A from turning into ?\S-a.
	 (if (and (memq 'shift mods)
		  (zerop (logand char ?\S-\^@))
		  (not (let ((case-fold-search nil))
			 (char-equal c (upcase c)))))
	     (setq c (upcase c) mods nil))
	 ;; What string are we considering using?
	 (condition-case nil
	     (setq string
		   (concat
		    "?"
		    (mapconcat
		     (lambda (modif)
		       (cond ((eq modif 'super) "\\s-")
			     (t (string ?\\ (upcase (aref (symbol-name modif) 0)) ?-))))
		     mods "")
		    (cond
		     ((memq c '(?\; ?\( ?\) ?\{ ?\} ?\[ ?\] ?\" ?\' ?\\)) (string ?\\ c))
		     ((eq c 127) "\\C-?")
		     (t
		      (string c)))))
	   (error nil))
	 ;; Verify the string reads a CHAR, not to some other character.
	 ;; If it doesn't, return nil instead.
	 (and string
	      (= (car (read-from-string string)) char)
	      string))))

(defun elisp--preceding-sexp ()
  "Return sexp before the point."
  (let ((opoint (point))
	ignore-quotes
	expr)
    (save-excursion
      (with-syntax-table emacs-lisp-mode-syntax-table
	;; If this sexp appears to be enclosed in `...'
	;; then ignore the surrounding quotes.
	(setq ignore-quotes
	      (or (eq (following-char) ?\')
		  (eq (preceding-char) ?\')))
	(forward-sexp -1)
	;; If we were after `?\e' (or similar case),
	;; use the whole thing, not just the `e'.
	(when (eq (preceding-char) ?\\)
	  (forward-char -1)
	  (when (eq (preceding-char) ??)
	    (forward-char -1)))

	;; Skip over hash table read syntax.
	(and (> (point) (1+ (point-min)))
	     (looking-back "#s" (- (point) 2))
	     (forward-char -2))

	;; Skip over `#N='s.
	(when (eq (preceding-char) ?=)
	  (let (labeled-p)
	    (save-excursion
	      (skip-chars-backward "0-9#=")
	      (setq labeled-p (looking-at "\\(#[0-9]+=\\)+")))
	    (when labeled-p
	      (forward-sexp -1))))

	(save-restriction
	  (if (and ignore-quotes (eq (following-char) ?`))
              ;; vladimir@cs.ualberta.ca 30-Jul-1997: Skip ` in `variable' so
              ;; that the value is returned, not the name.
	      (forward-char))
          (when (looking-at ",@?") (goto-char (match-end 0)))
	  (narrow-to-region (point-min) opoint)
	  (setq expr (read (current-buffer)))
          ;; If it's an (interactive ...) form, it's more useful to show how an
          ;; interactive call would use it.
          ;; FIXME: Is it really the right place for this?
          (when (eq (car-safe expr) 'interactive)
	       (setq expr
                  `(call-interactively
                    (lambda (&rest args) ,expr args))))
	  expr)))))
(define-obsolete-function-alias 'preceding-sexp 'elisp--preceding-sexp "25.1")

(defun elisp--eval-last-sexp (eval-last-sexp-arg-internal)
  "Evaluate sexp before point; print value in the echo area.
With argument, print output into current buffer.
With a zero prefix arg, print output with no limit on the length
and level of lists, and include additional formats for integers
\(octal, hexadecimal, and character)."
  (let ((standard-output (if eval-last-sexp-arg-internal (current-buffer) t)))
    ;; Setup the lexical environment if lexical-binding is enabled.
    (elisp--eval-last-sexp-print-value
     (eval (eval-sexp-add-defvars (elisp--preceding-sexp)) lexical-binding)
     eval-last-sexp-arg-internal)))


(defun elisp--eval-last-sexp-print-value (value &optional eval-last-sexp-arg-internal)
  (let ((unabbreviated (let ((print-length nil) (print-level nil))
			 (prin1-to-string value)))
	(print-length (and (not (zerop (prefix-numeric-value
					eval-last-sexp-arg-internal)))
			   eval-expression-print-length))
	(print-level (and (not (zerop (prefix-numeric-value
				       eval-last-sexp-arg-internal)))
			  eval-expression-print-level))
	(beg (point))
	end)
    (prog1
	(prin1 value)
      (let ((str (eval-expression-print-format value)))
	(if str (princ str)))
      (setq end (point))
      (when (and (bufferp standard-output)
		 (or (not (null print-length))
		     (not (null print-level)))
		 (not (string= unabbreviated
			       (buffer-substring-no-properties beg end))))
	(last-sexp-setup-props beg end value
			       unabbreviated
			       (buffer-substring-no-properties beg end))
	))))


(defvar elisp--eval-last-sexp-fake-value (make-symbol "t"))

(defun eval-sexp-add-defvars (exp &optional pos)
  "Prepend EXP with all the `defvar's that precede it in the buffer.
POS specifies the starting position where EXP was found and defaults to point."
  (setq exp (macroexpand-all exp))      ;Eager macro-expansion.
  (if (not lexical-binding)
      exp
    (save-excursion
      (unless pos (setq pos (point)))
      (let ((vars ()))
        (goto-char (point-min))
        (while (re-search-forward
                "(def\\(?:var\\|const\\|custom\\)[ \t\n]+\\([^; '()\n\t]+\\)"
                pos t)
          (let ((var (intern (match-string 1))))
            (and (not (special-variable-p var))
                 (save-excursion
                   (zerop (car (syntax-ppss (match-beginning 0)))))
              (push var vars))))
        `(progn ,@(mapcar (lambda (v) `(defvar ,v)) vars) ,exp)))))

(defun eval-last-sexp (eval-last-sexp-arg-internal)
  "Evaluate sexp before point; print value in the echo area.
Interactively, with prefix argument, print output into current buffer.

Normally, this function truncates long output according to the value
of the variables `eval-expression-print-length' and
`eval-expression-print-level'.  With a prefix argument of zero,
however, there is no such truncation.  Such a prefix argument
also causes integers to be printed in several additional formats
\(octal, hexadecimal, and character).

If `eval-expression-debug-on-error' is non-nil, which is the default,
this command arranges for all errors to enter the debugger."
  (interactive "P")
  (if (null eval-expression-debug-on-error)
      (elisp--eval-last-sexp eval-last-sexp-arg-internal)
    (let ((value
	   (let ((debug-on-error elisp--eval-last-sexp-fake-value))
	     (cons (elisp--eval-last-sexp eval-last-sexp-arg-internal)
		   debug-on-error))))
      (unless (eq (cdr value) elisp--eval-last-sexp-fake-value)
	(setq debug-on-error (cdr value)))
      (car value))))

(defun elisp--eval-defun-1 (form)
  "Treat some expressions specially.
Reset the `defvar' and `defcustom' variables to the initial value.
\(For `defcustom', use the :set function if there is one.)
Reinitialize the face according to the `defface' specification."
  ;; The code in edebug-defun should be consistent with this, but not
  ;; the same, since this gets a macroexpanded form.
  (cond ((not (listp form))
	 form)
	((and (eq (car form) 'defvar)
	      (cdr-safe (cdr-safe form))
	      (boundp (cadr form)))
	 ;; Force variable to be re-set.
	 `(progn (defvar ,(nth 1 form) nil ,@(nthcdr 3 form))
		 (setq-default ,(nth 1 form) ,(nth 2 form))))
	;; `defcustom' is now macroexpanded to
	;; `custom-declare-variable' with a quoted value arg.
	((and (eq (car form) 'custom-declare-variable)
	      (default-boundp (eval (nth 1 form) lexical-binding)))
	 ;; Force variable to be bound, using :set function if specified.
	 (let ((setfunc (memq :set form)))
	   (when setfunc
	     (setq setfunc (car-safe (cdr-safe setfunc)))
	     (or (functionp setfunc) (setq setfunc nil)))
	   (funcall (or setfunc 'set-default)
		    (eval (nth 1 form) lexical-binding)
		    ;; The second arg is an expression that evaluates to
		    ;; an expression.  The second evaluation is the one
		    ;; normally performed not by normal execution but by
		    ;; custom-initialize-set (for example), which does not
		    ;; use lexical-binding.
		    (eval (eval (nth 2 form) lexical-binding))))
	 form)
	;; `defface' is macroexpanded to `custom-declare-face'.
	((eq (car form) 'custom-declare-face)
	 ;; Reset the face.
	 (let ((face-symbol (eval (nth 1 form) lexical-binding)))
	   (setq face-new-frame-defaults
		 (assq-delete-all face-symbol face-new-frame-defaults))
	   (put face-symbol 'face-defface-spec nil)
	   (put face-symbol 'face-override-spec nil))
	 form)
	((eq (car form) 'progn)
	 (cons 'progn (mapcar #'elisp--eval-defun-1 (cdr form))))
	(t form)))

(defun elisp--eval-defun ()
  "Evaluate defun that point is in or before.
The value is displayed in the echo area.
If the current defun is actually a call to `defvar',
then reset the variable using the initial value expression
even if the variable already has some other value.
\(Normally `defvar' does not change the variable's value
if it already has a value.\)

Return the result of evaluation."
  ;; FIXME: the print-length/level bindings should only be applied while
  ;; printing, not while evaluating.
  (let ((debug-on-error eval-expression-debug-on-error)
	(print-length eval-expression-print-length)
	(print-level eval-expression-print-level))
    (save-excursion
      ;; Arrange for eval-region to "read" the (possibly) altered form.
      ;; eval-region handles recording which file defines a function or
      ;; variable.
      (let ((standard-output t)
            beg end form)
        ;; Read the form from the buffer, and record where it ends.
        (save-excursion
          (end-of-defun)
          (beginning-of-defun)
          (setq beg (point))
          (setq form (read (current-buffer)))
          (setq end (point)))
        ;; Alter the form if necessary.
        (let ((form (eval-sexp-add-defvars
                     (elisp--eval-defun-1 (macroexpand form)))))
          (eval-region beg end standard-output
                       (lambda (_ignore)
                         ;; Skipping to the end of the specified region
                         ;; will make eval-region return.
                         (goto-char end)
                         form))))))
  (let ((str (eval-expression-print-format (car values))))
    (if str (princ str)))
  ;; The result of evaluation has been put onto VALUES.  So return it.
  (car values))

(defun eval-defun (edebug-it)
  "Evaluate the top-level form containing point, or after point.

If the current defun is actually a call to `defvar' or `defcustom',
evaluating it this way resets the variable using its initial value
expression (using the defcustom's :set function if there is one), even
if the variable already has some other value.  \(Normally `defvar' and
`defcustom' do not alter the value if there already is one.)  In an
analogous way, evaluating a `defface' overrides any customizations of
the face, so that it becomes defined exactly as the `defface' expression
says.

If `eval-expression-debug-on-error' is non-nil, which is the default,
this command arranges for all errors to enter the debugger.

With a prefix argument, instrument the code for Edebug.

If acting on a `defun' for FUNCTION, and the function was
instrumented, `Edebug: FUNCTION' is printed in the echo area.  If not
instrumented, just FUNCTION is printed.

If not acting on a `defun', the result of evaluation is displayed in
the echo area.  This display is controlled by the variables
`eval-expression-print-length' and `eval-expression-print-level',
which see."
  (interactive "P")
  (cond (edebug-it
	 (require 'edebug)
	 (eval-defun (not edebug-all-defs)))
	(t
	 (if (null eval-expression-debug-on-error)
	     (elisp--eval-defun)
	   (let (new-value value)
	     (let ((debug-on-error elisp--eval-last-sexp-fake-value))
	       (setq value (elisp--eval-defun))
	       (setq new-value debug-on-error))
	     (unless (eq elisp--eval-last-sexp-fake-value new-value)
	       (setq debug-on-error new-value))
	     value)))))

;;; ElDoc Support

(defvar elisp--eldoc-last-data (make-vector 3 nil)
  "Bookkeeping; elements are as follows:
  0 - contains the last symbol read from the buffer.
  1 - contains the string last displayed in the echo area for variables,
      or argument string for functions.
  2 - 'function if function args, 'variable if variable documentation.")

(defun elisp-eldoc-documentation-function ()
  "`eldoc-documentation-function' (which see) for Emacs Lisp."
  (let ((current-symbol (elisp--current-symbol))
	(current-fnsym  (elisp--fnsym-in-current-sexp)))
    (cond ((null current-fnsym)
	   nil)
	  ((eq current-symbol (car current-fnsym))
	   (or (apply #'elisp--get-fnsym-args-string current-fnsym)
	       (elisp--get-var-docstring current-symbol)))
	  (t
	   (or (elisp--get-var-docstring current-symbol)
	       (apply #'elisp--get-fnsym-args-string current-fnsym))))))

(defun elisp--get-fnsym-args-string (sym &optional index)
  "Return a string containing the parameter list of the function SYM.
If SYM is a subr and no arglist is obtainable from the docstring
or elsewhere, return a 1-line docstring."
  (let ((argstring
	 (cond
	  ((not (and sym (symbolp sym) (fboundp sym))) nil)
	  ((and (eq sym (aref elisp--eldoc-last-data 0))
		(eq 'function (aref elisp--eldoc-last-data 2)))
	   (aref elisp--eldoc-last-data 1))
	  (t
	   (let* ((advertised (gethash (indirect-function sym)
                                       advertised-signature-table t))
                  doc
		  (args
		   (cond
		    ((listp advertised) advertised)
		    ((setq doc (help-split-fundoc (documentation sym t) sym))
		     (car doc))
		    (t (help-function-arglist sym)))))
             ;; Stringify, and store before highlighting, downcasing, etc.
             ;; FIXME should truncate before storing.
	     (elisp--last-data-store sym (elisp--function-argstring args)
                                    'function))))))
    ;; Highlight, truncate.
    (if argstring
	(elisp--highlight-function-argument sym argstring index))))

(defun elisp--highlight-function-argument (sym args index)
  "Highlight argument INDEX in ARGS list for function SYM.
In the absence of INDEX, just call `elisp--docstring-format-sym-doc'."
  ;; FIXME: This should probably work on the list representation of `args'
  ;; rather than its string representation.
  ;; FIXME: This function is much too long, we need to split it up!
  (let ((start          nil)
	(end            0)
	(argument-face  'eldoc-highlight-function-argument)
        (args-lst (mapcar (lambda (x)
                            (replace-regexp-in-string
                             "\\`[(]\\|[)]\\'" "" x))
                          (split-string args))))
    ;; Find the current argument in the argument string.  We need to
    ;; handle `&rest' and informal `...' properly.
    ;;
    ;; FIXME: What to do with optional arguments, like in
    ;;        (defun NAME ARGLIST [DOCSTRING] BODY...) case?
    ;;        The problem is there is no robust way to determine if
    ;;        the current argument is indeed a docstring.

    ;; When `&key' is used finding position based on `index'
    ;; would be wrong, so find the arg at point and determine
    ;; position in ARGS based on this current arg.
    (when (string-match "&key" args)
      (let* (case-fold-search
             key-have-value
             (sym-name (symbol-name sym))
             (cur-w (current-word))
             (args-lst-ak (cdr (member "&key" args-lst)))
             (limit (save-excursion
                      (when (re-search-backward sym-name nil t)
                        (match-end 0))))
             (cur-a (if (and cur-w (string-match ":\\([^ ()]*\\)" cur-w))
                        (substring cur-w 1)
                      (save-excursion
                        (let (split)
                          (when (re-search-backward ":\\([^()\n]*\\)" limit t)
                            (setq split (split-string (match-string 1) " " t))
                            (prog1 (car split)
                              (when (cdr split)
                                (setq key-have-value t))))))))
             ;; If `cur-a' is not one of `args-lst-ak'
             ;; assume user is entering an unknown key
             ;; referenced in last position in signature.
             (other-key-arg (and (stringp cur-a)
                                 args-lst-ak
                                 (not (member (upcase cur-a) args-lst-ak))
                                 (upcase (car (last args-lst-ak))))))
        (unless (string= cur-w sym-name)
          ;; The last keyword have already a value
          ;; i.e :foo a b and cursor is at b.
          ;; If signature have also `&rest'
          ;; (assume it is after the `&key' section)
          ;; go to the arg after `&rest'.
          (if (and key-have-value
                   (save-excursion
                     (not (re-search-forward ":.*" (point-at-eol) t)))
                   (string-match "&rest \\([^ ()]*\\)" args))
              (setq index nil ; Skip next block based on positional args.
                    start (match-beginning 1)
                    end   (match-end 1))
            ;; If `cur-a' is nil probably cursor is on a positional arg
            ;; before `&key', in this case, exit this block and determine
            ;; position with `index'.
            (when (and cur-a     ; A keyword arg (dot removed) or nil.
                       (or (string-match
                            (concat "\\_<" (upcase cur-a) "\\_>") args)
                           (string-match
                            (concat "\\_<" other-key-arg "\\_>") args)))
              (setq index nil ; Skip next block based on positional args.
                    start (match-beginning 0)
                    end   (match-end 0)))))))
    ;; Handle now positional arguments.
    (while (and index (>= index 1))
      (if (string-match "[^ ()]+" args end)
	  (progn
	    (setq start (match-beginning 0)
		  end   (match-end 0))
	    (let ((argument (match-string 0 args)))
	      (cond ((string= argument "&rest")
		     ;; All the rest arguments are the same.
		     (setq index 1))
		    ((string= argument "&optional"))         ; Skip.
                    ((string= argument "&allow-other-keys")) ; Skip.
                    ;; Back to index 0 in ARG1 ARG2 ARG2 ARG3 etc...
                    ;; like in `setq'.
		    ((or (and (string-match-p "\\.\\.\\.$" argument)
                              (string= argument (car (last args-lst))))
                         (and (string-match-p "\\.\\.\\.$"
                                              (substring args 1 (1- (length args))))
                              (= (length (remove "..." args-lst)) 2)
                              (> index 1) (eq (logand index 1) 1)))
                     (setq index 0))
		    (t
		     (setq index (1- index))))))
	(setq end           (length args)
	      start         (1- end)
	      argument-face 'font-lock-warning-face
	      index         0)))
    (let ((doc args))
      (when start
	(setq doc (copy-sequence args))
	(add-text-properties start end (list 'face argument-face) doc))
      (setq doc (elisp--docstring-format-sym-doc
		 sym doc (if (functionp sym) 'font-lock-function-name-face
                           'font-lock-keyword-face)))
      doc)))

;; Return a string containing a brief (one-line) documentation string for
;; the variable.
(defun elisp--get-var-docstring (sym)
  (cond ((not sym) nil)
        ((and (eq sym (aref elisp--eldoc-last-data 0))
              (eq 'variable (aref elisp--eldoc-last-data 2)))
         (aref elisp--eldoc-last-data 1))
        (t
         (let ((doc (documentation-property sym 'variable-documentation t)))
           (when doc
             (let ((doc (elisp--docstring-format-sym-doc
                         sym (elisp--docstring-first-line doc)
                         'font-lock-variable-name-face)))
               (elisp--last-data-store sym doc 'variable)))))))

(defun elisp--last-data-store (symbol doc type)
  (aset elisp--eldoc-last-data 0 symbol)
  (aset elisp--eldoc-last-data 1 doc)
  (aset elisp--eldoc-last-data 2 type)
  doc)

;; Note that any leading `*' in the docstring (which indicates the variable
;; is a user option) is removed.
(defun elisp--docstring-first-line (doc)
  (and (stringp doc)
       (substitute-command-keys
        (save-match-data
	  ;; Don't use "^" in the regexp below since it may match
	  ;; anywhere in the doc-string.
	  (let ((start (if (string-match "\\`\\*" doc) (match-end 0) 0)))
            (cond ((string-match "\n" doc)
                   (substring doc start (match-beginning 0)))
                  ((zerop start) doc)
                  (t (substring doc start))))))))

(defvar eldoc-echo-area-use-multiline-p)

;; If the entire line cannot fit in the echo area, the symbol name may be
;; truncated or eliminated entirely from the output to make room for the
;; description.
(defun elisp--docstring-format-sym-doc (sym doc face)
  (save-match-data
    (let* ((name (symbol-name sym))
           (ea-multi eldoc-echo-area-use-multiline-p)
           ;; Subtract 1 from window width since emacs will not write
           ;; any chars to the last column, or in later versions, will
           ;; cause a wraparound and resize of the echo area.
           (ea-width (1- (window-width (minibuffer-window))))
           (strip (- (+ (length name) (length ": ") (length doc)) ea-width)))
      (cond ((or (<= strip 0)
                 (eq ea-multi t)
                 (and ea-multi (> (length doc) ea-width)))
             (format "%s: %s" (propertize name 'face face) doc))
            ((> (length doc) ea-width)
             (substring (format "%s" doc) 0 ea-width))
            ((>= strip (length name))
             (format "%s" doc))
            (t
             ;; Show the end of the partial symbol name, rather
             ;; than the beginning, since the former is more likely
             ;; to be unique given package namespace conventions.
             (setq name (substring name strip))
             (format "%s: %s" (propertize name 'face face) doc))))))


;; Return a list of current function name and argument index.
(defun elisp--fnsym-in-current-sexp ()
  (save-excursion
    (let ((argument-index (1- (elisp--beginning-of-sexp))))
      ;; If we are at the beginning of function name, this will be -1.
      (when (< argument-index 0)
	(setq argument-index 0))
      ;; Don't do anything if current word is inside a string.
      (if (= (or (char-after (1- (point))) 0) ?\")
	  nil
	(list (elisp--current-symbol) argument-index)))))

;; Move to the beginning of current sexp.  Return the number of nested
;; sexp the point was over or after.
(defun elisp--beginning-of-sexp ()
  (let ((parse-sexp-ignore-comments t)
	(num-skipped-sexps 0))
    (condition-case _
	(progn
	  ;; First account for the case the point is directly over a
	  ;; beginning of a nested sexp.
	  (condition-case _
	      (let ((p (point)))
		(forward-sexp -1)
		(forward-sexp 1)
		(when (< (point) p)
		  (setq num-skipped-sexps 1)))
	    (error))
	  (while
	      (let ((p (point)))
		(forward-sexp -1)
		(when (< (point) p)
		  (setq num-skipped-sexps (1+ num-skipped-sexps))))))
      (error))
    num-skipped-sexps))

;; returns nil unless current word is an interned symbol.
(defun elisp--current-symbol ()
  (let ((c (char-after (point))))
    (and c
         (memq (char-syntax c) '(?w ?_))
         (intern-soft (current-word)))))

(defun elisp--function-argstring (arglist)
  "Return ARGLIST as a string enclosed by ().
ARGLIST is either a string, or a list of strings or symbols."
  (let ((str (cond ((stringp arglist) arglist)
                   ((not (listp arglist)) nil)
                   (t (format "%S" (help-make-usage 'toto arglist))))))
    (if (and str (string-match "\\`([^ )]+ ?" str))
        (replace-match "(" t t str)
      str)))

(provide 'elisp-mode)
;;; elisp-mode.el ends here
