;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; GATEWAY
;;;; © Michał "phoe" Herda 2016
;;;; classes/standard-listener.lisp

(in-package #:gateway/impl)

(in-readtable protest)

(defclass standard-listener (listener)
  ((%lock :accessor lock
          :initform (make-lock "Gateway - Listener lock"))
   (%connections :reader connections)
   (%notifier-connection :accessor notifier-connection)
   (%thread :accessor thread)
   (%name :accessor name
          :initform "Gateway - Listener")
   (%handler :accessor handler
             :initarg :handler
             :initform (error "Must define a handler function."))))

(defmethod (setf connections) (new-value (listener standard-listener))
  (prog1 (setf (slot-value listener '%connections) new-value)
    (%notify listener)))

(defun %notify (listener)
  (connection-send (notifier-connection listener) ()))

(define-constructor (standard-listener)
  (multiple-value-bind (connection-1 connection-2) (%make-connection-pair)
    (let ((fn (curry #'%listener-loop standard-listener)))
      (setf (notifier-connection standard-listener) connection-1
            (connections standard-listener) (list connection-2)
            (thread standard-listener)
            (make-thread fn :name (name standard-listener))))))

(defun %listener-ready-socket (listener)
  (let* ((connections (with-lock-held ((lock listener)) (connections listener)))
         (sockets (mapcar #'socket-of connections)))
    (first (wait-until (wait-for-input sockets :timeout nil :ready-only t)))))

(defun %listener-loop (listener)
  (with-restartability (listener)
    (loop
      (handler-case
          (let* ((socket (%listener-ready-socket listener))
                 (connection (owner socket))
                 (command (connection-receive connection)))
            (when command
              (funcall (handler listener) connection command)))
        (stream-error (e)
          (%listener-error listener e))))))

(defun %listener-error (listener condition)
  (let* ((connections (with-lock-held ((lock listener)) (connections listener)))
         (stream (stream-error-stream condition))
         (predicate (lambda (x) (eq stream (socket-stream (socket-of x)))))
         (connection (find-if predicate connections)))
    (when connection
      (kill connection)
      (with-lock-held ((lock listener))
        (setf (connections listener)
              (remove connection (connections listener) :count 1))))))

(defmethod deadp ((listener standard-listener))
  (not (thread-alive-p (thread listener))))

(defmethod kill ((listener standard-listener))
  (unless (eq (current-thread) (thread listener))
    (destroy-thread (thread listener)))
  (unless (deadp listener)
    (kill (notifier-connection listener))
    (with-lock-held ((lock listener))
      (mapc #'kill (connections listener))
      (setf (connections listener) ())))
  (values))



(define-test-case standard-listener-death
    (:description "Test of KILLABLE protocol for STANDARD-LISTENER."
     :tags (:protocol :killable :listener)
     :type :protocol)
  :arrange
  1  "Create a listener."
  2  "Get the reference to one side of the listener's notifier connection."
  3  "Get the reference to other side of the listener's notifier connection."
  4  "Create a connection."
  5  "Add the connection to the listener."
  6  "Assert the listener is alive."
  7  "Assert one side of the listener's notifier connection is alive."
  8  "Assert the other side of the listener's notifier connection is alive."
  :act
  9  "Kill the listener."
  :assert
  10 "Assert the listener is dead."
  11 "Assert the one side of the listener's notifier connection is dead."
  12 "Assert the other side of the listener's notifier connection is dead."
  13 "Assert the connection is dead.")

(define-test standard-listener-death
  (let* ((listener #1?(make-instance 'standard-listener
                                     :handler (constantly nil)))
         (notifier-1 #2?(notifier-connection listener))
         (notifier-2 #3?(first (connections listener))))
    (multiple-value-bind (connection-1 connection-2) #4?(%make-connection-pair)
      (declare (ignore connection-2))
      #5?(with-lock-held ((lock listener))
           (push connection-1 (connections listener)))
      #6?(is (alivep listener))
      #7?(is (alivep notifier-1))
      #8?(is (alivep notifier-2))
      #9?(kill listener)
      #10?(is (wait () (deadp listener)))
      #11?(is (deadp notifier-1))
      #12?(is (deadp notifier-2))
      #13?(is (deadp connection-1)))))

(define-test-case standard-listener-dead-connection
    (:description "Check if a dead connection is automatically cleared ~
from a listener's connection list."
     :tags (:implementation :connection :listener)
     :type :implementation)
  :arrange
  1  "Create a listener."
  2  "Create both sides of a connection."
  3  "Add the first side of connection to the listener."
  4  "Assert the listener is alive."
  :act
  5  "Kill the second side of the connection."
  :assert
  6  "Assert the first side of the connection is dead."
  7  "Assert the second side of the connection is dead."
  8  "Assert the listener's connection list does not contain the first side ~
of the connection."
  9  "Assert the listener's connection list contains only one element."
  10 "Assert the listener is alive.")

(define-test standard-listener-dead-connection
  (finalized-let* ((listener #1?(make-instance 'standard-listener
                                               :handler (constantly nil))
                             (kill listener)))
    (multiple-value-bind (connection-1 connection-2) #2?(%make-connection-pair)
      #3?(with-lock-held ((lock listener))
           (push connection-1 (connections listener)))
      #4?(is (alivep listener))
      #5?(kill connection-2)
      #6?(is (wait () (deadp connection-1)))
      #7?(is (deadp connection-2))
      #8?(is (wait (20) (not (member connection-1 (connections listener)))))
      #9?(is (= 1 (length (connections listener))))
      #10?(is (alivep listener)))))

(define-test-case standard-listener-message
    (:description ""
     :tags (:implementation :listener :connection)
     :type :implementation))