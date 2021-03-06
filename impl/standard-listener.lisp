;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; GATEWAY
;;;; © Michał "phoe" Herda 2017
;;;; classes/standard-listener.lisp

(in-package #:gateway/impl)

(in-readtable protest)

(defclass standard-listener (listener)
  ((%lock :accessor lock
          :initform (make-lock "Gateway - Listener lock"))
   (%connections :accessor connections)
   (%notifier-connection :accessor notifier-connection)
   (%thread :accessor thread)
   (%name :accessor name
          :initform "Gateway - Listener")
   (%handler :accessor handler
             :initarg :handler
             :initform (error "Must define a handler function.")))
  (:documentation #.(format nil "A standard implementation of Gateway protocol ~
class LISTENER.

The STANDARD-LISTENER spawns a thread which monitors the CONNECTIONs on the ~
connection list by means of READY-CONNECTION. It then attempts ~
to read a command by CONNECTION-RECEIVE and, if it is read, call its handler ~
function with the connection and the command as arguments.

The handler is expected to push a message in form (CONNECTION COMMAND) into ~
a designated place.")))

(define-print (standard-listener stream)
  (if (alivep standard-listener)
      (let ((connections (with-lock-held ((lock standard-listener))
                           (connections standard-listener))))
        (format stream "(~D connections, ALIVE)" (length connections)))
      (format stream "(DEAD)")))

(defmethod (setf connections) :after (new-value (listener standard-listener))
  (connection-send (notifier-connection listener) '()))

(define-constructor (standard-listener)
  (v:trace :gateway "Standard listener starting.")
  (multiple-value-bind (connection-1 connection-2) (make-connection-pair)
    (let ((fn (curry #'listener-loop standard-listener)))
      (setf (notifier-connection standard-listener) connection-1
            (connections standard-listener) (list connection-2)
            (thread standard-listener)
            (make-thread fn :name (name standard-listener))))))

(defun listener-ready-connection (listener)
  (tagbody :start
     (let* ((conns (with-lock-held ((lock listener)) (connections listener))))
       (assert (not (null conns)) () "Listener: connection list is empty.")
       (let* ((conn (ready-connection conns)))
         (unless conn (go :start))
         (v:trace :gateway "Standard listener: receiving from ~A."
                  (socket-peer-address (socket-of conn)))
         (return-from listener-ready-connection conn)))))

(defun listener-loop (listener)
  (with-restartability (listener)
    (loop
      (handler-case
          (let* ((connection (listener-ready-connection listener))
                 (command (connection-receive connection)))
            (when command
              (funcall (handler listener) connection command)))
        (stream-error (e)
          (listener-error listener e))))))

(defun listener-error (listener condition)
  (let* ((connections (with-lock-held ((lock listener)) (connections listener)))
         (stream (stream-error-stream condition))
         (predicate (lambda (x) (eq stream (socket-stream x))))
         (connection (find-if predicate connections :key #'socket-of)))
    (when connection
      (v:debug :gateway "Standard listener: removing dead connection ~A."
               (address connection))
      (kill connection)
      (with-lock-held ((lock listener))
        (setf (connections listener)
              (remove connection (connections listener) :count 1))))))

(defmethod deadp ((listener standard-listener))
  (not (thread-alive-p (thread listener))))

(defmethod kill ((listener standard-listener))
  (v:trace :gateway "Standard listener was killed.")
  (unless (eq (current-thread) (thread listener))
    (destroy-thread (thread listener)))
  (unless (deadp listener)
    (kill (notifier-connection listener))
    (with-lock-held ((lock listener))
      (mapc #'kill (connections listener))
      (setf (connections listener) '())))
  (values))

;; Oh goodness, I remember the days when I've had no idea what a closure was
;; and how a function can be an object.
;; ~phoe, 28 Dec 2017

;; Oh goodness, I remember the days when I wrote the above comment. I've learned
;; so much since then.
;; ~phoe, 03 Aug 2017

;; Oh goodness, I remember the days when I walked into a project that I have not
;; been in for some time and immediately going "wtf, who wrote this." These days
;; are over now.
;; ~phoe, 30 Mar 2018

;;; TESTS

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
    (multiple-value-bind (connection-1 connection-2) #4?(make-connection-pair)
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
    (multiple-value-bind (connection-1 connection-2) #2?(make-connection-pair)
      #3?(with-lock-held ((lock listener))
           (push connection-1 (connections listener)))
      #4?(is (alivep listener))
      #5?(kill connection-2)
      #6?(is (wait () (deadp connection-1)))
      #7?(is (deadp connection-2))
      #8?(is (wait () (not (member connection-1 (connections listener)))))
      #9?(is (= 1 (length (connections listener))))
      #10?(is (alivep listener)))))

(define-test-case standard-listener-message
    (:description "Tests the message-passing functionality of the ~
STANDARD-LISTENER."
     :tags (:implementation :listener :connection)
     :type :implementation)
  :arrange
  1 "Create a listener with a simple list-pushing handler."
  2 "Create both sides of connection 1."
  3 "Create both sides of connection 2."
  4 "Create both sides of connection 3."
  5 "Add first sides of the three connections to the listener's connection ~
list."
  :loop-act
  6 "Send a message through the other side of connection 1, 2 or 3."
  :loop-assert
  7 "Assert the message was pushed onto the list."
  8 "Pop the message from the list and go back to step 6 a few times.")

(define-test standard-listener-message
  (finalized-let* ((lock (make-lock))
                   (list '())
                   (fn (lambda (conn data) (with-lock-held (lock)
                                             (push (list conn data) list))))
                   (listener #1?(make-instance 'standard-listener :handler fn)
                             (kill listener))
                   (c1 (multiple-value-list #2?(make-connection-pair))
                       (mapc #'kill c1))
                   (c2 (multiple-value-list #3?(make-connection-pair))
                       (mapc #'kill c2))
                   (c3 (multiple-value-list #4?(make-connection-pair))
                       (mapc #'kill c3))
                   (c1a (first c1)) (c1b (second c1))
                   (c2a (first c2)) (c2b (second c2))
                   (c3a (first c3)) (c3b (second c3)))
    #5?(with-lock-held ((lock listener))
         (push c1a (connections listener))
         (push c2a (connections listener))
         (push c3a (connections listener)))
    (loop for i below 30
          for data = (make-list 10 :initial-element i)
          do (progn
               #6?(connection-send (whichever c1b c2b c3b) data)
               #7?(is (wait () (member data (with-lock-held (lock) list)
                                       :test #'equal :key #'second)))
               #8?(with-lock-held (lock) (pop list))))))
