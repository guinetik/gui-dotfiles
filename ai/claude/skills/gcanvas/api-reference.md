# GCanvas Painter API - Complete Reference

## Initialization

```javascript
import { Painter } from "../../src/index.js";
// Painter.init(ctx) is called automatically by Game
// Access sub-namespaces: Painter.shapes, Painter.lines, Painter.text,
//   Painter.colors, Painter.effects, Painter.img, Painter.opacity
```

## Core (Painter.*)

### State Management
```javascript
Painter.save()                        // Save state (ctx + opacity + debug tracking)
Painter.restore()                     // Restore state (validates balance)
Painter.useCtx(callback, options?)    // Safe context wrapper
  // Auto: beginPath() before, beginPath() after (prevents path bleeding)
  // options: { saveState: true } for full save/restore wrapping
```

### Transforms
```javascript
Painter.clear(x?, y?, w?, h?)        // Clear area (defaults to full canvas)
Painter.translate(x, y)              // Move origin
Painter.rotate(angle)                // Rotate in radians
Painter.scale(x, y)                  // Scale from origin
Painter.translateTo(x, y)            // Translate with NaN/undefined guard
Painter.resetPosition()              // Reset translation only
Painter.withPosition(x, y, fn)      // Execute fn in translated context
```

---

## Shapes (Painter.shapes.*)

### Rectangles
```javascript
.rect(x, y, w, h, color)
.outlineRect(x, y, w, h, color, lineWidth)
.roundRect(x, y, w, h, radii, fillColor?, strokeColor?, lineWidth?)
  // radii: number | [topLeft, topRight, bottomRight, bottomLeft]
.fillRoundRect(x, y, w, h, radii, color)
.strokeRoundRect(x, y, w, h, radii, color, lineWidth)
```

### Circles & Arcs
```javascript
.fillCircle(x, y, radius, color)
.strokeCircle(x, y, radius, color, lineWidth)
.arc(x, y, radius, startAngle, endAngle, counterclockwise?)
```

### Ellipses
```javascript
.fillEllipse(x, y, radiusX, radiusY, rotation, color)
.strokeEllipse(x, y, radiusX, radiusY, rotation, color, lineWidth)
.ellipse(x, y, radiusX, radiusY, rotation, startAngle, endAngle, ccw?)
```

### Polygons
```javascript
.polygon(points, fillColor?, strokeColor?, lineWidth?, lineJoin?)
  // points: [{x, y}, ...], lineJoin: "bevel"|"round"|"miter"
```

---

## Lines (Painter.lines.*)

### Drawing
```javascript
.line(x1, y1, x2, y2, color, lineWidth)
.dashedLine(x1, y1, x2, y2, dashPattern, color, lineWidth)
  // dashPattern: [dash, gap, dash, gap, ...]
.dottedLine(x1, y1, x2, y2, dotSize, gap, color)
```

### Curves
```javascript
.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y)
.quadraticCurve(x1, y1, cpx, cpy, x2, y2, color, lineWidth)
```

### Paths (SVG-style)
```javascript
.path(commands, fill?, stroke?, lineWidth?)
  // commands: [['M', x, y], ['L', x, y], ['C', cp1x, cp1y, cp2x, cp2y, x, y],
  //            ['Q', cpx, cpy, x, y], ['Z']]
```

### Path Control
```javascript
.beginPath()
.closePath()
.moveTo(x, y)
.lineTo(x, y)
.setLineDash(segments)
.resetLineDash()
.setLineWidth(width)
```

---

## Text (Painter.text.*)

### Rendering
```javascript
.fillText(text, x, y, color?, font?)
.strokeText(text, x, y, color?, lineWidth?, font?)
.outlinedText(text, x, y, fillColor, strokeColor, strokeWidth?, font?)
.wrappedText(text, x, y, maxWidth, lineHeight, color?, font?)
  // Returns: totalHeightDrawn
```

### Font & Alignment
```javascript
.setFont(font)                       // "24px 'Courier New', monospace"
.font()                              // Get current font
.setTextAlign(align)                 // 'left'|'right'|'center'|'start'|'end'
.setTextBaseline(baseline)           // 'top'|'hanging'|'middle'|'alphabetic'|'bottom'
```

### Measurement
```javascript
.measureTextWidth(text, font?)
.measureTextDimensions(text, font?, align?, baseline?)
  // Returns: { width, height, verticalAdjustment }
```

### Advanced
```javascript
.textOnPath(text, path, color?, font?, reverse?)
  // path: [{x, y}, ...], centers text along the path
.getPositionOnPath(path, offset)
  // Returns: { x, y, angle }
```

---

## Colors (Painter.colors.*)

### Fill & Stroke
```javascript
.fill(color)                         // Fill current path
.stroke(color, lineWidth?)           // Stroke current path
.strokeOptions(options)              // { color, lineWidth, lineCap, lineJoin }
.setFillColor(color)
.setStrokeColor(color)
```

### Color Generation
```javascript
.randomColorRGB()                    // [r, g, b]
.randomColorRGBA(alpha?)             // [r, g, b, a]
.randomColorHSL()                    // "hsl(...)" string
.randomColorHEX()                    // "#rrggbb"
```

### Conversion
```javascript
.hslToRgb(h, s, l)                  // [r, g, b] (0-255)
.rgbToHsl(r, g, b)                  // [h, s, l]
.hexToRgb(hex)                      // "#rrggbb" → [r, g, b]
.parseColorString(str)              // Any format → [r, g, b]
  // Supports: "hsl(...)", "#rrggbb", "rgb(...)"
```

### String Builders
```javascript
.rgba(r, g, b, a)                   // "rgba(r, g, b, a)"
.hsl(h, s, l)                       // "hsl(h, s%, l%)"
.hsla(h, s, l, a)                   // "hsla(h, s%, l%, a)"
.rgbArrayToCSS([r, g, b])           // "rgb(r, g, b)"
```

### Gradients
```javascript
.linearGradient(x0, y0, x1, y1, colorStops)
.radialGradient(x0, y0, r0, x1, y1, r1, colorStops)
.verticalGradient(x, y, w, h, colorStops)    // Convenience
.horizontalGradient(x, y, w, h, colorStops)  // Convenience
.conicGradient(x, y, startAngle, colorStops)
  // colorStops: [{offset: 0, color: "red"}, {offset: 1, color: "blue"}]
```

---

## Effects (Painter.effects.*)

### Shadows
```javascript
.dropShadow(color, blur, offsetX, offsetY)
.clearShadow()
```

### Blending & Opacity
```javascript
.setAlpha(alpha)                     // globalAlpha (0-1)
.setBlendMode(operation)             // globalCompositeOperation
  // 'source-over', 'multiply', 'screen', 'overlay',
  // 'color-dodge', 'lighter', etc.
```

### Clipping
```javascript
.clipRect(x, y, w, h)
.clipCircle(x, y, radius)
```

### Filters & Glow
```javascript
.blurRegion(x, y, w, h, blur)
.createGlow(color, blur, options?)   // { pulseSpeed, pulseMin, pulseMax, colorShift }
  // Returns: { update(), stop(), apply() }
.clearAllEffects()
```

---

## Images (Painter.img.*)

### Drawing
```javascript
.draw(source, x, y, options?)
  // source: <img>, <canvas>, <video>
  // options: { width, height, crop: {sx, sy, sw, sh},
  //   anchor: "center", rotation, scaleX, scaleY,
  //   flipX, flipY, alpha, smoothing }
.blit(source, x, y, w?, h?)         // Quick draw with size
```

### Patterns
```javascript
.createPattern(image, repetition)    // "repeat"|"repeat-x"|"repeat-y"|"no-repeat"
.fillPattern(image, x, y, w, h)
```

### Pixel Manipulation
```javascript
.createImageData(w, h)
.getImageData(x, y, w, h)
.putImageData(imageData, x, y, dirtyX?, dirtyY?, dirtyW?, dirtyH?)
.cloneImageData(imageData)
.mapPixels(imageData, fn)            // fn(r, g, b, a, index) → [r, g, b, a]
.setPixel(imageData, x, y, r, g, b, a)
```

### Raw Pixel Arrays
```javascript
.toImageData(rgbaArray, w, h)
.createPatternFromImageData(imageData, repeat?)
.createPatternFromPixels(rgbaArray, w, h, repeat?)
.createImageBitmapFromPixels(rgbaArray, w, h)  // async
```

### Bitmap
```javascript
.toBitmap(options?)                  // async, { type, quality }
.createBitmap(image)                 // async
```

---

## Opacity (Painter.opacity.*)

```javascript
.pushOpacity(opacity)                // Compound with current (multiply)
.popOpacity()                        // Restore previous
.saveOpacityState()                  // Backup (called by Painter.save)
.restoreOpacityState()               // Restore (called by Painter.restore)
```

---

## Shape Classes Quick Reference

### 2D Primitives
| Class | Constructor | Key Options |
|-------|------------|-------------|
| `Circle` | `(radius, options)` | color, stroke, lineWidth, origin |
| `Rect` | `(width, height, options)` | color, stroke, cornerRadius |
| `Square` | `(size, options)` | color, stroke |
| `Triangle` | `(width, height, options)` | color, stroke |
| `Hexagon` | `(radius, options)` | color, stroke |
| `Star` | `(outerR, innerR, points, options)` | color, stroke |
| `Line` | `(x1, y1, x2, y2, options)` | color, lineWidth |
| `Arc` | `(radius, startAngle, endAngle, options)` | color, stroke |
| `Text` (shape) | `(text, options)` | color, font, align |
| `ImageShape` | `(src, options)` | width, height |
| `SVGShape` | `(pathData, options)` | color, stroke, scale |
| `BezierShape` | `(points, options)` | color, lineWidth |
| `Pattern` | `(image, options)` | repetition |

### 3D Shapes (require Camera3D)
| Class | Constructor |
|-------|------------|
| `Cube` | `(size, options)` |
| `Sphere` | `(radius, options)` |
| `Cylinder` | `(radius, height, options)` |
| `Cone` | `(radius, height, options)` |
| `Prism` | `(radius, height, sides, options)` |

### Common Shape Options
```javascript
{
  x, y,                    // Position (world or parent-relative)
  color: "#fff",           // Fill color
  stroke: "#000",          // Stroke color
  lineWidth: 1,            // Stroke width
  origin: "top-left",      // "top-left"|"center"|"bottom-right"|etc.
  originX: 0, originY: 0,  // Fine-grained origin (0-1)
  rotation: 0,             // Radians
  scaleX: 1, scaleY: 1,   // Scale factors
  opacity: 1,              // 0-1
  visible: true,
  blendMode: "source-over"
}
```

### Shape Inheritance Chain
```
Euclidian (x, y, width, height, originX, originY)
  → Traceable (debug bounds drawing)
    → Geometry2d (bounds calculation, memoization)
      → Renderable (render lifecycle, visibility, opacity)
        → Transformable (rotation, scale, applyTransforms)
          → Shape (fill, stroke, lineWidth)
            → Circle, Rect, Star, etc.
```

---

## GameObject Classes Quick Reference

| Class | Import | Purpose |
|-------|--------|---------|
| `GameObject` | `game/objects/go.js` | Base interactive entity |
| `Scene` | `game/objects/scene.js` | Hierarchical container, local coords |
| `Text` (GO) | `game/objects/text.js` | Managed text with auto-update |
| `ImageGo` | `game/objects/image.js` | Managed image display |
| `LayoutScene` | `game/objects/layout-scene.js` | Scene with layout helpers |
| `GameObjectShapeWrapper` | `game/objects/wrapper.js` | Wraps Shape as GameObject |

### GameObject Lifecycle
```
constructor(game, options) → init() → update(dt) → render() → draw()
                                       ↑ called each frame by Pipeline ↑
```

### Scene Methods
```javascript
scene.add(gameObject)        // Add child (calls child.init())
scene.remove(gameObject)     // Remove child
scene.clear()                // Remove all children
scene.bringToFront(go)       // Z-order management
scene.sendToBack(go)
scene.bringForward(go)
scene.sendBackward(go)
scene.children               // Getter for child array
```
