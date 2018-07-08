;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; GATEWAY
;;;; © Michał "phoe" Herda 2017
;;;; protocols/killable.lisp

(in-package #:gateway/protocol)

(define-protocol killable
    (:documentation "The KILLABLE protocol describes objects which have two ~
states: alive and dead. A killable object is always created alive and may be ~
killed in any of the cases:
* the object terminates naturally as a part of its standard functioning,
* due to an external event, e.g. a programmer's request or termination of its ~
parent object,
* when an internal error occurs from which the object cannot recover."
     :tags (:killable)
     :export t)
  (:class killable () ())
  "A killable object. See protocol KILLABLE for details."
  (:function kill ((object killable)) (values))
  "If the object is alive, this function kills it. In any case, this functions ~
has no return values."
  (:function deadp ((object killable)) t)
  "Returns true if the object is dead, false otherwise"
  (:function alivep ((object killable)) t)
  "Returns true if the object is alive, false otherwise.
This function is a convenience function equivalent to NOT DEADP. No class
is required to define methods for it."
  (:macro with-restartability ((&optional killable) &body body))
  "This macro serves two purposes. First, it provides a semiautomatic means
of restarting the function body by means of providing a RETRY restart; second,
in case the retry is not chosen, it provides an optional facility of
automatically killing a killable object by means of UNWIND-PROTECT.
\
This macro is meant for being used inside functions passed to BT:MAKE-THREAD.")

(execute-protocol killable)

(defmethod alivep (object)
  (not (deadp object)))

(defun with-restartability-report (killable-name)
  `(lambda (stream)
     (format stream
             "Abort the current iteration and send the ~A back to its loop."
             (string-downcase (string (or ',killable-name "thread"))))))

;; TODO trace KILL, take care of multiple KILL calls
(defmacro with-restartability ((&optional killable) &body body)
  `(unwind-protect
        (tagbody :start
           (restart-case (progn ,@body)
             (retry () :report ,(with-restartability-report killable)
               (go :start))))
     ,(when killable `(uiop:symbol-call :gateway/protocol :kill ,killable))))