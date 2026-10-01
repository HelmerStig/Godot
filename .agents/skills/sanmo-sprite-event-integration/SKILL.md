---
name: sanmo-sprite-event-integration
description: Download an existing character spritesheet and bind a specified frame sequence to a Sanmo Godot gameplay event, including optional reverse, hold, loop, and return-to-idle behavior. Use for sprite-to-state or sprite-to-attack integration; not for generating new artwork.
---

# Sanmo sprite/event integration

Integrate an existing sheet into the requested fighter and gameplay event. For AutoSprite sources, also follow `sanmo-autosprite-pipeline` for remote operations and asset review. This skill does not authorize paid generation.

## Inputs and selection

Identify the fighter, event or attack variant, source sheet, FPS, forward start/end frames, optional reverse start/end, and final behavior (idle, crouch, held pose, loop, or another animation). Treat user-facing frame numbers as **1-based and inclusive**. Infer an omitted FPS from the comparable animation already in the fighter; report the choice.

If AutoSprite lists several `custom` sheets with the same frame count, inspect their images and creation times to identify the requested motion. Do not select solely by `kind`, latest date, or frame count. List/get remote data without spending credits; download only the chosen sheet. Do not expose signed URLs or credentials.

Inspect the destination and Git status before import. Preserve existing art: if the intended filename exists and differs, save the new sheet under a distinct descriptive name unless the user explicitly approves replacement. Keep source artwork and unrelated edits untouched.

## Frame and gameplay contract

Confirm actual dimensions, grid, 512×512 cells where applicable, frame count, transparency, orientation, foot line, and apparent size before slicing. Create exact atlas regions; never count empty cells as frames. Reuse each fighter's current scale and ground alignment unless inspection shows they need adjustment.

Example: forward `1→11`, reverse `10→1` maps to source indices `0…10`, then `9…0`, with no duplicate peak frame. Use non-looping animations for a one-shot sequence. A held pose stops at the requested frame; a loop repeats only the requested range. Avoid restarting animations every physics tick.

Connect the animation to the actual event path, not just the scene resource: input/state transition for moves, `get_hit_animation` and reaction lifecycle for hurt states, `AttackData`/variant and hitbox windows for attacks, or the relevant block/KO path. Account for any timer or hitstun so it cannot return to idle before a requested reverse segment finishes. Preserve interruption, knockout, landing, and reset behavior.

## Verification

Add focused tests for the sheet path, sliced frame indices, FPS, loop mode, event trigger, reverse/hold behavior, and final state. Import new PNGs in Godot, run `tests/run_smoke_tests.cmd`, and launch the main scene headlessly for at least 240 frames. Report the mapping, files changed, test result, any visual uncertainty, and whether credits were spent.
