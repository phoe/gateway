;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; GATEWAY
;;;; © Michał "phoe" Herda 2017
;;;; package.lisp

(defpackage #:gateway
  (:use #:common-lisp
        #:alexandria))

(uiop:define-package #:gateway/utils
    (:use #:common-lisp
          #:alexandria
          #:postmodern
          #:trivial-arguments
          #:trivia
          #:cl-ppcre)
  (:export
   ;; FUNCTIONS
   #:count-digits
   #:cat
   #:catn
   #:peek-char-no-hang
   #:data-getf
   #:data-equal
   #:valid-email-p
   #:valid-username-p
   #:valid-name-p
   #:fformat
   ;; MACROS
   #:define-constructor
   #:define-print
   #:wait
   #:wait-until
   #:finalized-let*
   ;; DEFINE-QUERY
   #:define-query
   #:define-queries
   ;; PRINR-TO-STRING
   #:prinr-to-string
   ;; VERIFY-ARGUMENTS
   #:verify-arguments
   ))

(defpackage #:gateway/variables
  (:use #:common-lisp)
  (:export
   ;; CONSTANTS
   #:*date-granularity-units*))

(defpackage #:gateway/framework
  (:use #:common-lisp
        #:gateway/utils
        #:gateway/protocols)
  (:export
   ;; WITH-RESTARTABILITY
   #:with-restartability
   ))

(defpackage #:gateway/db
  (:use #:common-lisp
        #:cl-yesql
        #:gateway/utils))

(defpackage #:gateway/install
  (:use #:common-lisp
        #:postmodern
        #:gateway/utils)
  (:export #:install
           #:uninstall
           #:reload))

(uiop:define-package #:gateway/protocols
    (:use #:common-lisp
          #:closer-mop
          #:protest
          #:gateway/utils
          #:gateway/framework)
  (:shadowing-import-from #:protest
                          #:standard-generic-function
                          #:defmethod
                          #:defgeneric))

(defpackage #:gateway/config
  (:use #:common-lisp
        #:alexandria
        #:gateway/utils
        #:gateway/protocols)
  (:export))

(defpackage #:gateway/impl
  (:use #:common-lisp
        #:named-readtables
        #:alexandria
        #:closer-mop
        #:cl-cpus
        #:1am
        #:safe-read
        #:usocket
        #:bordeaux-threads
        #:lparallel.queue
        #:protest
        #:gateway/utils
        #:gateway/variables
        #:gateway/protocols)
  (:shadowing-import-from #:closer-mop
                          #:standard-generic-function
                          #:defmethod
                          #:defgeneric))

(uiop:define-package #:gateway/tests
    (:use))

(protest:define-test-package #:gateway/impl #:gateway/tests)
