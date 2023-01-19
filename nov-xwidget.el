;;; nov-xwidget.el --- nov-xwidget - the best epub reader in Emacs -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Damon Chan

;; Author: Damon Chan <elecming@gmail.com>
;; URL: https://github.com/chenyanming/nov-xwidget
;; Keywords: hypermedia, multimedia, epub
;; Created: 1 June 2022
;; Version: 0.1.0
;; Package-Requires: ((emacs "28.1") (nov "0.4.0"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; nov-xwidget - the best epub reader in Emacs

;;; Code:

(require 'nov)
(require 'shr)
(require 'xwidget)
(require 'cl-lib)
(require 'evil-core nil 'noerror)

(defcustom nov-xwidget-script (format "
console.log(\"Hello world\");
" "")
  "Javascript scripts used to run in the epub file."
  :group 'nov-xwidget
  :type 'string)


(defcustom nov-xwidget-style-light (format "
    body {
        writing-mode: horizontal-tb;
        // background: %s !important;
        font-size: 18px !important;
        text-align: left !important;
        width: 90%% !important;
        height: 50%% !important;
        position: absolute !important;
        left: 49%% !important;
        top: 30%% !important;
        transform: translate(-50%%, -55%%) !important;
    }
    p {
        font-size: 1em !important;
        text-align: left !important;
        line-height: 1.3 !important;
        margin-bottom: 25px !important;
    }
    pre, tr, td, div.warning {
        font-size: 1em;
        background: #d8dee9;
    }
    th {
        font-size: 1em;
    }
    span {
        font-size: 18px;
    }
    /* Same font for all tags */
    a, em, caption, th, pre, tr, td, code, h1, h2, h3, h4, h5, h6, p, body {
        font-family: \"Fira Code\", Georgia,Cambria,\"Times New Roman\",Times,serif !important;
    }
    h1 {
        font-size: 2em !important;
        color: #2e3440 !important;
        margin-bottom: 10px !important;
    }
    h2 {
        font-size: 1.5em !important;
        color: #2e3440 !important;
        margin-bottom: 10px !important;
    }
    h3 {
        font-size: 1.3em !important;
        color: #2e3440 !important;
        margin-bottom: 10px !important;
    }
    h4 {
        font-size: 1.2em !important;
        color: #2e3440 !important;
        margin-bottom: 10px !important;
    }
    h5 {
        font-size: 1.1em !important;
        color: #2e3440 !important;
        margin-bottom: 10px !important;
    }
    h6 {
        font-size: 1em !important;
        color: #2e3440 !important;
        margin-bottom: 10px !important;
    }
    code {
        font-size: 1em !important;
    }
    :root {
        color-scheme: light; /* both supported */
    }

    body img {
        max-width: 100%% !important;
    }
    .programlisting {
        font-size: 20px;
    }
" (face-attribute 'default :background))
  "Light mode CSS style used to render the epub file."
  :group 'nov-xwidget
  :type 'string)


(defcustom nov-xwidget-style-dark (format "
    body {
        writing-mode: horizontal-tb;
        // background: %s !important;
        color: #eee !important;
        font-size: 18px !important;
        text-align: left !important;
        width: 90%% !important;
        height: 50%% !important;
        position: absolute !important;
        left: 49%% !important;
        top: 30%% !important;
        transform: translate(-50%%, -55%%) !important;
    }
    p {
        text-align: left !important;
        line-height: 1.3 !important;
        margin-bottom: 25px !important;
    }
    h1, h2, h3, h4, h5, h6 {
        /*color: #eee !important;*/
        border-bottom: 0px solid #eee !important;
    }
    pre, tr, td, div.warning {
        font-size: 1em;
        background: #272c35;
    }
    th {
        font-size: 1em;
        color: #eee !important;
    }

    span {
        font-size: 18px;
        color: #eee !important;
    }
    h1 {
        color: #ffaf69 !important;
    }
    h2 {
        color: #3fc6b7 !important;
    }
    h3 {
        color: #88d498 !important;
    }
    h4 {
        color: #80c3f0 !important;
    }
    h5 {
        color: #cccccc !important;
    }
    h6 {
        color: #cccccc !important;
    }

    /* Same font for all tags */
    a, em, caption, th, pre, tr, td, code, h1, h2, h3, h4, h5, h6, p, body {
        font-family: \"Fira Code\", Georgia,Cambria,\"Times New Roman\",Times,serif !important;
    }
    code {
        font-size: 1em !important;
    }
    :root {
        color-scheme: dark; /* both supported */
    }

    body, p.title  {
        color: #eee !important;
    }

    body a{
        color: #809fff !important;
    }

    body img {
        max-width: 100%% !important;
        filter: brightness(.8) contrast(1.2);
    }
    .programlisting {
        font-size: 20px;
    }
" (face-attribute 'default :background))
  "Dark mode CSS style used to render the epub file."
  :group 'nov-xwidget
  :type 'string)

(defcustom nov-xwidget-browser-function 'nov-xwidget-webkit-browse-url-other-window
  "TODO: xwidget may not work in some systems, set it to an
alternative browser function."
  :group 'nov-xwidget
  :type browse-url--browser-defcustom-type)

(defcustom nov-xwidget-debug nil
  "Enable the debug feature."
  :group 'nov-xwidget
  :type 'directory)

(defcustom nov-xwidget-inject-output-dir
  (expand-file-name (concat user-emacs-directory ".cache/nov-xwidget/"))
  "The nov-xwidget injected output html directory."
  :group 'nov-xwidget
  :type 'directory)

(defvar nov-xwidget-current-file nil)

(defvar nov-xwidget-header-function #'nov-xwidget-header
  "Function that returns the string to be used for the nov xwidget header.")

(define-derived-mode nov-xwidget-webkit-mode xwidget-webkit-mode "EPUB"
  "Major mode for reading epub files.
\\{nov-xwidget-webkit-mode-map}"
  (setq header-line-format '(:eval (funcall nov-xwidget-header-function))))

(defvar nov-xwidget-webkit-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "n" #'nov-xwidget-next-document)
    (define-key map "p" #'nov-xwidget-previous-document)
    (define-key map "]" #'nov-xwidget-next-document)
    (define-key map "[" #'nov-xwidget-previous-document)
    (define-key map "t" #'nov-xwidget-goto-toc)
    (define-key map "S" #'nov-xwidget-find-source-file)
    map)
  "Keymap for `nov-xwidget-webkit-mode-map'.")

(if (featurep 'evil)
    (if (fboundp 'evil-define-key)
        (evil-define-key '(normal emacs) nov-xwidget-webkit-mode-map
          (kbd "n") 'nov-xwidget-next-document
          (kbd "p") 'nov-xwidget-previous-document
          (kbd "]") 'nov-xwidget-next-document
          (kbd "[") 'nov-xwidget-previous-document
          (kbd "t") 'nov-xwidget-goto-toc
          (kbd "S") 'nov-xwidget-find-source-file)))

(defun nov-xwidget-header ()
  "Return the string to be used as the nov-xwidget header."
  (let* ((file nov-xwidget-current-file)
         (dom (with-temp-buffer
                (insert-file-contents file)
                (libxml-parse-html-region (point-min) (point-max)))))
    (format "%s %d/%d   %s %s   %s %s   %s %s"
            (propertize "Index:" 'face 'font-lock-preprocessor-face)
            nov-documents-index
            (1- (length nov-documents))
            (propertize "Title:" 'face 'font-lock-preprocessor-face)
            (alist-get 'title nov-metadata)
            (propertize "Author:" 'face 'font-lock-preprocessor-face)
            (or (alist-get 'creator nov-metadata) "")
            (propertize "Date:" 'face 'font-lock-preprocessor-face)
            (alist-get 'date nov-metadata))))

(defun nov-xwidget-fix-file-path (file)
  "Fix the FILE path by prefix _."
  (format "%s_%s.%s"
          (or (file-name-directory file) "")
          (file-name-base file)
          (replace-regexp-in-string
           "x?html?"
           "html"
           (file-name-extension file))))

(defun nov-xwidget-inject (file &optional callback)
  "Inject `nov-xwidget-script', `nov-xwidget-style-light', or `nov-xwidget-style-dark' into FILE.
Call CALLBACK on the final injected dom.
Input FILE should be  htm/html/xhtml
Output a new html file prefix by _."
  (when nov-xwidget-debug
    ;; create the nov-xwidget-inject-output-dir if not exists
    (unless (file-exists-p nov-xwidget-inject-output-dir)
      (make-directory nov-xwidget-inject-output-dir)) )
  (let* ((native-path file)
         ;; only work on html/xhtml file, rename xhtml as html
         ;; we need to save to a new html file, because the original file may be read only
         ;; saving to new html file is easier to tweak
         (output-native-file-name (if (or (string-equal (file-name-extension native-path) "htm")
                                          (string-equal (file-name-extension native-path) "html")
                                          (string-equal (file-name-extension native-path) "xhtml"))
                                      (format "_%s.html" (file-name-base native-path))
                                    (file-name-nondirectory native-path)))
         ;; get full path of the final html file
         (output-native-path (expand-file-name output-native-file-name (if nov-xwidget-debug
                                                                           nov-xwidget-inject-output-dir
                                                                         (setq nov-xwidget-inject-output-dir (file-name-directory native-path)))))
         ;; create the html if not esists, insert the `nov-xwidget-script' as the html script
         (dom (with-temp-buffer
                (insert-file-contents native-path)
                (libxml-parse-html-region (point-min) (point-max))))
         (new-dom (let ((dom dom))
                    ;; fix all href and point to the new html file
                    (cl-map 'list (lambda(x)
                                    (let* ((href (dom-attr x 'href))
                                           (new-href (nov-xwidget-fix-file-path href)))
                                      (dom-set-attribute x 'href new-href)))
                            ;; all elements that not start with http or https,
                            ;; but matches htm.*
                            (cl-remove-if
                             (lambda(x)
                               (string-match-p "https?.*"
                                               (dom-attr x 'href)))
                             (dom-elements dom 'href ".*htm.*")))
                    (dom-append-child
                     (dom-by-tag dom 'head)
                     '(meta ((charset . "utf-8"))))
                    (dom-append-child
                     (dom-by-tag dom 'head)
                     `(style nil ,(pcase (frame-parameter nil 'background-mode)
                                    ('light nov-xwidget-style-light)
                                    ('dark nov-xwidget-style-dark)
                                    (_ nov-xwidget-style-light))))
                    (dom-append-child
                     (dom-by-tag dom 'head)
                     `(script nil ,nov-xwidget-script))
                    dom)))
    (if callback
        (funcall callback new-dom))
    (with-temp-file output-native-path
      (shr-dom-print new-dom)
      ;; (encode-coding-region (point-min) (point-max) 'utf-8)
      output-native-path)))

(defun nov-xwidget-inject-all-files()
  "Inject `nov-xwidget-style-dark', `nov-xwidget-style-light', or
`nov-xwidget-script' to all files in `nov-documents'. It should
be run once after the epub file is opened, so that it can fix all
the href and generate new injected-htmls beforehand. You could
also run it after modifing `nov-xwidget-style-dark',
`nov-xwidget-style-light', or `nov-xwidget-script'."
  (interactive)
  (if nov-documents
      (dolist (document (append nov-documents nil))
        ;; inject all files
        (nov-xwidget-inject (cdr document))
        ;; fix the path
        ;; (setf (cdr document) (nov-xwidget-fix-file-path (cdr document)))
        )))

(defun nov-xwidget-webkit-find-file (file &optional arg new-session)
  "Open a FILE with xwidget webkit."
  (interactive
   (list
    (pcase major-mode
      ('nov-mode
       (cdr (aref nov-documents nov-documents-index)))
      (_
       (read-file-name "Webkit find file: ")))
    current-prefix-arg))
  ;; every time to open a file, force inject, so that the scripts are reloaded
  (let* ((file (nov-xwidget-inject file))
         ;; get web url of the file
         (path (replace-regexp-in-string
                " "
                "%20"
                (concat
                 "file:///"
                 file)))
         (final-path (if (string-equal (file-name-extension file) "ncx")
                         "about:blank"
                       path)))
    ;; workaround to view in windows
    ;; TODO it is able to support to browse in external browser
    ;; after supporting more advance html/style/scripts
    (cond
     ((eq nov-xwidget-browser-function 'nov-xwidget-webkit-browse-url-other-window)
      (nov-xwidget-webkit-browse-url-other-window final-path new-session 'switch-to-buffer)
      (setq-local nov-xwidget-current-file file)
      (unless (eq major-mode 'nov-xwidget-webkit-mode)
        (nov-xwidget-webkit-mode)))
     (t (funcall nov-xwidget-browser-function final-path)))))

(defun nov-xwidget-find-source-file ()
  "Open the source file."
  (interactive nil xwidget-webkit-mode)
  (find-file (cdr (aref nov-documents nov-documents-index))))

(defun nov-xwidget-webkit-browse-url-other-window (url &optional new-session switch-buffer-fun)
  "Ask xwidget-webkit to browse URL.
NEW-SESSION specifies whether to create a new xwidget-webkit session.
Interactively, URL defaults to the string looking like a url around point."
  (interactive (progn
                 (require 'browse-url)
                 (browse-url-interactive-arg "xwidget-webkit URL: "
                                             ;;(xwidget-webkit-current-url)
                                             )))
  (or (featurep 'xwidget-internal)
      (user-error "Your Emacs was not compiled with xwidgets support"))
  (require 'xwidget)
  (when (stringp url)
    (if new-session
        (xwidget-webkit-new-session url)
      (progn
        (xwidget-webkit-goto-url url)
        (if switch-buffer-fun
            (funcall switch-buffer-fun (xwidget-buffer (xwidget-webkit-current-session)))
          (pop-to-buffer (xwidget-buffer (xwidget-webkit-current-session))))))))

(defun nov-xwidget-view ()
  "View the current document in a xwidget webkit buffer."
  (interactive)
  (let* ((docs nov-documents)
         (index nov-documents-index)
         (toc nov-toc-id)
         (epub nov-epub-version)
         (metadata nov-metadata)
         (file (cdr (aref docs index))))

    ;; open the html file
    (nov-xwidget-webkit-find-file file nil t)
    ;; save nov related local variables
    (when (eq nov-xwidget-browser-function 'nov-xwidget-webkit-browse-url-other-window)
      (with-current-buffer (xwidget-buffer (xwidget-webkit-current-session))
        ;;(setq-local imenu-create-index-function 'my-nov-imenu-create-index)
        (setq-local nov-documents docs)
        (setq-local nov-documents-index index)
        (setq-local nov-toc-id toc)
        (setq-local nov-epub-version epub)
        (setq-local nov-metadata metadata))
      ;; save the file to `nox-xwidget-current-file', so that the header can parse
      (setq-local nov-xwidget-current-file file))))

(defun nov-xwidget-next-document ()
  "Go to the next document and render it."
  (interactive)
  (when (< nov-documents-index (1- (length nov-documents)))
    (let* ((docs nov-documents)
           (index (1+ nov-documents-index))
           (toc nov-toc-id)
           (epub nov-epub-version)
           (metadata nov-metadata)
           (path (cdr (aref docs index))))
      (nov-xwidget-webkit-find-file path)
      (with-current-buffer (buffer-name)
        (setq-local nov-documents docs)
        (setq-local nov-documents-index index)
        (setq-local nov-toc-id toc)
        (setq-local nov-metadata metadata)
        (setq-local nov-epub-version epub)))))

(defun nov-xwidget-previous-document ()
  "Go to the previous document and render it."
  (interactive)
  (when (> nov-documents-index 0)
    (let* ((docs nov-documents)
           (index (1- nov-documents-index))
           (toc nov-toc-id)
           (epub nov-epub-version)
           (metadata nov-metadata)
           (path (cdr (aref docs index))))
      (if (string-equal (file-name-extension path) "ncx")
          (nov-xwidget-goto-toc)
        (nov-xwidget-webkit-find-file path)
        (with-current-buffer (buffer-name)
          (setq-local nov-documents docs)
          (setq-local nov-documents-index index)
          (setq-local nov-toc-id toc)
          (setq-local nov-metadata metadata)
          (setq-local nov-epub-version epub))))))

(defun nov-xwidget-goto-toc ()
  "Go to the TOC index and render the TOC document."
  (interactive)
  (let* ((docs nov-documents)
         (epub nov-epub-version)
         (ncxp (version< nov-epub-version "3.0"))
         (index (nov-find-document (lambda (doc) (eq (car doc) nov-toc-id))))
         (toc nov-toc-id)
         (path (cdr (aref docs index)))
         (html-path (expand-file-name "toc.html" (file-name-directory path)))
         (html (if (file-exists-p html-path)
                   (with-temp-buffer (insert-file-contents html-path) (buffer-string))
                 ;; it could be empty sting
                 (nov-ncx-to-html path)))
         (dom (with-temp-buffer
                (if ncxp
                    (insert html)
                  (insert-file-contents path))
                (libxml-parse-html-region (point-min) (point-max))))
         (new-dom (let ((dom dom))
                    (if dom
                        (dom-add-child-before
                         dom
                         `(head nil
                                (meta ((charset . "utf-8")))
                                (title nil "TOC")
                                (style nil ,(pcase (frame-parameter nil 'background-mode)
                                              ('light nov-xwidget-style-light)
                                              ('dark nov-xwidget-style-dark)
                                              (_ nov-xwidget-style-light)))
                                (script nil ,nov-xwidget-script))) )
                    dom))
         (file (with-temp-file html-path
                 (shr-dom-print new-dom)
                 html-path)))
    (when (not index)
      (error "Couldn't locate TOC"))
    (nov-xwidget-webkit-find-file file)
    (with-current-buffer (buffer-name)
      (setq-local nov-documents docs)
      (setq-local nov-documents-index index)
      (setq-local nov-toc-id toc)
      (setq-local nov-epub-version epub))))

(provide 'nov-xwidget)
;;; nov-xwidget.el ends here
