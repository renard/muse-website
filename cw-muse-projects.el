(require 'muse-mode)     ; load authoring mode

(require 'muse-html)     ; load publishing styles I use
(require 'muse-latex)
(require 'muse-texinfo)
(require 'muse-docbook)

(require 'muse-project)  ; publish files in projects

(require 'cw-muse-cp-tag)
(require 'cw-muse-src-include-tag)
(require 'cw-muse-functions)

(setq muse-publish-report-threshhold 1)

(setq
 ; project root
 site-example-com:root "~/docs/sites/site.example.com/"
 ; project root source directory
 site-example-com:src (concat site-example-com:root "src/")
 ; project publish output
 site-example-com:out (concat site-example-com:root "out_html")
 ; directories to ignore
; site-example-com:skip '("img" "theme" "style"))
 site-example-com:skip '())
 

(muse-derive-style
 "cw-xhtml" "xhtml"
 :header (concat site-example-com:root "templates/header.html")
 :footer (concat site-example-com:root "templates/footer.html"))

(setq muse-current-file nil)
(setq muse-project-file-alist nil)
(setq muse-project-alist nil)
(setq muse-project-alist
      `(("site.example.com"
	 (,@(remove-if 
	     '(lambda (x)
		(intersection 
		 site-example-com:skip (split-string x "/") :test 'equal))
	     (muse-project-alist-dirs site-example-com:src))
	  :default "index")
	 ,@(muse-project-alist-styles
	    site-example-com:src site-example-com:out "cw-xhtml"
	    ;; :root-src is used for further computings
	    :root-src site-example-com:src ))))

(provide 'cw-muse-projects)
