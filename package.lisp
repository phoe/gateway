;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; GATEWAY
;;;; © Michał "phoe" Herda 2017
;;;; package.lisp

(defpackage #:gateway
  (:use #:common-lisp
        #:alexandria))

(defpackage #:gateway/operations
  (:use #:common-lisp
        #:alexandria
        #:phoe-toolbox
        #:gateway/protocols
        #:gateway/sql))
