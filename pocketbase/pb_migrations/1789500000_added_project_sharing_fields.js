/// <reference path="../pb_data/types.d.ts" />

// ADR-040: two new multi-select relation fields on `projects` so a project
// can be shared with team members as either a read-only viewer or a full
// editor, without introducing a separate join collection (see ADR-040 for
// why a single `role` field on a join collection was rejected).
migrate((app) => {
  const usersCollection = app.findCollectionByNameOrId("users");
  const projects = app.findCollectionByNameOrId("pbc_484305853");

  projects.fields.add(
    new Field({
      cascadeDelete: false,
      collectionId: usersCollection.id,
      hidden: false,
      id: "relation3011667262",
      maxSelect: 999,
      minSelect: 0,
      name: "sharedViewers",
      presentable: false,
      required: false,
      system: false,
      type: "relation",
    }),
  );
  projects.fields.add(
    new Field({
      cascadeDelete: false,
      collectionId: usersCollection.id,
      hidden: false,
      id: "relation3011667263",
      maxSelect: 999,
      minSelect: 0,
      name: "sharedEditors",
      presentable: false,
      required: false,
      system: false,
      type: "relation",
    }),
  );
  return app.save(projects);
}, (app) => {
  const projects = app.findCollectionByNameOrId("pbc_484305853");
  projects.fields.removeById("relation3011667262");
  projects.fields.removeById("relation3011667263");
  return app.save(projects);
});
