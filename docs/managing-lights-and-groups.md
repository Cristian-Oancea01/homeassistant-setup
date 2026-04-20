# Managing Lights and Light Groups in Home Assistant

This project uses two approaches for light groups — YAML and UI. This guide covers both.

---

## YAML Light Groups (current setup)

Defined in `config/integrations/light_groups.yaml`, included via `configuration.yaml`.

**Current groups:**

| Entity | Name | Members |
|--------|------|---------|
| `light.group_office_1_desk_setup` | Desk Setup | `light.office_1_desk` + `light.office_1_pc_bars` |
| `light.group_office_1_shelves` | Office 1 Shelves | `light.office_1_shelf_upper` + `light.office_1_shelf_lower` |

**To add a new YAML group:**

1. Edit `config/integrations/light_groups.yaml`
2. Add a new entry:
   ```yaml
   - platform: group
     name: "My Group Name"
     unique_id: group_my_group_name   # must be unique, snake_case
     entities:
       - light.entity_id_1
       - light.entity_id_2
   ```
3. Restart Home Assistant (Developer Tools → YAML → Restart).
4. The group appears as `light.my_group_name` in HA states.
5. Add the entity to the relevant Lovelace view in `config/lovelace/views/`.

---

## UI Light Groups (Helpers)

HA supports creating light groups directly from the UI — no config reload needed.

**To create a light group via UI:**

1. Go to **Settings → Devices & Services → Helpers**
2. Click **+ Add Helper** → **Group** → **Light Group**
3. Fill in:
   - **Name** — displayed in the dashboard (e.g. `Desk Setup`)
   - **Members** — pick the lights to group (type to search by entity or friendly name)
   - **Hide members** — enable if you don't want the individual lights to appear in the default UI
4. Click **Create**. The group appears immediately as a new `light.*` entity.
5. Find the entity ID under **Settings → Devices & Services → Helpers** or **Developer Tools → States** (search for your group name).
6. Add a mushroom light card to the relevant view in `config/lovelace/views/`:
   ```yaml
   - type: custom:mushroom-light-card
     entity: light.<your_group_entity_id>
     name: My Group
     show_brightness_control: true
     show_color_control: true
     collapsible_controls: true
   ```

**To edit an existing UI group:**

1. **Settings → Devices & Services → Helpers**
2. Click the group → **Edit**
3. Add or remove member lights → **Update**

**To delete a UI group:**

1. **Settings → Devices & Services → Helpers**
2. Click the group → **Delete**
3. Remove the card from the Lovelace YAML view.

---

## Finding Real Entity IDs

When adding new lights from Hue, Govee, or other integrations:

1. **Developer Tools → States** — filter by `light.` to see all light entities and their current state.
2. **Developer Tools → Template** — use `{{ states.light | map(attribute='entity_id') | list }}` to list all light entity IDs.
3. Real entity IDs always follow the pattern: `light.<device_name_snake_case>`.

---

## Renaming Lights (Friendly Name)

HA entity IDs come from the integration (e.g. Hue app room/device names). To change the **display name** without changing the entity ID:

1. **Settings → Devices & Services** → find the device → click the entity
2. Click the pencil icon → change **Name** → **Update**

Or rename in the Lovelace card directly using the `name:` property — this only affects the dashboard display.

To change the **entity ID** itself (affects automations, scripts, templates):

1. Developer Tools → States → click the entity → **Edit** (wrench icon)
2. Change the entity ID → **Update** — note this will break any existing automations referencing the old ID.
