/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_1895390756")

  // add field
  collection.fields.addAt(17, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text3427619058",
    "max": 0,
    "min": 0,
    "name": "rigging_kind",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": false,
    "system": false,
    "type": "text"
  }))

  // add field
  collection.fields.addAt(18, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text4118625930",
    "max": 0,
    "min": 0,
    "name": "gdtf_fixture_type_id",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": false,
    "system": false,
    "type": "text"
  }))

  // add field
  collection.fields.addAt(19, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text2871053649",
    "max": 0,
    "min": 0,
    "name": "gremium_inventory_item_id",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": false,
    "system": false,
    "type": "text"
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_1895390756")

  // remove field
  collection.fields.removeById("text3427619058")

  // remove field
  collection.fields.removeById("text4118625930")

  // remove field
  collection.fields.removeById("text2871053649")

  return app.save(collection)
})
