Require Import Coq.omega.Omega.
Require Import Coq.Lists.List Coq.Lists.SetoidList Coq.Bool.Bool
        Fiat.Common Fiat.Common.List.Operations Fiat.Common.Equality Fiat.Common.List.FlattenList.

Unset Implicit Arguments.

Local Notation iffT A B := ((A -> B) * (B -> A))%type.

Section ListFacts.

  Lemma map_id :
    forall {A: Type} (seq: list A),
      (map (fun x => x) seq) = seq.
  Proof.
    intros A seq; induction seq; simpl; congruence.
  Qed.

  Lemma app_singleton :
    forall {A} (x: A) s,
      [x] ++ s = x :: s.
  Proof.
    reflexivity.
  Qed.

  Lemma app_eq_nil_iff :
    forall {A} s1 s2,
      @nil A = s1 ++ s2 <-> ([] = s1 /\ [] = s2).
  Proof.
    intros; split; intro H.
    - symmetry in H; apply app_eq_nil in H; intuition.
    - intuition; subst; intuition.
  Qed.

  Lemma singleton_neq_nil :
    forall {A} (a: A),
      [a] = [] <-> False.
  Proof.
    intuition discriminate.
  Qed.

  Lemma in_nil_iff :
    forall {A} (item: A),
      List.In item [] <-> False.
  Proof.
    intuition.
  Qed.

  Lemma in_not_nil :
    forall {A} x seq,
      @List.In A x seq -> seq <> nil.
  Proof.
    intros A x seq in_seq eq_nil.
    apply (@in_nil _ x).
    subst seq; assumption.
  Qed.

  Lemma in_seq_false_nil_iff :
    forall {A} (seq: list A),
      (forall (item: A), (List.In item seq <-> False)) <->
      (seq = []).
  Proof.
    intros.
    destruct seq; simpl in *; try tauto.
    split; intro H.
    pose proof (H a); intuition.
    discriminate.
  Qed.


  Lemma map_map :
    forall { A B C } (f: A -> B) (g: B -> C),
    forall seq,
      List.map g (List.map f seq) = List.map (fun x => g (f x)) seq.
  Proof.
    intros; induction seq; simpl; f_equal; trivial.
  Qed.

  Lemma filter_all_true :
    forall {A} pred (seq: list A),
      (forall x, List.In x seq -> pred x = true) ->
      List.filter pred seq = seq.
  Proof.
    induction seq as [ | head tail IH ]; simpl; trivial.
    intros all_true.
    rewrite all_true by eauto.
    f_equal; intuition.
  Qed.

  Lemma filter_all_false :
    forall {A} seq pred,
      (forall item : A, List.In item seq -> pred item = false) ->
      List.filter pred seq = [].
  Proof.
    intros A seq pred all_false; induction seq as [ | head tail IH ]; simpl; trivial.
    rewrite (all_false head) by (simpl; eauto).
    intuition.
  Qed.

  Lemma map_filter_all_false :
    forall {A} pred seq,
      (forall subseq, List.In subseq seq ->
                      forall (item: A), List.In item subseq ->
                                        pred item = false) ->
      (List.map (List.filter pred) seq) = (List.map (fun x => []) seq).
  Proof.
    intros A pred seq all_false;
    induction seq as [ | subseq subseqs IH ] ; simpl; trivial.

    f_equal.

    specialize (all_false subseq (or_introl eq_refl)).
    apply filter_all_false; assumption.

    apply IH; firstorder.
  Qed.

  Lemma foldright_compose :
    forall {TInf TOutf TAcc}
           (g : TOutf -> TAcc -> TAcc) (f : TInf -> TOutf)
           (seq : list TInf) (init : TAcc),
      List.fold_right (compose g f) init seq =
      List.fold_right g init (List.map f seq).
  Proof.
    intros;
    induction seq;
    simpl;
    [  | rewrite IHseq ];
    reflexivity.
  Qed.

  Lemma in_map_unproject :
    forall {A B} projection seq,
    forall item,
      @List.In A item seq ->
      @List.In B (projection item) (List.map projection seq).
  Proof.
    intros ? ? ? seq;
    induction seq; simpl; intros item in_seq.

    trivial.
    destruct in_seq;
      [ left; f_equal | right ]; intuition.
  Qed.

  Lemma refold_map :
    forall {A B} (f: A -> B) x seq,
      f x :: map f seq = map f (x :: seq).
  Proof.
    simpl; reflexivity.
  Qed.

  Lemma refold_in :
    forall {A} a b l,
      @List.In A a (b :: l) <-> List.In a l \/ a = b.
  Proof.
    intros; simpl; intuition.
  Qed.

  Lemma app_map_inv :
    forall {A B} seq l1 l2 (f: A -> B),
      l1 ++ l2 = map f seq ->
      exists l1' l2',
        seq = l1' ++ l2' /\ l1 = map f l1' /\ l2 = map f l2'.
  Proof.
    induction seq; simpl; intros.

    exists (@nil A); exists (@nil A); simpl.
    apply app_eq_nil in H; intuition.

    destruct l1.
    rewrite app_nil_l in H.
    exists (@nil A); exists (a :: seq); simpl; intuition.

    rewrite <- app_comm_cons in H.
    inversion H.
    specialize (IHseq _ _ _ H2).
    destruct IHseq as [l1' [l2' (seq_eq_app & l1l1' & l2l2') ] ].
    exists (a :: l1'); exists (l2'); subst; intuition.
  Qed.

  Lemma cons_map_inv :
    forall {A B} seq x1 l2 (f: A -> B),
      x1 :: l2 = map f seq ->
      exists x1' l2',
        seq = x1' :: l2' /\ x1 = f x1' /\ l2 = map f l2'.
  Proof.
    intros * _eq.
    destruct seq as [ | x1' l2' ]; simpl in *; try discriminate.
    inversion _eq.
    exists x1'; exists l2'; subst; intuition.
  Qed.

  Lemma map_eq_nil_inv :
    forall {A B} (f: A -> B) seq,
      map f seq = [] -> seq = [].
  Proof.
    intros; destruct seq; simpl in *; try discriminate; trivial.
  Qed.


  Lemma filter_app :
    forall {A} (f: A -> _) s1 s2,
      List.filter f (s1 ++ s2) =
      List.filter f s1 ++ List.filter f s2.
  Proof.
    induction s1; simpl; intros.

    - reflexivity.
    - destruct (f a); simpl; congruence.
  Qed.

  Lemma filter_map :
    forall {A B} f g seq,
      List.filter f (@List.map A B g seq) =
      List.map g (List.filter (fun x => f (g x)) seq).
  Proof.
    induction seq; simpl; intros.

    - reflexivity.
    - destruct (f (g a)); simpl; [ f_equal | ]; assumption.
  Qed.

  Lemma filter_true :
    forall {A} s,
      @filter A (fun _ => true) s = s.
  Proof.
    induction s; simpl; try rewrite IHs; reflexivity.
  Qed.

  Lemma filter_false :
    forall {A} s,
      @filter A (fun _ => false) s = [].
  Proof.
    induction s; simpl; try rewrite IHs; reflexivity.
  Qed.

  Lemma filter_flat_map_join_snd :
    forall {A B} f s1 s2,
      flat_map (filter (fun x : A * B => f (snd x)))
               (map (fun a1 : A => map (fun b : B => (a1, b)) s2) s1) =
      flat_map (fun a1 : A => map (fun b : B => (a1, b)) (filter f s2)) s1.
  Proof.
    induction s1; simpl; intros; trivial.
    rewrite IHs1; f_equiv.
    rewrite filter_map; simpl; reflexivity.
  Qed.

  Lemma flat_map_empty :
    forall {A B} s,
      @flat_map A B (fun _ => []) s = [].
  Proof.
    induction s; firstorder.
  Qed.

  Lemma filter_commute :
    forall {A} f g seq,
      @filter A f (filter g seq) = filter g (filter f seq).
  Proof.
    induction seq; simpl; intros; trivial.
    destruct (f a) eqn:eqf; destruct (g a) eqn:eqg;
    simpl; rewrite ?eqf, ?eqg, ?IHseq; trivial.
  Qed.

  Lemma fold_right_id {A} :
    forall seq,
      @List.fold_right (list A) A (fun elem acc => elem :: acc) [] seq = seq.
  Proof.
    induction seq; simpl; try rewrite IHseq; congruence.
  Qed.

  Lemma fold_left_id {A} :
    forall seq,
      @List.fold_left (list A) A (fun acc elem => elem :: acc) seq [] = rev seq.
  Proof.
    intros.
    rewrite <- fold_left_rev_right.
    apply fold_right_id.
  Qed.

  Lemma In_partition {A}
  : forall f (l : list A) a,
      List.In a l <-> (List.In a (fst (List.partition f l))
                       \/ List.In a (snd (List.partition f l))).
  Proof.
    split; induction l; simpl; intros; intuition; simpl; subst;
    first [destruct (f a0); destruct (List.partition f l); simpl in *; intuition
          | destruct (f a); destruct (List.partition f l); simpl; intuition].
  Qed.

  Lemma In_partition_matched {A}
  : forall f (l : list A) a,
      List.In a (fst (List.partition f l)) ->
      f a = true.
  Proof.
    induction l; simpl; intros; intuition; simpl; subst; eauto.
    case_eq (f a); destruct (List.partition f l); simpl; intuition;
    rewrite H0 in H; eauto; inversion H; subst; eauto.
  Qed.

  Lemma In_partition_unmatched {A}
  : forall f (l : list A) a,
      List.In a (snd (List.partition f l)) ->
      f a = false.
  Proof.
    induction l; simpl; intros; intuition; simpl; subst; eauto.
    case_eq (f a); destruct (List.partition f l); simpl; intuition;
    rewrite H0 in H; eauto; inversion H; subst; eauto.
  Qed.

  Lemma nil_in_false :
    forall {A} seq,
      seq = nil <-> ~ exists (x: A), List.In x seq.
  Proof.
    split; intro H.
    intros [ x in_seq ]; subst; eauto using in_nil.
    destruct seq as [ | a ]; trivial.
    exfalso; apply H; exists a; simpl; intuition.
  Qed.

  Lemma In_InA :
    forall (A : Type) (l : list A) (eqA : relation A) (x : A),
      Equivalence eqA -> List.In x l -> InA eqA x l.
  Proof.
    induction l; intros; simpl in *.
    exfalso; eauto using in_nil.
    destruct H0.
    apply InA_cons_hd; subst; reflexivity.
    apply InA_cons_tl, IHl; trivial.
  Qed.

  Lemma fold_map :
    forall {A B C} seq f g init,
      @List.fold_left C A (fun acc x => f acc (g x)) seq init =
      @List.fold_left C B (fun acc x => f acc (  x)) (@List.map A B g seq) init.
  Proof.
    induction seq; simpl; intros; trivial; try rewrite IHseq; intuition.
  Qed.

  Lemma fold_plus_sym :
    forall (seq: list nat) (default: nat),
      List.fold_right plus default seq =
      List.fold_left plus seq default.
  Proof.
    intros; rewrite <- fold_left_rev_right.
    revert default; induction seq; simpl; eauto; intros.
    rewrite fold_right_app; simpl; rewrite <- IHseq.
    clear IHseq; revert a default; induction seq;
    simpl; intros; auto with arith.
    rewrite <- IHseq.
    rewrite Plus.plus_comm, <- Plus.plus_assoc; f_equal.
    rewrite Plus.plus_comm; reflexivity.
  Qed.

  Lemma map_snd {A B C} :
    forall (f : A -> B) (l : list (C * A)),
      List.map f (List.map snd l) =
      List.map snd (List.map (fun ca => (fst ca, f (snd ca))) l).
  Proof.
    intros; repeat rewrite List.map_map; induction l; simpl; eauto.
  Qed.

  Lemma partition_app {A} :
    forall f (l1 l2 : list A),
      List.partition f (l1 ++ l2) =
      (fst (List.partition f l1) ++ fst (List.partition f l2),
       snd (List.partition f l1) ++ snd (List.partition f l2)).
  Proof.
    induction l1; simpl.
    - intros; destruct (List.partition f l2); reflexivity.
    - intros; rewrite IHl1; destruct (f a); destruct (List.partition f l1);
      simpl; f_equal.
  Qed.


  Lemma partition_filter_eq {A} :
    forall (f : A -> bool) l,
      fst (List.partition f l) = List.filter f l.
  Proof.
    induction l; simpl; eauto.
    destruct (List.partition f l); destruct (f a); simpl in *; congruence.
  Qed.

  Lemma partition_filter_neq {A} :
    forall (f : A -> bool) l,
      snd (List.partition f l) = List.filter (fun a => negb (f a)) l.
  Proof.
    induction l; simpl; eauto.
    destruct (List.partition f l); destruct (f a); simpl in *; congruence.
  Qed.


  Lemma filter_app_inv {A}
  : forall pred (l l1 l2 : list A),
      filter pred l = app l1 l2
      -> exists l1' l2', l = app l1' l2'
                         /\ l1 = filter pred l1'
                         /\ l2 = filter pred l2'.
  Proof.
    induction l; simpl; intros.
    - destruct l1; simpl in *;
      [ destruct l2;
        [ eexists nil; eexists nil; intuition
        | discriminate]
      | discriminate ].
    - revert H; case_eq (pred a); intros.
      + destruct l1; simpl in *.
        * destruct l2; [ discriminate | ].
          injection H0; intros.
          apply (IHl [] l2) in H1; destruct_ex; intuition; subst.
          eexists []; eexists (_ :: _); intuition; simpl.
          rewrite H, H0; reflexivity.
        * injection H0; intros.
          apply IHl in H1; destruct_ex; subst.
          eexists (a0 :: x); eexists x0; intuition.
          rewrite H2; reflexivity.
          simpl; rewrite H, H1; reflexivity.
      + apply IHl in H0; destruct_ex; subst.
        eexists (a :: x); eexists x0; intuition.
        rewrite H1; reflexivity.
        simpl; rewrite H, H0; reflexivity.
  Qed.

  Lemma fold_left_sum_acc :
    forall {A B} seq m n (f: A -> list B),
      m +
      fold_left (fun (count : nat) (x : A) => count + length (f x)) seq n =
      fold_left (fun (count : nat) (x : A) => count + length (f x)) seq
                (n + m).
  Proof.
    induction seq; simpl; intros; eauto with arith.
    rewrite IHseq; f_equal; eauto with arith.
    repeat rewrite <- Plus.plus_assoc; f_equal; auto with arith.
  Qed.

  Lemma length_flat_map :
    forall {A B} seq (f: A -> list B),
      List.length (flat_map f seq) =
      fold_left (fun count (x : A) => count + List.length (f x)) seq 0.
  Proof.
    simpl; induction seq; simpl; intros; eauto.
    rewrite app_length, IHseq; clear.
    apply fold_left_sum_acc.
  Qed.

  Lemma filter_and {A}
  : forall (pred1 pred2 : A -> bool) (l : List.list A),
      List.filter (fun a => pred1 a && pred2 a) l =
      List.filter pred2 (List.filter pred1 l).
  Proof.
    induction l; simpl; eauto.
    case_eq (pred1 a); simpl; intros H; eauto;
    case_eq (pred2 a); simpl; intros; rewrite IHl; eauto.
  Qed.

  Definition ExtensionalEq {A B} f g :=
    forall (a: A), @eq B (f a) (g a).

  Lemma filter_by_equiv :
    forall {A} f g,
      ExtensionalEq f g ->
      forall seq, @List.filter A f seq = @List.filter A g seq.
  Proof.
    intros A f g obs seq; unfold ExtensionalEq in obs; induction seq; simpl; try rewrite obs; try rewrite IHseq; trivial.
  Qed.

  Lemma filter_by_equiv_meta :
    forall {A B : Type} (f g : A -> B -> bool),
      (forall (a: A), ExtensionalEq (f a) (g a)) ->
      (forall (a: A) (seq : list B), filter (f a) seq = filter (g a) seq).
  Proof.
    intros * equiv *;
    rewrite (filter_by_equiv _ _ (equiv _));
    reflexivity.
  Qed.

  Lemma filter_and' :
    forall {A} pred1 pred2,
    forall (seq: list A),
      List.filter (fun x => andb (pred1 x) (pred2 x)) seq =
      List.filter pred1 (List.filter pred2 seq).
  Proof.
    intros;
    induction seq;
    simpl;
    [ | destruct (pred1 a) eqn:eq1;
        destruct (pred2 a) eqn:eq2];
    simpl;
    try rewrite eq1;
    try rewrite eq2;
    trivial;
    f_equal;
    trivial.
  Qed.

  Local Ltac drop_take_t' :=
    idtac;
    match goal with
      | _ => reflexivity
      | _ => intro
      | _ => progress simpl in *
      | [ |- context[drop ?n []] ] => atomic n; destruct n
      | [ |- context[take ?n []] ] => atomic n; destruct n
      | [ |- context[drop ?n (_::_)] ] => atomic n; destruct n
      | [ |- context[take ?n (_::_)] ] => atomic n; destruct n
      | [ H : _ |- _ ] => rewrite H
      | _ => solve [ eauto with arith ]
      | _ => exfalso; omega
    end.

  Local Ltac drop_take_t := repeat drop_take_t'.

  Lemma drop_map {A B n} (f : A -> B) ls
  : drop n (map f ls) = map f (drop n ls).
  Proof.
    revert n; induction ls; drop_take_t.
  Qed.

  Lemma take_map {A B n} (f : A -> B) ls
  : take n (map f ls) = map f (take n ls).
  Proof.
    revert n; induction ls; drop_take_t.
  Qed.

  Lemma take_all {A n} {ls : list A} (H : List.length ls <= n) : take n ls = ls.
  Proof.
    revert n H; induction ls; drop_take_t.
  Qed.

  Lemma drop_all {A n} {ls : list A} (H : List.length ls <= n) : drop n ls = nil.
  Proof.
    revert n H; induction ls; drop_take_t.
  Qed.

  Lemma drop_all_iff {A n} {ls : list A}
  : (List.length ls <= n) <-> drop n ls = nil.
  Proof.
    split; [ apply drop_all | ].
    revert n; induction ls; [ simpl; intros; omega | ].
    intros [|n]; simpl.
    { intro; discriminate. }
    { intro; auto with arith. }
  Qed.

  Lemma take_append {A n} {ls ls' : list A}
  : take n (ls ++ ls') = take n ls ++ take (n - List.length ls) ls'.
  Proof.
    revert n ls'; induction ls; drop_take_t.
  Qed.

  Lemma drop_append {A n} {ls ls' : list A}
  : drop n (ls ++ ls') = drop n ls ++ drop (n - List.length ls) ls'.
  Proof.
    revert n ls'; induction ls; drop_take_t.
  Qed.

  Lemma fold_right_and_map_impl {A} {init1 init2 : Prop} (H : init1 -> init2) (ls : list A) (f g : A -> Prop) (H' : forall x, f x -> g x)
  : fold_right and init1 (map f ls) -> fold_right and init2 (map g ls).
  Proof.
    induction ls; simpl; trivial; intuition.
  Qed.

  Lemma f_fold_right_bool_rect {A B T} (f : T -> B) init (ls : list A) a b
  : f (fold_right (fun x acc => bool_rect (fun _ => T) (a x) acc (b x)) init ls)
    = fold_right (fun x acc => bool_rect (fun _ => B) (f (a x)) acc (b x)) (f init) ls.
  Proof.
    revert init; induction ls; simpl; trivial; intros.
    edestruct b; simpl; trivial.
  Qed.

  Lemma fold_right_fun {A B C} (f : A -> C -> (B -> C)) (init : B -> C) (x : B) (ls : list A)
  : fold_right (fun (a : A) (b : B -> C) x => f a (b x) x) init ls x
    = fold_right (B := A) (A := C) (fun a b => f a b x) (init x) ls.
  Proof.
    induction ls; simpl; trivial.
    rewrite IHls; reflexivity.
  Qed.

  Lemma nth_tl {A} n (ls : list A) a
  : nth n (tl ls) a = nth (S n) ls a.
  Proof.
    destruct ls, n; simpl; reflexivity.
  Qed.

  Lemma nth_drop {A} x y (ls : list A) a
  : nth x (drop y ls) a = nth (x + y) ls a.
  Proof.
    revert x y; induction ls; simpl; intros.
    { destruct x, y; reflexivity. }
    { destruct y; simpl.
      { destruct x; simpl; repeat (f_equal; []); try reflexivity; omega. }
      { rewrite IHls; destruct x; simpl; repeat (f_equal; []); try reflexivity; omega. } }
  Qed.

  Lemma nth_error_drop {A} x y (ls : list A)
  : nth_error (drop y ls) x = nth_error ls (x + y).
  Proof.
    revert x y; induction ls; simpl; intros.
    { destruct x, y; reflexivity. }
    { destruct y; simpl.
      { destruct x; simpl; repeat (f_equal; []); try reflexivity; omega. }
      { rewrite IHls; destruct x; simpl; repeat (f_equal; []); try reflexivity.
        rewrite NPeano.Nat.add_succ_r; reflexivity. } }
  Qed.

  Lemma in_map_iffT' {A B}
        (f : A -> B) (ls : list A) (y : B)
        (eq_dec : forall y', {y = y'} + {y <> y'})
  : iffT (In y (map f ls)) { x : A | f x = y /\ In x ls }.
  Proof.
    split; [ | intros [x H]; apply in_map_iff; exists x; assumption ].
    induction ls as [|l ls IHls].
    { simpl; intros []. }
    { simpl.
      intro H.
      destruct (eq_dec (f l)) as [e|e].
      { exists l; split.
        { clear -e; abstract (subst; reflexivity). }
        { left. reflexivity. } }
      { destruct IHls as [x H'].
        { clear -H e.
          abstract (destruct H; congruence). }
        { eexists.
          split; [ apply H' | right; apply H' ]. } } }
  Defined.

  Lemma in_map_iffT {A B}
        (eq_dec : forall y y' : B, {y = y'} + {y <> y'})
        (f : A -> B) (ls : list A) (y : B)
  : iffT (In y (map f ls)) { x : A | f x = y /\ In x ls }.
  Proof.
    apply in_map_iffT', eq_dec.
  Defined.

  Lemma in_map_iffT_nat {A}
        (f : A -> nat) (ls : list A) (y : nat)
  : iffT (In y (map f ls)) { x : A | f x = y /\ In x ls }.
  Proof.
    apply in_map_iffT, NPeano.Nat.eq_dec.
  Defined.

  Lemma nth_take_1_drop {A} (ls : list A) n a
  : nth n ls a = match take 1 (drop n ls) with
                   | nil => a
                   | x::_ => x
                 end.
  Proof.
    revert n.
    induction ls as [|x xs IHxs]; simpl; intros.
    { destruct n; reflexivity. }
    { destruct n; simpl; trivial; [].
      rewrite IHxs; simpl; reflexivity. }
  Qed.

  Lemma drop_drop {A} x y (ls : list A)
  : drop x (drop y ls) = drop (y + x) ls.
  Proof.
    revert x y.
    induction ls as [|l ls IHls].
    { intros [|x] [|y]; reflexivity. }
    { intros x [|y]; simpl.
      { reflexivity. }
      { apply IHls. } }
  Defined.

  Lemma drop_dropS {A} y (ls : list A)
  : drop 1 (drop y ls) = drop (S y) ls.
  Proof.
    rewrite drop_drop.
    rewrite NPeano.Nat.add_1_r.
    reflexivity.
  Qed.

  Lemma map_S_seq {A} (f : nat -> A) x y
  : map (fun i => f (S i)) (seq x y) = map f (seq (S x) y).
  Proof.
    clear; revert x; induction y; intros.
    { reflexivity. }
    { simpl.
      rewrite IHy; reflexivity. }
  Qed.

  Lemma length_drop {A} (n : nat) (ls : list A)
  : List.length (List.drop n ls) = List.length ls - n.
  Proof.
    revert ls; induction n; simpl; intros.
    { auto with arith. }
    { destruct ls; simpl; [ reflexivity | ].
      apply IHn. }
  Qed.

  Lemma drop_non_empty {A} (n : nat) (ls : list A)
        (H : ls <> nil)
  : List.drop (List.length ls - S n) ls <> nil.
  Proof.
    intro H'.
    apply (f_equal (@List.length _)) in H'.
    simpl in H'.
    rewrite length_drop in H'.
    destruct ls.
    { apply H; reflexivity. }
    { simpl length in H'.
      omega. }
  Qed.

  Lemma drop_S_non_empty {A} (n : nat) (ls : list A)
        (H : n < List.length ls)
  : List.drop (List.length ls - S n) ls <> nil.
  Proof.
    intro H'.
    apply (f_equal (@List.length _)) in H'.
    simpl in H'.
    rewrite length_drop in H'.
    omega.
  Qed.

  Lemma seq_S (start len : nat)
  : seq (S start) len = map S (seq start len).
  Proof.
    revert start; induction len; [ reflexivity | ].
    simpl in *; intros.
    rewrite IHlen; reflexivity.
  Qed.

  Lemma seq_0 (start len : nat)
  : seq start len = map (fun x => start + x) (seq 0 len).
  Proof.
    revert start; induction len; simpl; intros.
    { reflexivity. }
    { rewrite IHlen; simpl.
      rewrite seq_S.
      rewrite map_map.
      apply f_equal2.
      { omega. }
      { apply map_ext; intro; omega. } }
  Qed.

  Lemma seq_alt (start len : nat)
  : seq start len = match len with
                      | 0 => nil
                      | S len' => start :: map S (seq start len')
                    end.
  Proof.
    destruct len; simpl.
    { reflexivity. }
    { apply f_equal2.
      { reflexivity. }
      { rewrite seq_S.
        reflexivity. } }
  Qed.

  Lemma In_S_seq {start len x} (Hsmall : start <= x) (H : In (S x) (seq start len))
  : In x (seq start len).
  Proof.
    generalize dependent start; generalize x; induction len; intros; simpl in *.
    { assumption. }
    { destruct H as [H|H].
      { exfalso; omega. }
      { simpl in *.
        destruct (lt_eq_lt_dec start x0) as [[H' | H'] | H'];
          [ right; apply IHlen; assumption
          | left; assumption
          | exfalso; omega ]. } }
  Qed.

  Lemma uniquize_idempotent {A} (beq : A -> A -> bool) (ls : list A)
  : uniquize beq (uniquize beq ls) = uniquize beq ls.
  Proof.
    induction ls as [|x xs IHxs]; simpl; trivial.
    destruct (Equality.list_bin beq x (uniquize beq xs)) eqn:H;
      simpl;
      rewrite ?IHxs, ?H; reflexivity.
  Qed.

  Lemma uniquize_NoDupA {A} (beq : A -> A -> bool) (ls : list A)
  : NoDupA (fun x y => beq y x) (uniquize beq ls).
  Proof.
    induction ls as [|x xs IHxs]; simpl; [ solve [ constructor ] | ].
    destruct (Equality.list_bin beq x (uniquize beq xs)) eqn:H; trivial.
    constructor; trivial.
    intro H'.
    apply Equality.list_inA_lb in H'.
    congruence.
  Qed.

  Lemma uniquize_NoDup {A} (beq : A -> A -> bool) (beq_lb : forall x y, x = y -> beq x y = true) (ls : list A)
  : NoDup (uniquize beq ls).
  Proof.
    eapply NoDupA_NoDup; [ | apply uniquize_NoDupA ].
    repeat intro; eauto.
  Qed.

  Lemma NoDupA_uniquize {A} (beq : A -> A -> bool) (ls : list A) (H : NoDupA (fun x y => beq y x) ls)
  : uniquize beq ls = ls.
  Proof.
    induction ls as [|x xs IHxs]; simpl; [ solve [ constructor ] | ].
    inversion H; subst.
    rewrite IHxs by assumption; clear IHxs.
    destruct (Equality.list_bin beq x xs) eqn:H'; trivial.
    exfalso.
    apply Equality.list_inA_bl in H'.
    tauto.
  Qed.

  Lemma NoDup_NoDupA {A} (R : relation A) (ls : list A) (R_eq : forall x y, R x y -> x = y) (H : NoDup ls)
  : NoDupA R ls.
  Proof.
    induction ls; [ solve [ constructor ] | ].
    inversion H; subst.
    constructor; auto.
    rewrite InA_alt.
    intros [y [H' H'']].
    match goal with
      | [ H : _ |- _ ] => apply R_eq in H; subst
    end.
    tauto.
  Qed.

  Lemma NoDup_uniquize {A} (beq : A -> A -> bool) (beq_bl : forall x y, beq x y = true -> x = y) (ls : list A) (H : NoDup ls)
  : uniquize beq ls = ls.
  Proof.
    apply NoDupA_uniquize, NoDup_NoDupA; trivial; intros.
    symmetry; eauto.
  Qed.

  Lemma uniquize_shorter {A} (ls : list A) beq
  : List.length (uniquize beq ls) <= List.length ls.
  Proof.
    induction ls as [|x xs IHxs]; simpl; trivial.
    edestruct @Equality.list_bin; simpl; omega.
  Qed.

  Lemma uniquize_length {A} (ls : list A) beq
  : List.length (uniquize beq ls) = List.length ls
    <-> uniquize beq ls = ls.
  Proof.
    induction ls as [|x xs IHxs]; simpl; try (split; reflexivity).
    edestruct @Equality.list_bin; simpl.
    { pose proof (uniquize_shorter xs beq).
      split; intro H'.
      { omega. }
      { apply (f_equal (@List.length _)) in H'.
        simpl in H'.
        omega. } }
    { destruct IHxs.
      split; intro;
      first [ congruence
            | f_equal; auto ]. }
  Qed.

  Lemma uniquize_In {A} (ls : list A) (beq : A -> A -> bool) x
  : In x (uniquize beq ls) -> In x ls.
  Proof.
    intro H; induction ls as [|y ys IHys]; simpl in *; trivial.
    destruct (Equality.list_bin beq y (uniquize beq ys)) eqn:H'.
    { right; eauto with nocore. }
    { destruct H.
      { left; assumption. }
      { right; eauto with nocore. } }
  Qed.

  Lemma uniquize_In_refl {A} (ls : list A) (beq : A -> A -> bool) x (refl : beq x x = true) (bl : forall x y, beq x y = true -> x = y)
  : In x ls -> In x (uniquize beq ls).
  Proof.
    intro H; induction ls as [|y ys IHys]; simpl in *; trivial.
    destruct (Equality.list_bin beq y (uniquize beq ys)) eqn:H';
      destruct H; subst;
      eauto with nocore.
    { apply Equality.list_in_bl in H'; assumption. }
    { left; reflexivity. }
    { right; eauto with nocore. }
  Qed.

  Lemma uniquize_In_refl_iff {A} (ls : list A) (beq : A -> A -> bool) x (refl : beq x x = true) (bl : forall x y, beq x y = true -> x = y)
  : In x ls <-> In x (uniquize beq ls).
  Proof.
    split; first [ apply uniquize_In | apply uniquize_In_refl ]; assumption.
  Qed.

  Lemma fold_right_bool_rect {T} t b init ls' bv
  : fold_right (fun (x : T) (acc : bool -> bool)
                => bool_rect
                     (fun _ => bool -> bool)
                     (t x)
                     acc
                     (b x))
               init ls' bv
    = fold_right (fun (x : T) (acc : bool)
                  => bool_rect
                       (fun _ => bool)
                       (t x bv)
                       acc
                       (b x)) (init bv) ls'.
  Proof.
    induction ls' as [|x xs IHxs]; simpl;
    [ | destruct (b x); simpl; rewrite ?IHxs ];
    reflexivity.
  Qed.

  Lemma in_up_to {n m} (H : n < m) : List.In n (up_to m).
  Proof.
    revert n H; induction m; intros n H.
    { exfalso; omega. }
    { simpl.
      hnf in H.
      apply le_S_n in H.
      apply Compare_dec.le_lt_eq_dec in H.
      destruct H; subst; [ right; eauto | left; reflexivity ]. }
  Qed.

  Lemma in_up_to_iff {n m} : (n < m) <-> List.In n (up_to m).
  Proof.
    revert n; induction m; intros n; simpl.
    { split; intro; exfalso; omega. }
    { simpl.
      specialize (IHm n).
      destruct IHm.
      destruct (lt_eq_lt_dec n m) as [[?|?]|?]; split; intros; try omega; eauto; intuition. }
  Qed.

  Lemma first_index_helper_first_index_error
        {A B} (f : A -> bool)
        (rect : option (nat * A) -> B) (ls : list A) (rec : nat * A -> nat * A)
  : first_index_helper f rect ls rec
    = rect (let idx := first_index_error f ls in
            let v := option_rect (fun _ => option A) (nth_error ls) None idx in
            option_map
              rec
              (option_rect
                 (fun _ => option (nat * A))
                 (fun v' : A => option_map (fun idx' : nat => (idx', v')) idx)
                 None
                 v)).
  Proof.
    revert B rec rect; induction ls as [|x xs IHxs]; simpl; intros.
    { reflexivity. }
    { destruct (f x).
      { reflexivity. }
      { rewrite !IHxs.
        destruct (first_index_error f xs) as [idx|] eqn:Heq;
          simpl; [ | reflexivity ].
        destruct (nth_error xs idx) eqn:Heq'; simpl; [ | reflexivity ].
        rewrite Heq'; simpl.
        reflexivity. } }
  Qed.

  Local Ltac first_index_error_t'
    := idtac;
      match goal with
        | _ => discriminate
        | _ => congruence
        | _ => omega
        | _ => progress unfold value in *
        | [ H : Some _ = Some _ |- _ ] => inversion H; clear H
        | _ => progress subst
        | [ H : ?x = true |- context[?x] ] => rewrite H
        | [ H : and _ _ |- _ ] => destruct H
        | [ H : ex _ |- _ ] => destruct H
        | [ H : iff _ _ |- _ ] => destruct H
        | [ H : ?x = ?x -> ?A |- _ ] => specialize (H eq_refl)
        | _ => progress intros
        | _ => split
        | [ H : context[if ?b then _ else _] |- _ ] => destruct b eqn:?
        | [ H : context[option_map _ ?x] |- _ ] => destruct x eqn:?; unfold option_map in H
        | _ => solve [ repeat (esplit || eassumption) ]
        | [ H : context[nth_error (_::_) ?x] |- _ ] => is_var x; destruct x; simpl nth_error in H
        | [ H : S _ < S _ |- _ ] => apply lt_S_n in H
        | _ => solve [ eauto with nocore ]
        | [ |- context[if ?b then _ else _] ] => destruct b eqn:?
        | [ H : ?A -> ?B |- _ ] => let H' := fresh in assert (H' : A) by (assumption || omega); specialize (H H'); clear H'
        | [ H : forall n, n < S _ -> _ |- _ ] => pose proof (H 0); specialize (fun n => H (S n))
        | _ => progress simpl in *
        | [ H : forall x, ?f x = ?f ?y -> _ |- _ ] => specialize (H _ eq_refl)
        | [ H : forall x, ?f ?y = ?f x -> _ |- _ ] => specialize (H _ eq_refl)
        | [ H : forall n, S n < S _ -> _ |- _ ] => specialize (fun n pf => H n (lt_n_S _ _ pf))
        | [ H : nth_error nil ?x = Some _ |- _ ] => is_var x; destruct x
        | [ H : forall m x, nth_error (_::_) m = Some _ -> _ |- _ ] => pose proof (H 0); specialize (fun m => H (S m))
        | [ H : or _ _ |- _ ] => destruct H
        | [ H : forall x, _ = x \/ _ -> _ |- _ ] => pose proof (H _ (or_introl eq_refl)); specialize (fun x pf => H x (or_intror pf))
        | [ H : ?x = None |- context[?x] ] => rewrite H
        | [ H : S _ = S _ |- _ ] => inversion H; clear H
        | [ H : appcontext[first_index_helper] |- _ ] => rewrite first_index_helper_first_index_error in H
        | [ |- appcontext[first_index_helper] ] => rewrite first_index_helper_first_index_error
        | [ H : option_rect _ _ _ ?v = Some _ |- _ ] => destruct v eqn:?; simpl in H
        | [ H : option_rect _ _ _ ?v = None |- _ ] => destruct v eqn:?; simpl in H
      end.

  Local Ltac first_index_error_t :=
    repeat match goal with
             | _ => progress first_index_error_t'
             | [ H : _ |- _ ] => rewrite H by repeat first_index_error_t'
           end.

  Lemma first_index_error_Some_correct {A} (P : A -> bool) (n : nat) (ls : list A)
  : first_index_error P ls = Some n <-> ((exists elem, nth_error ls n = Some elem /\ P elem = true)
                                         /\ forall m, m < n -> forall elem, nth_error ls m = Some elem -> P elem = false).
  Proof.
    revert n.
    induction ls; simpl; intros.
    { destruct n; first_index_error_t. }
    { specialize (IHls (pred n)).
      destruct n; first_index_error_t. }
  Qed.

  Lemma first_index_error_None_correct {A} (P : A -> bool) (ls : list A)
  : first_index_error P ls = None <-> (forall elem, List.In elem ls -> P elem = false).
  Proof.
    induction ls; simpl; intros.
    { first_index_error_t. }
    { first_index_error_t.
      match goal with
        | [ H : first_index_error _ _ = Some _ |- _ ] => apply first_index_error_Some_correct in H
      end.
      first_index_error_t. }
  Qed.

  Lemma first_index_default_first_index_error
        {A} (f : A -> bool)
        default
        (ls : list A)
  : first_index_default f default ls
    = option_rect (fun _ => nat) (fun x => x) default (first_index_error f ls).
  Proof.
    unfold first_index_default.
    rewrite first_index_helper_first_index_error; simpl.
    destruct (first_index_error f ls) as [n|] eqn:H; simpl; [ | reflexivity ].
    destruct (nth_error ls n) eqn:H'; simpl; [ reflexivity | ].
    exfalso.
    apply first_index_error_Some_correct in H.
    repeat (destruct_head and; destruct_head ex).
    congruence.
  Qed.

  Lemma nth_error_In {A} (n : nat) (x : A) (ls : list A)
  : nth_error ls n = Some x -> List.In x ls.
  Proof.
    revert n; induction ls; intros [|n]; simpl in *;
    intros; try discriminate; unfold value in *.
    { left; congruence. }
    { right; eauto. }
  Qed.

  Lemma nth_error_None_long {A} (n : nat) (ls : list A)
  : nth_error ls n = None <-> List.length ls <= n.
  Proof.
    revert n; induction ls;
    intros [|n]; try (specialize (IHls n); destruct IHls);
    simpl in *; split; intros;
    unfold value in *;
    try (reflexivity || omega || congruence);
    intuition.
  Qed.

  Lemma nth_error_Some_short {A} (n : nat) (x : A) (ls : list A)
  : nth_error ls n = Some x -> n < List.length ls.
  Proof.
    destruct (le_lt_dec (List.length ls) n) as [H|H];
    intro H'; trivial.
    apply nth_error_None_long in H; congruence.
  Qed.

  Lemma nth_error_nth {A} (ls : list A) (n : nat) (y : A)
  : nth n ls y = match nth_error ls n with
                   | Some x => x
                   | None => y
                 end.
  Proof.
    revert n; induction ls; intros [|n]; simpl in *; intros;
    try discriminate;
    unfold value in *;
    eauto.
  Qed.

  Lemma nth_error_Some_nth {A} (ls : list A) (n : nat) (x : A)
  : nth_error ls n = Some x -> forall y, nth n ls y = x.
  Proof.
    intros H ?; rewrite nth_error_nth, H; reflexivity.
  Qed.

  Lemma length_up_to n
  : List.length (up_to n) = n.
  Proof.
    induction n; simpl; auto.
  Qed.

  Lemma filter_out_filter {A} f (ls : list A)
  :  filter_out f ls = filter (fun x => negb (f x)) ls.
  Proof.
    induction ls; simpl; trivial; rewrite !IHls; edestruct f; reflexivity.
  Qed.

  Lemma filter_filter_out {A} f (ls : list A)
  :  filter f ls = filter_out (fun x => negb (f x)) ls.
  Proof.
    induction ls; simpl; trivial; rewrite !IHls; edestruct f; reflexivity.
  Qed.

  Lemma nth'_helper_nth {A} n ls (default : A) offset (H : offset <= n)
  : nth'_helper n ls default offset = nth (n - offset) ls default.
  Proof.
    revert n default offset H.
    induction ls as [|x xs IHxs].
    { simpl; intros; destruct (n - offset); reflexivity. }
    { simpl; intros.
      destruct (beq_nat n offset) eqn:H';
        [ apply beq_nat_true in H'
        | apply beq_nat_false in H' ];
        subst;
        rewrite ?minus_diag; trivial.
      destruct (n - offset) eqn:H''.
      { omega. }
      { rewrite IHxs by omega.
        f_equal.
        omega. } }
  Qed.

  Lemma nth'_nth {A} n ls (default : A)
  : nth' n ls default = nth n ls default.
  Proof.
    change (nth'_helper n ls default 0 = nth n ls default).
    rewrite nth'_helper_nth by omega.
    f_equal; omega.
  Qed.


  Lemma NoDup_filter {A} :
    forall (f : A -> bool)
           (l : list A),
      NoDup l
      -> NoDup (filter f l).
  Proof.
    induction l; simpl.
    - constructor.
    - case_eq (f a); simpl; intros.
      + inversion H0; constructor; eauto.
        subst; unfold not; intros H1;
        apply filter_In in H1; intuition.
      + inversion H0; eauto.
  Qed.

  Lemma eqlistA_app_iff {A} (R : relation A) (x y z : list A)
  : SetoidList.eqlistA R (x ++ y) z <-> (exists x' y', (x' ++ y' = z)%list /\ SetoidList.eqlistA R x x' /\ SetoidList.eqlistA R y y').
  Proof.
    revert z.
    induction x as [|x xs IHxs]; simpl; intros z;
    split; intro H.
    { eexists nil; eexists z; split; [ reflexivity | ].
      split; first [ assumption | constructor ]. }
    { destruct H as [x' [y' [H0 [H1 H2]]]]; subst.
      inversion H1; subst; simpl.
      assumption. }
    { inversion_clear H.
      match goal with
        | [ H : SetoidList.eqlistA _ _ _ |- _ ]
          => apply IHxs in H; clear IHxs
      end.
      repeat match goal with
               | [ H : ex _ |- _ ] => destruct H
               | [ H : and _ _ |- _ ] => destruct H
               | _ => progress subst
             end.
      eexists (_::_)%list; simpl; eexists.
      repeat split; first [ assumption | constructor; assumption ]. }
    { repeat match goal with
               | [ H : ex _ |- _ ] => destruct H
               | [ H : and _ _ |- _ ] => destruct H
               | _ => progress subst
               | [ H : SetoidList.eqlistA _ (_::_) _ |- _ ] => inversion H; clear H
               | _ => progress simpl
               | [ |- SetoidList.eqlistA _ (_::_) (_::_) ] => constructor
               | _ => assumption
             end.
      apply IHxs.
      repeat esplit; eassumption. }
  Qed.

  Lemma eqlistA_eq {A} ls ls'
  : @SetoidList.eqlistA A eq ls ls' <-> ls = ls'.
  Proof.
    split; intro H; subst; try reflexivity.
    revert ls' H.
    induction ls as [|x xs IHxs]; intros []; intros;
    f_equal;
    inversion H; subst; trivial; eauto with nocore.
  Qed.

  Lemma fold_left_orb_true (ls : list bool)
  : fold_left orb ls true = true.
  Proof.
    induction ls; simpl; trivial.
  Qed.

  Lemma Forall_tails_id {A P} (ls : list A)
        (H : Forall_tails P ls)
  : P ls.
  Proof.
    destruct ls; simpl in *; try assumption.
    destruct H; assumption.
  Defined.

  Lemma Forall_tails_app {A P} (ls ls' : list A)
        (H : Forall_tails P (ls ++ ls'))
  : Forall_tails P ls'.
  Proof.
    induction ls; simpl in *; trivial.
    destruct H; auto.
  Defined.

  Lemma first_index_default_S_cons {A f k} {x} {xs : list A}
  : first_index_default f (S k) (x::xs) = if (f x) then 0 else S (first_index_default f k xs).
  Proof.
    simpl.
    rewrite first_index_default_first_index_error.
    rewrite first_index_helper_first_index_error; simpl.
    destruct (first_index_error f xs) eqn:H, (f x); trivial; simpl.
    apply first_index_error_Some_correct in H.
    repeat (destruct_head and; destruct_head ex).
    match goal with
      | [ H : ?x = Some _ |- context[?x] ] => rewrite H
    end.
    reflexivity.
  Qed.

  Definition Forall_ForallT_step
             (Forall_ForallT
              : forall A P ls,
                forall ls' ls'', ls = ls' -> ls = ls''
                                 -> (@Forall A P ls' <-> inhabited (@ForallT A P ls'')))
             A P ls
  : forall ls' ls'', ls = ls' -> ls = ls'' -> (@Forall A P ls' <-> inhabited (@ForallT A P ls'')).
  Proof.
    intros ls' ls'' H' H''; split; [ intro H | intros [H] ];
    (destruct ls as [|x xs];
     [
     | specialize (@Forall_ForallT A P xs (tl ls') (tl ls'') (f_equal (@tl _) H') (f_equal (@tl _) H''));
       pose proof (proj1' Forall_ForallT);
       pose proof (proj2' Forall_ForallT) ]);
    clear Forall_ForallT;
    simpl in *;
    repeat match goal with
             | [ H : nil = ?ls |- inhabited (ForallT _ ?ls) ] => clear -H; solve [ repeat first [ constructor | subst ] ]
           end;
    try solve [ repeat constructor ]; simpl in *.
    { destruct H;
      try (exfalso; clear -H'; abstract congruence);
      simpl in *;
      specialize_by assumption;
      destruct_head inhabited;
      constructor.
      destruct ls'';
        try (exfalso; clear -H''; abstract congruence).
      simpl in *.
      repeat first [ assumption | constructor ].
      apply (f_equal (hd x)) in H''.
      apply (f_equal (hd x)) in H'.
      simpl in *.
      clear -H H'' H'.
      pose proof (eq_trans (eq_sym H') H'') as H'''; clear H' H''.
      subst; assumption. }
    { clear -H'; subst; constructor. }
    { destruct ls';
      try (exfalso; clear -H'; abstract congruence);
      simpl in *.
      destruct ls'';
        try (exfalso; clear -H''; abstract congruence);
        simpl in *.
      destruct_head prod.
      specialize_by ltac:(repeat first [ assumption | constructor ]).
      repeat first [ assumption | constructor ].
      apply (f_equal (hd x)) in H''.
      apply (f_equal (hd x)) in H'.
      simpl in *.
      clear -p H'' H'.
      pose proof (eq_trans (eq_sym H') H'') as H'''; clear H' H''.
      subst; assumption. }
  Defined.

  Global Arguments Forall_ForallT_step {_ _ _} _ _ _ _ _ : simpl never.

  Fixpoint Forall_ForallT' A P ls {struct ls}
  : forall ls' ls'', ls = ls' -> ls = ls'' -> (@Forall A P ls' <-> inhabited (@ForallT A P ls''))
    := @Forall_ForallT_step (@Forall_ForallT') A P ls.
  Global Arguments Forall_ForallT' {_ _ _} _ _ _ _.
  Definition Forall_ForallT A P ls
  : @Forall A P ls <-> inhabited (@ForallT A P ls)
    := @Forall_ForallT' A P ls ls ls eq_refl eq_refl.
  Global Arguments Forall_ForallT {_ _ _}.

  Lemma step_Forall_ForallT' {A P ls ls' ls'' H' H''}
  : @Forall_ForallT' A P ls ls' ls'' H' H'' = @Forall_ForallT_step (@Forall_ForallT') A P ls ls' ls'' H' H''.
  Proof.
    destruct ls; reflexivity.
  Defined.

  Fixpoint Forall_ForallT_Forall_eq {A P ls} (x : @Forall A P ls) {struct x}
  : proj2' Forall_ForallT (proj1' Forall_ForallT x) = x.
  Proof.
    unfold Forall_ForallT in *.
    destruct x as [|? xs p ps]; simpl in *;
    [ | specialize (@Forall_ForallT_Forall_eq A P xs ps) ].
    { reflexivity. }
    { edestruct (@Forall_ForallT');
      unfold eq_ind_r.
      simpl in *.
      match goal with
        | [ |- context[match ?f ?x with _ => _ end] ]
          => destruct (f x) eqn:H'
      end.
      rewrite Forall_ForallT_Forall_eq; reflexivity. }
  Qed.

  Fixpoint ForallT_Forall_ForallT_eq {A} {P : A -> Prop} ls (x : inhabited (@ForallT A P ls)) {struct ls}
  : proj1' Forall_ForallT (proj2' (@Forall_ForallT A P ls) x) = x.
  Proof.
    unfold Forall_ForallT in *.
    destruct ls as [|v vs];
      [ clear ForallT_Forall_ForallT_eq | specialize (@ForallT_Forall_ForallT_eq A P vs) ];
      simpl in *;
      destruct_head inhabited;
      destruct_head prod;
      destruct_head True.
    { reflexivity. }
    { match goal with
        | [ x : _ |- _ ] => specialize (ForallT_Forall_ForallT_eq (inhabits x))
      end.
      unfold eq_ind_r in *; simpl in *.
      edestruct (@Forall_ForallT'); simpl in *.
      repeat (rewrite ForallT_Forall_ForallT_eq; simpl).
      reflexivity. }
  Qed.

  Fixpoint ForallT_code A P ls {struct ls} : @ForallT A P ls -> @ForallT A P ls -> Prop
    := match ls return @ForallT A P ls -> @ForallT A P ls -> Prop with
         | nil => fun _ _ => True
         | x::xs => fun H H' => fst H = fst H' /\ @ForallT_code A P xs (snd H) (snd H')
       end.
  Global Arguments ForallT_code {A P ls} _ _.
  Fixpoint ForallT_encode A P ls {struct ls}
  : forall (x y : @ForallT A P ls), x = y -> ForallT_code x y.
  Proof.
    destruct ls as [|v vs]; simpl; intros x y p.
    { constructor. }
    { specialize (@ForallT_encode A P vs (snd x) (snd y) (f_equal snd p)).
      apply (f_equal fst) in p.
      split; assumption. }
  Defined.
  Global Arguments ForallT_encode {A P ls} {_ _} _.
  Fixpoint ForallT_decode A P ls {struct ls}
  : forall (x y : @ForallT A P ls), ForallT_code x y -> x = y.
  Proof.
    destruct ls as [|v vs]; simpl; intros x y p.
    { destruct x, y; reflexivity. }
    { apply injective_projections'.
      { apply p. }
      { apply ForallT_decode, p. } }
  Defined.
  Global Arguments ForallT_decode {A P ls} {_ _} _.
  Fixpoint ForallT_endecode A P ls {struct ls}
  : forall (x y : @ForallT A P ls) p, @ForallT_encode A P ls x y (ForallT_decode p) = p.
  Proof.
    destruct ls as [|v vs]; simpl; intros x y p.
    { destruct p; reflexivity. }
    { destruct p as [p0 p1], x, y; simpl in *.
      destruct p0; simpl in *.
      apply f_equal2;
        [ rewrite f_equal_fst_injective_projections'
        | rewrite f_equal_snd_injective_projections' ];
        eauto. }
  Qed.
  Fixpoint ForallT_deencode A P ls {struct ls}
  : forall (x y : @ForallT A P ls) p, @ForallT_decode A P ls x y (ForallT_encode p) = p.
  Proof.
    destruct ls as [|v vs]; simpl; intros x y p.
    { destruct p, x; reflexivity. }
    { rewrite ForallT_deencode.
      destruct p, x; reflexivity. }
  Qed.

  Lemma Forall_proof_irrelevance {A P ls} (x y : @Forall A P ls)
        (pi : forall a (x y : P a), x = y)
  : x = y.
  Proof.
    rewrite <- (Forall_ForallT_Forall_eq x), <- (Forall_ForallT_Forall_eq y).
    apply f_equal.
    induction ls as [|v vs IHvs].
    { reflexivity. }
    { unfold Forall_ForallT in *.
      revert IHvs.
      set (ls := v::vs).
      set (ls' := v::vs).
      set (ls'' := v::vs).
      pose (eq_refl : v::vs = ls) as H.
      pose (eq_refl : ls = ls') as H'.
      pose (eq_refl : ls = ls'') as H''.
      change (v::vs) with ls' in x.
      change (v::vs) with ls'' in y.
      change
        ((forall (x0 : Forall P (tl ls')) (y0 : Forall P (tl ls'')),
            proj1' (Forall_ForallT' (tl ls') (tl ls'') (f_equal (@tl _) H') (f_equal (@tl _) H'')) x0
            = proj1' (Forall_ForallT' (tl ls'') (tl ls'') (f_equal (@tl _) H'') (f_equal (@tl _) H'')) y0)
         -> proj1' (Forall_ForallT' ls' ls'' H' H'') x
            = proj1' (Forall_ForallT' ls'' ls'' H'' H'') y).
      clearbody H H' H'' ls ls' ls''.
      intro IHvs.
      rewrite !step_Forall_ForallT'.
      simpl.
      destruct ls, x, y; try congruence.
      simpl in *.
      erewrite IHvs; clear IHvs.
      match goal with
        | [ |- match ?e with _ => _ end = match ?e' with _ => _ end ]
          => unify e e'; destruct e
      end.
      unfold eq_ind_r; simpl.
      repeat (f_equal; []).
      repeat match goal with
               | _ => intro
               | _ => progress simpl in *
               | _ => progress subst
               | _ => solve [ eauto with nocore ]
               | [ |- context[f_equal ?f ?H] ]
                 => generalize (f_equal f H); clear H
             end. }
  Qed.

  Lemma In_InT {A} (x : A) (ls : list A) (H : InT x ls)
  : In x ls.
  Proof.
    induction ls as [|y ys IHys]; simpl in *; trivial.
    destruct H; [ left | right ]; eauto with nocore.
  Qed.

  Lemma tl_drop {A} (ls : list A) (n : nat)
  : tl (List.drop n ls) = List.drop n (tl ls).
  Proof.
    revert n; induction ls as [|x xs IHxs].
    { intros [|?]; reflexivity. }
    { simpl.
      destruct n; simpl; trivial.
      rewrite IHxs; destruct xs; trivial; simpl.
      apply drop_all; simpl; omega. }
  Qed.

  Lemma map_ext_in {A B} (f f' : A -> B) (ls : list A)
        (H : forall a, List.In a ls -> f a = f' a)
  : List.map f ls = List.map f' ls.
  Proof.
    induction ls; simpl; trivial.
    rewrite H, IHls.
    { reflexivity. }
    { intros; apply H; right; assumption. }
    { left; reflexivity. }
  Qed.

  Lemma list_bin_map {A B} (f : A -> B) (beq : B -> B -> bool) (ls : list A) x
  : list_bin beq (f x) (map f ls) = list_bin (fun x y => beq (f x) (f y)) x ls.
  Proof.
    induction ls; trivial; simpl.
    rewrite IHls; reflexivity.
  Qed.

  Lemma uniquize_map {A B} (f : A -> B) (beq : B -> B -> bool) (ls : list A)
  : uniquize beq (map f ls) = map f (uniquize (fun x y => beq (f x) (f y)) ls).
  Proof.
    induction ls; trivial; simpl.
    rewrite !IHls, list_bin_map.
    edestruct @list_bin; simpl; reflexivity.
  Qed.

  Definition list_rect_In {A} (P : list A -> Type)
             (ls : list A)
             (Hnil : P nil)
             (Hcons : forall x xs, In x ls -> P xs -> P (x::xs))
  : P ls.
  Proof.
    induction ls as [|x xs IHxs]; [ assumption | ].
    apply Hcons.
    { left; reflexivity. }
    { apply IHxs; intros x' xs' H'.
      apply Hcons.
      right; exact H'. }
  Defined.

  Lemma fold_right_and_True_app ls ls'
  : fold_right and True (ls ++ ls') <-> (fold_right and True ls /\ fold_right and True ls').
  Proof.
    revert ls'; induction ls as [|?? IHls]; simpl; intros; try tauto.
    rewrite IHls; clear IHls.
    tauto.
  Qed.

  Lemma fold_right_and_True_flatten ls
  : fold_right and True (flatten ls) <-> fold_right and True (map (fold_right and True) ls).
  Proof.
    induction ls as [|?? IHls]; try tauto; simpl.
    rewrite <- IHls; clear IHls.
    rewrite fold_right_and_True_app; reflexivity.
  Qed.

  Lemma NoDup_app {A} (ls ls' : list A)
  : NoDup (ls ++ ls') -> NoDup ls /\ NoDup ls'.
  Proof.
    induction ls; simpl; intro H; split; trivial; try constructor;
    simpl in *.
    { inversion H; subst.
      eauto using in_or_app. }
    { apply IHls.
      inversion H; subst; assumption. }
    { apply IHls; inversion H; subst; assumption. }
  Qed.
  Lemma NoDup_app_in {A} (ls ls' : list A) (x : A) (H : NoDup (ls ++ ls'))
  : In x ls' -> In x ls -> False.
  Proof.
    intros H0 H1.
    induction ls as [|?? IHls]; simpl in *; trivial.
    destruct H1; inversion H; clear H; subst; eauto.
    rewrite in_app_iff in *.
    eauto.
  Qed.

  Lemma NoDup_app_in_iff {A} (ls ls' : list A)
  : NoDup (ls ++ ls') <-> (NoDup ls /\ NoDup ls' /\
                           forall x, In x ls' -> In x ls -> False).
  Proof.
    induction ls as [|?? IHls]; simpl in *; trivial;
    repeat (split || intro);
    repeat match goal with
             | _ => solve [ constructor ]
             | _ => assumption
             | _ => progress simpl in *
             | _ => progress destruct_head and
             | _ => progress destruct_head iff
             | _ => progress split_and
             | _ => progress subst
             | _ => progress specialize_by assumption
             | _ => progress specialize_by tauto
             | [ H : NoDup (_::_) |- _ ] => inversion H; clear H
             | [ |- NoDup (_::_) ] => constructor
             | [ H : _ |- _ ] => rewrite in_app_iff in H
             | _ => rewrite in_app_iff
             | [ H : ~(_ \/ _) |- _ ] => apply Decidable.not_or in H
             | _ => progress destruct_head or
             | _ => solve [ eauto using eq_refl with nocore ]
             | [ |- ~(?A \/ ?B) ] => cut (~A /\ ~B); [ tauto | ]
             | [ |- _ /\ _ ] => split
             | [ H : ?T, H' : ?T /\ _ -> ?B |- _ ] => specialize (fun X => H' (conj H X))
             | _ => progress split_in_context_by or (fun a b : Type => a) (fun a b : Type => b) ltac:(fun H => intuition eauto)
             | [ H : forall x, _ -> _ = x -> _ |- _ ] => specialize (fun k => H _ k eq_refl)
           end.
  Qed.
  Lemma NoDup_rev {A} (ls : list A)
  : NoDup (rev ls) <-> NoDup ls.
  Proof.
    induction ls as [|?? IHls]; simpl.
    { split; intro; constructor. }
    { split; intro H.
      { constructor.
        { rewrite in_rev.
          rapply @NoDup_app_in; [ eassumption | left; reflexivity ]. }
        { apply NoDup_app in H; apply IHls, H. } }
      { rewrite NoDup_app_in_iff, IHls.
        inversion H; clear H; subst.
        repeat split; simpl; trivial.
        { repeat constructor; simpl; intro; trivial. }
        { intros; destruct_head or; destruct_head False; subst.
          rewrite <- in_rev in *.
          eauto with nocore. } } }
  Qed.

  Lemma uniquize_nonnil {A} beq (ls : list A)
  : ls <> nil <-> Operations.List.uniquize beq ls <> nil.
  Proof.
    induction ls as [|a ls IHls]; simpl.
    { reflexivity. }
    { split; intros H H'.
      { destruct (list_bin beq a (Operations.List.uniquize beq ls)) eqn:Heq.
        { rewrite H' in IHls.
          destruct ls; simpl in *; try congruence.
          destruct IHls.
          specialize_by congruence.
          congruence. }
        { congruence. } }
      { congruence. } }
  Qed.
  Lemma rev_nonnil {A} (ls : list A)
  : ls <> nil <-> rev ls <> nil.
  Proof.
    destruct ls; simpl.
    { reflexivity. }
    { split; intros H H';
      apply (f_equal (@List.length _)) in H';
      rewrite ?app_length in H';
      simpl in *;
      omega. }
  Qed.

  Lemma Forall_tl {A} P (ls : list A)
  : List.Forall P ls -> List.Forall P (tl ls).
  Proof.
    intro H; destruct H; simpl; try constructor; assumption.
  Qed.
  Lemma Forall_inv_iff {A} P x (xs : list A)
  : List.Forall P (x::xs) <-> (P x /\ List.Forall P xs).
  Proof.
    split; intro H.
    { inversion H; subst; split; assumption. }
    { constructor; apply H. }
  Qed.

  Lemma app_take_drop {A} (ls : list A) n
  : (Operations.List.take n ls ++ Operations.List.drop n ls)%list = ls.
  Proof.
    revert ls; induction n as [|n IHn]; intros.
    { reflexivity. }
    { destruct ls as [|x xs]; simpl; trivial.
      apply f_equal.
      apply IHn. }
  Qed.

  Lemma map_proj1_sig_sig_In {A} (ls : list A)
  : List.map (@proj1_sig _ _) (sig_In ls) = ls.
  Proof.
    induction ls; simpl; f_equal; rewrite map_map; simpl; assumption.
  Qed.

  Lemma in_sig_uip {A} {P : A -> Prop} (UIP : forall x (p q : P x), p = q)
        (ls : list { x : A | P x })
        x
  : List.In x ls <-> List.In (proj1_sig x) (List.map (@proj1_sig _ _) ls).
  Proof.
    induction ls as [|y ys IHls]; simpl.
    { reflexivity. }
    { repeat match goal with
               | [ |- ?x = ?x \/ _ ] => left; reflexivity
               | [ H : ?A |- _ \/ ?A ] => right; assumption
               | [ |- exist _ ?x _ = exist _ ?x _ \/ _ ] => left; apply f_equal
               | _ => progress subst
               | _ => progress simpl in *
               | [ H : ?A -> ?B, H' : ?A |- _ ] => specialize (H H')
               | [ H : _ <-> _ |- _ ] => destruct H
               | [ |- _ <-> _ ] => split
               | _ => intro
               | [ H : _ \/ _ |- _ ] => destruct H
               | [ H : proj1_sig ?x = _ |- _ ] => is_var x; destruct x
               | [ |- context[exist _ _ _ = ?x] ] => is_var x; destruct x
               | _ => solve [ eauto with nocore ]
             end. }
  Qed.

  Lemma step_rev_up_to {n}
  : List.rev (up_to n)
    = match n with
        | 0 => nil
        | S n' => 0::map S (List.rev (up_to n'))
      end.
  Proof.
    induction n; simpl; [ reflexivity | ].
    etransitivity; [ rewrite IHn | reflexivity ].
    destruct n; simpl; [ reflexivity | ].
    rewrite map_app; reflexivity.
  Qed.

  Lemma map_nth_dep_helper {A B} (f' : nat -> nat) (f : nat -> A -> B) (l : list A) (d : A) (n : nat)
  : nth n (map (fun n'a => f (fst n'a) (snd n'a))
               (combine (List.map f' (List.rev (up_to (List.length l)))) l))
        (f (f' n) d)
    = f (f' n) (nth n l d).
  Proof.
    rewrite <- (map_nth (f (f' n))).
    rewrite step_rev_up_to.
    revert f' n; induction l as [|x xs IHxs]; intros.
    { destruct n; simpl; reflexivity. }
    { destruct n; simpl; [ reflexivity | ].
      specialize (IHxs (fun x => f' (S x))).
      rewrite <- IHxs; clear IHxs.
      rewrite map_map.
      rewrite <- step_rev_up_to.
      reflexivity. }
  Qed.

  Lemma map_nth_dep {A B} (f : nat -> A -> B) (l : list A) (d : A) (n : nat)
  : nth n (map (fun n'a => f (fst n'a) (snd n'a))
               (combine (List.rev (up_to (List.length l))) l))
        (f n d)
    = f n (nth n l d).
  Proof.
    rewrite <- (map_nth_dep_helper (fun x => x)).
    rewrite List.map_id; reflexivity.
  Qed.

  Lemma combine_map_l {A A' B} (g : A -> A') ls ls'
  : List.combine (List.map g ls) ls'
    = List.map (fun x : A * B => (g (fst x), snd x))
               (List.combine ls ls').
  Proof.
    revert ls'; induction ls as [|l ls IHls];
    intros [|l' ls']; simpl; f_equal.
    eauto with nocore.
  Qed.

  Lemma combine_map_r {A B B'} (g : B -> B') ls ls'
  : List.combine ls (List.map g ls')
    = List.map (fun x : A * B => (fst x, g (snd x)))
               (List.combine ls ls').
  Proof.
    revert ls'; induction ls as [|l ls IHls];
    intros [|l' ls']; simpl; f_equal.
    eauto with nocore.
  Qed.
End ListFacts.
