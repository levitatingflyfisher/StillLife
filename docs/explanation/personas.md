# Personas

Agents drive the real Still Life build as these people, per the fleet testing
rule. Each scenario gives a start state, plain steps, what success looks like,
and what to check. "Standard checks" means: text scale 1.3 at 360 dp width,
dark mode, airplane mode, and every error in plain words with a way forward.
Scenarios aim at the weak spots found by the September 2026 lens audit.

## Primary: Chidi, cataloguing the house before renewing insurance

Chidi is 47, owns a terraced house with their partner and two kids, and the
insurer asked for a contents list. They spend a Saturday walking room to
room, phone in one hand, photographing things with the other.

- **Goal:** catalogue items room by room and export a claim-ready PDF with
  correct totals.
- **Context:** standing, one-handed, interrupted by kids, weak Wi-Fi in the
  garage.
- **Would quit if:** an interrupted entry is lost, or the PDF is wrong.

**C1. First run.** Start: fresh install. Steps: finish onboarding; read the
Dashboard and Inventory; add the first item from wherever the screen
suggests. Success: the way to add an item is visible and named in words, not
only "Tap +"; the app says what it is for. Check: standard checks; hint text
is readable.

**C2. Add an item, interrupted.** Start: rooms "Garage" and "Kitchen". Steps:
open Add Item from the speed dial; type a name and price; press system back
before saving. Success: the entry is kept as a draft or the app asks first.
Check: no "Set up AI analysis" banner sits over the Name field; Room is not
drawn in the error colour when already filled.

**C3. Where is it?** Start: item "Cordless drill" in Garage, Red toolbox.
Steps: open the item from Inventory. Success: "Garage › Red toolbox" shows
under the name; the label id sits in Details labelled "Label id". Check: text
scale 1.3.

**C4. Insurance PDF totals.** Start: three items worth $12.34, $250.00 and
$1,200.00. Steps: Reports, export the insurance PDF; compare totals with the
Reports tab. Success: the PDF shows $1,462.34, not $146,234.00; progress
shows while it builds. Check: offline; any failure is a plain sentence with
Retry.

**C5. Back up.** Start: Settings with items. Steps: pick the encrypted
backup; create it; then import a broken file. Success: row labels say what
each option is for; the import error is plain, with a retry. Check: exports
are disabled when there are zero items.

## Secondary: Esperanza, sorting a late parent's belongings

Esperanza is 63, clearing their late mother's flat with a sibling, using a
shared tablet with text scale 1.3.

- **Goal:** find, filter and bulk-move items to "Storage Unit", and delete
  duplicates safely.
- **Context:** emotional task, large text, careful and slow.
- **Would quit if:** a delete cannot be taken back.

**E1. Delete and undo.** Start: 20 items. Steps: delete one item from its
detail screen; then bulk-select three and delete. Success: each dialog names
what goes; an Undo follows; no false "cannot be undone". Check: undo after
delete; bulk selection reachable without knowing about long-press.

**E2. Search keeps filters.** Start: filter set to room "Bedroom". Steps: open
search, type "lamp", close search. Success: the Bedroom filter still applies
and the badge tells the truth. Check: every app-bar icon has a label or
tooltip.

**E3. Dashboard at large text.** Start: items in three categories. Steps: read
the four stat tiles. Success: titles are not clipped to "Acquisition C…"; no
tile is painted in the error colour. Check: dark mode.
