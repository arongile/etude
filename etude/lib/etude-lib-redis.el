(require 'cl-lib)
(require 'dash)

(defvar e/redis--current-process nil "Current Redis client process, used when the process is not passed in to the request")

;;; Customization

(defgroup e/redis nil
  "Eredis is a Redis client API for Emacs Lisp")

(defcustom e/redis-max-retries 1000
  "Number of retries before failing to read the redis response. Note that this is a very high number because accepting input sometimes returns immediately, and if the response takes a few seconds you will do 10s of retries."

  :type 'integer
  :group 'e/redis)

(defcustom e/redis-response-timeout 3
  "Response timeout, in seconds, when waiting for output from Redis"

  :type 'integer
  :group 'e/redis)

;; Util

(defun e/redis-version() "0.9.6")

(defun e/redis--two-lists-to-map(key-list value-list)
  "take a list of keys LST1 and a list of values LST2 and make a hashmap, not particularly efficient
as it first constructs a list of key value pairs then uses that to construct the hashmap"
  (let ((retmap (make-hash-table :test 'equal)))
    (cl-mapc (lambda (k v)
               (puthash k v retmap))
             key-list value-list)
    retmap))

(defun e/redis--unflatten-map-worker(in keys values)
  (if (null in)
      (e/redis--two-lists-to-map keys values)
    (e/redis--unflatten-map-worker (cddr in) (cons (first in) keys) (cons (second in) values))))

(defun e/redis--unflatten-map(l)
  "take a list of value1 key1 ... valuen keyn and return a map"
  (let ((len (length l)))
    (if (/= (mod len 2) 0)
        (error "list must be even length"))
    (e/redis--unflatten-map-worker l nil nil)))

(defun e/redis--flatten-map(m)
  "flatten the key values of map M to a list of the form key1 value1 key2 value2..."
  (let ((key-values nil))
    (maphash (lambda (k v)
               (push k key-values)
               (push v key-values))
             m)
    (reverse key-values)))

(defun e/redis-parse-map-or-list-arg(a)
  "handle when an argument can be passed as a hash table or a list of key values"
  (if (hash-table-p a)
      (e/redis--flatten-map a)
    a))

(defun e/redis--insert-map(m)
  "insert a map M of key value pairs into the current buffer"
  (maphash (lambda (a b) (insert (format "%s,%s\n" a b))) m))

(defun e/redis--insert-list(l)
  "Insert a list L into the current buffer separated by commas"
  (let ((str (--reduce (concat acc "," it) l)))
    (insert str)))

(defun e/redis--stringify-numbers-and-symbols(item)
  (cond 
   ((numberp item)
    (number-to-string item))
   ((symbolp item)
    (symbol-name item))
   ((stringp item)
    item)
   (t
    (error "unsupported type: %s" item))))

(defun e/redis-build-request(command &rest arguments)
  "Construct a command to send to Redis using the RESP protocol"
  (let ((num-args (+ 1 (length arguments))))
    (if (> num-args 0)
        (let ((req (format "*%d\r\n$%d\r\n%s\r\n" num-args (length command) command)))
          (dolist (item arguments)
            (setf item (e/redis--stringify-numbers-and-symbols item))
            (setf req (concat req (format "$%d\r\n%s\r\n" (string-bytes item) item))))
          req)
      nil)))

(defun e/redis-map-keys(key-expr)
  "take a glob expression like \"user.id.*\" and return the key/values of matching keys"
  (let ((keys (e/redis-keys key-expr)))
    (if keys
        (let ((values (e/redis-mget keys)))
          (e/redis--two-lists-to-map keys values))
      nil)))

(defun e/redis-get-response(process)
  "Given the process we try to get its buffer, and the next response start position (which is stored in the process properties under `response-start', we then identify the message type and parse the response. If we run out of response (maybe it isn't all downloaded yet we return `incomplete' otherwise we return the response, the format of which may depend on the request type. We use the customizable variables `e/redis-response-timeout' and `e/redis-max-retries' to determine the behaviour if the response is incomplete."
  (let ((buffer (process-buffer process))
	(response-start (process-get process 'response-start))
	(tries 0)
	(done nil)
	(last-incomplete nil)
	(resp nil))
    (with-current-buffer buffer
      (while (and
	      (< tries e/redis-max-retries)
	      (not done))
	(accept-process-output process e/redis-response-timeout nil 1)
	(pcase-let ((`(,message . ,length)
		     (e/redis-parse-response (buffer-substring response-start (point-max)))))
	  (if (eq message 'incomplete)
	      (progn
		(incf tries 1)
		(setf last-incomplete t)
		(message (format "Incomplete message, will retry. (Attempt %d)" tries)))
	    (progn
	      (setf resp message)
	      (setf done t)
	      (setf last-incomplete nil)
	      (process-put process 'response-start (+ response-start length)))))))
    (if last-incomplete       
	(error "Response did not complete")
      resp)))
	      
(defun e/redis-response-type-of (response)
  "Get the type of RESP response based on the initial character"
  (let ((chr (elt response 0))
        (chr-type-alist '((?- . error)
                          (?* . array)
                          (?$ . single-bulk)
                          (?: . integer)
                          (?+ . status))))
    (cdr (assoc chr chr-type-alist))))

(defun e/redis-parse-response (response)
  "Parse the response. Returns a cons of the type and the body. Body will be 'incomplete if it is not yet fully downloaded or corrupted. An error is thrown when parsing an unknown type"
  (let ((response-type (e/redis-response-type-of response)))
    (cond ((eq response-type 'error)
           (e/redis-parse-error-response response))
          ((eq response-type 'array)
           (e/redis-parse-array-response response))
          ((eq response-type 'single-bulk)
           (e/redis-parse-bulk-response response))
          ((eq response-type 'integer)
           (e/redis-parse-integer-response response))
          ((eq response-type 'status)
           (e/redis-parse-status-response response))
          (t (error "Unkown RESP response prefix: %c" (elt response 0))))))

(defun e/redis--basic-response-length (resp)
  "Return the length of the response header or fail with nil if it doesn't end wth \r\n"
  (when (and resp (string-match "\r\n" resp))
    (match-end 0)))

(defun e/redis-parse-integer-response(resp)
  (let ((len (e/redis--basic-response-length resp)))
    (if len	
	`(,(string-to-number (cl-subseq resp 1)) . ,len)
      `(incomplete . 0))))

(defun e/redis-parse-error-response (resp)
  (e/redis-parse-status-response resp))

(defun e/redis-parse-status-response (resp)
  (let ((len (e/redis--basic-response-length resp)))
    (if len
	`(,(substring resp 1 (- len 2)) . ,len)
      '(incomplete . 0))))

(defun e/redis-parse-bulk-response (resp)
  "Parse the redis bulk response `resp'. Returns the dotted pair of the result and the total length of the message including any line feeds and the header. If the result is incomplete return `incomplete' instead of the message so the caller knows to wait for more data from the process"
  (let ((unibyte (string-as-unibyte resp)))
    (if (string-match "^$\\([\-]*[0-9]+\\)\r\n" unibyte)
	(let* ((body-size (string-to-number (match-string 1 unibyte)))
	       (header-size (+ (length (match-string 1 resp)) 1 2 2))
	       (total-size-bytes (+ header-size body-size))
	       (body-start (match-end 0)))
	  ;;(message (format "body size %d" body-size))
	  (if (< body-size 0)
	      `(,nil . ,(- header-size 2))
	    (if (= body-size 0)
		`("" . ,header-size)
	      (if (< (length unibyte) total-size-bytes)
		  `(incomplete . 0)
		(let ((message (string-as-multibyte
				(substring unibyte body-start (+ body-start body-size)))))
		  `(,message . ,(+ header-size (length message))))))))
      `(incomplete . 0))))

(defun e/redis-parse-array-response (resp)
  "Parse the redis array response RESP and return the list of results. handles null entries when length is -1 as per spec. handles lists of any type of thing, handles lists of lists etc"
  (if (string-match "^*\\([\-]*[0-9]+\\)\r\n" resp)
      (let ((array-length (string-to-number (match-string 1 resp)))
	    (header-size (+ (length (match-string 1 resp)) 1 2)))
	;;(message (format "parse array length %d header %d resp %s" array-length header-size resp))
	(case array-length
	  (0
	   `(() . 4))
	  (-1
	   `(nil . 5))
	  (t
	   (let ((things nil)
		 (current-pos header-size))
	     (dotimes (n array-length)
	       ;;(message (format "n %d current-pos %d" n current-pos))
	       (pcase-let ((`(,message . ,length)
			    (e/redis-parse-response (substring resp current-pos nil))))
		 ;;(message (format "%s length %d" message length))
		 (incf current-pos length)
		 (!cons message things)))
	     `(,(reverse things) . ,current-pos)))))
    `(incomplete . 0)))

(defun e/redis-command-returning (command &rest args)
  "Send a command that has the status code return type. If the last argument is a process then that is the process used, otherwise it will use the value of `e/redis--current-process'"
  (let* ((last-arg (car (last args)))
	 (process (if (processp last-arg)
		      last-arg
		    e/redis--current-process))
	 (command-args
	  (if (or
	       (null last-arg)
	       (processp last-arg))
	      (-butlast args)
	    args)))
    (if (and process (eq (process-status process) 'open))
	(progn 
          (process-send-string process (apply #'e/redis-build-request command command-args))
          (let ((ret-val (e/redis-get-response process)))
            (when (called-interactively-p 'any)
              (message ret-val))
            ret-val))
      (error "redis not connected"))))

(defun e/redis-sentinel(process event)
  "Sentinel function for redis network process which monitors for events"
  (message (format "sentinel event %s" event))
  (when (eq 'closed (process-status process))
    (when (eq process e/redis--current-process)
      (setq e/redis--current-process nil))
    (delete-process process)))

(defun e/redis-filter(process string)
  "filter function for redis network process, which receives output"
  (message (format "received %d bytes at process %s" (length string) e/redis--current-process))
  (process-put process 'e/redis-response-str (concat (or (process-get process 'e/redis-response-str)
                                                    "")
                                                string)))

(defun e/redis-delete-process(&optional process)
  (if process
      (prog1 
	  (delete-process process)
	(when (eq e/redis--current-process process)
	    (setq e/redis--current-process nil)))
    (when e/redis--current-process
      (delete-process e/redis--current-process)
      (setq e/redis--current-process nil))))

;; Create a unique buffer for each connection

(defun e/redis--generate-buffer(host port)
  (generate-new-buffer (format "redis-%s-%d" host port)))

;; Connect and disconnect functionality

(defun e/redis-connect(host port &optional nowait)
  "Connect to Redis on HOST PORT. `NOWAIT' can be set to non-nil to make the connection asynchronously. That's not supported when you run on Windows"
  (interactive (list (read-string "Host: " "localhost") (read-number "Port: " 6379)))
  (let ((buffer (e/redis--generate-buffer host port)))	
    (prog1
	(setq e/redis--current-process
              (make-network-process :name (buffer-name buffer)
				    :host host
				    :service port
				    :type nil
				    :nowait nowait
				    :keepalive t
				    :linger t
				    :sentinel #'e/redis-sentinel
				    :buffer buffer))
      (process-put e/redis--current-process 'response-start 1))))

(defun e/redis-clear-buffer(&optional process)
  "Erase the process buffer and reset the `response-start' property to the start"
  (let ((this-process (if (processp process)
			  process
			e/redis--current-process)))
    (when (processp this-process)
      (with-current-buffer (process-buffer this-process)
	(erase-buffer)
	(process-put this-process 'response-start 1)
	t))))

(defun e/redis-disconnect(&optional process)
  "Close the connection to Redis"
  (interactive)
  (e/redis-delete-process process))

;; legacy 'funny' names for connect and disconnect
(defalias 'e/redis-hai 'e/redis-connect)
(defalias 'e/redis-kthxbye 'e/redis-disconnect)


(provide 'etude-lib-redis)
