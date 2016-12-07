;;; ***************************
;;; * DEFTEMPLATES & DEFFACTS *
;;; ***************************

(deftemplate UI-state
   (slot id (default-dynamic (gensym*)))
   (slot display)
   (slot relation-asserted (default none))
   (slot response (default none))
   (multislot valid-answers)
   (slot state (default middle)))

(deftemplate state-list
   (slot current)
   (multislot sequence))

(deffacts startup
   (state-list))

;;;****************
;;;* STARTUP RULE *
;;;****************

(defrule system-banner ""
  =>
  (assert (UI-state (display WelcomeMessage)
                    (relation-asserted start)
                    (state initial)
                    (valid-answers))))

;;;***************
;;;* QUERY RULES *
;;;***************

(defrule determine-god-existance
  (logical (start))
  =>
  (assert (UI-state (display god.exists.query)
                    (relation-asserted god-exists)
                    (response Yes)
                    (valid-answers Yes No DontKnow DontCare)))
)

(defrule determine-more-gods
  (logical (god-exists Yes))
  =>
  (assert (UI-state (display gods.more.query)
                    (relation-asserted more-gods)
                    (response Yes)
                    (valid-answers Yes No)))
)

(defrule determine-god-control
  (logical (more-gods No))
  =>
  (assert (UI-state (display god.control.query)
                    (relation-asserted god-control)
                    (response Yes)
                    (valid-answers Yes No)))
)

(defrule determine-god-independent
  (logical (god-control Yes))
  =>
  (assert (UI-state (display god.independent.query)
                    (relation-asserted god-independent)
                    (response Yes)
                    (valid-answers Yes No)))
)

(defrule determine-god-in-all
  (logical (god-independent No))
  =>
  (assert (UI-state (display god.in.all.query)
                    (relation-asserted god-in-all)
                    (response Yes)
                    (valid-answers Yes No)))
)

(defrule determine-god-commited
  (logical (god-independent Yes))
  =>
  (assert (UI-state (display god.committed.to.world.query)
                    (relation-asserted god-commited)
                    (response Yes)
                    (valid-answers Yes No)))
)

;;;*************************
;;;* TEMPORARY CONCLUSION RULES *
;;;*************************

(defrule agnostic-temp-conclusion
  (logical (god-exists DontKnow))
  =>
  (assert (UI-state (display agnostic.temp.result)
                    (relation-asserted agnostic)
                    (response Yes)
                    (valid-answers Yes No)))
)

(defrule apatheist-temp-conclusion
  (logical (god-exists DontCare))
  =>
  (assert (UI-state (display apatheist.temp.result)
                    (relation-asserted apatheist)
                    (response Yes)
                    (valid-answers Yes No)))
)

(defrule atheist-temp-conclusion
  (logical (god-exists No))
  =>
  (assert (UI-state (display atheist.temp.result)
                    (relation-asserted atheist)
                    (response Yes)
                    (valid-answers Yes No)))
)

;;;*************************
;;;* FINAL CONCLUSION RULES *
;;;*************************

(defrule polytheist-conclusion
  (logical (more-gods Yes))
  =>
  (assert (UI-state (display polytheist.result)
                    (state final)))
)

(defrule agnostic-conclusion
  (logical (agnostic No))
  =>
  (assert (UI-state (display agnostic.result)
                    (state final)))
)

(defrule apatheist-conclusion
  (logical (apatheist No))
  =>
  (assert (UI-state (display apatheist.result)
                    (state final)))
)

(defrule atheist-conclusion
  (logical (atheist No))
  =>
  (assert (UI-state (display atheist.result)
                    (state final)))
)

;;;*************************
;;;* GUI INTERACTION RULES *
;;;*************************

(defrule ask-question
   (declare (salience 5))
   (UI-state (id ?id))
   ?f <- (state-list (sequence $?s&:(not (member$ ?id ?s))))
   =>
   (modify ?f (current ?id) (sequence ?id ?s))
   (halt)
)

(defrule handle-next-no-change-none-middle-of-chain
   (declare (salience 10))
   ?f1 <- (next ?id)
   ?f2 <- (state-list (current ?id) (sequence $? ?nid ?id $?))
   =>
   (retract ?f1)
   (modify ?f2 (current ?nid))
   (halt)
)

(defrule handle-next-response-none-end-of-chain
   (declare (salience 10))
   ?f <- (next ?id)
   (state-list (sequence ?id $?))
   (UI-state (id ?id) (relation-asserted ?relation))
   =>
   (retract ?f)
   (assert (add-response ?id))
)

(defrule handle-next-no-change-middle-of-chain
   (declare (salience 10))
   ?f1 <- (next ?id ?response)
   ?f2 <- (state-list (current ?id) (sequence $? ?nid ?id $?))
   (UI-state (id ?id) (response ?response))
   =>
   (retract ?f1)
   (modify ?f2 (current ?nid))
   (halt)
)

(defrule handle-next-change-middle-of-chain
   (declare (salience 10))
   (next ?id ?response)
   ?f1 <- (state-list (current ?id) (sequence ?nid $?b ?id $?e))
   (UI-state (id ?id) (response ~?response))
   ?f2 <- (UI-state (id ?nid))
   =>
   (modify ?f1 (sequence ?b ?id ?e))
   (retract ?f2)
)

(defrule handle-next-response-end-of-chain
   (declare (salience 10))
   ?f1 <- (next ?id ?response)
   (state-list (sequence ?id $?))
   ?f2 <- (UI-state (id ?id) (response ?expected) (relation-asserted ?relation))
   =>
   (retract ?f1)
   (if (neq ?response ?expected) then (modify ?f2 (response ?response)))
   (assert (add-response ?id ?response)))

(defrule handle-add-response
   (declare (salience 10))
   (logical (UI-state (id ?id) (relation-asserted ?relation)))
   ?f1 <- (add-response ?id ?response)
   =>
   (str-assert (str-cat "(" ?relation " " ?response ")"))
   (retract ?f1)
)

(defrule handle-add-response-none
   (declare (salience 10))
   (logical (UI-state (id ?id) (relation-asserted ?relation)))
   ?f1 <- (add-response ?id)
   =>
   (str-assert (str-cat "(" ?relation ")"))
   (retract ?f1)
)

(defrule handle-prev
   (declare (salience 10))
   ?f1 <- (prev ?id)
   ?f2 <- (state-list (sequence $?b ?id ?p $?e))
   =>
   (retract ?f1)
   (modify ?f2 (current ?p))
   (halt)
)
