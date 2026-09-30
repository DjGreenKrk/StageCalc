/// <reference path="../pb_data/types.d.ts" />

// ADR-040: guest read-only sharing links. Not synced to the local Drift
// schema (it is a pure server-side authorization artifact, same reasoning
// as why `owner` never grew a full sync-status column set) - no
// `local_id`/`workspace_id`/`revision`/`deleted` fields like the synced
// collections. Deleting a record revokes the link; there is no separate
// "revoked" flag. The token itself is never validated through the normal
// collection API rules - real guest access goes through the dedicated
// `pb_hooks/guest_project_share.pb.js` route, which looks this collection up
// with full `$app` access, bypassing these rules entirely. These rules only
// govern the owner managing their own links through the normal API.
migrate((app) => {
  const collection = new Collection({
    "createRule": "@request.auth.id != '' && project.owner = @request.auth.id",
    "deleteRule": "@request.auth.id != '' && project.owner = @request.auth.id",
    "fields": [
      {
        "autogeneratePattern": "[a-z0-9]{15}",
        "help": "",
        "hidden": false,
        "id": "text3208210256",
        "max": 15,
        "min": 15,
        "name": "id",
        "pattern": "^[a-z0-9]+$",
        "presentable": false,
        "primaryKey": true,
        "required": true,
        "system": true,
        "type": "text"
      },
      {
        "cascadeDelete": true,
        "collectionId": "pbc_484305853",
        "help": "",
        "hidden": false,
        "id": "relation5590214478",
        "maxSelect": 1,
        "minSelect": 0,
        "name": "project",
        "presentable": false,
        "required": true,
        "system": false,
        "type": "relation"
      },
      {
        "autogeneratePattern": "",
        "help": "",
        "hidden": false,
        "id": "text5590214479",
        "max": 0,
        "min": 0,
        "name": "label",
        "pattern": "",
        "presentable": true,
        "primaryKey": false,
        "required": false,
        "system": false,
        "type": "text"
      },
      {
        "autogeneratePattern": "",
        "help": "",
        "hidden": false,
        "id": "text5590214480",
        "max": 0,
        "min": 0,
        "name": "token",
        "pattern": "",
        "presentable": false,
        "primaryKey": false,
        "required": true,
        "system": false,
        "type": "text"
      },
      {
        "help": "",
        "hidden": false,
        "id": "date5590214481",
        "max": "",
        "min": "",
        "name": "created_at",
        "presentable": false,
        "required": true,
        "system": false,
        "type": "date"
      }
    ],
    "id": "pbc_5590214477",
    "indexes": [
      "CREATE UNIQUE INDEX `idx_project_guest_links_token` ON `project_guest_links` (`token`)"
    ],
    "listRule": "@request.auth.id != '' && project.owner = @request.auth.id",
    "name": "project_guest_links",
    "system": false,
    "type": "base",
    "updateRule": "@request.auth.id != '' && project.owner = @request.auth.id",
    "viewRule": "@request.auth.id != '' && project.owner = @request.auth.id"
  });

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_5590214477");

  return app.delete(collection);
})
