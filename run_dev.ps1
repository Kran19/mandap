# Launch Admin API
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd adminpanel/api; npm run start:dev" -WorkingDirectory $PSScriptRoot

# Launch Admin Web
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd adminpanel/web; npm run dev" -WorkingDirectory $PSScriptRoot

# Launch Flutter Application
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd application; D:\flutter\bin\flutter.bat run -d chrome" -WorkingDirectory $PSScriptRoot

Write-Host "Launched Admin API, Admin Web, and Flutter App in separate windows!" -ForegroundColor Green
Absolutely. Below is the final consolidated master prompt. It removes Stage, Flooring, and customer Poles from the current UX while preserving their C-V2 architecture for later phases.

You can give this directly to your coding agent.

MANDAP V2 — TRUSS STRUCTURE BUILDER
FINAL MASTER IMPLEMENTATION PROMPT
============================================================
PROJECT
============================================================

MANDAP V2

FEATURE:
TRUSS STRUCTURE BUILDER

PHASE:
POST-C-V2

BASELINE:
MANDAP V2 Phase C-V2 is COMPLETE / FROZEN.

============================================================
0. MISSION
============================================================

Transform the current MANDAP project editor into a dedicated,
professional TRUSS STRUCTURE BUILDER.

The current product experience should focus exclusively on designing
event truss structures.

The customer workflow is:

    LOGIN
      ↓
    PROJECTS
      ↓
    NEW PROJECT
      ↓
    PROJECT NAME
      ↓
    PLOT SIZE
      ↓
    TRUSS SIZE
      ↓
    GENERATE TRUSS
      ↓
    2D TRUSS BUILDER
      ↓
    CUSTOM EDITING
      ↓
    TRUSS CALCULATION / BOM
      ↓
    SAVE
      ↓
    SYNC
      ↓
    OPTIONAL 3D VIEW

The customer enters dimensions first.

MANDAP generates the actual structural truss.

The customer then customizes that generated structure.

This is NOT a generic drawing application.

This is NOT a simple rectangle generator.

This is a structural/event truss planning application.

============================================================
1. C-V2 FREEZE — ABSOLUTE RULE
============================================================

MANDAP V2 Phase C-V2 is frozen.

DO NOT rewrite, weaken, bypass, or duplicate any of the following:

- Phone-first authentication
- Phone/password/OTP authentication
- Redis OTP architecture
- Refresh sessions
- User architecture
- Organization tenancy
- Customer RBAC
- Admin RBAC
- Trial eligibility
- Billing architecture
- Razorpay integration
- ProjectVersion
- optimistic concurrency
- IdempotencyRecord
- ProjectSyncService
- LocalProjectStore
- offline persistence
- 409 conflict handling
- MandapLayout
- MandapNode
- MandapEdge
- existing undo/redo architecture
- existing coordinate system
- existing serializer
- legacy zone compatibility
- existing security controls

This feature is implemented ON TOP OF C-V2.

Do not create:

- second editor
- second project model
- second layout model
- second persistence system
- second sync system
- second coordinate system
- second truss model
- second BOM system

Reuse the existing architecture.

============================================================
2. CURRENT SCOPE — TRUSS ONLY
============================================================

THIS PHASE IS EXCLUSIVELY FOR TRUSS.

The current customer-facing builder must expose:

    TRUSS

Only.

DO NOT expose in the current builder:

    STAGE
    FLOORING
    PIPE
    CUSTOMER POLE

These are intentionally deferred.

Do NOT delete their existing C-V2 domain support.

Existing NodeTypes remain intact:

    NodeType.stage
    NodeType.carpet
    NodeType.pole

Existing projects containing these components must continue loading.

However, they should not appear in the primary Truss Builder creation UI.

Future phases will add:

    Flooring
    Stage
    Customer Poles

Do not implement those features now.

Do not create placeholder buttons for them.

Do not create speculative APIs for them.

============================================================
3. FIRST STEP — AUDIT THE EXISTING CODE
============================================================

Before changing code, inspect the actual repository.

Audit:

    application/
    adminpanel/

Specifically inspect:

    MandapLayout
    MandapNode
    MandapEdge
    NodeType
    TrussSpecification
    TrussGenerator
    MandapCalculationEngine
    BOM/material calculation
    coordinate transforms
    2D painter
    3D renderer
    MandapEditorController
    command architecture
    undo/redo
    selection
    drag behavior
    rotation
    LocalProjectStore
    ProjectSyncService
    ProjectVersion repository/API
    IdempotencyRecord
    serialization
    project dashboard
    project creation flow

DO NOT assume existing behavior.

Produce a concise architecture mapping before making major changes.

If an existing TrussGenerator already exists, improve/reuse it.

Do not create a competing generator without proving the existing one
cannot support the requirements.

============================================================
4. PRODUCT IDENTITY
============================================================

MANDAP should visually communicate:

    PROFESSIONAL EVENT TRUSS DESIGN

The builder should feel like:

    engineering software
    + event infrastructure planning
    + simple mobile UX

It should NOT feel like:

    generic CAD
    gaming UI
    generic drawing app
    furniture planner

Prioritize:

    structure
    measurements
    coordinates
    engineering grid
    member counts
    dimensions
    clean editing

============================================================
5. VISUAL DESIGN
============================================================

Primary builder canvas:

    deep green engineering background

Truss:

    silver / aluminum / white

Selected truss:

    clear accent highlight

Grid:

    subtle darker/lighter green lines

Text:

    high contrast

Controls:

    minimal
    clean
    professional

Avoid:

    excessive gradients
    excessive cards
    unnecessary decorative elements
    bright neon green
    unnecessary animations

The truss must remain the visual focus.

============================================================
6. NEW PROJECT FLOW
============================================================

When the user taps:

    NEW PROJECT

do NOT immediately open the generic editor.

Flow:

    NEW PROJECT
       ↓
    PROJECT NAME
       ↓
    CREATE TRUSS STRUCTURE
       ↓
    PLOT SIZE
       ↓
    TRUSS SIZE
       ↓
    GENERATE TRUSS
       ↓
    2D BUILDER

============================================================
7. CREATE TRUSS STRUCTURE SCREEN
============================================================

Create a professional screen:

    CREATE TRUSS STRUCTURE

SECTION A:

    PLOT SIZE

Fields:

    Plot Width
    Plot Depth

Example:

    Width: 100 ft
    Depth: 100 ft

The customer controls these values.

Do not hardcode 100 × 100.

Any valid positive dimensions should be supported within configured
application limits.

------------------------------------------------------------

SECTION B:

    TRUSS SIZE

Fields:

    Truss Width
    Truss Depth
    Truss Height / Top Chord Elevation

Example:

    Width: 40 ft
    Depth: 30 ft
    Height: 12 ft

These are examples only.

The customer controls the actual values.

------------------------------------------------------------

SECTION C:

Primary button:

    GENERATE TRUSS

Do not use:

    NEXT — Add to Design

The action should clearly communicate structure generation.

============================================================
8. CUSTOMER DIMENSIONS ARE AUTHORITATIVE
============================================================

If the user enters:

    Plot:
        100 × 100 ft

    Truss:
        40 × 30 ft

    Height:
        12 ft

the generated geometry must use those values.

Do NOT silently:

- scale them
- normalize them
- round them
- replace them with presets
- snap them to arbitrary dimensions
- convert through screen pixels
- substitute hidden defaults

Defaults are allowed only as suggestions.

============================================================
9. PLOT
============================================================

The plot represents the available design area.

Use a plot/application configuration rather than creating a fake
physical truss node.

Conceptually:

    PlotSettings

        width
        depth
        unit
        gridSettings

The plot controls:

    canvas boundary
    grid extent
    coordinate range
    valid placement area
    fit-to-plot behavior

The plot itself is not a structural member.

============================================================
10. REAL TRUSS GENERATION
============================================================

CRITICAL REQUIREMENT:

The current simplified rectangle-style output is NOT acceptable.

Do NOT generate:

    front rectangle
    back rectangle
    four simple poles

and call it a truss.

The generated structure must represent a real event truss portal /
roof structure similar to the supplied reference image.

The reference image is the visual/topological target.

The generated structure should communicate:

    EVENT TRUSS STRUCTURE

with:

    four primary outer vertical supports
    upper perimeter truss
    depth members
    roof structure
    recessed/inner roof frame
    diagonal corner transitions
    internal roof members
    connected structural topology
    lattice/X-bracing in rendering
    proper joints/connections

The structure must be generated from actual domain geometry.

Do NOT fake the structure using renderer-only decoration.

============================================================
11. TRUSS GENERATOR
============================================================

Use/create:

    TrussSpecification
    TrussGenerator

The specification should contain the required customer inputs.

Conceptually:

    TrussSpecification

        plotWidth
        plotDepth
        trussWidth
        trussDepth
        trussHeight
        profile/configuration
        optional structural parameters

The generator returns:

    MandapLayout

containing:

    MandapNode
    MandapEdge

Do not create a separate truss graph.

============================================================
12. STRUCTURAL TOPOLOGY
============================================================

The generated topology must be deterministic.

At minimum support:

    OUTER FRONT PORTAL
    OUTER BACK PORTAL
    LEFT DEPTH CONNECTION
    RIGHT DEPTH CONNECTION
    ROOF / INNER FRAME
    CORNER TRANSITIONS
    INTERNAL ROOF MEMBERS

Every structural member must be represented by a real edge.

Every edge must reference valid nodes.

Required invariants:

    no orphan nodes
    no orphan edges
    no invalid node references
    no duplicate edges
    no zero-length edges
    no NaN coordinates
    no infinite coordinates

============================================================
13. STRUCTURAL POINTS
============================================================

The supplied design references include:

    5-point structure
    6-point structure

Treat these as structural configurations.

Do NOT make them decorative dots.

Each point must represent an actual world-space structural/control point.

The configuration must define:

    what each point means
    how its coordinates affect the structure
    which members depend on it

The points must be part of the structural editing model.

============================================================
14. CENTER CONTROL POINT
============================================================

Implement the requested:

    CENTER DOT

This is a structural control point.

Moving it must change actual geometry.

It must NOT simply move a visual dot.

Example parameters that may be controlled:

    inner roof opening
    roof depth
    inner frame position
    roof geometry

The exact parameter must be defined in the domain/application layer.

When moved:

    structural nodes update
    structural edges update
    dimensions update
    BOM updates
    2D updates
    3D updates
    local persistence marks dirty

============================================================
15. TRUSS NUMBERING
============================================================

Generated members must have visible identifiers.

Recommended:

    T1
    T2
    T3
    T4
    ...

Persistent UUIDs remain the real identity.

Do NOT use list indexes as persistent IDs.

Member labels are presentation metadata.

Numbering must be deterministic.

Example:

    T1 = 10 ft
    T2 = 10 ft
    T3 = 8 ft

The user should clearly understand which physical member each label
represents.

============================================================
16. TRUSS LENGTH
============================================================

Every member length must be calculated from world coordinates.

Use:

    distance(startPosition, endPosition)

Do NOT calculate from:

    screen pixels
    rendered dimensions
    labels
    hardcoded lengths

Example:

    10 ft member

must actually have geometric length:

    10 ft

within the defined numerical tolerance.

============================================================
17. TOTAL TRUSS CALCULATION
============================================================

Provide a truss-specific summary.

Example:

    TRUSS SUMMARY

    Members
        20

    Total Truss
        184 ft

    Supports
        4

    Height
        30 ft

Optionally:

    10 ft × 12
    8 ft × 4
    6 ft × 4

The system must distinguish:

    total geometric length

from:

    inventory quantity by standard member length

Do not mix the two concepts.

============================================================
18. STANDARD MEMBER GROUPING
============================================================

If standardized inventory lengths are supported:

    10 ft
    8 ft
    6 ft
    etc.

group calculated members by actual length.

Example:

    12 members × 10 ft
    4 members × 8 ft

Then:

    total geometric length = 152 ft

Do not round member lengths into inventory buckets unless explicitly
configured.

============================================================
19. POLES / SUPPORTS
============================================================

This phase is TRUSS ONLY.

Do not expose customer-added Pole UI.

However, generated structural support geometry may remain part of the
truss system according to the existing architecture.

Do not create a second Pole model.

Do not count every NodeType.pole in the entire project as a truss support.

Use existing structural semantics to identify generated supports.

If the existing system represents support members differently,
preserve that architecture.

============================================================
20. DEFAULT "30" REQUIREMENT
============================================================

The product requirement states:

    "Poles by default 30 only in truss"

Do NOT guess the meaning.

Audit the existing implementation.

If 30 means:

    support height = 30 ft

then implement:

    default support height = 30 ft

If it means another parameter, preserve the actual existing semantic.

Do not implement a random "30 poles" count.

Any default must remain editable if the domain permits editing.

============================================================
21. 2D BUILDER
============================================================

The primary design workspace is 2D.

It must display:

    plot boundary
    engineering grid
    coordinate axes
    truss geometry
    structural nodes
    control points
    member labels
    dimensions
    selection
    Pen state
    Stretch controls

The 2D canvas is a projection of the authoritative world-space model.

It is NOT the source of truth.

============================================================
22. GREEN ENGINEERING CANVAS
============================================================

Use:

    deep green background

with:

    silver/white truss
    subtle engineering grid
    readable dimension labels

The green should be professional and dark.

Avoid neon green.

The grid should remain visually subordinate to the truss.

============================================================
23. GRID
============================================================

Reuse the existing adaptive grid system.

Conceptually:

    GridSettings

        visible
        snapEnabled
        spacing
        subdivision
        displayPrecision

Examples:

    0.10 ft
    0.01 ft

Zoom behavior:

    zoomed out:
        major grid

    zoomed in:
        subdivisions

    deeper zoom:
        0.01 increments

Changing grid settings must NOT modify domain coordinates.

============================================================
24. SNAP
============================================================

Provide:

    SNAP

with:

    ON
    OFF

SNAP ON:

    pointer position snaps to active grid.

SNAP OFF:

    free world-space placement.

Snap is an interaction feature only.

It does not replace stored coordinates.

============================================================
25. COORDINATES
============================================================

Authoritative coordinate system:

    X
    Z
    elevation/Y

Never use:

    screen pixel coordinates

as stored geometry.

Display:

    X: 10.20 ft
    Z: 15.40 ft

or equivalent engineering notation.

Display rounding is UI-only.

Storage must retain the actual floating-point value.

============================================================
26. 3D VIEW
============================================================

3D remains available as a visualization/editing surface where supported.

The 3D view must render the same MandapLayout used by 2D.

Do NOT create a separate 3D approximation.

Truss should render as:

    silver/aluminum structure

with:

    tubular members
    lattice/X-bracing
    joints
    supports
    roof structure

The 3D result should resemble the supplied real-world truss reference.

============================================================
27. 2D / 3D PARITY
============================================================

2D and 3D must share the same domain model.

Example:

    Move point in 2D
        ↓
    MandapLayout changes
        ↓
    3D updates

and where 3D editing is supported:

    Move point in 3D
        ↓
    MandapLayout changes
        ↓
    2D updates

No duplicated geometry.

============================================================
28. 3D COORDINATE INTERACTION
============================================================

For 3D dragging:

    screen point
        ↓
    camera ray
        ↓
    known interaction plane
        ↓
    world coordinate

Use the correct structural plane.

Do not blindly force:

    Y = 0

for elevated geometry.

Camera orbit, zoom, and pan must never alter domain coordinates.

============================================================
29. PEN TOOL
============================================================

Add a prominent:

    PEN

tool.

PEN OFF:

    normal navigation

PEN ON:

    structural editing mode

CRITICAL:

When PEN is ON, normal drag gestures must NOT accidentally pan or move
the entire structure.

The interaction mode must be unambiguous.

============================================================
30. PEN ACTIONS
============================================================

When PEN is active, allow appropriate structural actions:

    select node
    move node
    select member
    add member
    stretch member
    delete member

Do not overload one gesture with ambiguous behavior.

Provide clear active-state feedback.

============================================================
31. ADD TRUSS MEMBER
============================================================

The user must be able to add a truss member with Pen.

Example:

    tap start point
        ↓
    tap/drag end point
        ↓
    create member

The implementation must:

    create/reuse nodes
    create edge
    validate topology
    calculate length
    update BOM
    support undo
    persist locally
    sync through existing pipeline

The widget must NOT directly mutate domain maps.

============================================================
32. STRETCH ARROW
============================================================

Add:

    STRETCH

interaction.

When a member/structural section is selected:

    directional arrow/handle

must appear.

Dragging the handle modifies actual world geometry.

Example:

    10 ft
      ↓
    stretch
      ↓
    14 ft

The edge must actually become 14 ft geometrically.

Do not scale a rendered image.

============================================================
33. CENTER POINT + STRETCH
============================================================

Both interactions must modify the structural graph.

After modification:

    node coordinates
    edge lengths
    dimensions
    total truss
    BOM
    2D
    3D

must update from the same domain state.

============================================================
34. DELETE
============================================================

Allow deletion of valid truss members.

Node deletion is allowed only when structurally valid.

Never create:

    orphan edges
    orphan nodes
    broken references

If deletion would violate mandatory topology:

    prevent deletion

or:

    perform an explicit valid restructuring.

Do not silently corrupt the graph.

============================================================
35. THIN TRUSS
============================================================

Provide:

    THIN TRUSS

as a truss profile/visual option if compatible with the existing domain.

Changing profile must NOT change:

    member length
    world coordinates
    structural dimensions

Example:

    10 ft remains 10 ft.

Reuse existing profile concepts if present.

Do not create a second geometry engine.

============================================================
36. COMMAND ARCHITECTURE
============================================================

All semantic changes use commands.

Examples:

    AddTrussCommand
    MoveNodeCommand
    StretchTrussCommand
    DeleteTrussCommand
    UpdateTrussSpecificationCommand
    ChangeTrussProfileCommand

Every command supports:

    execute
    undo

Use the existing command stack.

Pointer drags must coalesce into one logical command.

Do not create one undo operation per pointer frame.

============================================================
37. UNDO / REDO
============================================================

Support:

    Generate
    Add
    Move
    Stretch
    Delete
    Profile change
    Center-point edit

Example:

    Generate
       ↓
    Add member
       ↓
    Stretch member
       ↓
    Undo
       ↓
    Undo
       ↓
    Redo

The domain state must restore correctly.

============================================================
38. INSPECTOR
============================================================

When selecting a truss member show:

    Member ID
    Length
    Start Point
    End Point
    Profile
    Elevation
    Structural information

Actions:

    Stretch
    Delete

When selecting a structural point:

    Point ID
    X
    Z
    Elevation

Actions:

    Move
    Delete if structurally valid

============================================================
39. DIMENSION LABELS
============================================================

Display engineering dimensions on the 2D canvas.

Examples:

    40.00 ft
    30.00 ft
    12.00 ft
    10.00 ft

Labels must come from world geometry.

They are not manually typed text.

============================================================
40. PROJECT PERSISTENCE
============================================================

The creation pipeline is:

    Generate Truss
        ↓
    Command
        ↓
    MandapLayout
        ↓
    LocalProjectStore
        ↓
    DIRTY
        ↓
    ProjectSyncService
        ↓
    ProjectVersion
        ↓
    CLEAN

The wizard/builder must NOT directly call HTTP.

============================================================
41. OFFLINE
============================================================

If the customer is offline:

    generate
    edit
    stretch
    add
    delete

must continue working where local data is available.

Persist locally.

Possible state:

    DIRTY
    OFFLINE

The structure must not disappear.

When connectivity returns:

    ProjectSyncService

handles synchronization.

============================================================
42. IDEMPOTENCY
============================================================

Continue using:

    Idempotency-Key

and:

    IdempotencyRecord

Same key + same request:

    idempotent replay

Same key + different request:

    409

Do not create a new builder-specific persistence mechanism.

============================================================
43. OPTIMISTIC CONCURRENCY
============================================================

ProjectVersion remains authoritative.

If:

    expectedCurrentVersionId

is stale:

    server returns 409

Then:

    preserve local structure
    enter existing CONFLICT state
    allow user resolution

Never silently overwrite the customer's custom truss.

============================================================
44. SAVE BEHAVIOR
============================================================

Meaningful structural mutations trigger local persistence.

Examples:

    Generate
    Add
    Move
    Stretch
    Delete
    Change specification
    Change structural profile

Do NOT mark dirty for:

    camera movement
    zoom
    selection
    inspector open
    grid visibility
    Pen toggle

============================================================
45. EXISTING PROJECTS
============================================================

Existing project flow:

    PROJECTS
       ↓
    OPEN PROJECT
       ↓
    latest ProjectVersion
       ↓
    TRUSS BUILDER

Do NOT regenerate the structure every time an existing project opens.

Load the stored version.

Only the new-project flow generates the initial truss.

============================================================
46. EXISTING C-V2 COMPONENT COMPATIBILITY
============================================================

Existing projects containing:

    TRUSS
    POLE
    STAGE
    CARPET

must continue to deserialize.

Do not delete existing domain support.

If an existing project contains Stage/Flooring/Pole:

    load safely

but do not expose them as new components in the current Truss Builder
creation UI.

============================================================
47. LEGACY ZONE COMPATIBILITY
============================================================

Preserve C-V2 legacy behavior:

    legacy flooring zone
        ↓
    NodeType.carpet

    legacy stage zone
        ↓
    NodeType.stage

Requirements:

    authoritative node wins
    deduplicate
    preserve IDs where possible
    malformed data fails safely
    historical ProjectVersion remains immutable
    deserialization does not mark layout DIRTY
    new writes use first-class nodes

Do not remove legacy support in this phase.

============================================================
48. CALCULATION / BOM
============================================================

The calculation engine remains authoritative for structural metrics.

Do not implement separate UI-only calculations.

At minimum calculate:

    truss member count
    total truss length
    member length groups
    structural support count
    structure height

All calculations derive from the domain graph.

============================================================
49. EXAMPLE
============================================================

User enters:

    Plot Width:       100 ft
    Plot Depth:       100 ft

    Truss Width:       40 ft
    Truss Depth:       30 ft
    Truss Height:      12 ft

System generates the real truss structure.

Then user:

    moves center point
    stretches a member
    adds a member
    deletes a member

The system recalculates everything.

Example:

    T1 = 10 ft
    T2 = 10 ft
    T3 = 14 ft

Total:

    34 ft

If the user adds another 10 ft member:

    44 ft

The displayed BOM must update automatically.

============================================================
50. PERFORMANCE
============================================================

The builder must remain responsive for practical event structures.

Test at least:

    100 × 100 ft plot
    substantial truss topology
    multiple members
    repeated editing
    zoom
    pan
    undo/redo
    save/sync

Do NOT:

    persist every pointer frame
    make API calls every frame
    rebuild the entire application unnecessarily
    create unnecessary object graphs every frame

============================================================
51. SECURITY
============================================================

Do not expose:

    JWT
    refresh tokens
    Redis OTP
    billing secrets
    internal secrets

Do not bypass backend authorization.

Customer permissions remain:

    OWNER
        full editing

    EDITOR
        editing

    VIEWER
        read-only

Archived projects:

    readable
    not editable

============================================================
52. TESTING — GENERATOR
============================================================

Test:

    arbitrary plot size
    arbitrary truss width
    arbitrary truss depth
    arbitrary height
    deterministic generation
    expected topology
    node count
    edge count
    no orphan nodes
    no orphan edges
    no duplicate edges
    no zero-length edges
    exact coordinates
    exact elevations
    exact dimensions

============================================================
53. TESTING — 5 / 6 POINT STRUCTURES
============================================================

Test:

    5-point configuration

and:

    6-point configuration

Verify:

    points are real structural/control points
    coordinates are correct
    dependent members update
    BOM updates
    undo/redo works
    serialization works

============================================================
54. TESTING — CENTER CONTROL
============================================================

Test:

    initial structure
        ↓
    move center control point
        ↓
    structure changes
        ↓
    member lengths change
        ↓
    BOM changes
        ↓
    undo
        ↓
    original structure restored

============================================================
55. TESTING — STRETCH
============================================================

Test:

    member = 10 ft
        ↓
    stretch
        ↓
    member = 14 ft

Verify:

    actual world geometry = 14 ft
    label = 14 ft
    BOM = 14 ft
    serialization = 14 ft
    reload = 14 ft

============================================================
56. TESTING — PEN
============================================================

Verify:

    PEN OFF
        → navigation works

    PEN ON
        → structural editing works

Specifically:

    PEN ON + drag
        ≠
    accidental camera movement

Test:

    add
    move
    stretch
    delete

and verify undo/redo.

============================================================
57. TESTING — 2D / 3D
============================================================

Test:

    2D coordinate
        ↓
    domain
        ↓
    3D

and where supported:

    3D coordinate
        ↓
    domain
        ↓
    2D

Use defined numerical tolerances.

Do not claim mathematical exactness from perspective projection.

Use:

    camera ray
       ↓
    known interaction plane
       ↓
    world coordinate

============================================================
58. TESTING — SERIALIZATION
============================================================

Test:

    generate
       ↓
    serialize
       ↓
    deserialize

Verify equivalent:

    nodes
    edges
    coordinates
    dimensions
    elevation
    rotation
    IDs
    topology
    profile
    control points

Also verify C-V2 legacy zone tests still pass.

============================================================
59. TESTING — LOCAL PERSISTENCE
============================================================

Test:

    generate
       ↓
    local persistence
       ↓
    DIRTY

Then:

    app restart
       ↓
    same structure

Then:

    offline edit
       ↓
    structure remains

============================================================
60. TESTING — SERVER PERSISTENCE
============================================================

Mandatory:

DEVICE A:

    create project
    plot = 100 × 100
    custom truss dimensions
    generate
    move center point
    stretch member
    add member
    save

SERVER:

    verify ProjectVersion

DEVICE B:

    login
    open same project

Verify:

    same topology
    same coordinates
    same dimensions
    same member lengths
    same custom edits

Do NOT test using only the untouched default structure.

The modified structure must be persisted.

============================================================
61. TESTING — IDEMPOTENCY
============================================================

Test:

    same key
    same request
        → one logical mutation

and:

    same key
    different request
        → 409

============================================================
62. TESTING — CONFLICT
============================================================

Device A:

    version N

Device B:

    version N

Device A saves:

    version N+1

Device B saves with:

    expectedCurrentVersionId = N

Expected:

    409

Device B local structure remains intact.

Conflict resolution remains available.

============================================================
63. TESTING — REGRESSION
============================================================

Run all relevant Phase 0–10 regression tests.

Verify that this feature does not break:

    authentication
    OTP
    organizations
    RBAC
    billing
    trial
    projects
    versioning
    serializer
    sync
    idempotency
    offline persistence
    conflict handling

============================================================
64. IMPLEMENTATION ORDER
============================================================

Do NOT start by redesigning the UI.

FIRST:

    1. Audit existing architecture
    2. Audit existing TrussGenerator
    3. Audit topology
    4. Audit coordinate model
    5. Audit calculation/BOM
    6. Audit editor commands
    7. Audit 2D renderer
    8. Audit 3D renderer
    9. Audit persistence/sync

THEN:

    10. PlotSettings
    11. Create Truss Structure flow
    12. TrussSpecification
    13. Real structural topology
    14. TrussGenerator
    15. Member identity/numbering
    16. Member length calculation
    17. 2D builder
    18. Pen mode
    19. Structural control points
    20. Center control
    21. Stretch
    22. Add member
    23. Delete member
    24. Thin Truss
    25. Inspector
    26. Green engineering canvas
    27. 3D parity
    28. BOM
    29. Local persistence
    30. ProjectVersion sync
    31. Idempotency
    32. Conflict handling
    33. Tests
    34. Performance
    35. Full regression

============================================================
65. NO UI-ONLY FAKE STRUCTURE
============================================================

This is a mandatory rule.

DO NOT:

    draw a fake truss image
    add decorative X lines
    visually simulate missing members
    create geometry only in the renderer

The actual structural graph must contain the structural members.

The renderer visualizes the domain graph.

============================================================
66. NO SECOND ARCHITECTURE
============================================================

Do not create:

    TrussLayout
    TrussProject
    TrussDatabase
    TrussSyncService
    TrussSerializer
    TrussEditor

if equivalent C-V2 systems already exist.

Use:

    MandapLayout
    MandapNode
    MandapEdge
    ProjectVersion
    ProjectSyncService
    LocalProjectStore

============================================================
67. FUTURE EXTENSIBILITY
============================================================

The current UI is TRUSS ONLY.

However, architecture should allow future components to reuse the same:

    MandapLayout
    MandapNode
    MandapEdge
    command system
    selection
    inspector
    2D renderer architecture
    3D renderer architecture
    persistence
    sync
    ProjectVersion
    idempotency

Future:

    Flooring
    Stage
    Customer Pole

must be addable later without rebuilding the core editor.

Do NOT implement them now.

============================================================
68. DEFINITION OF DONE
============================================================

This phase is COMPLETE only when:

[ ] New Project opens Create Truss Structure.
[ ] User can enter arbitrary plot width/depth.
[ ] User can enter arbitrary truss width/depth/height.
[ ] Generate Truss uses exact customer dimensions.
[ ] Generated structure is a real structural graph.
[ ] Generated topology resembles the supplied original truss reference.
[ ] Structure is not a simplistic rectangle.
[ ] Structural members have persistent IDs.
[ ] Member labels are deterministic.
[ ] Member lengths come from world geometry.
[ ] Total truss length is calculated.
[ ] Member quantity grouping is calculated.
[ ] Support count is calculated correctly.
[ ] 2D builder works.
[ ] Green engineering canvas works.
[ ] Grid works.
[ ] Adaptive grid works.
[ ] Snap works.
[ ] Coordinates are visible.
[ ] 5-point structure works.
[ ] 6-point structure works.
[ ] Center control point works.
[ ] Center control changes actual geometry.
[ ] Pen mode works.
[ ] Pen mode prevents accidental camera movement.
[ ] User can add truss members.
[ ] User can move structural points.
[ ] User can stretch members.
[ ] User can delete valid members.
[ ] Thin Truss works.
[ ] Inspector works.
[ ] Undo works.
[ ] Redo works.
[ ] 3D renders the same domain structure.
[ ] 2D/3D coordinate parity is verified.
[ ] Local persistence works.
[ ] Offline editing works.
[ ] ProjectVersion persistence works.
[ ] Idempotency works.
[ ] 409 conflict handling works.
[ ] Modified structure survives cross-device reload.
[ ] Existing C-V2 projects continue loading.
[ ] Legacy Stage/Flooring zones remain compatible.
[ ] Stage/Flooring/Pole are NOT exposed in this phase's UI.
[ ] Authentication remains intact.
[ ] Billing remains intact.
[ ] Trial system remains intact.
[ ] RBAC remains intact.
[ ] Archived projects remain read-only.
[ ] Full regression passes.
[ ] No second editor/persistence/sync architecture exists.

============================================================
69. VERIFICATION STANDARD
============================================================

DO NOT declare the phase complete because:

    code compiles
    APK builds
    screens render
    static analysis passes

Those are implementation evidence only.

Final report must separate:

    IMPLEMENTED
    UNIT TESTED
    INTEGRATION TESTED
    RUNTIME VERIFIED
    CROSS-DEVICE VERIFIED
    BLOCKED

If Flutter/Dart runtime is unavailable in the execution environment:

    explicitly mark Flutter runtime verification BLOCKED.

Do not fabricate test results.

============================================================
70. FINAL COMPLETION REPORT
============================================================

At completion provide:

A. Architecture audit
B. Files changed
C. Domain changes
D. Truss topology changes
E. Generator changes
F. 2D builder changes
G. Pen implementation
H. Center-point implementation
I. Stretch implementation
J. 3D implementation
K. BOM/calculation changes
L. Persistence changes
M. Sync/idempotency changes
N. Cross-device test
O. Tests executed
P. Test count
Q. Runtime verification
R. Performance results
S. Security regression
T. Phase 0–10 regression
U. Known limitations
V. Screenshots/evidence
W. Confirmation that C-V2 remains frozen

============================================================
71. FINAL PRODUCT PRINCIPLE
============================================================

The most important product rule is:

    USER ENTERS SIZE
            ↓
    MANDAP GENERATES REAL TRUSS
            ↓
    USER CUSTOMIZES REAL TRUSS
            ↓
    MANDAP RECALCULATES REAL STRUCTURE
            ↓
    MANDAP SAVES REAL STRUCTURE

The application must never fake the structure visually.

The geometry, calculations, BOM, coordinates, persistence,
2D representation, and 3D representation must all derive from
the same authoritative MandapLayout.

============================================================
END OF MASTER PROMPT
============================================================
Final scope

For this phase, keep the product very focused:

TRUSS only.

5

Then later you can add:

TRUSS BUILDER  ← NOW
     │
     ├── Flooring  ← FUTURE
     ├── Stage     ← FUTURE
     └── Poles     ← FUTURE

The key is that Flooring, Stage, and Poles are not deleted from C-V2; they are simply not exposed in this phase. This keeps the current product simple while preserving the architecture for the next phases.