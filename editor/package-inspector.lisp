#|
 This file is a part of trial
 (c) 2017 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:org.shirakumo.trial.editor)
(in-readtable :qtools)

(define-widget package-inspector (QDialog inspector)
  ((object)))

(define-initializer (package-inspector setup)
  (setf (q+:window-title package-inspector) (format NIL "Package Inspector for ~a" (package-name object)))
  (q+:resize package-inspector 700 800)
  (refresh-instances package-inspector))

(define-subwidget (package-inspector package-info)
    (q+:make-qformlayout)
  (setf (q+:margin package-info) 5)
  (setf (q+:spacing package-info) 0))

(define-subwidget (package-inspector show-inherited)
    (q+:make-qcheckbox "Inherited"))

(define-subwidget (package-inspector show-external)
    (q+:make-qcheckbox "External")
  (setf (q+:checked show-external) T))

(define-subwidget (package-inspector show-internal)
    (q+:make-qcheckbox "Internal"))

(define-subwidget (package-inspector filter)
    (q+:make-qlineedit)
  (setf (q+:placeholder-text filter) "Filter..."))

(define-subwidget (package-inspector clear-filter)
    (make-instance 'inline-button :icon :close :tooltip "Clear the filter."))

(define-subwidget (package-inspector symbols)
    (make-instance 'package-listing :inspector package-inspector))

(define-subwidget (package-inspector scroller)
    (q+:make-qscrollarea)
  (setf (q+:widget scroller) symbols)
  (setf (q+:widget-resizable scroller) T)
  (setf (q+:horizontal-scroll-bar-policy scroller) (q+:qt.scroll-bar-always-off))
  (setf (q+:vertical-scroll-bar-policy scroller) (q+:qt.scroll-bar-always-on)))

(define-subwidget (package-inspector intern)
    (q+:make-qpushbutton)
  (setf (q+:icon intern) (icon :add))
  (setf (q+:tool-tip intern) "Intern or import a new symbol."))

(define-subwidget (package-inspector use)
    (q+:make-qpushbutton)
  (setf (q+:icon use) (icon :use))
  (setf (q+:tool-tip use) "Use a new package."))

(define-subwidget (package-inspector rename)
    (q+:make-qpushbutton)
  (setf (q+:icon rename) (icon :rename))
  (setf (q+:tool-tip rename) "Rename the package."))

(define-subwidget (package-inspector refresh)
    (q+:make-qpushbutton)
  (setf (q+:icon refresh) (icon :refresh))
  (setf (q+:tool-tip refresh) "Refresh the list of symbols."))

(define-subwidget (package-inspector layout)
    (q+:make-qgridlayout package-inspector)
  (q+:add-layout layout package-info 0 0 1 4)
  (let ((inner (q+:make-qhboxlayout)))
    (q+:add-widget inner (q+:make-qlabel "Show:"))
    (q+:add-widget inner show-inherited)
    (q+:add-widget inner show-external)
    (q+:add-widget inner show-internal)
    (q+:add-layout layout inner 1 0 1 4))
  (let ((inner (q+:make-qhboxlayout)))
    (q+:add-widget inner filter)
    (q+:add-widget inner clear-filter)
    (q+:add-layout layout inner 2 0 1 4))
  (q+:add-widget layout scroller 3 0 1 4)
  (q+:add-widget layout refresh 4 0 1 1)
  (q+:add-widget layout intern 4 1 1 1)
  (q+:add-widget layout use 4 2 1 1)
  (q+:add-widget layout rename 4 3 1 1)
  (setf (q+:spacing layout) 0))

(define-slot (package-inspector refresh refresh-instances) ()
  (declare (connected filter (editing-finished)))
  (declare (connected refresh (clicked)))
  (sweep-layout package-info)
  (flet ((add-row (name value)
           (let ((label (q+:make-qlabel (princ-to-string value))))
             (q+:add-row package-info name label)
             (setf (q+:alignment label) (q+:qt.align-right)))))
    (add-row "Name" (package-name object))
    (add-row "Nicknames" (package-nicknames object))
    (add-row "Using" (mapcar #'package-name (package-use-list object)))
    (add-row "Used by" (mapcar #'package-name (package-used-by-list object))))
  (qui:clear-layout symbols T)
  (refresh-background package-inspector))

(defmethod refresh-background ((package-inspector package-inspector))
  (with-slots-bound (package-inspector package-inspector)
    (let ((syms ()) (filter (q+:text filter)))
      (do-symbols (symbol object)
        (let ((status (nth-value 1 (find-symbol (symbol-name symbol) object))))
          (when (and (or (and (eql status :inherited) (q+:is-checked show-inherited))
                         (and (eql status :external) (q+:is-checked show-external))
                         (and (eql status :internal) (q+:is-checked show-internal)))
                     (or (string= "" filter)
                         (search filter (symbol-name symbol) :test #'char-equal)))
            (push symbol syms))))
      (dolist (symbol (sort syms #'string< :key #'symbol-name))
        (add-item symbol package-inspector)
        (sleep 0.01)))))

(define-slot (package-inspector add-item) ((item qobject))
  (declare (connected package-inspector (add-item qobject)))
  (when (typep item 'signal-carrier)
    (qui:add-item (object item) symbols)))

(define-slot (package-inspector clear-filter) ()
  (declare (connected clear-filter (clicked)))
  (setf (q+:text filter) "")
  (refresh-instances package-inspector))

(define-slot (package-inspector intern) ()
  (declare (connected intern (clicked)))
  (multiple-value-bind (value got) (safe-input-value package-inspector)
    (when got
      (etypecase value
        (string (intern value object)
         (refresh-instances package-inspector))
        (symbol (import value object)
         (refresh-instances package-inspector))
        (T (q+:qmessagebox-critical package-inspector "Error interning symbol"
                                    (format NIL "The given value is not a symbol or string: ~%~a"
                                            value)))))))

(define-slot (package-inspector use) ()
  (declare (connected use (clicked)))
  (let ((name (q+:qinputdialog-get-text package-inspector "Enter package name"
                                        "Enter the name of the package to use.")))
    (when (string/= name "")
      (cond ((find-package name)
             (use-package (find-package name) object)
             (refresh-instances package-inspector))
            (T
             (q+:qmessagebox-critical package-inspector "Error using package"
                                      (format NIL "No package named ~a found." name)))))))

(define-slot (package-inspector rename) ()
  (declare (connected rename (clicked)))
  (let ((name-list (list* (package-name object)
                          (copy-list (package-nicknames object)))))
    (q+:exec (make-instance 'list-inspector :object name-list))
    (rename-package object (first name-list) (rest name-list))
    (refresh-instances package-inspector)))

(define-widget package-listing (QWidget qui:listing)
  ((inspector :initarg :inspector :accessor inspector)))

(defmethod qui:coerce-item (symbol (listing package-listing))
  (make-instance 'package-listing-widget :item symbol :container listing))

(define-widget package-listing-widget (QWidget qui:listing-item)
  ()
  (:default-initargs :draw-item NIL))

(define-subwidget (package-listing-widget name)
    (q+:make-qpushbutton (%r (symbol-name (qui:widget-item package-listing-widget)) "&" "&&"))
  (setf (q+:style-sheet name) "text-align:left;"))

(define-subwidget (package-listing-widget status)
    (let ((object (object (inspector (qui:container package-listing-widget))))
          (symbol (qui:widget-item package-listing-widget)))
      (q+:make-qlabel (safe-princ (nth-value 1 (find-symbol (symbol-name symbol) object)))))
  (setf (q+:alignment status) (q+:qt.align-center))
  (setf (q+:fixed-width status) 100))

(define-subwidget (package-listing-widget un/export)
    (make-instance 'inline-button :icon :export :tooltip "Un/Export the symbol from the package."))

(define-subwidget (package-listing-widget unintern)
    (make-instance 'inline-button :icon :remove :tooltip "Unintern the symbol from the package."))

(define-subwidget (package-listing-widget layout)
    (q+:make-qhboxlayout package-listing-widget)
  (q+:add-widget layout name)
  (q+:add-widget layout status)
  (q+:add-widget layout un/export)
  (q+:add-widget layout unintern)
  (setf (q+:spacing layout) 0)
  (setf (q+:margin layout) 0))

(define-slot (package-listing-widget inspect) ()
  (declare (connected name (clicked)))
  (inspect (qui:widget-item package-listing-widget)))

(define-slot (package-listing-widget un/export) ()
  (declare (connected un/export (clicked)))
  (let ((object (object (inspector (qui:container package-listing-widget))))
        (symbol (qui:widget-item package-listing-widget)))
    (if (eql :external (nth-value 1 (find-symbol (symbol-name symbol) object)))
        (unexport symbol object)
        (export symbol object))
    (setf (q+:text status) (safe-princ (nth-value 1 (find-symbol (symbol-name symbol) object))))))

(define-slot (package-listing-widget unintern) ()
  (declare (connected unintern (clicked)))
  (let ((object (object (inspector (qui:container package-listing-widget))))
        (symbol (qui:widget-item package-listing-widget)))
    (unintern symbol object)
    (qui:remove-widget package-listing-widget (qui:container package-listing-widget))))
