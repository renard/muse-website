;;; muse-website.el --- Generate a website from Muse

;; Copyright © 2010 Sebastien Gross <seb•ɑƬ•chezwam•ɖɵʈ•org>

;; Author: Sebastien Gross <seb•ɑƬ•chezwam•ɖɵʈ•org>
;; Keywords: emacs, muse
;; Last changed: 2010-08-04 16:32:52

;; This file is NOT part of GNU Emacs.
;; This file is NOT part of Muse.

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
;;
;; This allows to generate a full website directly from Muse files.

;;; Code:

(require 'muse-mode nil t)     ; load authoring mode
(require 'muse-html nil t)     ; load publishing styles I use
(require 'muse-latex nil t)
(require 'muse-texinfo nil t)
(require 'muse-docbook nil t)
(require 'muse-project nil t)  ; publish files in projects


(defvar muse-website-projects nil
    "List of Muse projects definition. Each element is a PLIST project
definition. Each project is assumed to be in a single directory root.
For each project definition following elements are required:

name

   The project name. Each pro

root

   The project root directory.

src

   The project source directory relative to 'root'.

default

   Default index file (usually \"index\".

out

  The project ouput directory relative to 'root'.

skip

  List of source directories to exclude from the building process.

style-base

  The style base for the project. Please note that each project would get its
  own style definition.

header

  Path to the project header (template) file relative to 'root'.


footer

  Same as 'header' but for the footer.")


(defun muse-website-set-project-alist ()
  "Set `muse-project-alist' according to `muse-website-projects'."
  (setq muse-project-alist nil)
  (mapcar
   (lambda (p)
     (let* ((p-name (format "%s" (plist-get p :name)))
	    (p-root (file-name-as-directory (plist-get p :root)))
	    (p-src (concat p-root (plist-get p :src)))
	    (p-default (plist-get p :default))
	    (p-out (concat p-root (plist-get p :out)))
	    (p-header (concat p-root (plist-get p :header)))
	    (p-footer (concat p-root (plist-get p :footer)))
	    (p-skip (plist-get p :skip))
	    (p-style-base (plist-get p :style-base))
	    (p-style (concat p-name "-" p-style-base)))

       (muse-derive-style
	p-style p-style-base
	:header p-header
	:footer p-footer)

       (add-to-list 'muse-project-alist
		    `(,p-name
		      (,@(remove-if
			  '(lambda (x)
			     (intersection
			      p-skip
			      (split-string x "/") :test 'equal))
			  (muse-project-alist-dirs p-src))
		       :default ,p-default)
		      ,@(muse-project-alist-styles
			 p-src p-out p-style
			 :root-src p-src
			 :default (format "%s.muse" p-default)
			 :skip p-skip)))))
   muse-website-projects))


(defvar muse-website-contents-text "Contents"
  "String to put on the top of contents list use by `muse-html-insert-contents'.")

(defadvice muse-html-insert-contents (around ad-muse-html-insert-contents activate)
  "Add content on `muse-website-contents-text' before the contents."
  (muse-insert-markup
   (format "<div class=\"contents_topic\"><p>%s</p>" muse-website-contents-text))
  ad-do-it
  (muse-insert-markup "</div>"))


(defun muse-website-get-publish-property (file property)
  "Return CONFIG property for FILE (or `muse-publishing-current-file' if nil)."
  (unless file
    (setq file muse-publishing-current-file))
  (plist-get
   (caddr (muse-project (muse-project-of-file file)))
   property))


(defun muse-website-path-to-root ()
  "Return relative path to project output root directory."
  (file-relative-name
   (expand-file-name (muse-website-get-publish-property nil :path))
   (expand-file-name (file-name-directory muse-publishing-current-output-path))))


(defun muse-website-last-modified (&optional lang)
  "Return the the last changed tag"
  (let* ((l-m (muse-website-extract-file-directive muse-publishing-current-file "date"))
	 (l-m-dtt (if l-m (date-to-time l-m) (current-time)))
	 (system-time-locale
	  (or
	   (muse-website-extract-file-directive muse-publishing-current-file "lang")
	   system-time-locale)))
    (insert
     (format-time-string "%d %b %Y %T" l-m-dtt t))))


(defun muse-website-extract-file-directive (file directive)
  "Extracts DIRECTIVE content from the source of Muse FILE."
  (with-temp-buffer
    (muse-insert-file-contents file)
    (beginning-of-buffer)
    (when (search-forward (concat "#" directive) nil t)
      (forward-char)
      (buffer-substring-no-properties (point)
				      (muse-line-end-position)))))


(defun muse-website-get-list-and-files (dir)
  "Return PLIST of muse files and directories from DIR with properties:

dirs

  List of directories from DIR

files

  List of files from DIR without project default file (generaly 'index.muse')."
  (let ((lst  (directory-files dir nil nil nil))
        dirs files)
    (while lst
      (if (file-directory-p (concat (file-name-as-directory dir) (car lst)))
	  ;; directories
	  (unless (member (car lst) '("." ".."))
	    (setq dirs (add-to-list 'dirs (car lst))))
	;; files
	(let ((file (concat
		     (file-name-as-directory dir)
		     (car lst))))
	  (when (and
		 ;; don't include directory index
		 (not (string-equal
		       (muse-website-get-publish-property file :default)
		       (car lst)))
		 ;; only include .muse files
		 (string-match "\.muse$" (car lst)))
	    (setq files (add-to-list 'files (car lst))))))
      (setq lst (cdr lst)))
    `(:dirs ,dirs :files ,files)))


(defun muse-website-sitetree (&optional dir root path)
  "Generate a site tree from current muse project."
  (unless dir (setq dir "."))
  (unless root
    (setq root
	  (plist-get (caddr (muse-project
			     (muse-project-of-file muse-publishing-current-file)))
		     :root-src)))
  (unless path (setq path "."))
  (let ((default_html (format "%s/%s/index.html" (muse-website-path-to-root) path))
	(default_muse (concat (file-name-as-directory root)
			      (file-name-as-directory dir)
			      "index.muse")))
    ;; Section title
    (insert (format "<ul><li><a href=\"%s\"><acronym title=\"%s\">%s</acronym></a>"
		    (format "%s/%s/index.html" (muse-website-path-to-root) path)
		    (muse-website-extract-file-directive default_muse "desc")
		    (muse-website-extract-file-directive default_muse "title")))
    ;; Section elements
    (let* ((fp (concat (file-name-as-directory root) dir))
	   (lst (muse-website-get-list-and-files fp))
	   (d (plist-get lst :dirs))
	   (f (plist-get lst :files)))
      ;; loop directories
      (while d
	(unless (member (car d)
			(muse-website-get-publish-property nil :skip))
	  (muse-website-sitetree
	   (car d) fp
	   (concat (file-name-as-directory path ) (car d))))
	(setq d (cdr d)))
      ;; loop directories
      (when f
	(insert "<ul>")
	(while f
	  (insert (format "<li><a href=\"%s\"><acronym title=\"%s\">%s</acronym></a><li>"
			  (format "%s/%s/%s.html" (muse-website-path-to-root) path
				  (file-name-sans-extension (car f)))
			  (muse-website-extract-file-directive
			   (concat root "/" dir "/" (car f)) "desc")
			  (muse-website-extract-file-directive
			   (concat root "/" dir "/" (car f)) "title")))
	  (setq f (cdr f)))
	(insert "</ul>")))
    (insert "</li></ul>")))

(add-to-list 'muse-publish-markup-tags
             '("whats-new" nil t nil muse-website-whats-new) nil)


(defun muse-website-whats-new (beg end attrs)
  "Generate a what's new fragment.

A LIMIT attribute could be specified to limit the entries number."
  (let ((limit (string-to-int (muse-publish-get-and-delete-attr "limit" attrs)))
	 (wn (muse-website-get-whats-new)))

    (when limit
      (setq wn (butlast wn (- (length wn) limit))))

    (muse-insert-markup "<ul class=\"simple\">")
    (loop for (a) on wn
	  do (muse-insert-markup
	      (format "<li>%s: <a class=\"reference external\" href=\"%s\">%s</a></li>"
		      (caddr a)
		      (car a)
		      (cadr a))))
    (muse-insert-markup "</ul>")))


(defun muse-website-get-whats-new (&optional project)
  "Return a list of all files from PROJECT (current project if nil).

Each element of that list contain:

- path from site root.
- page description
- last modification time."
  (unless project
    (setq project muse-current-project))
  (let ((root (file-name-as-directory
	       (expand-file-name (plist-get
				  (caddr (muse-project project))
				  :root-src))))
	ret)
    (sort
     (mapcar
      '(lambda (x)
	 `(,(format "%s.html" x)
	   ,(muse-website-extract-file-directive (format "%s%s.muse" root x) "desc")
	   ,(muse-website-extract-file-directive (format "%s%s.muse" root x) "date")))
      (muse-website-get-all-files project))
    '(lambda (a b)
       (string> (caddr a) (caddr b))))))




(defun muse-website-get-all-files (&optional project)
  "Return all files from a project.

Files are sorted in a way suitable for a site map generation:

  - directories are sorted
  - default files come before all others"
  (unless project
    (setq project muse-current-project))
  (let ((root-len (length (expand-file-name (plist-get
					     (caddr (muse-project project))
					     :root-src))))
	(default (file-name-sans-extension
		  (plist-get (caddr (muse-project project)) :default))))
    (mapcar
     '(lambda (x)
	(substring
	 (if (string= "/" (substring x -1))
	     (format "%s%s" x default)
	   x)
	 1))
     (sort
      (mapcar
       '(lambda (x)
	  (substring
	   (if (string= default (car x))
	       (file-name-directory (cdr x))
	     (file-name-sans-extension (cdr x)))
	   root-len))
       (muse-project-file-alist project))
      'string<))))





(provide 'muse-website)
