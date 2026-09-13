/// <reference path="../pb_data/types.d.ts" />

// ADR-028: replaces the empty/public rules from ADR-017 with real
// authorization. "Shared" collections are readable/writable by any
// authenticated team member; "private" ones are restricted to their owner
// (directly, or via their `project` relation for anything nested under a
// project).
migrate((app) => {
  const authRule = "@request.auth.id != ''";
  const ownerRule = "@request.auth.id != '' && owner = @request.auth.id";
  const projectOwnerRule =
    "@request.auth.id != '' && project.owner = @request.auth.id";

  const shared = [
    "pbc_1895390756", // catalog_devices
    "pbc_7001112224", // truss_load_chart_entries
    "pbc_1942858786", // locations
    "pbc_2144939904", // location_contacts
    "pbc_304432226", // location_power_connectors
    "pbc_4201605218", // power_presets
    "pbc_421753540", // power_outlet_templates
  ];
  for (const id of shared) {
    const collection = app.findCollectionByNameOrId(id);
    collection.listRule = authRule;
    collection.viewRule = authRule;
    collection.createRule = authRule;
    collection.updateRule = authRule;
    collection.deleteRule = authRule;
    app.save(collection);
  }

  const ownedDirectly = [
    "pbc_2442875294", // clients
    "pbc_484305853", // projects
  ];
  for (const id of ownedDirectly) {
    const collection = app.findCollectionByNameOrId(id);
    collection.listRule = ownerRule;
    collection.viewRule = ownerRule;
    collection.createRule = ownerRule;
    collection.updateRule = ownerRule;
    collection.deleteRule = ownerRule;
    app.save(collection);
  }

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
    collection.listRule = projectOwnerRule;
    collection.viewRule = projectOwnerRule;
    collection.createRule = projectOwnerRule;
    collection.updateRule = projectOwnerRule;
    collection.deleteRule = projectOwnerRule;
    app.save(collection);
  }
}, (app) => {
  const all = [
    "pbc_1895390756",
    "pbc_7001112224",
    "pbc_1942858786",
    "pbc_2144939904",
    "pbc_304432226",
    "pbc_4201605218",
    "pbc_421753540",
    "pbc_2442875294",
    "pbc_484305853",
    "pbc_3223496621",
    "pbc_461364642",
    "pbc_7001112223",
    "pbc_319770345",
    "pbc_4073588220",
    "pbc_1378466011",
    "pbc_4101664731",
  ];
  for (const id of all) {
    const collection = app.findCollectionByNameOrId(id);
    collection.listRule = "";
    collection.viewRule = "";
    collection.createRule = "";
    collection.updateRule = "";
    collection.deleteRule = "";
    app.save(collection);
  }
})
