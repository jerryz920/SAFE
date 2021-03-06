defenv Selfie :-
  spec('Load the principal keypair'),
  principal($1).

defcon standardSliceControlSet() :- 
  {
    controls(?Subject, ?Slice, true) :-
      owner(?Subject, ?Slice).
 
    controls(?Subject, ?Slice, ?Delegatable) :- 
      ?Delegator: delegateControl(?Subject, ?Slice, ?Delegatable),
      controls(?Delegator, ?Slice, true).
 
    controls(?Subject, ?Slice) :-
      controls(?Subject, ?Slice, _).
 
    controlPrivilege(?Subject, ?Slice, instantiate, ?Delegator) :- 
      controls(?Subject, ?Slice, ?Delegator).
 
    controlPrivilege(?Subject, ?Slice, ?Priv, ?Delegatable) :- 
      ?Delegator: delegateControlPrivilege(?Subject, ?Slice, ?Priv, ?Delegatable),

    controlPrivilege(?Delegator, ?Slice, ?Priv, true).
 
    name('object/standardSliceControl') :- 
      spec('Object set for standard slice control policy issued by self').
  }.

defcon standardSliceDefaultPrivilegeSet() :-
  {
    controlPrivilege(?Subject, ?Slice, info, ?Delegatable) :-
      slice(?Slice, ?Project, standard),
      ?PA := rootId(?Project),
      projectAuthority(?PA),
      ?PA: project(?Project),
      ?PA: memberPrivilege(?Subject, ?Project, info, ?Delegatable).
 
    controlPrivilege(?Subject, ?Slice, stop, true) :- 
      slice(?Slice, ?Project, standard),
      ?PA := rootId(?Project),
      projectAuthority(?PA),
      ?PA: project(?Project),
      owner(?Subject, ?Project).
 
    controlPrivilege(?Subject, ?Slice, info) :- 
      slice(?Slice, ?Project, standard),
      gmoc(?Subject).
 
    controlPrivilege(?Subject, ?Slice, stop) :- 
      slice(?Slice, ?Project, standard),
      gmoc(?Subject).
 
    name('object/standardSliceDefaultPrivilege') :- 
      spec('Object set for standard slice default privilege policy issued by self').
  }.

defcon createSlice(?SubjectId, ?SliceId, ?ProjectRef, ?StandardSliceControlRef, ?StandardSliceDefaultPrivilegeRef) :-
  {
    owner($SubjectId, $SliceId).
    slice($SliceId, $ProjectRef, standard).
    link($StandardSliceControlRef) :- spec('standard slice control set').
    link($StandardSliceDefaultPrivilegeRef) :- spec('standard slice default privileges set').
    name("delegate/$SubjectId/$SliceId") :- spec("delegate slice control by slice root to subject $SubjectId").
  }.

defpost publishSliceControlSets() :- [standardSliceControlSet(), standardSliceDefaultPrivilegeSet()].

defpost publishSlice(?ProjectOwnerRef, ?SubjectId) :- 
   ?ProjectRef                       := "?ProjectOwnerRef:projectGuid",
   ?StandardSliceControlRef          := computeIdFromName($Self, 'object/standardSliceControl'),
   ?StandardSliceDefaultPrivilegeRef := computeIdFromName($Self, 'object/standardSliceDefaultPrivilege'),
   //?SliceId := scid(), 
   ?SliceId                          := "$Self:sliceGuid",
   [createSlice(?SubjectId, ?SliceId, ?ProjectRef, ?StandardSliceControlRef, ?StandardSliceDefaultPrivilegeRef)].

definit publishSliceControlSets(), publishSlice($2, $3).
