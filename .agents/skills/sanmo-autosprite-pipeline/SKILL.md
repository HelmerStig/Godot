---
name: sanmo-autosprite-pipeline
description: Generate, regenerate, download, review, and integrate AutoSprite character animations into the Sanmo Godot project. Use for AutoSprite prompts or MCP operations, spritesheet imports, frame slicing, animation setup, character animation updates, and requests involving Mangler or other Sanmo fighters.
---

# Sanmo AutoSprite Pipeline

Use the AutoSprite MCP tools for remote account, character, job, and spritesheet operations. Keep generation decisions and Godot integration consistent with this repository.

## Safety and authorization

- Never expose, print, store, or commit `AUTOSPRITE_API_KEY`.
- Treat generation as credit-consuming unless the current tool explicitly marks the operation free.
- Before a paid call, state the current cost or estimate and obtain explicit confirmation. A request for a prompt alone never authorizes generation.
- Call `get_account` at most once per session and reuse the returned balance.
- Do not replace an existing PNG or animation resource without explicit user authorization. Preserve source artwork and unrelated working-tree changes.
- Prefer read-only AutoSprite calls while inspecting characters, sheets, jobs, or account state.

## Sanmo asset contract

- Store runtime character assets under `assets/sprites/characters/<character>/`.
- Use lowercase snake-case animation filenames such as `light_punch.png` and `block_hit.png`.
- Use transparent PNG spritesheets with 512x512 cells unless the user explicitly selects another size.
- Keep a fixed side view, consistent canvas alignment, stable ground line, scale, clothing, colors, face, and body proportions.
- Use a right-facing source orientation; let Godot mirror the sprite for the other side.
- Exclude baked shadows, backgrounds, camera motion, perspective changes, rotation, and horizontal drift.
- Let Godot manage world movement, collision, hitboxes, hurtboxes, and the ground shadow.
- Read the atlas or inspect the actual sheet before slicing. Never assume 25 frames or a fixed grid.

## Animation defaults

- Locomotion loops (`idle`, `walk`, `backwalk`, `run`): default to 12 FPS.
- Attacks: default to 24 FPS, non-looping, and align startup/active/recovery with `AttackData`.
- Reactions and transitions (`crouch`, `block_hit`, `hit`, `ko`, takeoff, landing): non-looping unless the held pose is a distinct loop.
- For a held crouch, play the descent once, hold its final frame, then reverse it or play a dedicated rise animation on release.
- For backwalk, keep the torso facing the opponent, move the rear foot first, follow with the lead foot, never cross feet, and prevent planted-foot sliding.
- Keep the last KO frame displayed until training reset.

Override these defaults when the existing sheet, atlas, frame data, or an explicit user choice requires it.

## Workflow

1. Inspect the target fighter directory, `SpriteFrames` resource, scene, state logic, current frame data, image dimensions, Git status, and any existing target asset.
2. Determine whether the request is prompt-only, remote generation, free regeneration, download, or local integration. Do only the requested scope.
3. For remote work, reuse the existing AutoSprite character when appropriate. List characters or spritesheets before creating duplicates.
4. Write a precise positive prompt and negative prompt. Describe foot planting, facing, loop behavior, held final poses, and camera alignment explicitly.
5. Before any paid operation, report cost and wait for confirmation. Then submit exactly one generation request unless the user approved a batch.
6. Follow the job with the appropriate status tool until success or failure. Do not repeatedly poll account balance.
7. Inspect the returned metadata and image before integration. Confirm frame size, count, columns, transparency, orientation, ground line, continuity, and loop seam.
8. Download into the correct character folder. If a target exists, retain it until the replacement is approved.
9. Add exact atlas regions to the fighter's `SpriteFrames`, set the requested FPS and loop mode, and connect the animation through the fighter state machine without restarting it every physics frame.
10. Update focused smoke tests for frame count, FPS, loop behavior, state selection, and relevant input transitions.
11. Run `tests/run_smoke_tests.cmd`, scan its log for engine/script/parse errors, and launch the main scene headlessly for at least 240 frames.
12. Report the generated operation, credits spent, files changed, animation settings, test result, and any visual judgment still requiring an in-game check.

## Prompt construction

Include only details relevant to animation. Start from this structure and adapt it:

```text
Create a [looping/non-looping] side-view 2D fighting-game animation for the supplied character.
[Describe the action as ordered body mechanics.]
Keep the character facing right, centered on a fixed canvas, and planted on one ground line.
Preserve identity, proportions, clothing, palette, and pixel-art rendering.
[Describe the required first frame, final frame, held pose, or seamless loop.]
```

Use a negative prompt covering unwanted rotation, direction changes, sliding feet, horizontal drift, scale changes, perspective changes, extra limbs, deformation, backgrounds, and baked shadows.

## Failure handling

- If AutoSprite MCP is unavailable, stop before generation and report that the MCP connection or environment variable must be restored.
- If a job fails, report the returned error and do not resubmit a paid request without confirmation.
- If frame extraction or looping is poor, prefer free regeneration from the existing video when supported.
- If generated art changes Mangler's identity or alignment materially, keep the existing runtime asset and present the new output as a candidate rather than integrating it.
