(in-package :cl-user)
(defpackage cl-blog-demo.web
  (:use :cl
        :caveman2
        :cl-blog-demo.config
        :cl-blog-demo.view
        :cl-blog-demo.db
        :datafly
        :sxql)
  (:export :*web*))
(in-package :cl-blog-demo.web)

;; for @route annotation
(syntax:use-syntax :annot)

;;
;; Application

(defclass <web> (<app>) ())
(defvar *web* (make-instance '<web>))
(clear-routing-rules *web*)

;; Models
(mito:connect-toplevel :sqlite3 :database-name (merge-pathnames #P"my-blog.db" *application-root*))

(mito:deftable user ()
  ((name :col-type (:varchar 64))
   (email :col-type (or (:varchar 128) :null))))

(mito:deftable post ()
  ((title :col-type :text)
   (content :col-type :text)
   (published :col-type :boolean)
   (views :col-type :integer)
   (user :col-type user :references user)))

(mito:ensure-table-exists 'user)
(mito:ensure-table-exists 'post)

;; (mito:insert-dao (make-instance 'user :name "Rajasegar" :email "rajasegar.c@gmail.com"))

(defun get-param (name parsed)
  (cdr (assoc name parsed :test #'string=)))

;;
;; Routing rules

(defroute "/" ()
  (render #P"index.html" (list :posts (mito:select-dao 'post
					(mito:includes 'user)
					(where (:= :published 1))) :author "Rajasegar")))

(defroute "/drafts" ()
  (render #P"drafts.html" (list :drafts (mito:select-dao 'post
					(mito:includes 'user)
					(where (:= :published 0))) :author "Rajasegar")))


(defroute "/signup" ()
  (render #P"signup.html"))

(defroute "/create" ()
  (render #P"create.html"))

(defroute ("/posts" :method :POST) (&key _parsed)
  (print _parsed)
  (let ((new-post (make-instance 'post
				 :title (get-param "title" _parsed)
				 :content (get-param "content" _parsed)
				 :published nil
				 :views 0
				 :user (mito:find-dao 'user  :email (get-param "email" _parsed)))))
    (mito:insert-dao new-post)
  (redirect "/")))

(defroute "/posts/:id" (&key id)
  (let ((post (mito:find-dao 'post :id id)))
    (if (equal (slot-value post 'published) t)
	(progn
	  (incf (slot-value post 'views))
	  (mito:save-dao post))
	nil)
    (render #P"show.html" (list :post post))))

(defroute "/posts/:id/publish" (&key id)
  (let ((post (mito:find-dao 'post :id id)))
    (setf (slot-value post 'published) t)
    (mito:save-dao post)
  (redirect "/")))

(defroute "/posts/:id/delete" (&key id)
  (mito:delete-by-values 'post :id id)
  (redirect "/"))
;;
;; Error pages

(defmethod on-exception ((app <web>) (code (eql 404)))
  (declare (ignore app))
  (merge-pathnames #P"_errors/404.html"
                   *template-directory*))
