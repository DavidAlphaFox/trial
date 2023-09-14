(in-package #:cl-user)
(defpackage #:trial
  (:nicknames #:org.shirakumo.fraf.trial)
  (:use #:cl
        #:org.shirakumo.fraf.math
        #:org.shirakumo.lru-cache)
  (:shadow #:// #:load)
  (:import-from #:static-vectors #:static-vector-pointer)
  (:import-from #:flow #:port)
  (:import-from #:org.shirakumo.memory-regions
                #:memory-region #:memory-region-pointer #:memory-region-size)
  (:local-nicknames
   (#:gamepad #:org.shirakumo.fraf.gamepad)
   (#:sequences #:org.shirakumo.trivial-extensible-sequences)
   (#:v #:org.shirakumo.verbose)
   (#:promise #:org.shirakumo.promise)
   (#:3ds #:org.shirakumo.fraf.trial.space)
   (#:mem #:org.shirakumo.memory-regions)
   #+windows (#:com #:org.shirakumo.com-on))
  ;; animation/asset.lisp
  (:export
   #:animation-asset
   #:meshes
   #:clips
   #:skeleton
   #:find-clip
   #:list-clips)
  ;; animation/clip.lisp
  (:export
   #:clip
   #:tracks
   #:start-time
   #:end-time
   #:loop-p
   #:duration
   #:find-animation-track
   #:clip
   #:define-clip)
  ;; animation/entity.lisp
  (:export
   #:animation-layer
   #:strength
   #:layer-controller
   #:layers
   #:add-layer
   #:remove-layer
   #:layer
   #:fade-controller
   #:play
   #:fade-to
   #:base-animated-entity
   #:armature
   #:animated-entity
   #:mesh)
  ;; animation/ik.lisp
  (:export
   #:ik-constraint
   #:apply-constraint
   #:ik-solver
   #:pose
   #:joints
   #:constraints
   #:iterations
   #:threshold
   #:ik-from-skeleton
   #:solve-for
   #:ccd-solver
   #:fabrik-solver
   #:ball-socket-constraint
   #:axis
   #:limit
   #:hinge-constraint
   #:axis
   #:min-angle
   #:max-angle
   #:ik-system
   #:solver
   #:strength
   #:active-p
   #:target
   #:clip-ik-system
   #:clip
   #:entity-target-ik-system
   #:entity
   #:offset
   #:ik-controller
   #:ik-systems
   #:add-ik-system
   #:remove-ik-system
   #:ik-system)
  ;; animation/mesh.lisp
  (:export
   #:mesh-data
   #:vertex-data
   #:index-data
   #:skinned-p
   #:static-mesh
   #:skinned-mesh
   #:position-normals
   #:cpu-skin)
  ;; animation/pose.lisp
  (:export
   #:pose
   #:joints
   #:parents
   #:pose<-
   #:pose=
   #:parent-joint
   #:global-transform
   #:matrix-palette
   #:blend-into
   #:layer-onto)
  ;; animation/skeleton.lisp
  (:export
   #:skeleton
   #:instantiate-clip
   #:rest-pose
   #:bind-pose
   #:inv-bind-pose
   #:reorder
   #:rest-pose*)
  ;; animation/track.lisp
  (:export
   #:animation-frame
   #:animation-track
   #:frames
   #:interpolation
   #:start-time
   #:end-time
   #:duration
   #:sample
   #:find-frame-idx
   #:valid-p
   #:fast-animation-track
   #:transform-track
   #:location
   #:scaling
   #:rotation)
  ;; assets/environment-map.lisp
  (:export
   #:environment-map-renderer
   #:irradiance-map-renderer
   #:prefiltered-environment-map-renderer
   #:environment-map-generator
   #:environment-map)
  ;; assets/image.lisp
  (:export
   #:load-image
   #:save-image
   #:image-loader
   #:image
   #:resize)
  ;; assets/mesh.lisp
  (:export
   #:mesh-loader
   #:mesh
   #:geometry-name
   #:attributes
   #:data-usage)
  ;; assets/shader-image.lisp
  (:export
   #:image-renderer
   #:dynamic-image-renderer
   #:cubemap-renderer
   #:shader-image-generator
   #:shader-image)
  ;; assets/sprite-data.lisp
  (:export
   #:sprite-data
   #:vertex-array
   #:texture
   #:animations
   #:frames
   #:load-animations)
  ;; assets/static.lisp
  (:export
   #:static)
  ;; assets/tile-data.lisp
  (:export
   #:tileset
   #:tile-size
   #:tilemap
   #:tileset
   #:tile-data)
  ;; assets/uniform-block.lisp
  (:export
   #:uniform-block)
  ;; formats/collada.lisp
  (:export)
  ;; formats/vertex-format.lisp
  (:export)
  ;; physics/constants.lisp
  (:export
   #:material-interaction-properties
   #:material-interaction-properties-a
   #:material-interaction-properties-b
   #:material-interaction-properties-static-friction
   #:material-interaction-properties-dynamic-friction
   #:material-interaction-properties-restitution
   #:make-material-interaction-properties
   #:list-material-interaction-properties
   #:set-material-interaction-properties)
  ;; physics/core.lisp
  (:export
   #:integrate
   #:mass
   #:start-frame
   #:physics-entity
   #:velocity
   #:inverse-mass
   #:force
   #:damping
   #:awake-p
   #:current-motion
   #:force
   #:apply-force
   #:gravity
   #:drag-force
   #:k1
   #:k2
   #:spring-force
   #:anchor
   #:anchor-offset
   #:local-offset
   #:spring-constant
   #:rest-length
   #:stiff-spring-force
   #:anchor
   #:anchor-offset
   #:local-offset
   #:spring-constant
   #:damping
   #:bungee-force
   #:located-force
   #:location
   #:spherical-force
   #:radius
   #:aabb-force
   #:bsize
   #:hit
   #:make-hit
   #:hit-a
   #:hit-b
   #:hit-location
   #:hit-normal
   #:hit-restitution
   #:hit-static-friction
   #:hit-dynamic-friction
   #:hit-depth
   #:a
   #:b
   #:location
   #:normal
   #:restitution
   #:static-friction
   #:dynamic-friction
   #:depth
   #:physics-system
   #:forces
   #:hits
   #:sleep-eps
   #:units-per-metre
   #:generate-hits
   #:resolve-hits)
  ;; physics/inertia-tensors.lisp
  (:export
   #:define-tensor-fun
   #:mass-aggregate-tensor
   #:combine-tensor
   #:box-tensor
   #:sphere-tensor
   #:shell-tensor
   #:cylinder-tensor
   #:cone-tensor
   #:tube-tensor)
  ;; physics/particle.lisp
  (:export
   #:particle
   #:acceleration
   #:separating-velocity
   #:resolve-velocity
   #:resolve-intersection
   #:resolve-hit
   #:hit-generator
   #:generate-hits
   #:define-hit-generation
   #:particle-link
   #:a
   #:b
   #:particle-cable
   #:max-length
   #:restitution
   #:particle-rod
   #:distance
   #:mass-aggregate-system
   #:hit-generators)
  ;; physics/primitives.lisp
  (:export
   #:detect-hit
   #:intersects-p
   #:detect-hits
   #:define-hit-detector
   #:finish-hit
   #:primitive
   #:primitive-entity
   #:primitive-material
   #:primitive-local-transform
   #:primitive-transform
   #:define-primitive-type
   #:entity
   #:material
   #:sphere
   #:sphere-radius
   #:make-sphere
   #:radius
   #:plane
   #:plane-normal
   #:plane-offset
   #:make-plane
   #:normal
   #:offset
   #:half-space
   #:make-half-space
   #:box
   #:box-bsize
   #:make-box
   #:bsize
   #:cylinder
   #:cylinder-radius
   #:cylinder-height
   #:make-cylinder
   #:radius
   #:height
   #:pill
   #:make-pill
   #:pill-radius
   #:pill-height
   #:triangle
   #:triangle-a
   #:triangle-b
   #:triangle-c
   #:make-triangle
   #:general-mesh
   #:general-mesh-vertices
   #:general-mesh-faces
   #:make-general-mesh
   #:convex-mesh
   #:convex-mesh-vertices
   #:convex-mesh-faces
   #:make-convex-mesh)
  ;; physics/ray.lisp
  (:export
   #:ray
   #:ray-location
   #:ray-direction
   #:copy-ray
   #:define-ray-test)
  ;; physics/resolution.lisp
  (:export
   #:contact
   #:contact-to-world
   #:contact-velocity
   #:contact-desired-delta
   #:contact-a-relative
   #:contact-b-relative
   #:make-contact
   #:rigidbody-system
   #:velocity-eps
   #:depth-eps)
  ;; physics/rigidbody.lisp
  (:export
   #:rigidbody
   #:rotation
   #:inverse-inertia-tensor
   #:torque
   #:angular-damping
   #:physics-primitives
   #:transform-matrix
   #:world-inverse-inertia-tensor
   #:last-frame-acceleration
   #:inertia-tensor
   #:impact-local
   #:impact)
  ;; physics/toolkit.lisp
  (:export)
  ;; renderer/lights.lisp
  (:export
   #:standard-light
   #:light-type
   #:location
   #:direction
   #:color
   #:attenuation
   #:spot-radius
   #:shadow-map
   #:active-p
   #:light
   #:cast-shadows-p
   #:ambient-light
   #:located-light
   #:linear-attenuation
   #:quadratic-attenuation
   #:point-light
   #:directional-light
   #:direction
   #:spot-light
   #:inner-radius
   #:outer-radius)
  ;; renderer/materials.lisp
  (:export
   #:missing
   #:black
   #:white
   #:neutral-normal
   #:material
   #:textures
   #:texture-names
   #:list-materials
   #:update-material
   #:define-material)
  ;; renderer/particle.lisp
  (:export
   #:particle-force-field
   #:particle-force-fields
   #:particle-emitter
   #:local-threads
   #:texture
   #:to-emit
   #:particle-rate
   #:vertex-array
   #:max-particles
   #:particle-force-fields
   #:particle-options
   #:particle-size
   #:particle-scaling
   #:particle-rotation
   #:particle-randomness
   #:particle-velocity
   #:particle-lifespan
   #:particle-lifespan-randomness
   #:particle-mode
   #:particle-flip
   #:particle-color
   #:emit
   #:depth-colliding-particle-emitter
   #:surface-thickness
   #:sorted-particle-emitter
   #:multi-texture-particle-emitter
   #:particle-sprite)
  ;; renderer/pbr.lisp
  (:export
   #:pbr-material
   #:albedo-factor
   #:emission-factor
   #:metallic-factor
   #:roughness-factor
   #:occlusion-factor
   #:alpha-cutoff
   #:albedo-texture
   #:metal-rough-occlusion-texture
   #:emission-texture
   #:normal-texture
   #:pbr-render-pass
   #:environment-light
   #:irradiance-map
   #:environment-map)
  ;; renderer/phong.lisp
  (:export
   #:phong-material
   #:diffuse-factor
   #:specular-factor
   #:alpha-cutoff
   #:diffuse-texture
   #:specular-texture
   #:normal-texture
   #:phong-render-pass)
  ;; renderer/standard-renderer.lisp
  (:export
   #:standard-environment-environment
   #:view-size
   #:location
   #:tt
   #:dt
   #:fdt
   #:standard-render-pass
   #:color
   #:normal
   #:depth
   #:material-block-type
   #:enable
   #:disable
   #:local-id
   #:notice-update
   #:standard-renderable
   #:vertex-array
   #:single-material-renderable
   #:material
   #:light-cache-render-pass)
  ;; renderer/tone-mapping.lisp
  (:export
   #:tone-mapping-pass
   #:gamma
   #:hable
   #:shoulder-strength
   #:linear-strength
   #:linear-angle
   #:toe-strength
   #:toe-numerator
   #:toe-denominator
   #:linear-white-point
   #:exposure-bias
   #:hill-aces
   #:narkowicz-aces
   #:reinhard
   #:reinhard-extended
   #:c-white
   #:schlick
   #:p
   #:hi-val
   #:tumblin-rushmeier
   #:luminance-map
   #:ld-max
   #:c-max
   #:uchimura
   #:max-rightness
   #:contrast
   #:linear-start
   #:linear-length
   #:black-tightness-shape
   #:black-tightness-offset
   #:ward
   #:ld-max)
  ;; resources/buffer-object.lisp
  (:export
   #:buffer-object
   #:buffer-type
   #:buffer-data
   #:data-usage
   #:size
   #:update-buffer-data
   #:resize-buffer)
  ;; resources/framebuffer.lisp
  (:export
   #:framebuffer
   #:attachments
   #:clear-bits
   #:resize
   #:capture
   #:blit-to-screen
   #:activate)
  ;; resources/shader-program.lisp
  (:export
   #:shader-program
   #:uniform-map
   #:shaders
   #:uniform
   #:uniform-location
   #:uniforms
   #:activate)
  ;; resources/shader.lisp
  (:export
   #:shader
   #:shader-type
   #:shader-source)
  ;; resources/shader-storage-buffer.lisp
  (:export
   #:shader-storage-buffer)
  ;; resources/texture.lisp
  (:export
   #:texture
   #:width
   #:height
   #:depth
   #:target
   #:level
   #:samples
   #:internal-format
   #:pixel-format
   #:pixel-type
   #:pixel-data
   #:mag-filter
   #:min-filter
   #:anisotropy
   #:wrapping
   #:storage
   #:allocate-texture-storage
   #:resize)
  ;; resources/uniform-buffer.lisp
  (:export
   #:uniform-buffer
   #:qualifiers
   #:binding
   #:struct
   #:with-buffer-tx)
  ;; resources/vertex-array.lisp
  (:export
   #:vertex-array
   #:vertex-form
   #:size
   #:bindings
   #:index-buffer
   #:indexed-p
   #:compute-buffer-bindings)
  ;; resources/vertex-buffer.lisp
  (:export
   #:vertex-buffer
   #:buffer-type
   #:buffer-data
   #:element-type
   #:data-usage
   #:size
   #:update-buffer-data)
  ;; resources/vertex-struct-buffer.lisp
  (:export
   #:vertex-struct-buffer)
  ;; achievements.lisp
  (:export
   #:achievement
   #:list-achievements
   #:name
   #:title
   #:description
   #:icon
   #:event-type
   #:test-function
   #:active-p
   #:define-achievement
   #:award
   #:achievement-event
   #:achievement-unlocked
   #:achievement-relocked
   #:+achievement-api+
   #:*achievement-apis*
   #:achievement-api
   #:load-achievement-data
   #:save-achievement-data
   #:notifications-display-p
   #:local-achievement-api)
  ;; actions.lisp
  (:export
   #:action-set
   #:exclusive-action-set
   #:active-p
   #:find-action-set
   #:list-action-sets
   #:active-action-set
   #:define-action-set
   #:action
   #:source-event
   #:analog-action
   #:value
   #:directional-action
   #:direction
   #:define-action)
  ;; array-container.lisp
  (:export
   #:array-container
   #:objects)
  ;; asset-pool.lisp
  (:export
   #:find-pool
   #:remove-pool
   #:list-pools
   #:pool
   #:name
   #:base
   #:assets
   #:define-pool
   #:asset
   #:list-assets
   #:pool-path
   #:trial)
  ;; asset.lisp
  (:export
   #:placeholder-resource
   #:asset
   #:pool
   #:name
   #:input
   #:loaded-p
   #:load
   #:reload
   #:unload
   #:list-resources
   #://
   #:coerce-asset-input
   #:input*
   #:define-asset
   #:generate-assets-from-path
   #:define-assets-from-path
   #:single-resource-asset
   #:multi-resource-asset
   #:file-input-asset)
  ;; async.lisp
  (:export
   #:task-thread
   #:start
   #:stop
   #:task-runner-main
   #:promise-task
   #:with-eval-in-task-thread)
  ;; bag.lisp
  (:export
   #:bag)
  ;; camera.lisp
  (:export
   #:camera
   #:near-plane
   #:far-plane
   #:project-view
   #:setup-perspective
   #:map-visible
   #:in-view-p
   #:screen-area
   #:do-visible
   #:2d-camera
   #:sidescroll-camera
   #:zoom
   #:target
   #:3d-camera
   #:fov
   #:target-camera
   #:target
   #:up
   #:following-camera
   #:fps-camera
   #:rotation
   #:x-acceleration
   #:y-acceleration
   #:freeroam-camera
   #:move-speed
   #:editor-camera)
  ;; capture.lisp
  (:export
   #:start
   #:stop
   #:active-p
   #:capture
   #:start-capture
   #:stop-capture
   #:replay
   #:start-replay
   #:stop-replay)
  ;; conditions.lisp
  (:export
   #:trial-error
   #:thread-did-not-exit
   #:resource-not-allocated
   #:context-creation-error
   #:resource-depended-on
   #:shader-compilation-error
   #:initarg-not-supplied
   #:arg!
   #:not-implemented
   #:implement!)
  ;; container.lisp
  (:export
   #:scene-node
   #:container
   #:scene
   #:clear
   #:enter
   #:leave
   #:register
   #:deregister
   #:contains-p
   #:map-scene-graph
   #:do-scene-graph
   #:entity
   #:name)
  ;; context.lisp
  (:export
   #:*context*
   #:context-creation-error
   #:with-context
   #:launch-with-context
   #:make-context
   #:monitor
   #:name
   #:context
   #:current-thread
   #:context-waiting
   #:context-lock
   #:context-wait-lock
   #:resources
   #:handler
   #:shared-with
   #:glsl-target-version
   #:rgba-icon
   #:rgba-icon-width
   #:rgba-icon-height
   #:rgba-icon-data
   #:create-context
   #:destroy-context
   #:valid-p
   #:make-current
   #:current-p
   #:done-current
   #:hide
   #:show
   #:visible-p
   #:resize
   #:quit
   #:swap-buffers
   #:show-cursor
   #:hide-cursor
   #:lock-cursor
   #:unlock-cursor
   #:cursor
   #:title
   #:vsync
   #:width
   #:height
   #:profile
   #:version
   #:resize
   #:list-video-modes
   #:current-monitor
   #:list-monitors
   #:find-monitor
   #:clipboard
   #:cursor-position
   #:local-key-string
   #:gain-focus
   #:lose-focus
   #:window-hidden
   #:window-shown
   #:window-close
   #:context-info)
  ;; controller.lisp
  (:export
   #:system-action
   #:save-game
   #:load-game
   #:reload-scene
   #:quit-game
   #:toggle-overlay
   #:noto-sans
   #:noto-mono
   #:controller
   #:text
   #:show-overlay
   #:observe
   #:observe!
   #:stop-observing
   #:load-request
   #:maybe-reload-scene
   #:eval-request
   #:func
   #:call-in-render-loop
   #:with-eval-in-render-loop
   #:display-controller)
  ;; data-pointer.lisp
  (:export
   #:memory-region
   #:memory-region-pointer
   #:memory-region-size)
  ;; debug.lisp
  (:export
   #:debug-draw
   #:debug-point
   #:debug-line
   #:debug-clear)
  ;; deferred.lisp
  (:export
   #:geometry-pass
   #:depth
   #:position
   #:normal
   #:albedo
   #:metal
   #:geometry-shaded
   #:diffuse-map
   #:specular-map
   #:normal-map
   #:roughness-map
   #:occlusion-map
   #:deferred-render-pass
   #:position-map
   #:normal-map
   #:albedo-map
   #:metal-map
   #:light
   #:light-block)
  ;; deploy.lisp
  (:export)
  ;; display.lisp
  (:export
   #:display
   #:poll-input
   #:context
   #:clear-color
   #:setup-rendering
   #:render)
  ;; effects.lisp
  (:export
   #:render-pass
   #:color
   #:depth
   #:solid-render-pass
   #:fill-color
   #:simple-post-effect-pass
   #:previous-pass
   #:color
   #:active-p
   #:iterative-post-effect-pass
   #:iterations
   #:temporal-post-effect-pass
   #:previous
   #:copy-pass
   #:negative-pass
   #:box-blur-pass
   #:intensity
   #:sobel-pass
   #:gaussian-blur-pass
   #:direction
   #:radial-blur-pass
   #:exposure
   #:samples
   #:origin
   #:swirl-pass
   #:radius
   #:angle
   #:fxaa-pass
   #:blend-pass
   #:a-pass
   #:b-pass
   #:blend-type
   #:high-pass-filter
   #:threshold
   #:low-pass-filter
   #:chromatic-aberration-filter
   #:offset
   #:luminance-pass
   #:light-scatter-pass
   #:black-render-pass
   #:density
   #:weight
   #:decay
   #:samples
   #:visualizer-pass
   #:t[0]
   #:t[1]
   #:t[2]
   #:t[3]
   #:textures-per-line)
  ;; entity.lisp
  (:export
   #:entity
   #:container
   #:clear)
  ;; error-handling.lisp
  (:export
   #:*error-report-hook*
   #:*inhibit-standalone-error-handler*
   #:standard-error-hook
   #:emessage
   #:report-on-error
   #:standalone-error-handler)
  ;; event-loop.lisp
  (:export
   #:event
   #:listener
   #:add-listener
   #:remove-listener
   #:handle
   #:make-event
   #:event-loop
   #:issue
   #:process
   #:discard-events
   #:define-handler
   #:undefine-handler
   #:define-event
   #:define-event-pool
   #:tick
   #:tt
   #:dt
   #:fc
   #:pre-tick
   #:post-tick
   #:class-changed
   #:changed-class)
  ;; features.lisp
  (:export
   #:*debug-features*
   #:*optimize-features*
   #:reload-with-features)
  ;; fps.lisp
  (:export
   #:fps-counter)
  ;; fullscreenable.lisp
  (:export
   #:fullscreenable
   #:original-mode
   #:resolution
   #:fullscreen)
  ;; gamepad.lisp
  (:export)
  ;; geometry-clipmap.lisp
  (:export)
  ;; geometry-shapes.lisp
  (:export
   #:make-rectangle-mesh
   #:make-triangle-mesh
   #:make-cube-mesh
   #:make-quad-grid-mesh
   #:make-line-grid-mesh
   #:make-sphere-mesh
   #:make-disc-mesh
   #:make-cylinder-mesh
   #:make-cone-mesh
   #:make-tube-mesh
   #:make-lines
   #:fullscreen-square
   #:empty-vertex-array
   #:unit-cube
   #:unit-sphere
   #:unit-square
   #:unit-disc
   #:unit-point
   #:grid
   #:axes
   #:2d-axes)
  ;; geometry.lisp
  (:export
   #:geometry
   #:meshes
   #:read-geometry
   #:write-geometry
   #:sphere-mesh
   #:size
   #:vertex-mesh
   #:face-length
   #:vertex-type
   #:faces
   #:vertices
   #:add-vertex
   #:triangulate
   #:check-mesh-valid
   #:pack
   #:with-vertex-filling
   #:vertex
   #:location
   #:fill-vector-data
   #:vertex-attribute-size
   #:vertex-attribute-stride
   #:vertex-attribute-offset
   #:vertex-attribute-category
   #:vertex-attribute-order
   #:vertex-attribute<
   #:location
   #:uv
   #:normal
   #:color
   #:tangent
   #:joints
   #:weights
   #:uv-0
   #:uv-1
   #:uv-2
   #:uv-3
   #:joints-0
   #:joints-1
   #:joints-2
   #:joints-3
   #:weights-0
   #:weights-1
   #:weights-2
   #:weights-3
   #:fill-vertex-attribute
   #:vertex-attributes
   #:vertex=
   #:textured-vertex
   #:uv
   #:normal-vertex
   #:normal
   #:colored-vertex
   #:color
   #:basic-vertex
   #:replace-vertex-data
   #:make-vertex-data)
  ;; gl-features.lisp
  (:export
   #:enable-feature
   #:disable-feature
   #:push-features
   #:pop-features
   #:with-pushed-features)
  ;; gl-struct.lisp
  (:export
   #:gl-struct
   #:storage
   #:compute-depedent-types
   #:gl-source
   #:gl-struct-class
   #:gl-type
   #:layout-standard
   #:struct-fields
   #:define-gl-struct
   #:gl-vector
   #:element-type)
  ;; hash-table-container.lisp
  (:export
   #:hash-table-container)
  ;; helpers.lisp
  (:export
   #:located-entity
   #:location
   #:sized-entity
   #:bsize
   #:oriented-entity
   #:orientation
   #:up
   #:rotated-entity
   #:rotation
   #:axis-rotated-entity
   #:axis
   #:angle
   #:pivoted-entity
   #:pivot
   #:scaled-entity
   #:scaling
   #:transformed-entity
   #:orientation
   #:tf
   #:fullscreen-entity
   #:vertex-entity
   #:colored-entity
   #:vertex-colored-entity
   #:textured-entity
   #:texture
   #:mesh-entity
   #:mesh-asset
   #:mesh
   #:multi-mesh-entity
   #:lod-entity
   #:lods
   #:select-lod
   #:lod
   #:treshold
   #:coverage-lod-entity
   #:distance-lod-entity)
  ;; hdr.lisp
  (:export
   #:hdr-output-pass
   #:high-color-pass
   #:bloom-pass
   #:high-pass)
  ;; input.lisp
  (:export
   #:+input-source+
   #:input-event
   #:keyboard-event
   #:key-event
   #:key
   #:modifiers
   #:repeat-p
   #:key-press
   #:key-release
   #:text-entered
   #:replace-p
   #:mouse-event
   #:mouse-button-event
   #:mouse-press
   #:mouse-release
   #:mouse-double-click
   #:mouse-scroll
   #:delta
   #:mouse-move
   #:old-pos
   #:file-drop-event
   #:paths
   #:gamepad-event
   #:device
   #:gamepad-attach
   #:gamepad-remove
   #:gamepad-button-event
   #:button
   #:gamepad-press
   #:gamepad-release
   #:gamepad-move
   #:axis
   #:old-pos
   #:pos
   #:key
   #:mouse
   #:gamepad
   #:gamepad-added
   #:gamepad-removed)
  ;; interpolation.lisp
  (:export
   #:bezier
   #:hermite
   #:linear
   #:constant
   #:interpolate
   #:ninterpolate)
  ;; language.lisp
  (:export
   #:language
   #:languages
   #:language-dir
   #:language-files
   #:define-language-change-hook
   #:load-language
   #:save-language
   #:language-string
   #:ensure-language-string
   #:@format
   #:@formats
   #:@)
  ;; layered-container.lisp
  (:export
   #:layered-container
   #:layer-index
   #:layer-count)
  ;; lines.lisp
  (:export
   #:lines
   #:line-width)
  ;; list-container.lisp
  (:export
   #:list-container)
  ;; loader.lisp
  (:export
   #:staging-area
   #:staged
   #:dependencies
   #:stage
   #:unstage
   #:compute-load-sequence
   #:loader
   #:commit
   #:abort-commit
   #:load-with
   #:unload-with
   #:progress)
  ;; main.lisp
  (:export
   #:+main+
   #:main
   #:username
   #:scene
   #:controller
   #:setup-scene
   #:change-scene
   #:enter-and-load
   #:launch)
  ;; mapping.lisp
  (:export
   #:+map-key-events+
   #:trigger
   #:keymap
   #:mapping-function
   #:remove-mapping-function
   #:map-event
   #:retained
   #:clear-retained
   #:reset-retained
   #:directional
   #:clear-directional
   #:action-mapping
   #:action-type
   #:event-type
   #:qualifier
   #:mapping-active-p
   #:active-mappings
   #:event-applicable-p
   #:event-active-p
   #:perform-event-mapping
   #:from-mapping-description
   #:to-mapping-description
   #:event-from-action-mapping
   #:event-to-action-mapping
   #:stratify-action-mapping
   #:digital-mapping
   #:threshold
   #:toggle-p
   #:axis-directional-mapping
   #:dead-zone
   #:axis
   #:digital-directional-mapping
   #:high-value
   #:low-value
   #:mouse-directional-mapping
   #:scaling
   #:point
   #:stick
   #:buttons
   #:keys
   #:compile-mapping
   #:load-mapping
   #:save-mapping
   #:find-action-mappings
   #:update-action-mappings)
  ;; os-resources.lisp
  (:export
   #:*open-in-browser-hook*
   #:system-username
   #:open-in-browser
   #:open-in-file-manager
   #:rename-thread
   #:cpu-time
   #:io-bytes
   #:gpu-room
   #:cpu-room)
  ;; parallax.lisp
  (:export
   #:parallax
   #:parallax-background
   #:change-background)
  ;; particle.lisp
  (:export
   #:particle-system
   #:particle-capacity
   #:active-particles
   #:lifetime
   #:clock)
  ;; pipeline.lisp
  (:export
   #:pipeline
   #:nodes
   #:passes
   #:textures
   #:clear-pipeline
   #:connect
   #:check-consistent
   #:resize
   #:pack-pipeline)
  ;; pipelined-scene.lisp
  (:export
   #:pipelined-scene
   #:to-preload
   #:preload)
  ;; prompt.lisp
  (:export
   #:prompt-string
   #:action-strings
   #:action-string)
  ;; rails.lisp
  (:export
   #:rail
   #:target
   #:rail-points
   #:duration
   #:rail-location
   #:linear-rail
   #:rail-times)
  ;; render-texture.lisp
  (:export
   #:render-texture
   #:width
   #:height
   #:clear-color
   #:texture)
  ;; render-loop.lisp
  (:export
   #:render-loop
   #:thread
   #:delta-time
   #:frame-time
   #:target-frame-time
   #:reset-render-loop
   #:start
   #:stop
   #:render
   #:update)
  ;; resource.lisp
  (:export
   #:resource
   #:generator
   #:name
   #:allocate
   #:deallocate
   #:allocated-p
   #:check-allocated
   #:foreign-resource
   #:data-pointer
   #:gl-resource
   #:gl-name)
  ;; resource-generator.lisp
  (:export
   #:resource-generator
   #:generate-resources
   #:register-generation-observer
   #:clear-observers
   #:observe-generation
   #:resource
   #:compiled-generator
   #:compile-resources
   #:recompile-needed-p)
  ;; scene-buffer.lisp
  (:export
   #:scene-buffer
   #:render-pass)
  ;; scene.lisp
  (:export
   #:unit
   #:node
   #:scene
   #:name-map)
  ;; serialize.lisp
  (:export
   #:define-type-serializer
   #:define-object-type-serializer
   #:serialize-as
   #:deserialize-as)
  ;; settings.lisp
  (:export
   #:+settings+
   #:setting-file-path
   #:keymap-path
   #:load-keymap
   #:save-keymap
   #:load-settings
   #:save-settings
   #:setting
   #:observe-setting
   #:remove-setting-observer
   #:define-setting-observer
   #:video-mode
   #:fullscreen
   #:vsync
   #:framerate
   #:fps-counter)
  ;; sdl2-gamepad-map.lisp
  (:export)
  ;; selection-buffer.lisp
  (:export
   #:ensure-selection-color
   #:selection-buffer
   #:scene
   #:color->object-map
   #:object-at-point
   #:color->object
   #:selection-buffer-pass
   #:selectable
   #:selection-color
   #:find-new-selection-color)
  ;; shader-entity.lisp
  (:export
   #:shader-entity-class
   #:effective-shaders
   #:effective-buffers
   #:direct-shaders
   #:direct-buffers
   #:inhibited-shaders
   #:compute-effective-shaders
   #:class-shader
   #:remove-class-shader
   #:make-shader-program
   #:define-class-shader
   #:shader-entity
   #:define-shader-entity
   #:effective-shader-class
   #:compute-effective-shader-class
   #:standalone-shader-entity
   #:update-uniforms
   #:shader-program
   #:dynamic-shader-entity)
  ;; shader-pass.lisp
  (:export
   #:port
   #:shader-pass-class
   #:texture-port
   #:texture
   #:texspec
   #:uniform-port
   #:uniform-name
   #:input
   #:output
   #:attachment
   #:fixed-input
   #:static-input
   #:check-consistent
   #:buffer
   #:shader-pass
   #:framebuffer
   #:active-p
   #:renderable
   #:transformed
   #:renderable
   #:render-with
   #:dynamic-renderable
   #:apply-transforms
   #:bind-textures
   #:object-renderable-p
   #:shader-program-for-pass
   #:make-pass-shader-program
   #:coerce-pass-shader
   #:define-shader-pass
   #:generate-pass-program
   #:prepare-pass-program
   #:scene-pass
   #:per-object-pass
   #:construct-frame
   #:render-frame
   #:sort-frame
   #:single-shader-pass
   #:single-shader-scene-pass
   #:shader-program
   #:post-effect-pass)
  ;; skybox.lisp
  (:export
   #:skybox
   #:texture
   #:vertex-array
   #:skybox-pass)
  ;; sprite.lisp
  (:export
   #:sprite-frame
   #:xy
   #:uv
   #:duration
   #:sprite-animation
   #:name
   #:start
   #:end
   #:next-animation
   #:loop-to
   #:sprite-entity
   #:frame-idx
   #:frames
   #:make-sprite-frame-mesh
   #:frame
   #:animated-sprite
   #:clock
   #:animations
   #:find-animation
   #:animation
   #:playback-speed
   #:playback-direction
   #:reset-animation
   #:switch-animation
   #:play)
  ;; ssao,lisp
  (:export
   #:ssao-pass
   #:position-map
   #:normal-map
   #:occlusion)
  ;; static-vector.lisp
  (:export
   #:make-static-vector
   #:static-vector-p
   #:static-vector
   #:maybe-free-static-vector)
  ;; text.lisp
  (:export
   #:debug-text
   #:text
   #:foreground
   #:background)
  ;; texture-source.lisp
  (:export
   #:texture-source
   #:texture-source-src
   #:texture-source-dst
   #:pixel-data
   #:pixel-type
   #:pixel-format
   #:level
   #:target
   #:texture-sources->texture-size
   #:texture-sources->target
   #:normalize-texture-sources
   #:make-image-source
   #:merge-texture-sources
   #:upload-texture-source
   #:merge-textures)
  ;; tile-layer.lisp
  (:export
   #:tile-layer
   #:tileset
   #:tilemap
   #:tile-size
   #:visibility
   #:resize
   #:size
   #:tile
   #:clear)
  ;; toolkit.lisp
  (:export
   #:define-global
   #:+app-vendor+
   #:+app-system+
   #:data-root
   #:git-repo-commit
   #:version
   #:toolkit
   #:transfer-to
   #:coerce-object
   #:finalize
   #:gl-property
   #:current-time
   #:kw
   #:enlist
   #:unlist
   #:remf*
   #:popf
   #:one-of
   #:input-source
   #:input-value
   #:input-literal
   #:with-retry-restart
   #:with-new-value-restart
   #:with-unwind-protection
   #:with-cleanup-on-failure
   #:acquire-lock-with-starvation-test
   #:with-trial-io-syntax
   #:tempdir
   #:tempfile
   #:with-tempfile
   #:rename-file*
   #:make-uuid
   #:logfile
   #:config-directory
   #:standalone-logging-handler
   #:make-thread
   #:with-thread
   #:thread-did-not-exit
   #:wait-for-thread-exit
   #:with-thread-exit
   #:with-error-logging
   #:with-ignored-errors-on-release
   #:with-timing-report
   #:ensure-class
   #:list-subclasses
   #:list-leaf-classes
   #:format-timestring
   #:descriptor
   #:ensure-instance
   #:type-prototype
   #:maybe-finalize-inheritance
   #:with-slots-bound
   #:with-all-slots-bound
   #:initargs
   #:clone
   #:minimize
   #:generate-name
   #:clamp
   #:deadzone
   #:lerp
   #:deg->rad
   #:rad->deg
   #:db
   #:angle-midpoint
   #:symbol->c-name
   #:c-name->symbol
   #:check-gl-type
   #:gl-type-size
   #:cl-type->gl-type
   #:gl-type->cl-type
   #:gl-coerce
   #:gl-vendor
   #:check-texture-size
   #:define-enum-check
   #:check-texture-target
   #:check-texture-mag-filter
   #:check-texture-min-filter
   #:check-texture-wrapping
   #:check-texture-internal-format
   #:check-texture-pixel-format
   #:check-texture-pixel-type
   #:check-shader-type
   #:check-vertex-buffer-type
   #:check-vertex-buffer-element-type
   #:check-vertex-buffer-data-usage
   #:check-framebuffer-attachment
   #:internal-format-components
   #:internal-format-pixel-format
   #:internal-format-pixel-type
   #:pixel-data-stride
   #:infer-internal-format
   #:infer-swizzle-format
   #:infer-swizzle-channels
   #:infer-pixel-type
   #:pixel-type->cl-type
   #:when-gl-extension)
  ;; transforms.lisp
  (:export
   #:*view-matrix*
   #:*projection-matrix*
   #:*model-matrix*
   #:view-matrix
   #:projection-matrix
   #:model-matrix
   #:look-at
   #:perspective-projection
   #:orthographic-projection
   #:with-pushed-matrix
   #:translate
   #:translate-by
   #:rotate
   #:rotate-by
   #:scale
   #:scale-by
   #:reset-matrix
   #:vec->screen
   #:screen->vec)
  ;; window.lisp
  (:export
   #:window
   #:register-window
   #:deregister-window
   #:list-windows
   #:window
   #:name)
  ;; workbench.lisp
  (:export))

(defpackage #:cl+trial
  (:nicknames #:org.shirakumo.fraf.trial.cl+trial)
  (:shadowing-import-from #:trial #:// #:load)
  (:use #:cl
        #:trial
        #:org.shirakumo.fraf.math))

(let ((symbols ()))
  (do-symbols (symb '#:cl+trial) (push symb symbols))
  (export symbols '#:cl+trial))

(defpackage #:trial-user
  (:nicknames #:org.shirakumo.fraf.trial.user)
  (:use #:cl+trial))
