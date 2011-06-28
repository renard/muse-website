;;; cw-muse.el --- Muse extensions

;; Copyright © 2010 Sebastien Gross <seb•ɑƬ•chezwam•ɖɵʈ•org>

;; Author: Sebastien Gross <seb•ɑƬ•chezwam•ɖɵʈ•org>
;; Keywords:
;; Last changed: 2010-08-30 14:26:00

;; This file is NOT part of GNU Emacs.

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


;;; Code:

(defcustom cw:muse:expand-macros-begin "`"
 "Macro delimiter end."
 :group 'muse
 :type 'string)

(defcustom cw:muse:expand-macros-end "`"
 "Macro delimiter end."
 :group 'muse
 :type 'string)

(defun cw:muse:expand-macros ()
  "Expand macros before muse processing."
  (save-excursion
    (save-restriction
      (save-match-data
	(beginning-of-buffer)
	(let (macro replacement)
	  (while (search-forward-regexp (concat
					 "^#\\(" cw:muse:expand-macros-begin
					 "[^" cw:muse:expand-macros-end "]+" cw:muse:expand-macros-end
					 "\\) \\(.*\\)$") nil t)
	    (setq macro (match-string 1))
	    (setq replacement (match-string 2))
	    (delete-region (point-at-bol) (point-at-eol))
	    (save-excursion
	      (save-match-data
		(replace-string macro replacement nil (point-min) (point-max))))))))))
(add-hook 'muse-before-publish-hook 'cw:muse:expand-macros)


(when (require 'muse-website nil t)
  (require 'cw-muse-projects)
  (muse-website-set-project-alist)

  (setq muse-publish-report-threshhold 1)

  (add-hook 'muse-mode-hook
	    (lambda ()
	      (unless muse-publishing-current-file
		;;(set-input-method "french-dim-postfix")
		(flyspell-mode)
		(ispell-change-dictionary "francais")
		(flyspell-buffer)
		(set (make-local-variable 'time-stamp-start) "^#date ")))))

(when (require 'cw-muse-src-include-tag nil t)
  (setq cw:muse-publish-include-header
      (concat
       "<div class=\"include\">"
       "<p class=\"show\" id=\"${file}_show\" style=\"display: block;\">"
       "<a onclick=\"toogle_display('${file}')\">"
       "<acronym title=\"Afficher le contenu de ${file}\">✔ <tt class=\"docutils literal\">"
       "<span class=\"pre\">${file}</span></tt></acronym></a>"
       "<a href=\"${file}\">"
       "<acronym title=\"Télécharger le contenu de ${file}\"> ⇘</acronym></a></p>"

       "<p class=\"hide\" id=\"${file}_hide\" style=\"display: none;\">"
       "<a onclick=\"toogle_display('${file}')\">"
       "<acronym title=\"Cacher le contenu de ${file}\">✘ <tt class=\"docutils literal\">"
       "<span class=\"pre\">${file}</span></tt></acronym></a>"
       "<a href=\"${file}\">"
       "<acronym title=\"Télécharger le contenu de ${file}\"> ⇘</acronym></a></p>"
       "<div class=\"included\" id=\"${file}_div\" style=\"display: none;\">")
      cw:muse-publish-include-footer "</div></div>"))

(require 'cw-muse-cp-tag nil t)


(provide 'cw-muse)
