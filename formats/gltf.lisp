(defpackage #:org.shirakumo.fraf.trial.gltf
  (:use #:cl+trial)
  (:shadow #:asset #:load-image)
  (:local-nicknames
   (#:gltf #:org.shirakumo.fraf.gltf)
   (#:v #:org.shirakumo.verbose))
  (:export))
(in-package #:org.shirakumo.fraf.trial.gltf)

(defun gltf-node-transform (node)
  (let ((matrix (gltf:matrix node))
        (translation (gltf:translation node))
        (scale (gltf:scale node))
        (rotation (gltf:rotation node)))
    (let ((transform (if matrix
                         (tfrom-mat (mat4 matrix))
                         (transform))))
      (when translation
        (vsetf (tlocation transform)
               (aref translation 0)
               (aref translation 1)
               (aref translation 2)))
      (when scale
        (vsetf (tscaling transform)
               (aref scale 0)
               (aref scale 1)
               (aref scale 2)))
      (when rotation
        (qsetf (trotation transform)
               (aref rotation 0)
               (aref rotation 1)
               (aref rotation 2)
               (aref rotation 3)))
      transform)))

(defmethod gltf:construct-element-reader ((element-type (eql :scalar)) (component-type (eql :float)))
  (lambda (ptr)
    (values (cffi:mem-ref ptr :float)
            (cffi:incf-pointer ptr 4))))

(defmethod gltf:construct-element-reader ((element-type (eql :vec2)) (component-type (eql :float)))
  (lambda (ptr)
    (values (vec (cffi:mem-ref ptr :float)
                 (cffi:mem-ref (cffi:incf-pointer ptr 4) :float))
            (cffi:incf-pointer ptr 4))))

(defmethod gltf:construct-element-reader ((element-type (eql :vec3)) (component-type (eql :float)))
  (lambda (ptr)
    (values (vec (cffi:mem-ref ptr :float)
                 (cffi:mem-ref (cffi:incf-pointer ptr 4) :float)
                 (cffi:mem-ref (cffi:incf-pointer ptr 4) :float))
            (cffi:incf-pointer ptr 4))))

(defmethod gltf:construct-element-reader ((element-type (eql :vec4)) (component-type (eql :float)))
  (lambda (ptr)
    (values (quat (cffi:mem-ref ptr :float)
                  (cffi:mem-ref (cffi:incf-pointer ptr 4) :float)
                  (cffi:mem-ref (cffi:incf-pointer ptr 4) :float)
                  (cffi:mem-ref (cffi:incf-pointer ptr 4) :float))
            (cffi:incf-pointer ptr 4))))

(defmethod gltf:construct-element-reader ((element-type (eql :mat4)) (component-type (eql :float)))
  (lambda (ptr)
    (let ((elements (make-array 16 :element-type 'single-float)))
      (dotimes (i (length elements))
        (setf (aref elements i) (cffi:mem-aref ptr :float i)))
      (values (nmtranspose (mat4 elements))
              (cffi:inc-pointer ptr (* 4 16))))))

(defun load-joint-names (gltf)
  (map 'vector #'gltf:name (gltf:nodes gltf)))

(defun load-rest-pose (gltf)
  (let* ((nodes (gltf:nodes gltf))
         (pose (make-instance 'pose :size (length nodes))))
    (loop for i from 0 below (length nodes)
          for node = (aref nodes i)
          do (setf (elt pose i) (gltf-node-transform node))
             (setf (parent-joint pose i) (if (gltf:parent node)
                                             (gltf:idx (gltf:parent node))
                                             -1)))
    (check-consistent pose)
    pose))

(defun load-animation-track (track sampler)
  (setf (interpolation track) (ecase (gltf:interpolation sampler)
                                (:step :constant)
                                (:linear :linear)
                                (:cubicspline :hermite)))
  (setf (frames track) (cons (gltf:input sampler) (gltf:output sampler))))

(defun load-clip (animation)
  (let ((clip (make-instance 'clip :name (gltf:name animation))))
    (loop for channel across (gltf:channels animation)
          for sampler = (svref (gltf:samplers animation) (gltf:sampler channel))
          for track = (find-animation-track clip (gltf:idx (gltf:node (gltf:target channel))) :if-does-not-exist :create)
          do (case (gltf:path (gltf:target channel))
               (:translation (load-animation-track (location track) sampler))
               (:scale (load-animation-track (scaling track) sampler))
               (:rotation (load-animation-track (rotation track) sampler))
               (T (v:warn :trial.gltf "Unknown animation channel target path: ~s on ~s, ignoring."
                        (gltf:path (gltf:target channel)) (gltf:name animation)))))
    (trial::recompute-duration clip)))

(defun load-clips (gltf &optional (table (make-hash-table :test 'equal)))
  (loop for animation across (gltf:animations gltf)
        for clip = (load-clip animation)
        do (setf (gethash (name clip) table) clip))
  table)

(defun load-bind-pose (gltf)
  (let* ((rest-pose (load-rest-pose gltf))
         (world-bind-pose (make-array (length rest-pose))))
    (dotimes (i (length world-bind-pose))
      (setf (svref world-bind-pose i) (global-transform rest-pose i)))
    (loop for skin across (gltf:skins gltf)
          for joints = (gltf:joints skin)
          for acc = (gltf:inverse-bind-matrices skin)
          do (loop for i from 0 below (length joints)
                   for inv-bind-matrix = (elt acc i)
                   do (setf (aref world-bind-pose (gltf:idx (svref joints i)))
                            (tfrom-mat (minv inv-bind-matrix)))))
    (let ((bind-pose rest-pose))
      (loop for i from 0 below (length world-bind-pose)
            for current = (svref world-bind-pose i)
            for p = (parent-joint bind-pose i)
            do (setf (elt bind-pose i)
                     (if (<= 0 p)
                         (t+ (tinv (svref world-bind-pose p)) current)
                         current)))
      (check-consistent bind-pose)
      bind-pose)))

(defun load-skeleton (gltf)
  (make-instance 'skeleton :rest-pose (load-rest-pose gltf)
                           :bind-pose (load-bind-pose gltf)
                           :joint-names (load-joint-names gltf)))

(defun gltf-attribute-to-native-attribute (attribute)
  (case attribute
    (:position 'location)
    (:normal 'normal)
    (:tangent 'tangent)
    (:texcoord_0 'uv)
    ;;(:texcoord_1 'uv-1)
    ;;(:texcoord_2 'uv-2)
    ;;(:texcoord_3 'uv-3)
    (:joints_0 'joints)
    (:joints_1 'joints-1)
    (:joints_2 'joints-2)
    (:joints_3 'joints-3)
    (:weights_0 'weights)
    (:weights_1 'weights-1)
    (:weights_2 'weights-2)
    (:weights_3 'weights-3)))

(defun load-vertex-attribute (mesh attribute accessor skin)
  (let ((data (vertex-data mesh))
        (stride (vertex-attribute-stride mesh))
        (offset (vertex-attribute-offset attribute mesh)))
    (when (< (length data) (length accessor))
      (setf data (adjust-array data (* (length accessor) stride) :element-type 'single-float))
      (setf (vertex-data mesh) data))
    (case (vertex-attribute-category attribute)
      (joints
       (flet ((map-joint (joint)
                (float (max 0 (gltf:idx (svref (gltf:joints skin) joint))) 0f0)))
         (loop for i from 0 below (length accessor)
               for el = (elt accessor i)
               do (setf (aref data (+ (* i stride) offset 0)) (map-joint (aref el 0)))
                  (setf (aref data (+ (* i stride) offset 1)) (map-joint (aref el 1)))
                  (setf (aref data (+ (* i stride) offset 2)) (map-joint (aref el 2)))
                  (setf (aref data (+ (* i stride) offset 3)) (map-joint (aref el 3))))))
      (uv
       (loop for i from 0 below (length accessor)
             for el = (elt accessor i)
             do (setf (aref data (+ (* i stride) offset 0)) (vx2 el))
                (setf (aref data (+ (* i stride) offset 1)) (- 1.0 (vy2 el)))))
      (T
       (ecase (vertex-attribute-size attribute)
         (1
          (loop for i from 0 below (length accessor)
                for el = (elt accessor i)
                do (setf (aref data (+ (* i stride) offset)) (float el 0f0))))
         (2
          (loop for i from 0 below (length accessor)
                for el = (elt accessor i)
                do (setf (aref data (+ (* i stride) offset 0)) (vx2 el))
                   (setf (aref data (+ (* i stride) offset 1)) (vy2 el))))
         (3
          (loop for i from 0 below (length accessor)
                for el = (elt accessor i)
                do (setf (aref data (+ (* i stride) offset 0)) (vx3 el))
                   (setf (aref data (+ (* i stride) offset 1)) (vy3 el))
                   (setf (aref data (+ (* i stride) offset 2)) (vz3 el))))
         (4
          (loop for i from 0 below (length accessor)
                for el = (elt accessor i)
                do (setf (aref data (+ (* i stride) offset 0)) (qx el))
                   (setf (aref data (+ (* i stride) offset 1)) (qy el))
                   (setf (aref data (+ (* i stride) offset 2)) (qz el))
                   (setf (aref data (+ (* i stride) offset 3)) (qw el)))))))))

(defmethod org.shirakumo.memory-regions:call-with-memory-region ((function function) (accessor gltf:accessor) &key (start 0))
  (let ((region (org.shirakumo.memory-regions:memory-region
                 (cffi:inc-pointer (gltf:start accessor) start)
                 (* (gltf:size accessor) (gltf:byte-stride accessor)))))
    (declare (dynamic-extent region))
    (funcall function region)))

(defun load-primitive (primitive &key name skin model)
  (let* ((attributes (sort (loop for attribute being the hash-keys of (gltf:attributes primitive)
                                 for native = (gltf-attribute-to-native-attribute attribute)
                                 when native collect native)
                           #'vertex-attribute<))
         (mesh (make-instance (if skin 'skinned-mesh 'static-mesh)
                              :name name :vertex-form (gltf:mode primitive)
                              :vertex-attributes attributes)))
    (when (and model (gltf:material primitive))
      (setf (material mesh)
            (find-material (or (gltf:name (gltf:material primitive))
                               (gltf:idx (gltf:material primitive)))
                           model)))
    (loop for attribute being the hash-keys of (gltf:attributes primitive) using (hash-value accessor)
          for native = (gltf-attribute-to-native-attribute attribute)
          do (when (member native attributes)
               (load-vertex-attribute mesh native accessor skin)))
    (when (gltf:indices primitive)
      (let* ((accessor (gltf:indices primitive))
             (indexes (make-array (length accessor) :element-type (ecase (gltf:component-type accessor)
                                                                    (:uint8  '(unsigned-byte 8))
                                                                    (:uint16 '(unsigned-byte 16))
                                                                    (:uint32 '(unsigned-byte 32))))))
        (org.shirakumo.memory-regions:replace indexes accessor)
        (setf (faces mesh) (coerce indexes '(simple-array (unsigned-byte 32) 1)))))
    mesh))

(defun load-mesh (mesh model &key skin)
  (let ((base-name (or (gltf:name mesh) (gltf:idx mesh)))
        (primitives (gltf:primitives mesh)))
    (case (length primitives)
      (0)
      (1 (list (load-primitive (aref primitives 0) :skin skin :name base-name :model model)))
      (T (loop for i from 0 below (length primitives)
               for primitive = (aref primitives i)
               collect (load-primitive primitive :skin skin :name (cons base-name i) :model model))))))

(defun load-meshes (gltf model)
  (let ((meshes (make-array 0 :adjustable T :fill-pointer T)))
    (loop for node across (gltf:nodes gltf)
          for skin = (gltf:skin node)
          do (when (gltf:mesh node)
               (loop for mesh in (load-mesh (gltf:mesh node) model :skin skin)
                     do (vector-push-extend mesh meshes))))
    meshes))

(defun load-image (asset texinfo)
  (when texinfo
    (let* ((texture (gltf:texture texinfo))
           (sampler (gltf:sampler texture))
           (image (gltf:source texture))
           (name (or (gltf:name image)
                     (gltf:uri image)
                     (gltf:name (gltf:buffer-view image))
                     (format NIL "image-~d" (gltf:idx image)))))
      (generate-resources 'image-loader (if (gltf:uri image)
                                            (gltf:path image)
                                            (memory-region (gltf:start (gltf:buffer-view image))
                                                           (gltf:byte-length (gltf:buffer-view image))))
                          :type (or (gltf:mime-type image) T)
                          :resource (resource asset name)
                          :mag-filter (if sampler (gltf:mag-filter sampler) :linear)
                          :min-filter (if sampler (gltf:min-filter sampler) :linear)
                          :wrapping (list (if sampler (gltf:wrap-s sampler) :clamp-to-edge)
                                          (if sampler (gltf:wrap-t sampler) :clamp-to-edge)
                                          (if sampler (gltf:wrap-t sampler) :clamp-to-edge))))))

(defun load-materials (gltf model asset)
  (flet ((to-vec (array)
           (ecase (length array)
             (2 (vec (aref array 0) (aref array 1)))
             (3 (vec (aref array 0) (aref array 1) (aref array 2)))
             (4 (vec (aref array 0) (aref array 1) (aref array 2) (aref array 3))))))
    (loop for material across (gltf:materials gltf)
          for pbr = (gltf:pbr material)
          for name = (or (gltf:name material) (gltf:idx material))
          for mr = (load-image asset (gltf:metallic-roughness pbr))
          for omr = (load-image asset (gltf:occlusion-metalness-roughness-texture material))
          for rmo = (load-image asset (gltf:roughness-metallic-occlusion-texture material))
          do (when mr (setf (trial::swizzle mr) '(:b :g :r :a)))
             (when omr (setf (trial::swizzle omr) '(:g :b :r :a)))
             (when rmo (setf (trial::swizzle rmo) '(:g :r :b :a)))
             (let ((material (trial:ensure-instance
                              (trial:find-material name model NIL) 'trial:pbr-material
                              :albedo-texture (load-image asset (gltf:albedo pbr))
                              :metal-rough-texture mr
                              :metal-rough-occlusion-texture (or omr rmo)
                              :occlusion-texture (load-image asset (gltf:occlusion-texture material))
                              :emissive-texture (load-image asset (gltf:emissive-texture material))
                              :normal-texture (load-image asset (gltf:normal-texture material))
                              :albedo-factor (to-vec (gltf:albedo-factor pbr))
                              :metallic-factor (float (gltf:metallic-factor pbr) 0f0)
                              :roughness-factor (float (gltf:roughness-factor pbr) 0f0)
                              :emissive-factor (to-vec (gltf:emissive-factor material))
                              :occlusion-factor (if (gltf:occlusion-texture material) 1.0 0.0)
                              :alpha-cutoff (float (gltf:alpha-cutoff material) 0f0))))
               (setf (trial:find-material name model) material)))))

(defun load-light (light)
  (flet ((make (type &rest initargs)
           (apply #'make-instance type
                  ;; FIXME: intensity is not correctly handled here.
                  :color (v* (vec (aref (gltf:color light) 0)
                                  (aref (gltf:color light) 1)
                                  (aref (gltf:color light) 2))
                             (/ (gltf:intensity light) 10000))
                  initargs)))
    (etypecase light
      (gltf:directional-light
       (make 'trial:directional-light :direction (vec 0 0 -1)))
      (gltf:point-light
       (make 'trial:point-light :linear-attenuation (or (gltf:range light) 0.0)))
      (gltf:spot-light
       (make 'trial:spot-light :direction (vec 0 0 -1)
                               :linear-attenuation (or (gltf:range light) 0.0)
                               :inner-radius (rad->deg (gltf:inner-angle light))
                               :outer-radius (rad->deg (gltf:outer-angle light)))))))

(defun load-camera (camera)
  (etypecase camera
    (gltf:orthographic-camera
     (make-instance 'trial:2d-camera :near-plane (gltf:znear camera)
                                     :far-plane (gltf:zfar camera)))
    (gltf:perspective-camera
     (make-instance 'trial:3d-camera :fov (gltf:fov camera)
                                     :near-plane (gltf:znear camera)
                                     :far-plane (gltf:zfar camera)))))

(defun load-shape (shape model &rest args)
  (flet ((ensure-mesh (mesh)
           (or (find-mesh (or (gltf:name mesh) (gltf:idx mesh)) model NIL)
               (first (load-mesh mesh model)))))
    (etypecase shape
      (gltf:box-shape
       (apply #'trial:make-box :bsize (vec (* 0.5 (aref (gltf:size shape) 0))
                                           (* 0.5 (aref (gltf:size shape) 1))
                                           (* 0.5 (aref (gltf:size shape) 2)))
              args))
      (gltf:capsule-shape
       (apply #'trial:make-pill :height (float (* 0.5 (gltf:height shape)) 0f0)
                                :radius (max (float (gltf:radius-top shape) 0f0)
                                             (float (gltf:radius-bottom shape) 0f0))
                                args))
      (gltf:convex-shape
       (let ((mesh (ensure-mesh (gltf:mesh shape))))
         (apply #'trial:make-convex-mesh :vertices (trial:reordered-vertex-data mesh '(trial:location))
                                         :faces (trial::simplify (trial:faces mesh) '(unsigned-byte 16))
                                         args)))
      (gltf:cylinder-shape
       (apply #'trial:make-cylinder :height (float (* 0.5 (gltf:height shape)) 0f0)
                                    :radius (max (float (gltf:radius-top shape) 0f0)
                                                 (float (gltf:radius-bottom shape) 0f0))
                                    args))
      (gltf:sphere-shape
       (apply #'trial:make-sphere :radius (float (gltf:radius shape) 0f0)
              args))
      (gltf:trimesh-shape
       (let ((mesh (ensure-mesh (gltf:mesh shape))))
         (apply #'trial:make-general-mesh :vertices (trial:reordered-vertex-data mesh '(trial:location))
                                          :faces (trial::simplify (trial:faces mesh) '(unsigned-byte 16))
                                          args))))))

(defvar *physics-material-cache* (make-hash-table :test 'equal))
(defun physics-material-instance (material)
  (let ((name (list (gltf:static-friction material)
                    (gltf:dynamic-friction material)
                    (gltf:restitution material)
                    (gltf:friction-combine material)
                    (gltf:restitution-combine material))))
    (or (gethash name *physics-material-cache*)
        (setf (gethash name *physics-material-cache*)
              (trial:make-material-interaction-properties
               NIL NIL
               (gltf:static-friction material)
               (gltf:dynamic-friction material)
               (gltf:restitution material)
               (gltf:friction-combine material)
               (gltf:restitution-combine material))))))

(defun find-colliders (node model)
  ;; FIXME: implement triggers
  (let ((primitives (make-array 0 :adjustable T :fill-pointer T))
        (material :wood))
    (labels ((process (collider tf)
               (when (gltf:physics-material collider)
                 (setf material (physics-material-instance (gltf:physics-material collider))))
               ;; FIXME: implement collision filtering
               (let ((primitive (load-shape (gltf:shape collider) model
                                            :local-transform (tmat tf))))
                 (setf (trial:primitive-material primitive) material)
                 (vector-push-extend primitive primitives)))
             (recurse (node tf)
               (let ((tf (t+ tf (gltf-node-transform node))))
                 (when (gltf:collider node)
                   (process (gltf:collider node) tf))
                 (loop for child across (gltf:children node)
                       do (recurse child tf)))))
      (let ((tf (transform)))
        (when (gltf:collider node)
          (process (gltf:collider node) tf))
        (loop for child across (gltf:children node)
              do (recurse child tf)))
      (trial::simplify primitives))))

(defun load-environment-light (light)
  (make-instance 'trial:environment-light
                 :color (vec (gltf:intensity light) (gltf:intensity light) (gltf:intensity light))
                 :irradiance-map (trial:implement!)
                 :environment-map (trial:implement!)))

(defmethod load-model (input (type (eql :glb)) &rest args)
  (apply #'load-model input :gltf args))

(defmethod load-model (input (type (eql :gltf)) &key (generator (make-instance 'resource-generator))
                                                     (model (make-instance 'model)))
  (gltf:with-gltf (gltf input)
    (let ((meshes (meshes model))
          (clips (clips model))
          (scenes (scenes model)))
      (load-materials gltf model generator)
      (loop for mesh across (load-meshes gltf model)
            do (setf (gethash (name mesh) meshes) mesh)
               (trial::make-vertex-array mesh (resource generator (name mesh))))
      ;; Patch up
      (when (loop for mesh being the hash-values of meshes
                  thereis (skinned-p mesh))
        (setf (skeleton model) (load-skeleton gltf))
        (load-clips gltf clips)
        (let ((map (make-hash-table :test 'eql)))
          (trial::reorder (skeleton model) map)
          (loop for clip being the hash-values of clips
                do (trial::reorder clip map))
          (loop for mesh being the hash-values of meshes
                do (when (typep mesh 'trial:skinned-mesh)
                     (trial::reorder mesh map)))))
      ;; Construct scene graphs
      (labels ((mesh-name (node)
                 (or (gltf:name (gltf:mesh node)) (gltf:idx (gltf:mesh node))))
               (construct (node)
                 (cond ((loop for skin across (gltf:skins gltf)
                              thereis (loop for joint across (gltf:joints skin)
                                            thereis (eq joint node)))
                        ;; Eliminate nodes that are parts of a skin
                        NIL)
                       ((gltf:mesh node)
                        (let ((mesh-name (mesh-name node)))
                          (make-instance (etypecase (or (gethash mesh-name meshes)
                                                        (gethash (cons mesh-name 0) meshes))
                                           (static-mesh 'basic-entity)
                                           (skinned-mesh 'basic-animated-entity))
                                         :lods (loop for i from -1
                                                     for threshold across (gltf:lod-screen-coverage node)
                                                     for lod = mesh-name then (mesh-name (aref (gltf:lods node) i))
                                                     collect (make-instance 'lod :threshold threshold :mesh lod))
                                         :transform (gltf-node-transform node)
                                         :name (gltf:name node)
                                         :asset generator
                                         :mesh mesh-name)))
                       (T
                        (make-instance 'basic-node :transform (gltf-node-transform node)
                                                   :name (gltf:name node)))))
               (recurse (children container)
                 (loop for node across children
                       for child = (construct node)
                       when child
                       do (recurse (gltf:children node) child)
                          (when (gltf:light node)
                            (enter (load-light (gltf:light node)) child))
                          (when (gltf:camera node)
                            (enter (load-camera (gltf:camera node)) child))
                          ;; FIXME: implement joints
                          (when (gltf:rigidbody node)
                            (etypecase child
                              (basic-entity (change-class child 'trial:basic-physics-entity))
                              (basic-animated-entity (change-class child 'trial:animated-physics-entity)))
                            (setf (trial:mass child) (if (gltf:kinematic-p (gltf:rigidbody node)) 0.0 (gltf:mass (gltf:rigidbody node))))
                            ;; FIXME: implement center-of-mass
                            ;; FIXME: implement gravity-factor ???
                            (let* ((r (gltf:inertia-orientation (gltf:rigidbody node)))
                                   (r (qmat (quat (aref r 0) (aref r 1) (aref r 2) (aref r 3))))
                                   (i (mat3)))
                              (loop for e across (gltf:inertia-diagonal (gltf:rigidbody node))
                                    for r from 0
                                    do (setf (mcref i r r) e))
                              ;; I = R * D * R^-1
                              (!m* i i (mtranspose r))
                              (!m* i r i)
                              (setf (trial:inertia-tensor child) i))
                            (map-into (varr (trial:velocity child)) (lambda (x) (float x 0f0)) (gltf:linear-velocity (gltf:rigidbody node)))
                            (map-into (varr (trial:rotation child)) (lambda (x) (float x 0f0)) (gltf:angular-velocity (gltf:rigidbody node)))
                            ;; FIXME: this will eagerly decompose colliders and so on even if the node is never used...
                            (setf (trial:physics-primitives child) (find-colliders node model)))
                          (enter child container))))
        (loop for node across (gltf:scenes gltf)
              for scene = (make-instance 'basic-node :name (gltf:name node))
              do (setf (gethash (gltf:name node) scenes) scene)
                 (when (gltf:light node)
                   (enter (load-environment-light (gltf:light node)) scene))
                 (recurse (gltf:nodes node) scene)))
      model)))

(defun add-convex-shape (gltf vertices faces)
  (let* ((primitive (gltf:make-mesh-primitive gltf vertices faces '(:position)))
         (mesh (gltf:make-indexed 'gltf:mesh gltf :primitives (vector primitive))))
    (gltf:make-indexed 'gltf:convex-shape gltf :mesh mesh :kind "convex")))

(defun push-convex-shape (base-node shape)
  (let* ((collider (make-instance 'gltf:collider :collision-filter (gltf:collision-filter (gltf:collider base-node))
                                                 :physics-material (gltf:physics-material (gltf:collider base-node))
                                                 :shape shape
                                                 :gltf (gltf:gltf base-node)))
         (child (gltf:make-indexed 'gltf:node base-node :collider collider)))
    (gltf:push-child child base-node)))

(defmethod optimize-model (file (type (eql :glb)) &rest args)
  (apply #'optimize-model file :gltf args))

(defmethod optimize-model (file (type (eql :gltf)) &rest args &key (output file) &allow-other-keys)
  (let ((decomposition-args (remf* args :output))
        (shape-table (make-hash-table :test 'eql))
        (work-done-p NIL))
    (trial:with-tempfile (tmp :type (pathname-type file))
      (gltf:with-gltf (gltf file)
        ;; Rewrite trimesh shapes to multiple new shapes.
        ;; TODO: if original trimesh mesh has no other refs anywhere, remove it
        (loop for shape across (gltf:shapes gltf)
              do (when (and (typep shape 'gltf:trimesh-shape)
                            ;; Only bother decomposing it if it's actually referenced anywhere.
                            (loop for node across (gltf:nodes gltf)
                                  thereis (and (gltf:collider node) (eql shape (gltf:shape (gltf:collider node))))))
                   (let* ((primitives (gltf:primitives (gltf:mesh shape)))
                          (mesh (load-primitive (aref primitives 0)))
                          (verts (reordered-vertex-data mesh '(location)))
                          (hulls (handler-bind ((warning #'muffle-warning))
                                   (apply #'org.shirakumo.fraf.convex-covering:decompose
                                          verts (faces mesh) decomposition-args))))
                     (setf (gethash shape shape-table)
                           (loop for hull across hulls
                                 collect (add-convex-shape
                                          gltf
                                          (org.shirakumo.fraf.convex-covering:vertices hull)
                                          (trial::simplify (org.shirakumo.fraf.convex-covering:faces hull) '(unsigned-byte 16))))))))
        ;; Rewrite nodes with refs to trimesh colliders to have child nodes for
        ;; all decomposed hulls.
        (loop for node across (gltf:nodes gltf)
              do (when (and (gltf:collider node)
                            (typep (gltf:shape (gltf:collider node)) 'gltf:trimesh-shape))
                   (loop for shape in (gethash (gltf:shape (gltf:collider node)) shape-table)
                         do (push-convex-shape node shape))
                   (setf (gltf:collider node) NIL)
                   ;; Clear the extension, too. Ideally this would be done by the library already.
                   (remhash "collider" (gethash "KHR_rigid_bodies" (gltf:extensions node)))
                   (setf work-done-p T)))
        (when work-done-p
          (gltf:serialize gltf tmp)))
      (when work-done-p
        ;; FIXME: this does not work correctly if gltf serialises to multiple files.
        (org.shirakumo.filesystem-utils:rename-file* tmp output)))))
