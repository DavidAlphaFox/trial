#|
 This file is a part of trial
 (c) 2017 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:org.shirakumo.trial.editor)
(in-readtable :qtools)

(define-widget hash-table-inspector (QDialog inspector)
  ((object)))

(define-initializer (hash-table-inspector setup)
  (setf (q+:window-title hash-table-inspector) (format NIL "Inspecting ~a" (safe-princ object)))
  (q+:resize hash-table-inspector 500 600)
  (refresh-instances hash-table-inspector))

(define-subwidget (hash-table-inspector table-info)
    (q+:make-qformlayout)
  (setf (q+:margin table-info) 5)
  (setf (q+:spacing table-info) 0))

(define-subwidget (hash-table-inspector entries)
    (make-instance 'table-listing :object (object hash-table-inspector)))

(define-subwidget (hash-table-inspector scroller)
    (q+:make-qscrollarea)
  (setf (q+:widget scroller) entries)
  (setf (q+:widget-resizable scroller) T)
  (setf (q+:horizontal-scroll-bar-policy scroller) (q+:qt.scroll-bar-always-off))
  (setf (q+:vertical-scroll-bar-policy scroller) (q+:qt.scroll-bar-always-on)))

(define-subwidget (hash-table-inspector clear)
    (q+:make-qpushbutton)
  (setf (q+:icon clear) (icon :clear))
  (setf (q+:tool-tip clear) "Clear the hash table."))

(define-subwidget (hash-table-inspector refresh)
    (q+:make-qpushbutton)
  (setf (q+:icon refresh) (icon :refresh))
  (setf (q+:tool-tip refresh) "Refresh the list of entries."))

(define-subwidget (hash-table-inspector layout)
    (q+:make-qgridlayout hash-table-inspector)
  (q+:add-layout layout table-info 0 0 1 2)
  (q+:add-widget layout scroller 1 0 1 2)
  (q+:add-widget layout refresh 2 0 1 1)
  (q+:add-widget layout clear 2 1 1 1)
  (setf (q+:spacing layout) 0))

(define-slot (hash-table-inspector refresh refresh-instances) ()
  (declare (connected refresh (clicked)))
  (sweep-layout table-info)
  (flet ((add-row (name value)
           (let ((label (q+:make-qlabel (prin1-to-string value))))
             (q+:add-row table-info name label)
             (setf (q+:alignment label) (q+:qt.align-right)))))
    (add-row "Count" (hash-table-count object))
    (add-row "Size" (hash-table-size object))
    (add-row "Test" (hash-table-test object))
    (add-row "Weakness" (tg:hash-table-weakness object))
    (add-row "Rehash Size" (hash-table-rehash-size object))
    (add-row "Rehash Threshold" (hash-table-rehash-threshold object)))
  (qui:clear-layout entries T)
  (refresh-background hash-table-inspector))

(defmethod refresh-background ((hash-table-inspector hash-table-inspector))
  (with-slots-bound (hash-table-inspector hash-table-inspector)
    (loop for key being the hash-key of object
          do (add-item key hash-table-inspector)
             (sleep 0.01))))

(define-slot (hash-table-inspector add-item) ((item qobject))
  (declare (connected hash-table-inspector (add-item qobject)))
  (when (typep item 'signal-carrier)
    (qui:add-item (object item) entries)))

(define-slot (hash-table-inspector clear) ()
  (declare (connected clear (clicked)))
  (clrhash object)
  (refresh-instances hash-table-inspector))

(define-widget table-listing (QWidget qui:listing)
  ((object :initarg :object :accessor object)))

(defmethod qui:coerce-item (key (listing table-listing))
  (make-instance 'table-listing-widget :item key :container listing))

(define-widget table-listing-widget (QWidget qui:listing-item)
  ()
  (:default-initargs :draw-item NIL))

(define-subwidget (table-listing-widget key-button)
    (q+:make-qpushbutton (safe-prin1 (qui:widget-item table-listing-widget))))

(define-subwidget (table-listing-widget value-button)
    (let ((object (object (qui:container table-listing-widget)))
          (key (qui:widget-item table-listing-widget)))
      (q+:make-qpushbutton (safe-prin1 (gethash key object)))))

(define-subwidget (table-listing-widget set-value)
    (make-instance 'inline-button :icon :set :tooltip "Set the slot to a new value."))

(define-subwidget (table-listing-widget remove-entry)
    (make-instance 'inline-button :icon :remove :tooltip "Remove the entry."))

(define-subwidget (table-listing-widget layout)
    (q+:make-qhboxlayout table-listing-widget)
  (q+:add-widget layout key-button)
  (q+:add-widget layout value-button)
  (q+:add-widget layout set-value)
  (q+:add-widget layout remove-entry)
  (setf (q+:spacing layout) 0)
  (setf (q+:margin layout) 0))

(define-slot (table-listing-widget inspect-key) ()
  (declare (connected key-button (clicked)))
  (inspect (qui:widget-item table-listing-widget)))

(define-slot (table-listing-widget inspect-value) ()
  (declare (connected value-button (clicked)))
  (let ((object (object (qui:container table-listing-widget)))
        (key (qui:widget-item table-listing-widget)))
    (inspect (gethash key object))))

(define-slot (table-listing-widget set-value) ()
  (declare (connected set-value (clicked)))
  (let* ((object (object (qui:container table-listing-widget)))
         (key (qui:widget-item table-listing-widget)))
    (multiple-value-bind (value got) (safe-input-value table-listing-widget)
      (when got
        (setf (gethash key object) value)
        (setf (q+:text value-button) (safe-prin1 value))))))

(define-slot (table-listing-widget remove-entry) ()
  (declare (connected remove-entry (clicked)))
  (let ((object (object (qui:container table-listing-widget)))
        (key (qui:widget-item table-listing-widget)))
    (remhash key object)
    (qui:remove-widget table-listing-widget (qui:container table-listing-widget))))
