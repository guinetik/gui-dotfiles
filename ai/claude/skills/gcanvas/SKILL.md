---
name: gcanvas
description: Use when working with the GCanvas HTML5 Canvas library - creating demos, drawing shapes, using the rendering pipeline, positioning objects, or writing game logic. Use when encountering canvas ctx calls, render/draw confusion, or coordinate system issues in GCanvas projects.
---

# GCanvas Engine Reference

## Overview

GCanvas is a zero-dependency HTML5 Canvas engine with a two-layer architecture: **Shapes** (stateless drawing) and **GameObjects** (managed lifecycle + interactivity). All rendering flows through a **Pipeline** that manages update/render cycles. The engine provides a **Painter** abstraction that replaces raw `ctx` calls with a declarative, composable API.

**Core rule:** Never use raw `ctx` operations when Painter or Shape classes cover the use case. The Painter API standardizes drawing, handles save/restore automatically, and prevents path bleeding bugs.

## When to Use

- Building demos or games with GCanvas
- Drawing shapes, text, lines, or effects on canvas
- Working with the Game/Pipeline/GameObject system
- Positioning objects (especially nested in Scenes)
- Any canvas rendering in the GCanvas codebase

## Two-Layer Architecture

| Layer | Classes | Purpose | Has Lifecycle? | Interactive? |
|-------|---------|---------|---------------|-------------|
| **Shape** | Circle, Rect, Text, etc. | Stateless drawing primitives | No | No |
| **GameObject** | GameObject, Scene, Text (GO) | Managed entities in Pipeline | Yes (update/render) | Yes (events) |

**Decision:** Use Shapes for static/decorative drawing. Use GameObjects when you need update loops, input events, or pipeline integration.

```javascript
// Shape: draw once, no lifecycle
const circle = new Circle(50, { x: 100, y: 100, color: "#ff0" });
circle.render(ctx);  // One-shot draw

// GameObject: managed by pipeline, receives updates
const label = new Text(this, "Score: 0", { color: "#fff" });
this.pipeline.add(label);  // Pipeline calls update(dt) and render() each frame
```

## The Rendering Pipeline

### Frame Sequence

```
game.loop(timestamp)
  |
  +-- game.update(dt)          // Phase 1: Logic
  |     +-- pipeline.update(dt)
  |           +-- each active obj.update(dt)
  |           +-- Tweenetik.updateAll(dt)
  |
  +-- game.render()            // Phase 2: Drawing
        +-- game.clear()       // !! Clears entire canvas !!
        +-- pipeline.render()
              +-- each visible+active obj.render()
```

### CRITICAL: super.render() Clears the Canvas

`Game.render()` calls `this.clear()` THEN `pipeline.render()`. Custom drawing MUST come AFTER `super.render()`:

```javascript
// BAD: Custom drawing gets erased by super.render()
render() {
  Painter.shapes.fillCircle(50, 50, 20, "red");  // Drawn...
  super.render();  // ...then ERASED by clear(), then pipeline draws
}

// GOOD: Draw overlays after pipeline finishes
render() {
  super.render();  // Clear + pipeline renders all objects
  Painter.shapes.fillCircle(50, 50, 20, "red");  // Overlay on top
}
```

### Pipeline Filtering

Pipeline only renders objects that are both `visible` AND `active`:

```javascript
pipeline.render() {
  collection.getSortedChildren()  // Z-order sorted
    .filter(obj => obj.visible)   // Skip hidden
    .filter(obj => obj.active)    // Skip inactive
    .forEach(obj => obj.render());
}
```

## render() vs draw() - The Critical Distinction

This is the most common source of bugs. These are NOT interchangeable.

| Method | Called By | What It Does | Override? |
|--------|----------|-------------|-----------|
| `render()` | Pipeline | Orchestrator: save ctx, translate to (x,y), manage opacity, call draw(), restore ctx | **NEVER override** |
| `draw()` | render() | Artist: apply transforms, do actual drawing via Painter | **Override this** |

### What render() Does Automatically

```
render() {
  1. Skip if !visible or opacity <= 0
  2. Painter.save()
  3. Painter.translateTo(this.x, this.y)    // Position in world
  4. Calculate pivot from origin
  5. Push opacity
  6. call this.draw()                       // <-- YOUR CODE HERE
  7. Pop opacity
  8. Painter.restore()
}
```

### What draw() Should Do

```javascript
// In a custom GameObject subclass:
draw() {
  super.draw();  // REQUIRED: applies rotation/scale transforms + debug bounds

  // Now draw using Painter API (you're in local space, translated to x,y)
  Painter.shapes.fillCircle(0, 0, 30, "#ff0");  // Draws at object's position
}
```

### Shape render() vs GameObject render()

Shapes and GameObjects share the same render() chain through Renderable. The key difference:

- **Shape.render()** - Call directly when drawing standalone shapes
- **GameObject.render()** - Called BY the pipeline, never call manually

### GameObjectShapeWrapper: draw() not render()

When wrapping a Shape inside a GameObject, call `shape.draw()` not `shape.render()`:

```javascript
// The wrapper's render() already translated to (this.x, this.y).
// Calling shape.render() would OVERWRITE the translation (translateTo replaces, not adds).
// Calling shape.draw() renders at the wrapper's position correctly.
draw() {
  super.draw();
  this.shape.draw();  // draw(), NOT render()!
}
```

### Scene.draw() Calls Children's render()

Scene is special - its `draw()` calls `render()` on each child (full lifecycle):

```javascript
// Inside Scene.draw():
children.filter(visible).forEach(child => {
  Painter.save();
  child.render();   // Full render() - translate, transform, draw, restore
  Painter.restore();
});
```

This is correct because each child needs its own translation and transform context.

## Coordinate System and Positioning

### Origin System (v3.0)

Every object has `originX` and `originY` (0-1 normalized). The `(x, y)` position places the **origin point** in world space.

| Origin | originX | originY | (x,y) places... |
|--------|---------|---------|-----------------|
| `"top-left"` (default) | 0 | 0 | Top-left corner |
| `"center"` | 0.5 | 0.5 | Center point |
| `"bottom-right"` | 1 | 1 | Bottom-right corner |

```javascript
// Default: top-left origin
new Rect(80, 40, { x: 100, y: 100 });
// Top-left at (100, 100), bottom-right at (180, 140)

// Center origin
new Rect(80, 40, { x: 100, y: 100, origin: "center" });
// Center at (100, 100), top-left at (60, 80)
```

### How Origin Affects Drawing

Inside `draw()`, shapes offset themselves by `-(width * originX, height * originY)`:

```javascript
// For a 100x100 rect with origin "center" at position (200, 200):
// 1. render() translates context to (200, 200)
// 2. draw() calculates offset: (-100*0.5, -100*0.5) = (-50, -50)
// 3. Rect draws from (-50, -50) to (50, 50) in local space
// 4. Result: rect centered at (200, 200) on screen
```

### Origin Affects Rotation/Scale Pivot

Transforms are applied around the origin point. A shape with `origin: "center"` rotates around its center. A shape with default origin rotates around its top-left corner.

### Scene Local Coordinates

Children inside a Scene are positioned **relative to the Scene**:

```javascript
const scene = new Scene(game, { x: 200, y: 200 });
const child = new Text(game, "Hello", { x: 50, y: 30 });
scene.add(child);
// child renders at screen position (200 + 50, 200 + 30) = (250, 230)
```

### Nested Scenes Stack Additively

```javascript
const outer = new Scene(game, { x: 100, y: 100 });
const inner = new Scene(game, { x: 50, y: 50 });
const shape = new Circle(10, { x: 25, y: 25, color: "#ff0" });

inner.add(shape);
outer.add(inner);
pipeline.add(outer);
// shape screen position: 100 + 50 + 25 = (175, 175)
```

### Circle Bounding Box Gotcha

Circle's origin is relative to its **bounding box**, not its center:

```javascript
// Top-left origin (default): bounding box top-left at (100, 100)
new Circle(50, { x: 100, y: 100 });
// Circle CENTER is at (150, 150), not (100, 100)!

// Center origin: circle center at (100, 100)
new Circle(50, { x: 100, y: 100, origin: "center" });
// Bounding box top-left at (50, 50)
```

### Scene3D Must Be Centered

Scene3D with Camera3D projects from origin. Place it at canvas center:

```javascript
const scene3d = new Scene3D(this, {
  x: this.width / 2,
  y: this.height / 2,
  camera: new Camera3D({ perspective: 800 })
});
```

## Painter API - Use Instead of Raw ctx

**Core rule: If Painter has a method for it, use Painter.** Raw ctx calls bypass save/restore tracking, opacity management, and debug logging.

### Context Access Pattern

```javascript
// BAD: Raw ctx manipulation
ctx.save();
ctx.strokeStyle = "rgba(255,255,255,0.5)";
ctx.lineWidth = 2;
ctx.beginPath();
ctx.moveTo(x1, y1);
ctx.lineTo(x2, y2);
ctx.stroke();
ctx.restore();

// GOOD: Painter.useCtx handles beginPath + cleanup automatically
Painter.useCtx((ctx) => {
  ctx.strokeStyle = "rgba(255,255,255,0.5)";
  ctx.lineWidth = 2;
  ctx.moveTo(x1, y1);
  ctx.lineTo(x2, y2);
  ctx.stroke();
});
// useCtx auto-calls beginPath() before AND after (prevents path bleeding)

// BETTER: Use Painter.lines for common operations
Painter.lines.line(x1, y1, x2, y2, "rgba(255,255,255,0.5)", 2);
```

### Painter.useCtx Behavior

- Calls `ctx.beginPath()` before your callback
- Calls `ctx.beginPath()` after (clears path, prevents bleeding)
- Pass `{ saveState: true }` for full save/restore wrapping

### Painter.save/restore vs ctx.save/restore

Painter.save/restore wraps ctx.save/restore AND:
- Manages opacity stack (compound opacity across nested objects)
- Tracks caller info for debugging unbalanced save/restore
- Validates stack balance (errors on restore without save)

**Always use `Painter.save()` / `Painter.restore()`, never raw ctx.save/restore.**

### Quick API Reference

**Shapes** (`Painter.shapes.*`):
| Method | Signature |
|--------|-----------|
| `rect` | `(x, y, w, h, color)` |
| `outlineRect` | `(x, y, w, h, color, lineWidth)` |
| `fillCircle` | `(x, y, radius, color)` |
| `strokeCircle` | `(x, y, radius, color, lineWidth)` |
| `fillEllipse` | `(x, y, rx, ry, rotation, color)` |
| `roundRect` | `(x, y, w, h, radii, fill, stroke, lineWidth)` |
| `polygon` | `(points, fill, stroke, lineWidth, lineJoin)` |

**Lines** (`Painter.lines.*`):
| Method | Signature |
|--------|-----------|
| `line` | `(x1, y1, x2, y2, color, lineWidth)` |
| `dashedLine` | `(x1, y1, x2, y2, dashPattern, color, lineWidth)` |
| `path` | `(commands, fill, stroke, lineWidth)` |
| `quadraticCurve` | `(x1, y1, cpx, cpy, x2, y2, color, lineWidth)` |

Path commands: `['M', x, y]`, `['L', x, y]`, `['C', cp1x, cp1y, cp2x, cp2y, x, y]`, `['Q', cpx, cpy, x, y]`, `['Z']`

**Text** (`Painter.text.*`):
| Method | Signature |
|--------|-----------|
| `fillText` | `(text, x, y, color, font)` |
| `strokeText` | `(text, x, y, color, lineWidth, font)` |
| `outlinedText` | `(text, x, y, fill, stroke, strokeWidth, font)` |
| `wrappedText` | `(text, x, y, maxWidth, lineHeight, color, font)` |
| `measureTextWidth` | `(text, font)` |

**Colors** (`Painter.colors.*`):
| Method | Signature |
|--------|-----------|
| `fill` | `(color)` |
| `stroke` | `(color, lineWidth)` |
| `hslToRgb` | `(h, s, l)` → `[r, g, b]` |
| `rgbToHex` | `(r, g, b)` → `"#rrggbb"` (via rgbArrayToCSS or hexToRgb inverse) |
| `rgba` | `(r, g, b, a)` → CSS string |
| `hsl` | `(h, s, l)` → CSS string |
| `linearGradient` | `(x0, y0, x1, y1, [{offset, color}])` |
| `radialGradient` | `(x0, y0, r0, x1, y1, r1, [{offset, color}])` |

**Effects** (`Painter.effects.*`):
| Method | Signature |
|--------|-----------|
| `dropShadow` | `(color, blur, offsetX, offsetY)` |
| `clearShadow` | `()` |
| `setAlpha` | `(alpha)` |
| `setBlendMode` | `(operation)` |
| `clipRect` | `(x, y, w, h)` |
| `clipCircle` | `(x, y, radius)` |

**Images** (`Painter.img.*`):
| Method | Signature |
|--------|-----------|
| `draw` | `(source, x, y, {width, height, crop, anchor, rotation, alpha})` |
| `blit` | `(source, x, y, w, h)` |
| `getImageData` | `(x, y, w, h)` |
| `putImageData` | `(imageData, x, y)` |
| `mapPixels` | `(imageData, fn)` where `fn(r,g,b,a,i) → [r,g,b,a]` |

**Transforms** (on Painter directly):
| Method | Signature |
|--------|-----------|
| `translate` | `(x, y)` |
| `rotate` | `(angle)` — radians |
| `scale` | `(x, y)` |
| `translateTo` | `(x, y)` — with NaN guard |
| `clear` | `(x, y, w, h)` — defaults to full canvas |

## Common Mistakes

### 1. Raw ctx Instead of Painter

```javascript
// BAD
ctx.fillStyle = "red";
ctx.fillRect(0, 0, 100, 50);

// GOOD
Painter.shapes.rect(0, 0, 100, 50, "red");
```

### 2. super.render() Order in Game

```javascript
// BAD: Custom drawing before super.render() gets cleared
render() {
  this.drawMyOverlay();
  super.render();  // Clears canvas, then pipeline renders
}

// GOOD: Custom drawing after super.render()
render() {
  super.render();
  this.drawMyOverlay();  // Draws on top of pipeline output
}
```

### 3. Overriding render() Instead of draw()

```javascript
// BAD: Overriding render() bypasses transform/opacity/save-restore management
class MyObj extends GameObject {
  render() { /* breaks everything */ }
}

// GOOD: Override draw() for custom rendering
class MyObj extends GameObject {
  draw() {
    super.draw();  // Applies transforms
    Painter.shapes.fillCircle(0, 0, 20, "#f00");
  }
}
```

### 4. Forgetting super.draw() in draw() Override

```javascript
// BAD: Rotation/scale won't be applied
draw() {
  Painter.shapes.rect(0, 0, 50, 50, "blue");
}

// GOOD: super.draw() calls applyTransforms()
draw() {
  super.draw();
  Painter.shapes.rect(0, 0, 50, 50, "blue");
}
```

### 5. Calling shape.render() Inside a Wrapper

```javascript
// BAD: Double translation (translateTo REPLACES, doesn't add)
draw() {
  super.draw();
  this.myShape.render();  // Overwrites position!
}

// GOOD: shape.draw() uses the existing translated context
draw() {
  super.draw();
  this.myShape.draw();  // Draws at wrapper's position
}
```

### 6. Assuming Circle (x,y) Is Center

```javascript
// With default origin, (x,y) is bounding box top-left
new Circle(50, { x: 100, y: 100 });
// Circle center at (150, 150), NOT (100, 100)

// For center positioning, use origin: "center"
new Circle(50, { x: 100, y: 100, origin: "center" });
// Circle center at (100, 100)
```

### 7. Positioning Children in Absolute Coords

```javascript
// BAD: Ignores scene's local coordinate system
const scene = new Scene(game, { x: 200, y: 200 });
const btn = new Text(game, "Click", { x: 300, y: 300 }); // Ends up at (500, 500)!
scene.add(btn);

// GOOD: Position relative to scene
const btn = new Text(game, "Click", { x: 100, y: 100 }); // Ends up at (300, 300)
scene.add(btn);
```

### 8. Using ctx.save/restore Instead of Painter

```javascript
// BAD: Bypasses opacity stack and debug tracking
ctx.save();
// ... drawing ...
ctx.restore();

// GOOD: Painter manages the full state stack
Painter.save();
// ... drawing ...
Painter.restore();
```

## Demo Structure Quick Reference

```javascript
import { Game, Painter, Scene, Text } from "../../src/index.js";

const CONFIG = {
  // All magic numbers go here
};

class MyDemo extends Game {
  constructor(canvas) {
    super(canvas);
    this.backgroundColor = "#000";
    this.enableFluidSize();
  }

  init() {
    super.init();
    // Create GameObjects, add to pipeline
    this.pipeline.add(myObject);
  }

  update(dt) {
    super.update(dt);
    // Game logic (dt in seconds)
  }

  render() {
    super.render();  // ALWAYS FIRST: clears canvas + pipeline render
    // Optional: custom overlay drawing AFTER super.render()
  }
}

window.addEventListener("load", () => {
  const canvas = document.getElementById("game");
  new MyDemo(canvas).start();
});
```

## Mobile & Responsive Patterns

GCanvas demos should be responsive across mobile, tablet, and desktop. The `Screen` class (from `src/io/screen.js`) provides device detection and responsive utilities.

### Setup

```javascript
import { Game, Screen } from "../../src/index.js";

class MyDemo extends Game {
  constructor(canvas) {
    super(canvas);
    this.enableFluidSize();  // Auto-resize canvas to window
  }

  init() {
    super.init();
    Screen.init(this);  // Initialize device detection + events
  }
}
```

**Both are needed:** `enableFluidSize()` makes the canvas responsive, `Screen.init(this)` enables device detection and emits resize/orientation events.

### Pattern 1: Responsive CONFIG Values

Use `Screen.responsive(mobile, tablet, desktop)` in CONFIG objects. This is the most common pattern - scale particle counts, sizes, and spacing by device:

```javascript
const CONFIG = {
  count: Screen.responsive(250, 400, 500),        // Fewer particles on mobile
  trailLength: Screen.responsive(150, 200, 250),   // Shorter trails on mobile
  ui: {
    margin: Screen.responsive(8, 12, 16),
    buttonWidth: Screen.responsive(90, 110, 130),
    fontSize: Screen.responsive(12, 14, 16),
  },
};
```

### Pattern 2: Zoom Scaling for Camera/3D Demos

Scale zoom based on smallest screen dimension:

```javascript
const CONFIG = {
  baseScreenSize: 900,  // Reference screen size for zoom = 1.0
  minZoom: 0.3,
  maxZoom: 2.0,
};

// In init():
this.defaultZoom = Math.min(
  CONFIG.maxZoom,
  Math.max(CONFIG.minZoom, Screen.minDimension() / CONFIG.baseScreenSize)
);
```

### Pattern 3: Device-Conditional Logic

```javascript
if (Screen.isMobile) {
  // Simplify UI, reduce effects
}
if (Screen.isTouchPrimary()) {
  // Use touch-friendly interaction sizes
}
```

### Screen API Quick Reference

| Property/Method | Returns | Description |
|----------------|---------|-------------|
| `Screen.isMobile` | boolean | width <= 768 |
| `Screen.isTablet` | boolean | 768 < width <= 1024 |
| `Screen.isDesktop` | boolean | width > 1024 |
| `Screen.hasTouch` | boolean | Touch capability detected |
| `Screen.isTouchPrimary()` | boolean | Touch + mobile/tablet |
| `Screen.width` / `Screen.height` | number | Current window dimensions |
| `Screen.pixelRatio` | number | Device pixel ratio (2 for retina) |
| `Screen.orientation` | string | `"portrait"` or `"landscape"` |
| `Screen.responsive(m, t, d)` | any | Returns value for current device |
| `Screen.minDimension()` | number | `min(width, height)` |
| `Screen.scaled(value)` | number | Value * pixelRatio |
| `Screen.prefersReducedMotion()` | boolean | OS accessibility setting |
| `Screen.prefersDarkMode()` | boolean | OS dark mode preference |
| `Screen.requestWakeLock()` | Promise | Prevent screen sleep (games) |

### Screen Events

After `Screen.init(game)`, events are emitted on `game.events`:

| Event | Payload | When |
|-------|---------|------|
| `screenresize` | `{width, height, isMobile, isTablet, isDesktop}` | Window resizes |
| `devicechange` | `{isMobile, isTablet, isDesktop, previous}` | Breakpoint crossed |
| `orientationchange` | `{orientation, isPortrait, isLandscape}` | Portrait/landscape switch |

## Full Painter API Documentation

For the complete 92+ method API surface organized by namespace, see `api-reference.md` in this skill directory.

For engine architecture deep-dives, see the project docs:
- `docs/concepts/` - Architecture, coordinate system, lifecycle, interactivity
- `docs/modules/` - Per-module API documentation
- `docs/getting-started/` - Tutorials
