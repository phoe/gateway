;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; GATEWAY
;;;; © Michał "phoe" Herda 2016
;;;; standard-acceptor.lisp

(in-package #:gateway)

(defclass standard-acceptor (acceptor)
  ((%socket :accessor socket)
   (%thread :accessor thread)
   (%name :accessor name)
   (%pusher :accessor pusher
            :initarg :pusher
            :initform (error "Must define a pusher function."))))

(defconstructor (standard-acceptor (host "127.0.0.1") (port 0))
  (check-type host string)
  (check-type port (unsigned-byte 16))
  (let* ((socket (socket-listen "127.0.0.1" port :reuseaddress t))
         (name (format nil "Acceptor for ~{~D.~D.~D.~D~}:~D"
                       (coerce (get-local-name socket) 'list)
                       (get-local-port socket)))
         (fn (lambda () (%acceptor-loop-1 standard-acceptor)))
         (thread (make-thread fn :name (cat "Gateway - " name))))
    (setf (socket standard-acceptor) socket
          (name standard-acceptor) name
          (thread standard-acceptor) thread)))

(defun %acceptor-loop-1 (acceptor)
  (format t "[~~] ~A: starting.~%" (name acceptor))
  (unwind-protect
       (%acceptor-loop-2 acceptor)
    (kill acceptor)
    (format t "[!] ~A: killed.~%" (name acceptor))))

(defun %acceptor-loop-2 (acceptor)
  (restart-case
      (loop (%acceptor-loop-3 acceptor))
    (retry ()
      :report "Abort the current iteration and send the acceptor back to its loop."
      (format t "[!] ~A: restarted.~%" (name acceptor))
      (%acceptor-loop-2 acceptor))))

(defun %acceptor-loop-3 (acceptor)
  (let* ((socket (socket acceptor))
         (accept (socket-accept (wait-for-input socket)))
         (connection (make-instance 'standard-connection :socket accept)))
    (format t "[~~] ~A: got a connection, ~{~A.~A.~A.~A~}:~S.~%"
            (name acceptor)
            (coerce (get-peer-address accept) 'list) (get-peer-port accept))
    (funcall (pusher acceptor) connection)))

(defmethod alivep ((acceptor standard-acceptor))
  (thread-alive-p (thread acceptor)))

(defmethod kill ((acceptor standard-acceptor))
  (socket-close (socket acceptor))
  (unless (eq (current-thread) (thread acceptor))
    (destroy-thread (thread acceptor)))
  (values))

(deftest test-standard-acceptor
  (let ((acceptor (make-instance 'standard-acceptor :pusher (lambda (x) x))))
    (is (alivep acceptor))
    (kill acceptor)
    (is (wait (0.1) (not (alivep acceptor)))))
  (let* ((connections nil)
         (pusher (lambda (x) (push x connections))))
    (finalized-let* ((acceptor (make-instance 'standard-acceptor :pusher pusher)
                               (kill acceptor)
                               (is (wait (0.1) (not (alivep acceptor)))))
                     (host (get-local-address (socket acceptor)))
                     (port (get-local-port (socket acceptor)))
                     (socket-1 (socket-connect host port)
                               (socket-close socket-1)
                               (is (not (open-stream-p (socket-stream socket-1)))))
                     (socket-2 (socket-connect host port)
                               (socket-close socket-2)
                               (is (not (open-stream-p (socket-stream socket-2)))))
                     (socket-3 (socket-connect host port)
                               (socket-close socket-3)
                               (is (not (open-stream-p (socket-stream socket-3))))))
      (is (wait (0.5 :step 0.01) (= 3 (length connections)))))))