;;;; Autogenerated ASD file for system "GATEWAY"
;;;; In order to regenerate it, run update-asdf
;;;; from shell (see https://github.com/phoe-krk/asd-generator)
;;;; For those who do not have update-asdf,
;;;; run `ros install asd-generator` (if you have roswell installed)
;;;; There are also an interface available from lisp:
;;;; (asd-generator:regen &key im-sure)
(asdf/parse-defsystem:defsystem #:gateway
  :description "A graphical chat/RP client written in Common Lisp."
  :author "Michał \"phoe\" Herda"
  :license "GPL3"
  :depends-on (#:hu.dwim.defclass-star
	       #:named-readtables
	       #:ironclad
	       #:closer-mop
	       #:cl-colors
	       #:jpl-queues
	       #:alexandria
	       #:bordeaux-threads
	       #:usocket
	       #:iterate
	       #:flexi-streams
	       #:local-time)
  :serial t
  :components ((:file "package")
	       (:file "helper/list-utils")
	       (:file "helper/logging")
	       (:file "helper/queue")
	       (:file "helper/varia")
	       (:file "protocol")
	       (:file "constants")
	       (:file "data/data")
	       (:file "impl/empty")
	       (:file "impl/shard/message")
	       (:file "impl/shard/password")
	       (:file "impl/shard/persona")
	       (:file "impl/shard/chat")
	       (:file "impl/shard/player")
	       (:file "impl/shard/world-map")
	       (:file "gateway")))
