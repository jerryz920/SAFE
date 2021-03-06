//defenv Selfie() :-
//  spec('Load the principal keypair'),
//  principal($1).


//
// for GENI federation
//
//geniRoot($Peer).
//
//memberAuthority(?MA) :- $Peer: memberAuthority(?MA).
//
//geniUser(?User) :- ?MA: geniUser(?User), $Peer: memberAuthority(?MA).
//
//guestUser(?User) :- ?MA: geniUser(?User), $Peer: memberAuthority(?MA).
//geniUser(?User) :- guestUser(?User).
//
//guestUser(?User) :- ?MA: geniUser(?User), ?Peer: memberAuthority(?MA), peerRoot($Peer).
//

//defenv RootDir() :- u'IBpC0ljPorTuO85iJ-9GIxkXyDlOHAfFwcKfGtj-h2U:root'.
//defenv RootDir() :- '_Multe5KNgvw3Wk6eYF7_ZVXMXnKwxsTFNIzWiY87hM:root'.
defenv RootDir() :- 'hBZy2DLtG7qF7CxdZNWusPKdDz6LbA3lBDFIBDGbHTo:root'.

//defenv GeniRoot() :- u'jT9Gocrdu_KIm3Vb9eQc2a3lNWmtHp_AX1b3nD_cq-o'.
//defenv GeniRoot() :- u'IBpC0ljPorTuO85iJ-9GIxkXyDlOHAfFwcKfGtj-h2U'.
//defenv GeniRoot() :- '_Multe5KNgvw3Wk6eYF7_ZVXMXnKwxsTFNIzWiY87hM'.
defenv GeniRoot() :- 'hBZy2DLtG7qF7CxdZNWusPKdDz6LbA3lBDFIBDGbHTo'.

defenv MyAnchorSet() :- anchorSet().

//
// Identity set (apply to all participants)
//

defcon makeMyIdentitySet(?CN) :-
  spec("Construct the identity set for self"),
  {
    principal($SelfKey) :- spec("identity set for $CN").
  }.

defcon makeMySubjectSet() :-
  spec("Construct the subject set for self"),
  {
    link($Self).
    label("subject($Self)").
  }.

defcon addTokenToSubjectSet(?Token) :-
  spec("Add a token to the user's subject set. Invoke after the user gets a delegation"),
  {
    link($Token).
    label("subject($Self)").
  }.

defpost postIdSet(?CN) :- [makeMyIdentitySet(?CN)].

defpost postSubjectSet() :- [makeMySubjectSet()].

defpost updateSubjectSet(?Token) :- [addTokenToSubjectSet(?Token)].


//
// Federation policy: trust structure and user/PI registration
//

defcon trustStructure() :-
  spec('Federation trust structure: adopted by all participants'),
  {
    memberAuthority(?MA) :- geniRoot(?Geni), ?Geni: memberAuthority(?MA).
    sliceAuthority(?SA) :- geniRoot(?Geni), ?Geni: sliceAuthority(?SA).
    projectAuthority(?PA) :- geniRoot(?Geni), ?Geni: projectAuthority(?PA).
    geniProxy(?GeniProxy) :- geniRoot(?Geni), ?Geni: geniProxy(?GeniProxy).
    aggregate(?Agg) :- geniRoot(?Geni), ?Geni: aggregate(?Agg).
    gmoc(?GeniMOC) :- geniRoot(?Geni), ?Geni: gmoc(?GeniMOC).
    label('geni/trust-structure').
  }.

defcon registeredUserPolicy() :-
  spec('Federation policy for registered users and PIs: adopted by all participants'),
  {
    geniUser(?User) :- memberAuthority(?MA), ?MA: geniUser(?User).
    geniPI(?User) :- memberAuthority(?MA), ?MA: geniPI(?User).
    label('geni/registered-user').
  }.

definit trustStructure(), registeredUserPolicy().

//
// Federation root: endorsements
//

defcon endorseMA(?MA) :-
  spec('endorse a member authority'),
  {
    memberAuthority($MA) :- spec("geni endorses a member authority $MA").
    label("ma/$MA").
  }.

defcon endorsePA(?PA) :-
  spec('endorse a project authority'),
  {
    projectAuthority($PA) :- spec("geni endorses a project authority $PA").
    label("pa/$PA").
  }.

defcon endorseSA(?SA) :-
  spec('endorse a slice authority'),
  {
    sliceAuthority($SA) :- spec("geni endorses a slice authority $SA").
    label("sa/$SA").
  }.

defcon endorseCP(?CP) :-
  spec('endorse an aggregate'),
  {
    aggregate($CP) :- spec("geni endorses an aggregate $CP").
    label("aggregate/$CP").
  }.

defpost postMAEndorsement(?MA) :- [endorseMA(?MA)].
defpost postPAEndorsement(?PA) :- [endorsePA(?PA)].
defpost postSAEndorsement(?SA) :- [endorseSA(?SA)].
defpost postCPEndorsement(?CP) :- [endorseCP(?CP)].


//
// MA: endorsements for registered users and PIs.
//

defcon endorsePI(?PI) :-
  spec('Endorse a geni PI'),
  ?SubjectSetRef := label($Self, "subject($Self)"),
  {
    geniUser($PI).
    geniPI($PI).
    link($SubjectSetRef).
    label("pi/$PI").
  }.

defcon endorseUser(?User) :- 
  spec('Endorse a geni user'),
  ?SubjectSetRef := label($Self, "subject($Self)"),
  {
    geniUser($User).
    link($SubjectSetRef).
    label("user/$User").
  }.

defpost postPIEndorsement(?PI) :- [endorsePI(?PI)].
defpost postUserEndorsement(?User) :- [endorseUser(?User)].


//
// PA: projects and their policy sets
//

defcon projectMemberSet() :- 
  ?StdGroupSetRef := label("standard-user-group-membership-policy"),
  {
    link($StdGroupSetRef).  // Post basic user group policy first

    memberPrivilege(?User, ?Project, instantiate, ?Delegatable) :- 
      member(?User, ?Project, ?Delegatable).

    memberPrivilege(?User, ?Project, ?Priv, ?Delegatable) :-
      delegatesMemberPrivilege(?Delegator, ?User, ?Project, ?Priv, ?Delegatable),
      memberPrivilege(?Delegator, ?Project, ?Priv, true).

    delegatesMemberPrivilege(?Delegator, ?User, ?Project, ?Priv, ?Delegatable) :-
      ?Delegator: delegateMemberPrivilege(?User, ?Project, ?Priv, ?Delegatable).
 
    label('pa/standard-project-membership') :- 
      spec('Standard project membership policy').
  }.

defpost postProjectMemberSet() :- 
  [projectMemberSet()].

defpost postProjectMembershipDelegation(?SubjectId, ?ProjectId, ?Delegatable) :- 
  [delegateGroupMembership(?SubjectId, ?ProjectId, ?Delegatable)].


//
// PA authZ policy for project creation.
//
defcon projectPolicySet() :-
  {
    approveProject(?Owner) :-
      geniPI(?Owner).
    label('pa/standard-project-operations').
  }.

definit projectPolicySet().

defpost postProjectSet(?SubjectId, ?ProjectId, ?ProjectMembershipPolicyRef) :- 
  [createGroupSet(?SubjectId, ?ProjectId, ?ProjectMembershipPolicyRef, project)].

//
// SA: slices and their policy sets
//

defcon standardSliceControlSet() :- 
  ?StdGroupSetRef := label("standard-user-group-membership-policy"),
  {
    link($StdGroupSetRef).  // Post basic user group policy first
 
    controlPrivilege(?Subject, ?Slice, instantiate, ?Delegator) :- 
      member(?Subject, ?Slice, ?Delegator).
 
    controlPrivilege(?Subject, ?Slice, ?Priv, ?Delegatable) :- 
      delegatesControlPrivilege(?Delegator, ?Subject, ?Slice, ?Priv, ?Delegatable),
      controlPrivilege(?Delegator, ?Slice, ?Priv, true).

    delegatesControlPrivilege(?Delegator, ?Subject, ?Slice, ?Priv, ?Delegatable) :-
      ?Delegator: delegatesControlPrivilege(?Subject, ?Slice, ?Priv, ?Delegatable).

    label('sa/standard-slice-control') :- 
      spec('Standard slice control policy').
  }.

defpost postStandardSliceControlSet() :- 
  [standardSliceControlSet()].


defcon standardSliceDefaultPrivilegeSet() :-
  ?StdSliceControlSetRef := label("sa/standard-slice-control"),
  {
    link($StdSliceControlSetRef).  // Post standard slice control set first

    controlPrivilege(?Subject, ?Slice, info, ?Delegatable) :-
      slice(?Slice, ?Project, standard),
      ?PA := rootPrincipal(?Project),
      projectAuthority(?PA),
      ?PA: group(?Project, project, standard),
      ?PA: memberPrivilege(?Subject, ?Project, info, ?Delegatable).
 
    controlPrivilege(?Subject, ?Slice, stop, true) :- 
      slice(?Slice, ?Project, standard),
      ?PA := rootPrincipal(?Project),
      projectAuthority(?PA),
      ?PA: group(?Project, project, standard),
      ?PA: owner(?Subject, ?Project).
 
    controlPrivilege(?Subject, ?Slice, info) :- 
      slice(?Slice, ?Project, standard),
      gmoc(?Subject).
 
    controlPrivilege(?Subject, ?Slice, stop) :- 
      slice(?Slice, ?Project, standard),
      gmoc(?Subject).
 
    label('sa/standard-slice-privilege') :- 
      spec('Standard slice default privilege policy').
  }.

defpost postStandardSliceDefaultPrivilegeSet() :- 
  [standardSliceDefaultPrivilegeSet()].

defpost postSliceControl(?SubjectId, ?SliceId, ?Delegatable) :- 
  [delegateGroupMembership(?SubjectId, ?SliceId, ?Delegatable)].


//
// SA authZ policy for slice creation.
//
defcon slicePolicySet() :-
  {
    approveSlice(?Subject, ?Project) :-
      ?PA := rootPrincipal(?Project),
      projectAuthority(?PA),
      ?PA: group(?Project, project, standard),
      ?PA: memberPrivilege(?Subject, ?Project, instantiate, _),
      geniUser(?Subject).

    label('sa/standard-slice-operations').
  }.

definit slicePolicySet().

//
// A newly approved slice is created as a set with links to its policy sets.
//

defcon createSliceSet(?SliceId, ?ProjectId) :-
  ?SliceGroupSetRef := label($Self, "groups/?SliceId"),
  {
    link($SliceGroupSetRef).
    slice($SliceId, $ProjectId, standard).
    label("slice/$SliceId").
  }.

defpost postSliceSet(?SubjectId, ?SliceId, ?ProjectId, ?SliceControlPrivRef) :- 
  [createSliceSet(?SliceId, ?ProjectId), createGroupSet(?SubjectId, ?SliceId, ?SliceControlPrivRef, slice)].


//
// Aggregate
//

defcon aggregatePolicySet() :- 
  {
     approveSliver(?Subject, ?Slice) :-
       ?SA := rootPrincipal(?Slice),
       ?SA: slice(?Slice, ?Project, standard),
       sliceAuthority(?SA), 
       ?SA: controlPrivilege(?Subject, ?Slice, instantiate, _),
       geniUser(?Subject).
 
     label('aggregate/standard-slice-operations').
  }.

definit aggregatePolicySet().

defcon sliverAccessPolicySet() :-
  {
    approveSliverAccess(?SubjectId, ?SliverId) :-
      ?CP := rootPrincipal(?SliverId),
      aggregate(?CP),
      ?CP: sliverPrivilege(?SubjectId, ?SliverId), 
      geniUser(?SubjectId).

    label('aggregate/standard-sliver-access').
  }.

definit sliverAccessPolicySet().

defcon addSliverAcl(?SliverId, ?GroupId) :-
  spec("For Aggregate.addSliverAcl"),
  {
     //sliverPrivilege($SliverId, $GroupId).
     sliverPrivilege(?SubjectId, $SliverId) :- ?GRoot := rootPrincipal($GroupId), ?GRoot: member(?SubjectId, $GroupId).
     label("acls($SliverId)").
  }.

defpost postSliverAcl(?SliverId, ?GroupId) :- 
  [addSliverAcl(?SliverId, ?GroupId)].


defcon createStitchportSet(?SliverId, ?SliceId, ?ZoneId, ?VlanTag) :-
  spec("For aggregate.createStitchportSet"),
  ?SubjectSetRef := label("subject($Self)"),
  ?AclsSetRef := label("acls(?SliverId)"),
  ?SA := rootPrincipal(?SliceId),
  ?SliceSetRef := label(?SA, "slice/?SliceId"),
  ?ZoneSetRef := label("zones/?ZoneId"),
  {
    sliverOf($SliverId, $SliceId, standard).
    stitchport($SliverId, $ZoneId, $VlanTag).
    link($SubjectSetRef).
    link($AclsSetRef).
    link($SliceSetRef).
    link($ZoneSetRef).
    label("slivers/$SliverId").
  }.

defpost postStitchportSet(?SliverId, ?SliceId, ?ZoneId, ?VlanTag) :- 
  [createStitchportSet(?SliverId, ?SliceId, ?ZoneId, ?VlanTag)].


defcon createSliverSet(?SliverId, ?SliceId) :-
  spec("For aggregate.createSliverSet"),
  ?SubjectSetRef := label($Self, "subject($Self)"),
  ?AclsSetRef := label($Self, "acls($SliverId)"),
  ?SA := rootPrincipal(?SliceId),
  ?SliceSetRef := label(?SA, "slice/$SliceId"),
  {
    sliverOf($SliverId, $SliceId, standard).
    link($SubjectSetRef).
    link($AclsSetRef).
    link($SliceSetRef).
    label("slivers/$SliverId").
  }.

defpost postSliverSet(?SliverId, ?SliceId) :- 
  [createSliverSet(?SliverId, ?SliceId)].


defcon addAdjacentCP(?AdjacentCP) :-
  spec("For aggregate.addAdjacentCP"),
  {
    adjacentAggregate($AdjacentCP).
    label("adjacent-CP-list").  // optional: update this link to the aggregate's subject set
  }.

defpost updateAdjacentCPList(?AdjacentCP) :- 
  [addAdjacentCP(?AdjacentCP)].


defcon createZoneSet(?ZoneId) :-
  spec("For aggregate.createZoneSet"),
  ?SubjectSetRef := label($Self, "subject($Self)"),
  {
    l2zone($ZoneId, standard).
    link($SubjectSetRef).
    label("zones/$ZoneId").
  }.

defpost postZoneSet(?ZoneId) :- 
  [createZoneSet(?ZoneId)].


//
// Guards
// There are three for primary GENI interfaces:
// pa.createProject, sa.createSlice, agg.createSliver.
// AuthZ for other agg slice operations is similar to approveSliver.
//

defguard createProject() :-
  spec("Guard for ProjectAuthority.createProject"),
  ?PolicyRef := label("pa/standard-project-operations"),
  {
    link($MyAnchorSet).
    link($PolicyRef).
    link($BearerRef).
    approveProject($Subject)?
  }.

defguard createSlice(?ProjectId) :-
  spec("Guard for SliceAuthority.createSlice"),
  ?PolicyRef := label("sa/standard-slice-operations"),
  {
    link($MyAnchorSet).
    link($PolicyRef).
    link($BearerRef). 
    approveSlice($Subject, $ProjectId)?
  }.

defguard createSliver(?SliceId) :-
  spec("Guard for Aggregate.createSliver"),
  ?PolicyRef := label("aggregate/standard-slice-operations"),
  {
    link($MyAnchorSet).
    link($PolicyRef).
    link($BearerRef). 
    approveSliver($Subject, $SliceId)?
  }.

defguard accessSliver(?SliverId) :-
  spec("Guard for Aggregate.accessSliver"),
  ?PolicyRef := label("aggregate/standard-sliver-access"),
  ?SliverSetRef := label("slivers/?SliverId"),
  {
    link($MyAnchorSet).
    link($PolicyRef).
    link($SliverSetRef).
    link($BearerRef). 
    approveSliverAccess($Subject, $SliverId)?
  }.

defguard stitchSlivers(?SrcSliverId, ?PeerSliverId) :-
  spec("Guard for Aggregate.stitchSlivers"),
  ?SrcAggregate := rootPrincipal(?SrcSliverId),
  ?SrcSliverSetRef := label(?SrcAggregate, "slivers/?SrcSliverId"),
  ?PeerAggregate := rootPrincipal(?PeerSliverId), 
  ?PeerSliverSetRef := label(?PeerAggregate, "slivers/?PeerSliverId"), 
  ?PolicyRef := label("aggregate/standard-sliver-access"),
  ?AdjacentCPSetRef := label("adjacent-CP-list"),
  {
    link($MyAnchorSet).
    link($BearerRef). 
    link($SrcSliverSetRef).
    link($PeerSliverSetRef).
    link($PolicyRef).
    link($AdjacentCPSetRef).
  
    validZone(?SliverId) :-
      ?Aggregate := rootPrincipal(?SliverId),
      ?Aggregate: stitchport(?SliverId, ?ZoneId, ?VlanTag),
      ?Aggregate: l2zone(?ZoneId, standard).

    approveStitching(?SrcSliverId, ?PeerSliverId) :-
      validZone(?SrcSliverId),
      validZone(?PeerSliverId),
      ?SrcCP := rootPrincipal(?SrcSliverId),
      adjacentAggregate(?SrcCP),
      ?SrcCP: sliverOf(?SrcSliverId, ?SrcSliceId, standard),
      ?SrcSA := rootPrincipal(?SrcSliceId),
      ?SrcSA: member($Subject, ?SrcSliceId),
      approveSliverAccess($Subject, ?PeerSliverId).

    approveStitching($SrcSliverId, $PeerSliverId)?
  }.


defguard addSliverAcl(?SliverId) :-
  ?SliverSetRef := label($Self, "slivers/?SliverId"),
  {
     link($MyAnchorSet).
     link($BearerRef).
     link($SliverSetRef).

     approveSliverAcl(?SubjectId, ?SliverId) :-
       sliverOf(?SliverId, ?SliceId, standard),
       ?SA := rootPrincipal(?SliceId),
       ?SA: member(?SubjectId, ?SliceId),
       geniUser(?SubjectId). 

     approveSliverAcl($Subject, $SliverId)?
  }.


//
// Group authority
//

defcon userGroupMemberSet() :-
  spec('Policies on group membership'),
  {
    member(?User, ?Group) :-
      member(?User, ?Group, _).

    member(?User, ?Group, true) :-
      owner(?User, ?Group).

    member(?User, ?Group, ?Delegatable) :-
      groupMember(?Group, ?User, ?Delegatable).

    member(?User, ?Group, ?Delegatable) :-
      ?Delegator: delegateMember(?User, ?Group, ?Delegatable),
      member(?Delegator, ?Group, true).

    member(?User, ?Group, ?Delegatable) :-
      nestGroup(?Group, ?ToGroup, true),
      ToGroupRoot := rootPrincipal(?ToGroup),
      ToGroupRoot: member(?User, ?ToGroup, ?Delegatable).

    member(?User, ?Group, ?Delegatable) :-
      nestGroup(?Group, ?ToGroup, false),
      ?ToGroupRoot := rootPrincipal(?ToGroup),
      ?ToGroupRoot: groupMember(?ToGroup, ?User, ?Delegatable).

    label('standard-user-group-membership-policy').
  }.

defpost postUserGroupMemberSet() :-
  [userGroupMemberSet()].
                                                  

defcon createGroupSet(?SubjectId, ?GroupId, ?PolicyRef, ?Type) :-
  spec('Construct a set for a group'),
  ?SubjectSetRef := label($Self, "subject($Self)"),
  {
    owner($SubjectId, $GroupId).
    group($GroupId, $Type, standard). 
    link($PolicyRef).
    link($SubjectSetRef).
    label("groups/$GroupId").  // Update the subject set of $SubjectId
  }.

defpost postGroupSet(?SubjectId, ?GroupId, ?PolicyRef, ?Type) :- 
  [createGroupSet(?SubjectId, ?GroupId, ?PolicyRef, ?Type)].

defcon addTokenToGroupSet(?Token, ?GroupId) :-
  spec("Add a link to a group's ID set. Invoked after delegation to this group"),
  {
    link($Token).
    label("groups/$GroupId").
  }.

defpost updateGroupSet(?Token, ?GroupId) :- [addTokenToGroupSet(?Token, ?GroupId)].

defcon addGroupMember(?GroupId, ?SubjectId, ?Delegatable) :-
  spec('Add a user into a group'),
  ?GroupSetRef := label($Self, "groups/?GroupId"),
  {
    groupMember($GroupId, $SubjectId, $Delegatable).
    link($GroupSetRef).
    label("groupMember/$GroupId/$SubjectId").     (* this link should be saved in the subject set of ?User *)
  }.

defpost postGroupMember(?GroupId, ?SubjectId, ?Delegatable) :- [addGroupMember(?GroupId, ?SubjectId, ?Delegatable)].

defcon delegateGroup(?GroupId, ?ToGroupId, ?Delegatable) :-
  spec('Delegate administration to another group'), (* Membership is granted if membership of that group is granted *)
  ?GroupSetRef := label($Self, "groups/?GroupId"),
  {
    nestGroup($GroupId, $ToGroupId, $Delegatable).
    link($GroupSetRef).
    label("delegateGroup/$GroupId/$ToGroupId").  (* this link should be stored in the ?ToGroupId set *)
  }.

defpost postGroupDelegation(?GroupId, ?ToGroupId, ?Delegatable) :- [delegateGroup(?GroupId, ?ToGroupId, ?Delegatable)].


//
// Group member
//

defcon delegateGroupMembership(?SubjectId, ?GroupId, ?Delegatable) :-
  spec('Delegate group membership to another user'),
  ?SubjectSetRef := label("subject($Self)"),
  {
    delegateMember($SubjectId, $GroupId, $Delegatable).
    link($SubjectSetRef).
    label("group membership delegation $SubjectId $GroupId").  (* this link should be saved in the subject set of ?SubjectId *)
  }.

defpost postUserGroupMembershipDelegation(?SubjectId, ?GroupId, ?Delegatable) :- [delegateGroupMembership(?SubjectId, ?GroupId, ?Delegatable)].


//
// Naming authority
//

defcon makeObjectSet(?Scid) :-
  spec("Construct a set for object ?Scid"),
  {
    label("$Scid").
  }.

defcon addTokenToObjectSet(?Token, ?Scid) :-
  spec("Add a link to an object set"),
  {
    link($Token).
    label("$Scid").
  }.

defpost postObjectSet(?Scid) :- [makeObjectSet(?Scid)].

defpost updateObjectSet(?Token, ?Scid) :- [addTokenToObjectSet(?Token, ?Scid)].


defcon mountObject(?ObjectName, ?ChildScid, ?ParentScid) :-
  spec('Create a name entry'),
  ?ParentToken := label(?ParentScid),
  {
    link($ParentToken).
    nameObject($ObjectName, $ChildScid, $ParentScid).
    nameObject2($ParentScid, $ObjectName, $ChildScid).
    label("$ParentScid/$ObjectName").
  }.

defpost postObjectDelegation(?ObjectName, ?Scid, ?MountScid) :- [mountObject(?ObjectName, ?Scid, ?MountScid)].


defcon grantAccess(?Group, ?DirScid) :-
  spec('Grant group access to directory'),
  {
    accessToDir($Group, $DirScid).
    label("$DirScid").
  }.

defpost postDirectoryAccess(?Group, ?DirScid) :- [grantAccess(?Group, ?DirScid)].


defcon checkDirectObject(?Dir, ?Name) :-
  spec("Check if a name represents a direct object"),
  {
    directObject(?Scid) :- ?NameAuthority := rootPrincipal($Dir), ?NameAuthority: nameObject($Name, ?Scid, $Dir).
    directObject(?Scid)?
    label("$Dir-$Name").
  }.

resolve(?Dir, ?Name, ?Scid, ?LastCertToken) :-
  singleComponent(?Name),
  ?RulesRef := checkDirectObject(?Dir, ?Name),
  ?DirAuthority := rootPrincipal(?Dir),
  ?ObjDelToken := label(?DirAuthority, "?Dir/?Name"),
  ?ScidSet := inferSet(?RulesRef, ?ObjDelToken),
  ?ObjScid := getNthArgFromSlogset(?ScidSet, 0),
  unify(?Scid, ?ObjScid),
  unify(?LastCertToken, ?ObjDelToken).

resolve(?Dir, ?Name, ?Scid, ?LastCertToken) :-
  splitHead(?Name, ?FirstComponent, ?Tail),
  ?RulesRef := checkDirectObject(?Dir, ?FirstComponent),
  ?DirAuthority := rootPrincipal(?Dir),
  ?ObjDelToken := label(?DirAuthority, "?Dir/?FirstComponent"),
  ?SubDirSet := inferSet(?RulesRef, ?ObjDelToken),
  ?SubDir := getNthArgFromSlogset(?SubDirSet, 0),
  resolve(?SubDir, ?Tail, ?Scid, ?LastCertToken).


defcon srnEvaluation() :-
  spec("Rules for SRN certified evaluation, in a bottom-up fashion"),
  {
    srnNameToID(?Name, ?Scid) :-
      singleComponent(?Name),
      ?RootAuthority := rootPrincipal($RootDir),
      ?RootAuthority: nameObject(?Name, ?Scid, $RootDir).

    srnNameToID(?Name, ?Scid) :-
      splitLast(?Name, ?Init, ?LastComponent),
      srnNameToID(?Init, ?Dir),
      ?DirAuthority := rootPrincipal(?Dir),
      ?DirAuthority: nameObject(?LastComponent, ?Scid, ?Dir).

    srnIDPathTo(?UpstreamScid, ?DownstreamScid) :-
      ?UpstreamScid = ?DownstreamScid.

    srnIDPathTo(?UpstreamScid, ?DownstreamScid) :-
      ?UpstreamRoot := rootPrincipal(?UpstreamScid),
      ?UpstreamRoot: nameObject2(?UpstreamScid, ?Name, ?MiddleScid),
      srnIDPathTo(?MiddleScid, ?DownstreamScid).

    label("SRN-standard-evaluation").
  }.

definit srnEvaluation().

defguard queryName(?RootDir, ?Name) :-
  spec("Query a name"),
  resolve(?RootDir, ?Name, ?Scid, ?LastCertToken),
  ?ObjRoot := rootPrincipal(?Scid),
  ?ObjToken := label(?ObjRoot, ?Scid),
  {
    link($ObjToken).

    srnNameToID(?Name, ?Scid) :-
      singleComponent(?Name),
      ?RootAuthority := rootPrincipal($RootDir),
      ?RootAuthority: nameObject(?Name, ?Scid, $RootDir).

    srnNameToID(?Name, ?Scid) :-
      splitLast(?Name, ?Init, ?LastComponent),
      srnNameToID(?Init, ?Dir),
      ?DirAuthority := rootPrincipal(?Dir),
      ?DirAuthority: nameObject(?LastComponent, ?Scid, ?Dir).

    srnNameToID($Name, ?Scid)?
  }.



//
// Local example
//

defcon fedEndorsementStub() :-
  ?E1 := endorseMA($Self),
  ?E2 := endorsePA($Self),
  ?E3 := endorseSA($Self),
  ?E4 := endorseCP($Self),
  {
    link($E1).
    link($E2).
    link($E3).
    link($E4).
    label("geni/endorse-self-stub").
  }.


//
// Disabled the following from anchorSet()
// Caused infinite loops
// ?FedEndorseRef := fedEndorsementStub(),
//  link($FedEndorseRef).
//

defcon anchorSet() :-
  ?FedStructureRef := label("geni/trust-structure"),
  ?FedUserRef := label("geni/registered-user"),   
  {
    geniRoot($GeniRoot).
    link($FedStructureRef).
    link($FedUserRef).   
    label("geni/anchor-set").
  }.
