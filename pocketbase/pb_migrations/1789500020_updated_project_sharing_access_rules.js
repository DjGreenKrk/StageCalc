/// <reference path="../pb_data/types.d.ts" />

// ADR-040: extends the owner-only access rules from ADR-028 to also let in
// a project's shared viewers/editors (and, for `clients`, the recipient of
// a project shared with them). Every added clause checks exactly one
// relation field with a single `?=` - never two `?=` clauses ANDed on the
// same multi-valued relation, which PocketBase would match independently
// per clause and could therefore grant access no single related record
// actually satisfies (see ADR-040 for the full explanation).
migrate((app) => {
  const viewerOrEditor =
    "@request.auth.id != '' && (owner = @request.auth.id || sharedViewers ?= @request.auth.id || sharedEditors ?= @request.auth.id)";
  const editorOnly =
    "@request.auth.id != '' && (owner = @request.auth.id || sharedEditors ?= @request.auth.id)";
  const ownerRule = "@request.auth.id != '' && owner = @request.auth.id";

  const projects = app.findCollectionByNameOrId("pbc_484305853");
  projects.listRule = viewerOrEditor;
  projects.viewRule = viewerOrEditor;
  projects.createRule = ownerRule;
  projects.updateRule = editorOnly;
  projects.deleteRule = ownerRule;
  app.save(projects);

  const nestedViewerOrEditor =
    "@request.auth.id != '' && (project.owner = @request.auth.id || project.sharedViewers ?= @request.auth.id || project.sharedEditors ?= @request.auth.id)";
  const nestedEditorOnly =
    "@request.auth.id != '' && (project.owner = @request.auth.id || project.sharedEditors ?= @request.auth.id)";

  const ownedViaProject = [
    "pbc_3223496621", // project_groups
    "pbc_461364642", // project_items
    "pbc_7001112223", // project_group_hook_assignments
    "pbc_319770345", // project_distros
    "pbc_4073588220", // project_outlets
    "pbc_1378466011", // power_connections
    "pbc_4101664731", // project_trusses
  ];
  for (const id of ownedViaProject) {
    const collection = app.findCollectionByNameOrId(id);
    collection.listRule = nestedViewerOrEditor;
    collection.viewRule = nestedViewerOrEditor;
    collection.createRule = nestedEditorOnly;
    collection.updateRule = nestedEditorOnly;
    collection.deleteRule = nestedEditorOnly;
    app.save(collection);
  }

  const clients = app.findCollectionByNameOrId("pbc_2442875294");
  const clientViewerOrEditor =
    "@request.auth.id != '' && (owner = @request.auth.id || projects_via_client.sharedViewers ?= @request.auth.id || projects_via_client.sharedEditors ?= @request.auth.id)";
  clients.listRule = clientViewerOrEditor;
  clients.viewRule = clientViewerOrEditor;
  // create/update/delete stay owner-only (unchanged from ADR-028) - sharing
  // a project only reveals its client, never hands over editing it.
  app.save(clients);

  const users = app.findCollectionByNameOrId("users");
  users.listRule = "@request.auth.id != ''";
  users.viewRule = "@request.auth.id != ''";
  app.save(users);
}, (app) => {
  const ownerRule = "@request.auth.id != '' && owner = @request.auth.id";
  const projectOwnerRule =
    "@request.auth.id != '' && project.owner = @request.auth.id";

  const projects = app.findCollectionByNameOrId("pbc_484305853");
  projects.listRule = ownerRule;
  projects.viewRule = ownerRule;
  projects.createRule = ownerRule;
  projects.updateRule = ownerRule;
  projects.deleteRule = ownerRule;
  app.save(projects);

  const ownedViaProject = [
    "pbc_3223496621",
    "pbc_461364642",
    "pbc_7001112223",
    "pbc_319770345",
    "pbc_4073588220",
    "pbc_1378466011",
    "pbc_4101664731",
  ];
  for (const id of ownedViaProject) {
    const collection = app.findCollectionByNameOrId(id);
    collection.listRule = projectOwnerRule;
    collection.viewRule = projectOwnerRule;
    collection.createRule = projectOwnerRule;
    collection.updateRule = projectOwnerRule;
    collection.deleteRule = projectOwnerRule;
    app.save(collection);
  }

  const clients = app.findCollectionByNameOrId("pbc_2442875294");
  clients.listRule = ownerRule;
  clients.viewRule = ownerRule;
  app.save(clients);

  const users = app.findCollectionByNameOrId("users");
  users.listRule = "id = @request.auth.id";
  users.viewRule = "id = @request.auth.id";
  app.save(users);
})
