;;; This implementation is based on the original Xenocollide code by Gary Snethen available at 
;;;   https://github.com/erwincoumans/xenocollide
;;;

(in-package #:org.shirakumo.fraf.trial.mpr)

(defconstant COLLIDE-EPS 1f-3)

(defun search-point (a b +dir pa pb p)
  (declare (type vec3 +dir pa pb p))
  (declare (type trial:primitive a b))
  (declare (optimize speed (safety 0)))
  (let ((-dir (v- +dir)))
    (declare (dynamic-extent -dir))
    (trial:global-support-function b +dir pb)
    (trial:global-support-function a -dir pa)
    (!v- p pb pa)))

(defmacro with-vecs (vecs &body body)
  `(let ,(loop for vec in vecs collect `(,vec (vec3)))
     (declare (dynamic-extent ,@vecs))
     (declare (type vec3 ,@vecs))
     ,@body))

(defun %mpr (a b n ap bp)
  (declare (type trial:primitive a b))
  (declare (type vec3 n ap bp))
  (declare (optimize speed (safety 1)))
  (with-vecs (v01 v02 v0 v11 v12 v1 v21 v22 v2 v31 v32 v3 v41 v42 v4)
    (macrolet ((t<- (to from)
                 `(progn (rotatef ,(trial::mksym *package* 'v to) ,(trial::mksym *package* 'v from))
                         (rotatef ,(trial::mksym *package* 'v to 1) ,(trial::mksym *package* 'v from 1))
                         (rotatef ,(trial::mksym *package* 'v to 2) ,(trial::mksym *package* 'v from 2))))
               (finish (value)
                 `(return-from %mpr ,value)))
      (trial:global-location a v01)
      (trial:global-location b v02)
      (!v- v0 v02 v01)
      (when (v= 0 v0)
        (vsetf v0 0.00001 0 0))
      (!v- n v0)
      (search-point a b n v11 v12 v1)
      (when (<= (v. v1 n) 0)
        (finish NIL))
      
      (!vc n v1 v0)
      (when (v= 0 n)
        (!v- n v1 v0)
        (nvunit n)
        (v<- ap v11)
        (v<- bp v12)
        (finish T))
      (search-point a b n v21 v22 v2)
      (when (<= (v. v2 n) 0)
        (finish NIL))
      
      (!vc n (v- v1 v0) (v- v2 v0))
      (let ((dist (v. n v0))
            (hit NIL))
        (when (< 0 dist)
          (t<- 1 2)
          (nv- n))
        
        (loop
         (setf hit NIL)
         (search-point a b n v31 v32 v3)
         (when (<= (v. v3 n) 0)
           (finish NIL))
         (cond ((< (v. (vc v1 v3) v0) 0)
                (t<- 2 3)
                (!vc n (v- v1 v0) (v- v3 v0)))
               ((< (v. (vc v3 v2) v0) 0)
                (t<- 1 3)
                (!vc n (v- v3 v0) (v- v2 v0)))
               (T
                (loop 
                 (nvunit* (!vc n (v- v2 v1) (v- v3 v1)))
                 (let ((d (v. n v1)))
                   (when (and (not hit) (<= 0 d))
                     (let* ((b0 (v. (vc v1 v2) v3))
                            (b1 (v. (vc v3 v2) v0))
                            (b2 (v. (vc v0 v1) v3))
                            (b3 (v. (vc v2 v1) v0))
                            (sum (+ b0 b1 b2 b3)))
                       (when (<= sum 0)
                         (setf b0 0
                               b1 (v. (vc v2 v3) n)
                               b2 (v. (vc v3 v1) n)
                               b3 (v. (vc v1 v2) n)
                               sum (+ b1 b2 b3)))
                       (setf sum (/ sum))
                       (nv* (nv+* (nv+* (nv+* (!v* ap v01 b0) v11 b1) v21 b2) v31 b3) sum)
                       (nv* (nv+* (nv+* (nv+* (!v* bp v02 b0) v12 b1) v22 b2) v32 b3) sum)
                       (setf hit T))))
                 (search-point a b n v41 v42 v4)
                 (when (or (<= (v. (v- v4 v3) n) COLLIDE-EPS)
                           (<= 0 (- (v. v4 n))))
                   (finish hit))
                 (if (< (v. (vc v4 v1) v0) 0)
                     (if (< (v. (vc v4 v2) v0) 0)
                         (t<- 1 4)
                         (t<- 3 4))
                     (if (< (v. (vc v4 v3) v0) 0)
                         (t<- 2 4)
                         (t<- 1 4)))))))))))

(defun detect-hits (a b hits start end)
  (declare (type trial:primitive a b))
  (declare (type (unsigned-byte 32) start end))
  (declare (type simple-vector hits))
  (declare (optimize speed))
  (when (<= end start)
    (return-from detect-hits start))
  (let* ((hit (aref hits start))
         (n (trial:hit-normal hit)) (ap (vec3)) (bp (vec3)))
    (declare (dynamic-extent ap bp))
    (cond ((%mpr a b n ap bp)
           (with-vecs (s1 s2 s)
             (search-point a b n s1 s2 s)
             (nv+ (!v* s1 n (v. (nv- s1 ap) n)) ap)
             (nv+ (!v* s2 n (v. (nv- s2 bp) n)) bp)
             (setf (trial:hit-depth hit) (vdistance s1 s2))
             (v<- (trial:hit-location hit) (v* (v+ s1 s2) 0.5)))
           (trial:finish-hit hit a b)
           (1+ start))
          (T
           start))))
