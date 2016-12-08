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
                    (state running)
                    (response Yes)
                    (valid-answers Yes No DontKnow DontCare)))
)

(defrule determine-more-gods
  (logical (god-exists Yes))
  =>
  (assert (UI-state (display gods.more.query)
                    (relation-asserted more-gods)
                    (state running)
                    (response Yes)
                    (valid-answers Yes No)))
)

(defrule determine-god-control
  (logical (more-gods No))
  =>
  (assert (UI-state (display god.control.query)
                    (relation-asserted god-control)
                    (state running)
                    (response Yes)
                    (valid-answers Yes No)))
)

(defrule determine-god-independent
  (logical (god-control Yes))
  =>
  (assert (UI-state (display god.independent.query)
                    (relation-asserted god-independent)
                    (state running)
                    (response Yes)
                    (valid-answers Yes No)))
)

(defrule determine-god-in-all
  (logical (god-independent No))
  =>
  (assert (UI-state (display god.in.all.query)
                    (relation-asserted god-in-all)
                    (state running)
                    (response Yes)
                    (valid-answers Yes No)))
)

(defrule determine-god-commited
  (logical (god-independent Yes))
  =>
  (assert (UI-state (display god.committed.to.world.query)
                    (relation-asserted god-commited)
                    (state running)
                    (response Yes)
                    (valid-answers Yes No)))
)

(defrule determine-world-part-of-god
  (logical (god-in-all No))
  =>
  (assert (UI-state (display world.part.of.god.query)
                    (relation-asserted world-part-of-god)
                    (state running)
                    (response Yes)
                    (valid-answers Yes No)))
)

(defrule determine-meaning-in-world
  (logical (or (atheist Yes) (apatheist Yes) (agnostic Yes)))
  =>
  (assert (UI-state (display meaning.in.world.query)
                    (relation-asserted meaning-in-world)
                    (state running)
                    (response Yes)
                    (valid-answers Yes No DontKnow DontCare)))
)

;;;*************************
;;;* TEMPORARY CONCLUSION RULES *
;;;*************************

(defrule agnostic-temp-conclusion
  (logical (god-exists DontKnow))
  =>
  (assert (UI-state (display agnostic.temp.result)
                    (relation-asserted agnostic)
                    (state temp)
                    (response Yes)
                    (valid-answers Yes)))
)

(defrule apatheist-temp-conclusion
  (logical (god-exists DontCare))
  =>
  (assert (UI-state (display apatheist.temp.result)
                    (relation-asserted apatheist)
                    (state temp)
                    (response Yes)
                    (valid-answers Yes)))
)

(defrule atheist-temp-conclusion
  (logical (god-exists No))
  =>
  (assert (UI-state (display atheist.temp.result)
                    (relation-asserted atheist)
                    (state temp)
                    (response Yes)
                    (valid-answers Yes)))
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
  (logical (meaning-in-world DontKnow))
  =>
  (assert (UI-state (display agnostic.result)
                    (state final)))
)

(defrule apatheist-conclusion
  (logical (meaning-in-world DontCare))
  =>
  (assert (UI-state (display apatheist.result)
                    (state final)))
)

(defrule deist-conclusion
  (logical (or (god-control No) (god-commited No)))
  =>
  (assert (UI-state (display deist.result)
                    (state final)))
)

(defrule pantheist-conclusion
  (logical (god-in-all Yes))
  =>
  (assert (UI-state (display pantheist.result)
                    (state final)))
)

(defrule world-god-relation-question-conclusion
  (logical (world-part-of-god No))
  =>
  (assert (UI-state (display world.god.relation.question.result)
                    (state final)))
)

(defrule panentheist-conclusion
  (logical (world-part-of-god Yes))
  =>
  (assert (UI-state (display panentheist.result)
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
