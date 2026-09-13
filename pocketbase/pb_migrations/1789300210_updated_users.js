/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("users")

  collection.listRule = "id = @request.auth.id"
  collection.viewRule = "id = @request.auth.id"
  collection.createRule = null
  collection.updateRule = "id = @request.auth.id"
  collection.deleteRule = null

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("users")

  collection.listRule = null
  collection.viewRule = null
  collection.createRule = null
  collection.updateRule = null
  collection.deleteRule = null

  return app.save(collection)
})
