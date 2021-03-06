;;; gmail-search-mode.el --- Search for GMail threads.

;; Copyright (c) 2014 Chris Done. All rights reserved.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(require 'gmail)
(require 'gmail-headers)
(require 'gmail-encoding)

(defcustom gmail-search-mode-page-columns
  80
  "Width of the page."
  :type 'integer
  :group 'gmail)

(defcustom gmail-search-mode-date-length
  18
  "Length of the date string."
  :type 'integer
  :group 'gmail)

(defcustom gmail-search-mode-date-format
  "%H:%M, %d %b %Y"
  "Format string for dates."
  :type 'string
  :group 'gmail)

(defface gmail-search-mode-from-face
  '()
  "Face for the sender of emails."
  :group 'gmail)

(defface gmail-search-mode-subject-face
  '()
  "Face for subjects."
  :group 'gmail)

(defface gmail-search-mode-subject-unread-face
  '()
  "Face for unread subjects."
  :group 'gmail)

(defface gmail-search-mode-read-face
  `()
  "Face for read email."
  :group 'gmail)

(defface gmail-search-mode-unread-face
  '((((class color)) :weight bold))
  "Face for unread emails."
  :group 'gmail)

(defface gmail-search-mode-snippet-face
  '()
  "Face for the snippet."
  :group 'gmail)

(defface gmail-search-mode-body-face
  '()
  "Face for the snippet."
  :group 'gmail)

(defface gmail-search-mode-date-face
  '()
  "Face for the date."
  :group 'gmail)

(defface gmail-search-mode-labels-face
  '()
  "Face for labels."
  :group 'gmail)

(defface gmail-search-mode-query-face
  '((((class color) (background dark)) :foreground "#999")
    (((class color) (background light)) :foreground "#999"))
  "Face for queries/"
  :group 'gmail)

(defvar gmail-search-mode-query ""
  "Current query being used.")
(make-variable-buffer-local 'gmail-search-mode-query)

(defvar gmail-search-mode-labels '()
  "Current labels being used.")
(make-variable-buffer-local 'gmail-search-mode-labels)

(defvar gmail-search-mode-threads '()
  "Current thread results.")
(make-variable-buffer-local 'gmail-search-mode-threads)

(define-derived-mode gmail-search-mode special-mode "GMail-Search"
  "Search GMail for your emails."
  (gmail-search-mode-revert))

(define-key gmail-search-mode-map (kbd "g") 'gmail-search-mode-revert)
(define-key gmail-search-mode-map (kbd "s") 'gmail-search-mode-search)
(define-key gmail-search-mode-map (kbd "d") 'gmail-search-mode-delete)
(define-key gmail-search-mode-map (kbd "a") 'gmail-search-mode-archive)
(define-key gmail-search-mode-map (kbd "n") 'gmail-search-mode-next)
(define-key gmail-search-mode-map (kbd "i") 'gmail-search-mode-inbox)
(define-key gmail-search-mode-map (kbd "p") 'gmail-search-mode-prev)
(define-key gmail-search-mode-map (kbd "c") 'gmail-compose)
(define-key gmail-search-mode-map (kbd "RET") 'gmail-search-mode-open-thread)

(defun gmail-compose ()
  (interactive)
  (switch-to-buffer (get-buffer-create "*gmail-compose*"))
  (unless (eq major-mode 'gmail-compose-mode)
    (gmail-compose-mode)))

(defun gmail-search-mode-inbox ()
  (interactive)
  (gmail-search-mode-set '() "label:inbox"))

(defun gmail-search ()
  (interactive)
  (switch-to-buffer (get-buffer-create "*gmail-search*"))
  (unless (eq major-mode 'gmail-search-mode)
    (gmail-search-mode)))

(defun gmail-search-mode-next ()
  "Go to the next result."
  (interactive)
  (if (= (line-beginning-position)
         (line-end-position))
      (forward-line 1)
    (search-forward-regexp "\n\n")))

(defun gmail-search-mode-prev ()
  "Go to the prev result."
  (interactive)
  (search-backward-regexp "\n\n")
  (backward-paragraph)
  (forward-line 1))

(defun gmail-search-mode-open-thread ()
  "Open the thread at point."
  (interactive)
  (let ((thread-id (get-text-property (point) 'gmail-search-mode-thread-id))
        (subject (get-text-property (point) 'gmail-search-mode-thread-subject)))
    (switch-to-buffer (get-buffer-create (format "*gmail-thread:%s:%s*" thread-id subject)))
    (gmail-thread-mode)
    (setq gmail-thread-mode-thread-id thread-id)
    (gmail-thread-mode-render)))

(defun gmail-search-mode-delete ()
  "Open the thread at point."
  (interactive)
  (let ((thread-id (get-text-property (point) 'gmail-search-mode-thread-id)))
    (message "Deleting ...")
    (gmail-helper-threads-modify thread-id (list "TRASH") (list))
    (message "Deleted.")
    (gmail-search-mode-revert)))

(defun gmail-search-mode-archive ()
  "Open the thread at point."
  (interactive)
  (let ((thread-id (get-text-property (point) 'gmail-search-mode-thread-id)))
    (message "Archiving ...")
    (gmail-helper-threads-modify thread-id (list) (list "INBOX"))
    (message "Archived.")
    (gmail-search-mode-revert)))

(defun gmail-search-mode-revert ()
  "Revert the current buffer; in other words: re-run the search."
  (interactive)
  (let ((inhibit-read-only t))
    (erase-buffer)
    (insert "Search: " (propertize gmail-search-mode-query 'face 'gmail-search-mode-query-face)
            "\n")
    (insert (propertize "\nRefreshing thread list…" 'face 'font-lock-comment)))
  (redisplay t)
  (setq gmail-search-mode-threads
        (gmail-helper-threads-list gmail-search-mode-labels
                                   gmail-search-mode-query))
  (gmail-search-mode-render))

(defun gmail-search-mode-render ()
  "Render the threads list."
  (let ((original-point (point)))
    (let ((inhibit-read-only t)
          (thread-results gmail-search-mode-threads)
          (threads (plist-get gmail-search-mode-threads :threads)))
      (delete-region (1- (line-beginning-position))
                     (line-end-position))
      (insert (format "%d estimated total results\n" (plist-get thread-results :resultSizeEstimate)))
      (insert "\n")
      (let ((ids (remove-if
                  (lambda (id)
                    (gmail-cache-p (format "thread-%s-%S" id 'full)))
                  (mapcar (lambda (thread-result)
                            (plist-get thread-result :id))
                          threads))))
        (unless (null ids)
          (insert (propertize (format "Downloading %d threads…" (length ids))
                              'face 'font-lock-comment))
          (redisplay t)
          (gmail-helper-threads-get-many ids 'full)))
      (delete-region (line-beginning-position)
                     (line-end-position))
      (let ((meta-threads
             (mapcar
              (lambda (thread-result)
                (gmail-helper-threads-get (plist-get thread-result :id) 'full))
              threads)))
        (cl-loop for thread in meta-threads
                 do (gmail-search-mode-render-thread thread)))
      (goto-char original-point))))

(defun gmail-search-mode-render-thread (thread)
  "Render the given thread."
  (let* ((messages (plist-get thread :messages))
         (message (car messages))
         (snippet (gmail-encoding-decode-html (plist-get message :snippet)))
         (payload (plist-get message :payload))
         (headers (plist-get payload :headers))
         (subject (gmail-headers-lookup "Subject" headers))
         (from (gmail-headers-lookup "From" headers))
         (date (mail-header-parse-date (gmail-headers-lookup "Date" headers)))
         (labels (plist-get message :labelIds))
         (unread (remove-if-not (lambda (label) (string= label "UNREAD"))
                                (apply #'append
                                       (mapcar (lambda (message)
                                                 (plist-get message :labelIds))
                                               messages)))))
    (let ((view
           (concat (gmail-search-mode-ellipsis
                    (propertize (concat from " ") 'face 'gmail-search-mode-from-face)
                    (- gmail-search-mode-page-columns (1+ gmail-search-mode-date-length)))
                   (propertize
                    (format-time-string gmail-search-mode-date-format date)
                    'face 'gmail-search-mode-date-face)
                   "\n"
                   (gmail-search-mode-ellipsis
                    (concat (gmail-search-mode-ellipsis
                             (propertize subject
                                         'face (if unread
                                                   'gmail-search-mode-subject-unread-face
                                                 'gmail-search-mode-subject-face))
                             (/ gmail-search-mode-page-columns 2))
                            (if (string= "" subject)
                                "" " ")
                            (propertize snippet
                                        'face 'gmail-search-mode-snippet-face))
                    (1- gmail-search-mode-page-columns))
                   "\n"
                   (mapconcat #'identity
                              (mapcar (lambda (label)
                                        (propertize label
                                                    'face 'gmail-search-mode-labels-face))
                                      (mapcar #'gmail-labels-pretty labels))
                              (propertize ", "
                                          'face
                                          'gmail-search-mode-from-face))
                   " "
                   (let ((replies (1- (length messages))))
                     (if (= replies 1)
                         "(1 reply)"
                       (if (= 0 replies)
                           ""
                         (format "(%d replies)" replies))))
                   "\n\n"))
          (point (point)))
      (insert (propertize view
                          'gmail-search-mode-thread-id (plist-get thread :id)
                          'gmail-search-mode-thread-subject subject))
      (let ((o (make-overlay point (point))))
        (if unread
            (overlay-put o 'face 'gmail-search-mode-unread-face)
          (overlay-put o 'face 'gmail-search-mode-read-face))))))

(defun gmail-search-mode-ellipsis (string n)
  "Take from the string and add an ellipsis if it was cut off."
  (concat (substring string 0 (min (length string) n))
          (propertize
           (if (> (length string) n)
               "…"
             "")
           'face
           (get-text-property (max 0 (1- (length string))) 'face string))))

(defun gmail-search-mode-take (string n)
  "Take from the string and add an ellipsis if it was cut off."
  (substring string 0 (min (length string) n)))

(defun gmail-search-mode-set (labels query)
  "Set the query used for the search in the current buffer."
  (setq gmail-search-mode-query query)
  (setq gmail-search-mode-labels labels)
  (gmail-search-mode-revert))

(defun gmail-search-mode-search ()
  "Search in the current search buffer."
  (interactive)
  (let ((q (read-from-minibuffer
            "Search: "
            gmail-search-mode-query)))
    (gmail-search-mode-set '() q)))

(provide 'gmail-search-mode)
