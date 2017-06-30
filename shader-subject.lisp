#|
 This file is a part of trial
 (c) 2017 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:org.shirakumo.fraf.trial)

(defclass shader-subject-class (subject-class)
  ((effective-shaders :initform () :accessor effective-shaders)
   (direct-shaders :initform () :initarg :shaders :accessor direct-shaders)
   (inhibit-shaders :initform () :initarg :inhibit-shaders :accessor inhibit-shaders)))

(defmethod cascade-option-changes :before ((class shader-subject-class))
  (let ((effective-shaders ())
        (inhibited (inhibit-shaders class)))
    ;; Make all direct shaders effective
    (loop for (type shader) on (direct-shaders class) by #'cddr
          do (setf (getf effective-shaders type)
                   (list shader)))
    ;; Go through all superclasses in order
    (loop for super in (c2mop:compute-class-precedence-list class)
          do (when (typep super 'shader-subject-class)
               (setf inhibited (append inhibited (inhibit-shaders super)))
               (loop for (type shader) on (direct-shaders super) by #'cddr
                     unless (find (list (class-name super) type) inhibited :test #'equal)
                     do (pushnew shader (getf effective-shaders type)))))
    ;; Compute effective single shader sources
    (loop for (type shaders) on effective-shaders by #'cddr
          do (setf (getf effective-shaders type)
                   (glsl-toolkit:merge-shader-sources
                    (loop for (priority shader) in (stable-sort shaders #'> :key #'first)
                          collect (etypecase shader
                                    (string shader)
                                    (list (destructuring-bind (pool path) shader
                                            (pool-path pool path))))))))
    (setf (effective-shaders class) effective-shaders)))

(defmethod effective-shaders ((class symbol))
  (effective-shaders (find-class class)))

(defmethod direct-shaders ((class symbol))
  (direct-shaders (find-class class)))

(defmethod class-shader (type (class shader-subject-class))
  (getf (direct-shaders class) type))

(defmethod class-shader (type (class symbol))
  (class-shader type (find-class class)))

(defmethod (setf class-shader) (shader type (class shader-subject-class))
  (setf (getf (direct-shaders class) type) shader))

(defmethod (setf class-shader) (shader type (class symbol))
  (setf (class-shader type (find-class class)) shader))

(defmethod (setf class-shader) :after (shader type (class shader-subject-class))
  (cascade-option-changes class))

(defmethod remove-class-shader (type (class shader-subject-class))
  (remf (direct-shaders class) type))

(defmethod remove-class-shader (type (class symbol))
  (remove-class-shader type (find-class class)))

(defmethod remove-class-shader :after (type (class shader-subject-class))
  (cascade-option-changes class))

(defmethod make-class-shader-program ((class shader-subject-class))
  (make-asset 'shader-program
              (loop for (type source) on (effective-shaders class) by #'cddr
                    collect (make-asset 'shader (list source) :type type))))

(defmacro define-class-shader ((class type &optional (priority 0)) &body definitions)
  `(setf (class-shader ,type ',class)
         (list ,priority (progn ,@definitions))))

(defclass shader-subject (subject)
  ()
  (:metaclass shader-subject-class))

(defmethod effective-shaders ((subject shader-subject))
  (effective-shaders (class-of subject)))

(defmethod direct-shaders ((subject shader-subject))
  (direct-shaders (class-of subject)))

(defmethod class-shader (type (subject shader-subject))
  (class-shader type (class-of subject)))

(defmethod (setf class-shader) (source type (subject shader-subject))
  (setf (class-shader type (class-of subject)) source))

(defmethod remove-class-shader (type (subject shader-subject))
  (remove-class-shader type (class-of subject)))

(defmethod make-class-shader-program ((subject shader-subject))
  (make-class-shader-program (class-of subject)))

(defmacro define-shader-subject (&environment env name direct-superclasses direct-slots &rest options)
  (unless (find-if (lambda (c) (c2mop:subclassp (find-class c T env) 'shader-subject)) direct-superclasses)
    (setf direct-superclasses (append direct-superclasses (list 'shader-subject))))
  (unless (find :metaclass options :key #'first)
    (push '(:metaclass shader-subject-class) options))
  `(eval-when (:compile-toplevel :load-toplevel :execute)
     (defclass ,name ,direct-superclasses
       ,direct-slots
       ,@options)))

(define-class-shader (shader-subject :vertex-shader)
  "#version 330 core")

(define-class-shader (shader-subject :fragment-shader)
  "#version 330 core
out vec4 color;

void main(){
  color = vec4(1.0, 1.0, 1.0, 1.0);
}")
