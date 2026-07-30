import AppKit

// Renders the Plummet app icon: a minimal dark angular rock falling on the
// cream "field notebook" background, with faint motion streaks above it.
// Output: 1024x1024 PNG (no alpha — iOS icons must be opaque).

let size = 1024
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: size, pixelsHigh: size,
    bitsPerSample: 8, samplesPerPixel: 4,
    hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0, bitsPerPixel: 0
)!

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor {
    CGColor(red: r, green: g, blue: b, alpha: a)
}

let paper    = rgb(0.984, 0.984, 0.953) // #FBFBF3
let line     = rgb(0.894, 0.906, 0.847) // #E4E7D8
let ink      = rgb(0.153, 0.153, 0.145) // near-black rock
let facet    = rgb(0.353, 0.349, 0.333) // lighter rock face
let pencil   = rgb(0.533, 0.529, 0.505) // motion streaks

// Background
ctx.setFillColor(paper)
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

// Faint graph grid (ties to the notebook aesthetic)
ctx.setStrokeColor(line)
ctx.setLineWidth(2)
let step = 1024.0 / 16.0
var g = 0.0
while g <= 1024.0 {
    ctx.move(to: CGPoint(x: g, y: 0));    ctx.addLine(to: CGPoint(x: g, y: 1024))
    ctx.move(to: CGPoint(x: 0, y: g));    ctx.addLine(to: CGPoint(x: 1024, y: g))
    g += step
}
ctx.strokePath()

// Motion streaks above the rock (coords are bottom-up in AppKit).
// Tapered vertical lines suggesting a downward plunge.
func streak(x: CGFloat, top: CGFloat, bottom: CGFloat, width: CGFloat, alpha: Double) {
    ctx.setStrokeColor(rgb(0.533, 0.529, 0.505, alpha))
    ctx.setLineWidth(width)
    ctx.setLineCap(.round)
    ctx.move(to: CGPoint(x: x, y: bottom))
    ctx.addLine(to: CGPoint(x: x, y: top))
    ctx.strokePath()
}
_ = pencil
streak(x: 424, top: 872, bottom: 712, width: 16, alpha: 0.32)
streak(x: 512, top: 906, bottom: 706, width: 20, alpha: 0.52)
streak(x: 600, top: 872, bottom: 712, width: 16, alpha: 0.32)

// The rock — an irregular angular polygon, scaled up and centered.
let scale: CGFloat = 1.2
let cx: CGFloat = 512, cy: CGFloat = 430, dy: CGFloat = 40
func T(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
    CGPoint(x: cx + scale * (x - cx), y: cy + dy + scale * (y - cy))
}
let rock: [CGPoint] = [
    T(352, 470), T(470, 575), T(610, 548), T(700, 430),
    T(648, 292), T(500, 238), T(366, 300), T(322, 400),
]
func addPolygon(_ pts: [CGPoint]) {
    ctx.move(to: pts[0])
    for p in pts.dropFirst() { ctx.addLine(to: p) }
    ctx.closePath()
}

ctx.setFillColor(ink)
addPolygon(rock)
ctx.fillPath()

// A single lighter facet for a subtle chiseled read (top-right face).
let facetPts: [CGPoint] = [
    T(470, 575), T(610, 548), T(700, 430), T(560, 430),
]
ctx.setFillColor(facet)
addPolygon(facetPts)
ctx.fillPath()

NSGraphicsContext.restoreGraphicsState()

// Flatten onto opaque paper (strip alpha) and write PNG.
guard let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write("failed to encode PNG\n".data(using: .utf8)!)
    exit(1)
}
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png"
try! png.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
