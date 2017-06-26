#|
 This file is a part of trial
 (c) 2016 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:org.shirakumo.fraf.trial)

(define-subject camera (located-entity)
  ((near-plane :initarg :near-plane :accessor near-plane)
   (far-plane :initarg :far-plane :accessor far-plane))
  (:default-initargs
   :location (vec 0 30 200)
   :near-plane 0.01f0
   :far-plane 1000000.0f0))

(define-generic-handler (camera project-view tick -100))
(define-generic-handler (camera setup-perspective resize))

(defmethod (setf near-plane) :after (val (camera camera))
  (setup-perspective camera))

(defmethod (setf far-plane) :after (val (camera camera))
  (setup-perspective camera))

(defmethod paint :around ((camera camera) target))

(defmethod setup-perspective :before ((camera camera) ev)
  (reset-matrix *projection-matrix*))

(defmethod setup-perspective :after ((camera camera) ev)
  (gl:viewport 0 0 (width ev) (height ev)))

(defmethod project-view :before ((camera camera) ev)
  (reset-matrix))

(define-subject 2d-camera (camera)
  ()
  (:default-initargs
   :near-plane 0.0
   :far-plane 100.0
   :location (vec 0 0 200)))

(defmethod setup-perspective ((camera 2d-camera) ev)
  (orthographic-projection 0 (width ev) (height ev) 0
                           (near-plane camera) (far-plane camera)))

(define-subject sidescroll-camera (2d-camera)
  ((zoom :initarg :zoom :accessor zoom)
   (target :initarg :target :accessor target))
  (:default-initargs
   :zoom 1.0
   :target NIL))

(defmethod project-view ((camera sidescroll-camera) ev)
  (let ((z (zoom camera)))
    (reset-matrix *view-matrix*)
    (scale-by z z z *view-matrix*)
    (translate (v- (location camera) (location (target camera))) *view-matrix*)))

(define-subject 3d-camera (camera)
  ((fov :initarg :fov :accessor fov))
  (:default-initargs
   :fov 75))

(defmethod (setf fov) :after (val (camera 3d-camera))
  (setup-perspective camera))

(defmethod setup-perspective  ((camera 3d-camera) ev)
  (perspective-projection (fov camera) (/ (width ev) (max 1 (height ev)))
                          (near-plane camera) (far-plane camera)))

(define-subject target-camera (3d-camera)
  ((target :initarg :target :accessor target)
   (up :initarg :up :accessor up))
  (:default-initargs
   :target (vec 0 0 0)
   :up (vec 0 1 0)))

(defmethod project-view ((camera target-camera) ev)
  (look-at (location camera) (target camera) (up camera)))

(define-subject pivot-camera (target-camera)
  ()
  (:default-initargs
   :target NIL))

(defmethod project-view ((camera pivot-camera) ev)
  (when (target camera)
    (look-at (location camera)
             (location (target camera))
             (up camera))))

(define-subject following-camera (target-camera)
  ()
  (:default-initargs
   :target NIL))

(defmethod project-view ((camera following-camera) ev)
  (when (target camera)
    (look-at (v+ (location camera)
                 (location (target camera)))
             (location (target camera))
             (up camera))))

(define-subject fps-camera (3d-camera)
  ((rotation :initarg :rotation :accessor rotation)
   (acceleration :initarg :acceleration :accessor acceleration)
   (x-inverted :initarg :x-inverted :accessor x-inverted)
   (y-inverted :initarg :y-inverted :accessor y-inverted))
  (:default-initargs
   :rotation (vec 0 0 0)
   :acceleration 0.01
   :x-inverted NIL
   :y-inverted NIL))

(defmethod project-view ((camera fps-camera) ev)
  (rotate +vx+ (vx (rotation camera)))
  (rotate +vy+ (vy (rotation camera)))
  (rotate +vz+ (vz (rotation camera)))
  (translate (v- (the vec3 (location camera)))))

(defun do-fps-movement (camera old-pos pos)
  (let ((delta (v- pos old-pos)))
    (when (x-inverted camera) (setf (vx delta) (- (vx delta))))
    (when (y-inverted camera) (setf (vy delta) (- (vy delta))))
    (nv+ (rotation camera) (nv* (vyx_ delta)
                                (acceleration camera)))))

(define-handler (fps-camera mouse-move) (ev old-pos pos)
  (do-fps-movement fps-camera old-pos pos))

(define-subject freeroam-camera (fps-camera)
  ((move-speed :initarg :move-speed :accessor move-speed))
  (:default-initargs
   :move-speed 4))

(define-handler (freeroam-camera tick) (ev)
  (let ((vec (vec 0 0 0))
        (speed (move-speed freeroam-camera)))
    (cond ((retained 'movement :left)
           (setf (vx vec) (- speed)))
          ((retained 'movement :right)
           (setf (vx vec) (+ speed))))
    (cond ((retained 'movement :up)
           (setf (vz vec) (- speed)))
          ((retained 'movement :down)
           (setf (vz vec) (+ speed))))
    (cond ((retained 'key :space)
           (setf (vy vec) (+ speed)))
          ((retained 'key :c)
           (setf (vy vec) (- speed))))
    (let ((rot (v* (/ PI -180) (rotation freeroam-camera))))
      (nvrotv vec rot))
    (nv+ (location freeroam-camera) vec)))

(define-subject editor-camera (freeroam-camera)
  ())

(define-handler (editor-camera mouse-move) (ev old-pos pos)
  (when (or (retained 'mouse :middle)
            (retained 'key :control))
    (do-fps-movement editor-camera old-pos pos)))

(define-handler (editor-camera resume) (ev))
(define-handler (editor-camera pause) (ev))
