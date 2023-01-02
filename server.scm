(define PORT (string->number (get-environment-variable "PORT")))

(import json)
(import http)
(import (srfi 13)) ;; string libraries

(define (match str)
  (string=? (read-string (string-length str)) str))

(define (match-any char)
  (when (char=? char (peek-char))
    (read-char)
    (match-any char)))

(define return (make-parameter #f))


(define (return-request-error)
  ((return) "I'm sorry, there is an error in the request. I cannot understand what you sent!\n"))

(define (return-timeout-error)
  ((return) "I'm sorry, the code ran for too long. I had to stop it. I hope I didn't break anything!\n"))

(define (return-help)
  ((return) #<<help-end
Sorry! I didn't catch that.

To run code, use the `run` command as such : 
  @gambot run
  ```
  (println "hello world")
  ```

To see this help message, use @gambot help.
help-end
))

(define (read-code-block)
  (define buffer (open-string))

  (print port: buffer "(begin \n")

  (let loop ((writing #f))
    (let ((line (read-line)))
      (if (eq? #!eof line)
        (return-help)
        (if (and (<= 3 (string-length line)) (string=? (substring line 0 3) "```"))
          (if writing
            (begin
              (print port: buffer ")")
              buffer)
            (loop #t))
          (begin
            (if writing
              (print port: buffer line "\n"))
            (loop writing)))))))

(define (read-run-command json-context)


  (define code-block (read-code-block))
  (define output (open-output-string))
  (define stdout (current-output-port))

  (define (display-exception-error ex)
    (println "I'm sorry, it seems like there is a bug in your code... See below :\n```" )
    (display-exception ex)
    (println "```")
    (thread-terminate! (current-thread)))


  (define (code-lambda) 
    (parameterize ((current-output-port output))
      (with-exception-handler
        display-exception-error
        (lambda ()
          (let* ((code (read code-block))
                 (result (eval code)))
            (if (not (eq? #!void result))
              (print result)))))))

  (define (wait-for-termination! thread #!optional (timeout #f) (timeout-exit 'timeout-exit) (termination-exit 'termination-exit))
    (let ((eh (current-exception-handler)))
      (with-exception-handler
        (lambda (exc)
          (if (not (or (terminated-thread-exception? exc)
                       (uncaught-exception? exc)))
            (eh exc)
            termination-exit)) ; unexpected exceptions are handled by eh
        (lambda ()
          ; The following call to thread-join! will wait until the
          ; thread terminates.  If the thread terminated normally
          ; thread-join! will return normally.  If the thread
          ; terminated abnormally then one of these two exception
          ; objects is raised by thread-join!:
          ;   - terminated-thread-exception object
          ;   - uncaught-exception object
          (if timeout
            (thread-join! thread timeout timeout-exit)
            (thread-join! thread)))))) 

  (define code-thread (make-thread code-lambda))

  (thread-start! code-thread)
  (if  (eq? (wait-for-termination! code-thread
                                   2
                                   'exit)
            'exit)
    (return-timeout-error)
    ((return) (get-output-string output))))

(define (read-message json-context)
  (let ((bot-name (table-ref json-context "bot_full_name")))
    (if (not (and
               (match-any #\space)
               (match (string-append "@**" bot-name "**"))
               (match-any #\space)))
      (return-help))

    (let ((command (read-line))) 
      (if (eq? #!eof command)
        (return-help)
        (let ((command (string-trim-right command)))
          (cond ((equal? command "run") 
                 (read-run-command json-context))
                (else  (return-help))))))))


(define (POST)
  (let* ((request (current-request))
         (uri (request-uri request))
         (path (uri-path uri))
         (content (request-content request))
         (json (json-decode content)))

    (if (and content (not (eq? json 'json-error)))
      (let* ((message (table-ref json "message" #f))
             (content (table-ref message "content" #f)))
        (call-with-input-string 
          content
          (lambda (port)
            (let ((msg 
                    (call/cc 
                      (lambda (c) 
                        (parameterize 
                          ((return c)
                           (current-input-port port))
                          (read-message json))))))
              (print (string-append "Message send : " msg))
              (let* ((json-out (make-table)))
                (table-set! json-out "content" msg)
                (reply-json (json-encode json-out)))))))

      (reply-text "error in request\n" "text/plain"))))


(define (main port-number)
  (http-server-start!
    (make-http-server
      port-number: port-number
      threaded?: #f
      GET: POST
      POST: POST)))


(print 
  (string-append "server running on port " 
                 (number->string PORT)))
(main PORT)

