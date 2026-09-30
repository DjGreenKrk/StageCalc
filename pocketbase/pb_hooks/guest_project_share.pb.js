/// <reference path="../pb_data/types.d.ts" />

// ADR-040: public, read-only endpoint for guest project-sharing links.
// Deliberately the *only* place a request without a logged-in PocketBase
// account can read project data - everything below runs with full `$app`
// access and bypasses the `projects`/nested collections' API rules
// entirely, rather than trying to teach those rules a public, token-gated
// exception (see ADR-040 for why that was rejected as too risky to get
// right without live testing against every collection it would touch).
//
// GET /api/stagecalc/shared/{token}
//
// Returns 404 (not the project's real id, not a permission error) for both
// "token never existed" and "token was revoked" - the two are
// indistinguishable to a caller, which is the point: revoking a link is
// just deleting its `project_guest_links` record.
routerAdd("GET", "/api/stagecalc/shared/{token}", (e) => {
  const token = e.request.pathValue("token");
  if (!token) {
    throw new NotFoundError("Nieznany link.");
  }

  let link;
  try {
    link = e.app.findFirstRecordByFilter(
      "project_guest_links",
      "token = {:token}",
      { token: token },
    );
  } catch (error) {
    link = null;
  }
  if (!link) {
    throw new NotFoundError("Nieznany link.");
  }

  const findByIdOrNull = (collection, id) => {
    if (!id) {
      return null;
    }
    try {
      return e.app.findRecordById(collection, id);
    } catch (error) {
      return null;
    }
  };

  const project = findByIdOrNull("projects", link.getString("project"));
  if (!project) {
    throw new NotFoundError("Nieznany link.");
  }

  const params = { projectId: project.id };
  const byProject = (collection, sort) => {
    const records = e.app.findRecordsByFilter(
      collection,
      "project = {:projectId}",
      sort || "",
      0,
      0,
      params,
    );
    return records.map((record) => record.publicExport());
  };

  const client = findByIdOrNull("clients", project.getString("client"));
  const location = findByIdOrNull("locations", project.getString("location"));

  return e.json(200, {
    label: link.getString("label"),
    project: project.publicExport(),
    client: client ? client.publicExport() : null,
    location: location ? location.publicExport() : null,
    groups: byProject("project_groups", "sort_order"),
    items: byProject("project_items", "sort_order"),
    hookAssignments: byProject("project_group_hook_assignments", "sort_order"),
    distros: byProject("project_distros", "sort_order"),
    outlets: byProject("project_outlets", "sort_order"),
    connections: byProject("power_connections", "sort_order"),
    trusses: byProject("project_trusses", "sort_order"),
  });
});
