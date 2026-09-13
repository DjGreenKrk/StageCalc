/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const usersCollection = app.findCollectionByNameOrId("users")

  const clients = app.findCollectionByNameOrId("pbc_2442875294")
  clients.fields.add(new Field({
    "cascadeDelete": false,
    "collectionId": usersCollection.id,
    "hidden": false,
    "id": "relation3011667260",
    "maxSelect": 1,
    "minSelect": 0,
    "name": "owner",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "relation"
  }))
  app.save(clients)

  const projects = app.findCollectionByNameOrId("pbc_484305853")
  projects.fields.add(new Field({
    "cascadeDelete": false,
    "collectionId": usersCollection.id,
    "hidden": false,
    "id": "relation3011667261",
    "maxSelect": 1,
    "minSelect": 0,
    "name": "owner",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "relation"
  }))
  return app.save(projects)
}, (app) => {
  const clients = app.findCollectionByNameOrId("pbc_2442875294")
  clients.fields.removeById("relation3011667260")
  app.save(clients)

  const projects = app.findCollectionByNameOrId("pbc_484305853")
  projects.fields.removeById("relation3011667261")
  return app.save(projects)
})
