# STRONG Scenario

STRONG is a logic package for tags, resource objects, hierarchical names, and groups.   This scenario is to get started on groups with a redacted slang package called *strong-lite*, which omits support for symbolic names.

Groups in STRONG are secure objects.  The objects are *secure* in the sense that their names are certified, so that an untrusted principal cannot hijack another principal's object and make undetectably bogus statements about it.  Specifically, each secure object is named by a unique *self-certifying identifier* (scid).  The scid is bound to the object's *controlling (root) principal* or *owner*: an object's owner is the principal who creates the object and is empowered to direct how others should reason about the object.  A scid is formed by concatenating the owner's keyhash with a unique object name chosen by the owner, e.g., a UUID.

Any principal may create a group.   The owner is authoritative for the group and chooses its scid.  The self-certifying scid is sufficient to authenticate the owner's statements about the group.

STRONG allows a group's owner to add principals to the group or add other groups to the group.  Thus the group hierarchy is a DAG.  For example, it is possible that group *G* is a member of multiple other groups.  A group owner may also delegate its privilege to designate other members.

STRONG illustrates a tricky aspect of SAFE linking.   Each group is represented by a logic set in the store, indexed by the group scid.  These sets have various links among them representing subgroup relationships.  Additionally, each principal maintains a *subject set* with links to its group memberships.  Keeping the links straight requires some additional calls: each principal or group (the owner) must accept any memberships granted to it and install the link.  Additionally, a user claiming membership in a group must pass its subject set link to the authorizer.

## Running the STRONG-lite scenario

Strong-lite is a single SAFE trust script that combines the actions of all participants.
You can run it on a local SAFE install with a slang-shell issuing REST calls to a safe-server.  The safe-server is a client of a shared KV store (Riak) and is pointed at a local keypair directory with four keypairs.

One way to get set up is to follow the [standard docker setup for ImPACT](https://github.com/RENCI-NRIG/impact-docker-images/tree/master/safe-server) including generating keypairs for some sample principals for use with STRONG.

We recommend following that scenario to run a Riak store in a local docker container, but run the SAFE components on your host.   Launch your Riak in the usual way, and test it with curl commands on your host.  You can extract the curl commands from the [test script](https://github.com/RENCI-NRIG/SAFE/blob/master/dockerfiles/riak/test.sh).  Then run the SAFE elements as follows.

Launch the server with a command like this.  Here we assume that the pathname of the keypair directory is "~/safe-scratch/principalkeys", but you can put it wherever you want.   We also assume that your *application.conf* file for project *safe-server* points at your Riak as its metastore.  The default is sufficient if Riak is running in a local container.

```
cd safe
sbt "project safe-server" "run -f ../safe-apps/strong/strong-lite.slang -r safeService  -kd  ~/safe-scratch/principalkeys"
```

Your slang-shell loads the matching `strong-client.slang` script, as described below.

### 1. Start a slang-shell

Start your slang-shell in the usual fashion.  Something like:

```
cd safe
sbt "project safe-lang" "run"
```

From this point forward we run the scenario by issuing commands to the slang-shell.   These commands run on behalf of the different principals in the scenario.

Once the slang-shell gives you a prompt, point it at your safe-server.    Something like:

```
?ServerJVM := "localhost:7777".
```

If your safe-server is indeed running on localhost on port 7777, this command is optional: it is given as the default in the `mvp.slang` safe-server script.

Finally, load the strong client script into your slang-shell:

```
import("safe-apps/strong/strong-client.slang").
```

### 2. Make some UUIDs

These commands simply define some random UUIDs and assign their values to slang-shell variables.  The scenario uses them to make scids for new groups.

```
?UUID1 := "6ec7211c-caaf-4e00-ad36-0cd413accc91".
?UUID2 := "1b924687-a317-4bd7-a54f-a5a0151f49d3".
?UUID3 := "26dbc728-3c8d-4433-9c4b-2e065b644db5".
?UUID4 := "1ef7e6dd-5342-414e-8cce-54e55b3b9a83".
```

### 3. Post the principal certificates

As always, the principals must post their IdSet certificates.   These slang-shell commands presume that you are using the same keypairs generated as for the STRONG example.  But we assign their values to principals Alice, Bob, etc., with corresponding shell variables *A*, *B*, *C*,...

```
?Self := "strong-1".
?A := postRawIdSet("strong-1").
?Self := "strong-2".
?B := postRawIdSet("strong-2").
?Self := "strong-3".
?C := postRawIdSet("strong-3").
?Self := "strong-4".
?D := postRawIdSet("strong-4").
```

Each principal certificate is posted in the shared K/V store at a token that is the principal's keyhash.  Each `postRawIdSet` returns the keyhash, and slang-shell saves it in a shell variable that names the principal for future commands.


### 4.  Alice makes group G1: Bob is a member

Alice creates a group **G1**and puts Bob in it,  with no delegator privilege. 

```
?Self:=$A. 
?G1:="$A: $UUID1".
?BtoG1token:=postGroupMember($G1, $B, false).
```

Bob has to put the group token in his subject set.

```
?Self:=$B. 
?SubjectSetB := updateSubjectSet($BtoG1token). 
```

Any principal can query Bob's membership, given Bob's subject set.  *ReqEnvs* is a special slang-shell variable to pass the subject set as a hidden token in the request.  This query should be satisfied.  

```
?ReqEnvs := ":::$SubjectSetB". 
queryMembership($G1,$B)?
```

### 5. Bob makes group G2: Cindy is a member

Bob creates a group **G2**and puts Cindy in it.

```
?Self:=$B. 
?G2:="$B: $UUID2".
?CtoG2token:=postGroupMember($G2, $C, false).
```

Again with the token linking:

```
?Self:=$C. 
?SubjectSetC := updateSubjectSet($CtoG2token).
```

### 6. Alice adds G2 as a subgroup of G1

```
?Self:=$A. 
?G2toG1token:=postGroupDelegation($G1, $G2, false).
```

```
?Self:=$B. 
?G2set:=updateGroupSet($G2toG1token, $G2).
```


### 6.  Cindy is a member of G1


```
?ReqEnvs := ":::$SubjectSetC". 
queryMembership($G2,$C)? 
queryMembership($G1,$C)?
```

