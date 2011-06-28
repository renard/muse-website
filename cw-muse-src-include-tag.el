;;; cw-muse-src-include-tag.el --- Override default muse include tag.

;; Copyright © 2010 Sebastien Gross <seb•ɑƬ•chezwam•ɖɵʈ•org>

;; Author: Sebastien Gross <seb•ɑƬ•chezwam•ɖɵʈ•org>
;; Keywords: emacs, muse
;; Last changed: 2010-08-04 12:00:04

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
;; string-template could be found at:
;; https://git.chezwam.org:446/?p=elisp-string-template.git

;;; Code:

(require 'htmlize)
(require 'string-template)

(defvar cw:muse-publish-include-header "<div class=\"include\">"
  "String to be included as header for a <include> tag.

Its content would be processed with `string-template' using following
substitutions:

file

   value from FILE include tag attribute.")

(defvar cw:muse-publish-include-footer "</div>"
  "String to be included as footer for a <include> tag.

Its content would be processed with `string-template' like
`cw:muse-publish-include-header'.")

(defadvice muse-publish-include-tag
  (around cw:muse-publish-include-tag activate)
  "Wrap <include> tag.

If MARKUP attribute is set to 'src' then the file is included as
a syntax-highlighted buffer html fragment into the document. The
default major mode is automaticaly detected. The file is also
copied into the project output directory.

The content of both `cw:muse-publish-include-header' and
`cw:muse-publish-include-footer' is repectivelly preppended and
appended to html fragment.

To include a file content with syntax higlighting simply use:

  <include file=\"foobar\" markup=\"src\">

The buffer mode would be automatically detected uf LANG attribute
is unset."
  (let
      ((file (muse-publish-get-and-delete-attr "file" attrs))
       (markup (muse-publish-get-and-delete-attr "markup" attrs))
       (lang (muse-publish-get-and-delete-attr "lang" attrs))
       substitute)

    (setq substitute (plist-put substitute :file file))

    (unless file
      (error "No file attribute specified in <include> tag"))

    (cond
     ((string-equal markup "src")
      ;; set up attributes for muse-publish-include-tag
      (setq attrs (aput 'attrs "file" file))
      (setq attrs (aput 'attrs "markup" "src"))
      (setq
       attrs (aput
              'attrs "lang"
	      (or lang
		  (substring
		   (symbol-name
		    (with-temp-buffer
		      ;; file name needs to be absolute when inserting file
		      ;; content
		      (insert-file-contents
		       (expand-file-name
			file
			(file-name-directory muse-publishing-current-file)))
		      (set-auto-mode)
		      major-mode))
		   0 -5))))

      ;; insert include header
      (muse-insert-markup
       (string-template cw:muse-publish-include-header substitute))

      ;; publish the file content as an "<include> tag
      (ad-set-arg 0 (point))
      (ad-set-arg 1 (point))
      ad-do-it

      ;; insert include footer
      (muse-insert-markup
       (string-template cw:muse-publish-include-footer substitute))

      ;; copy the file
      (copy-file
       (expand-file-name file (file-name-directory
			       muse-publishing-current-file))
       (expand-file-name file (file-name-directory
			       muse-publishing-current-output-path))
       t t t))
     ;; default call
     (t ad-do-it))))

(provide 'cw-muse-src-include-tag)
