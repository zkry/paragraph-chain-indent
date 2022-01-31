;;; write-indent.el --- ???? -*- lexical-binding: t -*-

;; Author: Zachary Romero

;; This file is not part of GNU Emacs

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.


;;; Commentary:

;; paragraph-chain-indent provides overlays for the buffer which make
;; paragraphs separated by a newline appear to be indented.  To
;; activate the mode, run the command `paragraph-chain-indent-mode'.
;;
;; example:
;;
;; This is line one
;;
;; Line two
;;
;; will appear as:
;;
;; This is line one
;;     Line two

;;; Code:

(defgroup paragraph-chain-indent nil "Indent chaining paragraphs as indentation "
  :group 'paragraph-chain-indent)

(defcustom paragraph-chain-indent-independent-paragraph-size
  100
  "The size which any paragraph longer than should be separated."
  :type 'integer
  :group 'paragraph-chain-indent)

(defcustom paragraph-chain-indent-indent-amount
  4
  "The amount of virtual indentation to display."
  :type 'integer
  :group 'paragraph-chain-indent)

(defvar-local paragraph-chain-indent-overlays nil)

(defun paragraph-chain-indent--delete-overlays ()
  ""
  (dolist (ov paragraph-chain-indent-overlays)
    (delete-overlay ov))
  (setq paragraph-chain-indent-overlays nil))

(defun paragraph-chain-indent--add-overlay-at-point ()
  (let ((ov (make-overlay (point) (1+ (point)) nil t nil)))
    (overlay-put ov 'invisible t)
    (overlay-put ov 'after-string (make-string paragraph-chain-indent-indent-amount ?\s))
    (overlay-put ov 'evaporate t)
    (push ov paragraph-chain-indent-overlays)))

(defun paragraph-chain-indent--add-overlays (&optional beg end)
  (let ((beg (or beg (point-min)))
        (end (or end (point-max))))
    (save-excursion
      (save-restriction
        (widen)
        (goto-char beg)
        (beginning-of-line)
        (while (< (point) end)
          (save-excursion
            (when (looking-at "[\t\s]*[a-z\"]")
              (forward-line 1)
              (when (looking-at "\n")
                (forward-line 1)
                (when (and (looking-at "[\t\s]*[a-z\"]")
                           (< (- (save-excursion (end-of-line) (point)) (point))
                              paragraph-chain-indent-independent-paragraph-size))
                  (forward-line -1)
                  (paragraph-chain-indent--add-overlay-at-point)))))
          (forward-line 1))))))

(defun paragraph-chain-indent--after-change (beg end len)
  (let* ((beg (save-excursion (goto-char beg) (forward-line -3) (point)))
         (end (save-excursion (goto-char beg) (forward-line 3) (point))))
    (dolist (ov paragraph-chain-indent-overlays)
      (delete-overlay ov)
      (setq paragraph-chain-indent-overlays nil))
    (paragraph-chain-indent--add-overlays)))

(define-minor-mode paragraph-chain-indent-mode
  "Reformats paragraphs "
  :init-value nil
  :lighter nil
  :keyword nil
  (cond
   (paragraph-chain-indent-mode
    (add-hook 'after-change-functions #'paragraph-chain-indent--after-change :append :local)
    (paragraph-chain-indent--add-overlays))
   (t
    (paragraph-chain-indent--delete-overlays)
    (remove-hook 'after-change-functions #'paragraph-chain-indent--after-change t))))

(provide 'paragraph-chain-indent)

;;; paragraph-chain-indent.el ends here
