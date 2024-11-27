;;; repeat-tests.el --- Tests for repeat.el          -*- lexical-binding: t; -*-

;; Copyright (C) 2021-2024 Free Software Foundation, Inc.

;; Author: Juri Linkov <juri@linkov.net>

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
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Code:

(require 'ert)
(require 'repeat)

;; Key mnemonics: a - Activate (enter, also b), c - Continue (also d),
;;                q - Quit (exit)

(defvar repeat-tests-calls nil)

(defun repeat-tests-call-a (&optional arg)
  (interactive "p")
  (push `(,arg a) repeat-tests-calls))

(defun repeat-tests-call-b (&optional arg)
  (interactive "p")
  (push `(,arg b) repeat-tests-calls))

(defun repeat-tests-call-c (&optional arg)
  (interactive "p")
  (push `(,arg c) repeat-tests-calls))

(defun repeat-tests-call-d (&optional arg)
  (interactive "p")
  (push `(,arg d) repeat-tests-calls))

(defun repeat-tests-call-q (&optional arg)
  (interactive "p")
  (push `(,arg q) repeat-tests-calls))

;; Global keybindings
(defvar-keymap repeat-tests-map
  :doc "Keymap for keys that initiate repeating sequences."
  "C-x w a" 'repeat-tests-call-a
  "C-M-a"   'repeat-tests-call-a
  "C-M-b"   'repeat-tests-call-b)

(defvar-keymap repeat-tests-repeat-map
  :doc "Keymap for repeating sequences."
  :repeat ( :enter (repeat-tests-call-a)
            :exit  (repeat-tests-call-q))
  "a"     'ignore ;; for non-nil repeat-check-key only
  "c"     'repeat-tests-call-c
  "d"     'repeat-tests-call-d
  "q"     'repeat-tests-call-q)

;; Test using a variable instead of the symbol:
(put 'repeat-tests-call-b 'repeat-map repeat-tests-repeat-map)

(defmacro with-repeat-mode (map &rest body)
  "Create environment for testing `repeat-mode'."
  (declare (indent 1) (debug (symbol body)))
  `(unwind-protect
       (progn
         (repeat-mode +1)
         (with-temp-buffer
           (save-window-excursion
             ;; `execute-kbd-macro' applied to window only
             (set-window-buffer nil (current-buffer))
             (use-local-map ,map)
             ,@body)))
     (repeat-mode -1)
     (use-local-map nil)))

(defun repeat-tests--check (keys calls inserted)
  (setq repeat-tests-calls nil)
  (delete-region (point-min) (point-max))
  (execute-kbd-macro (kbd keys))
  (should (equal (nreverse repeat-tests-calls) calls))
  ;; Check for self-inserting keys
  (should (equal (buffer-string) inserted)))

(ert-deftest repeat-tests-check-key ()
  (with-repeat-mode repeat-tests-map
    (let ((repeat-echo-function 'ignore))
      (let ((repeat-check-key t))
        (repeat-tests--check
         "C-x w a c d z"
         '((1 a) (1 c) (1 d)) "z")
        (repeat-tests--check
         "C-M-a c d z"
         '((1 a) (1 c) (1 d)) "z")
        (repeat-tests--check
         "C-M-b c d z"
         '((1 b)) "cdz")
        (unwind-protect
            (progn
              (put 'repeat-tests-call-b 'repeat-check-key 'no)
              (repeat-tests--check
               "C-M-b c d z"
               '((1 b) (1 c) (1 d)) "z"))
          (put 'repeat-tests-call-b 'repeat-check-key nil)))
      (let ((repeat-check-key nil))
        (repeat-tests--check
         "C-M-b c d z"
         '((1 b) (1 c) (1 d)) "z")
        (unwind-protect
            (progn
              (put 'repeat-tests-call-b 'repeat-check-key t)
              (repeat-tests--check
               "C-M-b c d z"
               '((1 b)) "cdz"))
          (put 'repeat-tests-call-b 'repeat-check-key nil))))))

(ert-deftest repeat-tests-exit-command ()
  (with-repeat-mode repeat-tests-map
    (let ((repeat-echo-function 'ignore))
      ;; 'c' doesn't continue since 'q' exited
      (repeat-tests--check
       "C-x w a c d q c"
       '((1 a) (1 c) (1 d) (1 q)) "c"))))

(ert-deftest repeat-tests-exit-key ()
  (with-repeat-mode repeat-tests-map
    (let ((repeat-echo-function 'ignore))
      (let ((repeat-exit-key nil))
        (repeat-tests--check
         "C-x w a c d c RET z"
         '((1 a) (1 c) (1 d) (1 c)) "\nz"))
      (let ((repeat-exit-key [return]))
        (repeat-tests--check
         "C-x w a c d c <return> z"
         '((1 a) (1 c) (1 d) (1 c)) "z")))))

(ert-deftest repeat-tests-keep-prefix ()
  (with-repeat-mode repeat-tests-map
    (let ((repeat-echo-function 'ignore))
      (repeat-tests--check
       "C-x w a c d c z"
       '((1 a) (1 c) (1 d) (1 c)) "z")
      (let ((repeat-keep-prefix nil))
        (repeat-tests--check
         "C-2 C-x w a c d c z"
         '((2 a) (1 c) (1 d) (1 c)) "z")
        (repeat-tests--check
         "C-2 C-x w a C-3 z"
         '((2 a)) "zzz"))
      ;; Fixed in bug#51281 and bug#55986
      (let ((repeat-keep-prefix t))
        ;; Re-enable to take effect.
        (repeat-mode -1) (repeat-mode +1)
        (repeat-tests--check
         "C-2 C-x w a c d c z"
         '((2 a) (2 c) (2 d) (2 c)) "z")
        ;; Unimplemented feature (maybe unnecessary):
        ;; (repeat-tests--check
        ;;  "C-2 C-x w a C-1 C-2 c d C-3 C-4 c z"
        ;;  '((2 a) (12 c) (12 d) (34 c)) "z")
        ))))

;; TODO: :tags '(:expensive-test)  for repeat-exit-timeout


(require 'use-package)

(defun repeat-tests-bind-call-a (&optional arg)
  (interactive "p")
  (push `(,arg a) repeat-tests-calls))

(defun repeat-tests-bind-call-c (&optional arg)
  (interactive "p")
  (push `(,arg c) repeat-tests-calls))

(defun repeat-tests-bind-call-d (&optional arg)
  (interactive "p")
  (push `(,arg d) repeat-tests-calls))

(defun repeat-tests-bind-call-q (&optional arg)
  (interactive "p")
  (push `(,arg q) repeat-tests-calls))

(ert-deftest repeat-tests-bind-keys ()
  (defvar repeat-tests-bind-keys-map (make-sparse-keymap))
  (bind-keys
   :map repeat-tests-bind-keys-map
   ("C-M-a" . repeat-tests-bind-call-a)
   :repeat-map repeat-tests-bind-keys-repeat-map
   :continue
   ("c"     . repeat-tests-bind-call-c)
   :exit
   ("q"     . repeat-tests-bind-call-q)
   )

  ;; TODO: it seems there is no :entry, so need to do explicitly:
  (put 'repeat-tests-bind-call-a 'repeat-map 'repeat-tests-bind-keys-repeat-map)

  (with-repeat-mode repeat-tests-bind-keys-map
    (let ((repeat-echo-function 'ignore)
          (repeat-check-key nil))
      ;; 'q' should exit
      (repeat-tests--check
       "C-M-a c q c"
       '((1 a) (1 c) (1 q)) "c"))))

(provide 'repeat-tests)
;;; repeat-tests.el ends here
