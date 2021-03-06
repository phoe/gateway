;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; GATEWAY
;;;; © Michał "phoe" Herda 2017
;;;; protocols/kernel.lisp

(in-package #:gateway/protocol)

(define-protocol kernel
    (:documentation "The KERNEL protocol describes objects which are capable of ~
processing messages, either sequentially or concurrently. In the second case, ~
the kernel contains implementation-dependent objects called workers.
\
The message's format is implementation-dependent.
\
On each enqueued message, the kernel's handler function is eventually called ~
on that message. That function is an one-argument function that expects the ~
implementation-dependent message as its argument."
     :tags (:kernel)
     :dependencies (killable named with-handler)
     :export t)
  (:class kernel (killable named with-handler) ())
  "A kernel object. See protocol KERNEL for details."
  (:function enqueue ((kernel kernel) message) (values))
  "Enqueues a message in the kernel for processing.")

(execute-protocol kernel)
