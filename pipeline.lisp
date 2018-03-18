#|
 This file is a part of trial
 (c) 2017 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:org.shirakumo.fraf.trial)

(defclass pipeline ()
  ((nodes :initform NIL :accessor nodes)
   (passes :initform #() :accessor passes)
   (textures :initform #() :accessor textures)))

(defmethod finalize ((pipeline pipeline))
  (clear pipeline))

(defmethod enter ((pass shader-pass) (pipeline pipeline))
  (pushnew pass (nodes pipeline)))

(defmethod leave ((pass shader-pass) (pipeline pipeline))
  (setf (nodes pipeline) (delete pass (nodes pipeline))))

(defmethod clear-pipeline ((pipeline pipeline))
  (loop for tex across (textures pipeline)
        do (finalize tex))
  (loop for pass across (passes pipeline)
        do (when (framebuffer pass)
             (finalize (framebuffer pass))
             (setf (framebuffer pass) NIL))
           (remove-handler pass pipeline))
  (setf (nodes pipeline) ())
  (setf (passes pipeline) #())
  (setf (textures pipeline) #()))

(defmethod connect ((source flow:port) (target flow:port) (pipeline pipeline))
  (unless (find (flow:node source) (nodes pipeline))
    (enter (flow:node source) pipeline))
  (unless (find (flow:node target) (nodes pipeline))
    (enter (flow:node target) pipeline))
  (flow:connect source target 'flow:directed-connection)
  pipeline)

(defmethod check-consistent ((pipeline pipeline))
  (dolist (node (nodes pipeline))
    (dolist (port (flow:ports node))
      (check-consistent port))))

(defmethod resize ((pipeline pipeline) width height)
  (gl:scissor 0 0 width height)
  ;; FIXME: keep width/height according to desired texspec
  (loop for texture across (textures pipeline)
        do (resize texture width height)))

(defmethod normalized-texspec ((texspec list))
  (assert (= 0 (getf texspec :level 0)))
  (assert (eql :dynamic (getf texspec :storage :dynamic)))
  (let ((initargs (loop for (key val) in (class-default-initargs 'texture)
                        collect key collect val)))
    (loop for (key val) on initargs by #'cddr
          collect key
          collect (or (getf texspec key)
                      (case key
                        (:width 'width)
                        (:height 'height)
                        (T val))))))

(defmethod normalized-texspec ((port texture-port))
  (normalized-texspec (texspec port)))

(defmethod normalized-texspec ((port output))
  (normalized-texspec
   (append (texspec port)
           ;; Default internal format for attachments
           (case (attachment port)
             (:depth-attachment
              (list :internal-format :depth-component
                    :min-filter :linear))
             (:stencil-attachment
              (list :internal-format :stencil-index
                    :min-filter :linear))
             (:depth-stencil-attachment
              (list :internal-format :depth-stencil
                    :min-filter :linear))
             (T
              (list :internal-format :rgba))))))

(defun allocate-textures (passes textures texspec)
  (flet ((kind (port)
           ;; FIXME: This is really dumb and inefficient. If we could remember which port belongs
           ;;        to which joined texspec instead it could be much better and wouldn't need to
           ;;        recompute everything all the time.
           (and (typep port 'output) (join-texspec texspec (normalized-texspec port)))))
    (flow:allocate-ports passes :sort NIL :test #'kind :attribute :texid)
    (let* ((texture-count (loop for pass in passes
                                when (flow:ports pass)
                                maximize (loop for port in (flow:ports pass)
                                               when (and (flow:attribute port :texid)
                                                         (kind port))
                                               maximize (1+ (flow:attribute port :texid)))))
           (offset (length textures)))
      (adjust-array textures (+ offset texture-count) :initial-element NIL)
      (dolist (pass passes textures)
        (dolist (port (flow:ports pass))
          (when (kind port)
            ;; FIXME: Recompute the minimal upgraded texspec across all shared
            ;;        ports, as the partitioning done by the allocation mechanism
            ;;        might have broken up texspecs that were initially grouped.
            (let* ((texid (+ offset (flow:attribute port :texid)))
                   (texture (or (aref textures texid)
                                (apply #'make-instance 'texture texspec))))
              (setf (aref textures texid) texture)
              (setf (texture port) texture)
              (dolist (connection (flow:connections port))
                (setf (texture (flow:right connection)) texture)))))))))

(defmethod pack-pipeline ((pipeline pipeline) target)
  (check-consistent pipeline)
  (v:info :trial.pipeline "~a packing for ~a (~ax~a)" pipeline target (width target) (height target))
  (let* ((passes (flow:topological-sort (nodes pipeline)))
         (textures (make-array 0 :initial-element NIL :adjustable T))
         (texspecs (loop for port in (mapcan #'flow:ports passes)
                         when (typep port 'output)
                         collect (normalized-texspec port))))
    (clear-pipeline pipeline)
    ;; Compute texture set
    (dolist (texspec (join-texspecs texspecs))
      (allocate-textures passes textures texspec))
    ;; Discretize texture size
    (loop for texture across textures
          do (flet ((eval-size (size)
                      (eval `(let ((width ,(width target))
                                   (height ,(height target)))
                               (declare (ignorable width height))
                               ,size))))
               (setf (width texture) (eval-size (width texture)))
               (setf (height texture) (eval-size (height texture)))))
    ;; FIXME: Replace textures with existing ones if they match to save on re-allocation.
    ;; Compute frame buffers
    (dolist (pass passes)
      (add-handler pass pipeline)
      (setf (framebuffer pass)
            (make-instance 'framebuffer
                           :attachments (loop for port in (flow:ports pass)
                                              when (typep port '(and output (not buffer)))
                                              collect (list (attachment port) (texture port))))))
    ;; All done.
    (v:info :trial.pipeline "~a pass order: ~a" pipeline passes)
    (v:info :trial.pipeline "~a texture count: ~a" pipeline (length textures))
    (v:info :trial.pipeline "~a texture allocation: ~:{~%~a~:{~%    ~a: ~a~}~}" pipeline
            (loop for pass in passes
                  collect (list pass (loop for port in (flow:ports pass)
                                           collect (list (flow:name port) (texture port))))))
    (setf (passes pipeline) (coerce passes 'vector))
    (setf (textures pipeline) textures)))

(defmethod paint-with ((pipeline pipeline) source)
  (loop for pass across (passes pipeline)
        for fbo = (framebuffer pass)
        do (gl:bind-framebuffer :framebuffer (gl-name fbo))
           ;; FIXME: Figure out which to clear depending on framebuffer attachments
           (gl:clear :color-buffer :depth-buffer :stencil-buffer)
           (paint-with pass source)))

(defmethod register-object-for-pass ((pipeline pipeline) object)
  (loop for pass across (passes pipeline)
        do (register-object-for-pass pass object)))
