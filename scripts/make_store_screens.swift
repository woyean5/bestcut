// Builds App Store screenshots (6.9", 1320x2868): a pastel background, a headline, and the app screen in a phone frame.
// Usage: swift scripts/make_store_screens.swift <captures dir> <out dir> <lang>
// Reads <captures dir>/<lang>/<n>.png (raw 1320x2868 simulator screenshots) and writes <out dir>/<lang>/<n>.png.
import AppKit

let args = CommandLine.arguments
let capDir = URL(fileURLWithPath: args[1]), outDir = URL(fileURLWithPath: args[2]), lang = args[3]
let W: CGFloat = 1320, H: CGFloat = 2868

struct Slide { let shot: String; let bg: NSColor; let ink: NSColor; let title: [String: String] }
func hex(_ v: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((v >> 16) & 0xff) / 255, green: CGFloat((v >> 8) & 0xff) / 255, blue: CGFloat(v & 0xff) / 255, alpha: 1)
}

let slides: [Slide] = [
    Slide(shot: "1", bg: hex(0xFCEFCF), ink: hex(0x4A2A12), title: [
        "ko": "비슷한 사진은 한 묶음으로\n베스트 컷은 미리 골라 둬요",
        "en": "Similar shots, grouped.\nBest one already picked.",
        "ja": "似た写真はひとまとめに\nベストショットは選んでおきます",
        "zh-Hans": "相似照片自动归组\n最佳一张已帮你选好"]),
    Slide(shot: "2", bg: hex(0xE6E6FB), ink: hex(0x2B2668), title: [
        "ko": "흔들리고 어두운 사진은\n알아서 표시해요",
        "en": "Blurry and dark shots,\nflagged for you.",
        "ja": "ブレた写真や暗い写真は\n自動でお知らせ",
        "zh-Hans": "模糊、过暗的照片\n自动帮你标出"]),
    Slide(shot: "3", bg: hex(0xDDF2E4), ink: hex(0x174A2C), title: [
        "ko": "한 장씩 넘기며\n빠르게 골라요",
        "en": "Swipe to pick,\none photo at a time.",
        "ja": "1枚ずつスワイプして\nサクサク選べる",
        "zh-Hans": "一张张滑动\n轻松快速挑选"]),
    Slide(shot: "4", bg: hex(0xFFE4E1), ink: hex(0x5E1F2A), title: [
        "ko": "두 장 나란히 놓고\n함께 확대해 비교",
        "en": "Zoom two photos\nside by side.",
        "ja": "2枚を並べて\n一緒に拡大して比較",
        "zh-Hans": "两张并排\n同步放大对比"]),
    Slide(shot: "5", bg: hex(0xDDEEFB), ink: hex(0x123A5C), title: [
        "ko": "고른 사진은 앨범으로\n지우기 전엔 꼭 확인해요",
        "en": "Your picks become an album.\nYou confirm every delete.",
        "ja": "選んだ写真はアルバムに\n削除の前に必ず確認",
        "zh-Hans": "选中的照片存入相簿\n删除前一定再确认"]),
    Slide(shot: "6", bg: hex(0xF1ECE4), ink: hex(0x2E2A25), title: [
        "ko": "사진은 iPhone 밖으로\n나가지 않아요",
        "en": "Your photos never\nleave your iPhone.",
        "ja": "写真がiPhoneの外に\n出ることはありません",
        "zh-Hans": "照片始终\n留在你的 iPhone 上"]),
]

func roundedPath(_ r: CGRect, _ radius: CGFloat) -> CGPath { CGPath(roundedRect: r, cornerWidth: radius, cornerHeight: radius, transform: nil) }

try? FileManager.default.createDirectory(at: outDir.appendingPathComponent(lang), withIntermediateDirectories: true)
for slide in slides {
    let shotURL = capDir.appendingPathComponent(lang).appendingPathComponent(slide.shot + ".png")
    guard let shot = NSImage(contentsOf: shotURL)?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        print("missing \(shotURL.path)"); continue
    }
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(W), pixelsHigh: Int(H), bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    let gctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = gctx
    let ctx = gctx.cgContext

    // Background
    ctx.setFillColor(slide.bg.cgColor)
    ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))

    // Headline (AppKit draws bottom-up; place it near the top)
    let para = NSMutableParagraphStyle()
    para.alignment = .center
    para.lineSpacing = 14
    // Start large and shrink until the headline fits on its two lines.
    let raw = slide.title[lang] ?? slide.title["en"]!
    let textBox = CGRect(x: 70, y: H - 560, width: W - 140, height: 400)
    var size: CGFloat = 104
    var text = NSAttributedString()
    var measured = CGRect.zero
    repeat {
        text = NSAttributedString(string: raw, attributes: [
            .font: NSFont.systemFont(ofSize: size, weight: .bold), .foregroundColor: slide.ink, .paragraphStyle: para,
            .kern: lang == "en" ? -1.5 : -2])
        measured = text.boundingRect(with: CGSize(width: textBox.width, height: 1000), options: [.usesLineFragmentOrigin])
        size -= 4
    } while measured.height > size * 2.75 && size > 60
    text.draw(with: CGRect(x: textBox.minX, y: textBox.minY + (textBox.height - measured.height) / 2,
                           width: textBox.width, height: measured.height), options: [.usesLineFragmentOrigin])

    // Phone: the whole device is shown, like Apple's own product shots — titanium band, black bezel, side buttons.
    let screenW: CGFloat = 960, scale = screenW / CGFloat(shot.width)
    let screenH = CGFloat(shot.height) * scale
    let bezel: CGFloat = 26, band: CGFloat = 13
    let screenTop = H - 640
    let screen = CGRect(x: (W - screenW) / 2, y: screenTop - screenH, width: screenW, height: screenH)
    let screenRadius = screenW * 0.14
    let glass = screen.insetBy(dx: -bezel, dy: -bezel)            // black glass edge
    let body = glass.insetBy(dx: -band, dy: -band)                // titanium band
    let bodyRadius = screenRadius + bezel + band

    // Side buttons sit behind the band so only their outer edge shows.
    func button(_ x: CGFloat, _ topFromBody: CGFloat, _ length: CGFloat) {
        let r = CGRect(x: x, y: body.maxY - topFromBody - length, width: 14, height: length)
        let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                           colors: [hex(0x3A3A3C).cgColor, hex(0x8E8E93).cgColor, hex(0x3A3A3C).cgColor] as CFArray, locations: [0, 0.5, 1])!
        ctx.saveGState()
        ctx.addPath(roundedPath(r, 6)); ctx.clip()
        ctx.drawLinearGradient(g, start: CGPoint(x: r.minX, y: 0), end: CGPoint(x: r.maxX, y: 0), options: [])
        ctx.restoreGState()
    }
    let left = body.minX - 9, right = body.maxX - 5
    button(left, 330, 90)    // action button
    button(left, 480, 170)   // volume up
    button(left, 680, 170)   // volume down
    button(right, 560, 260)  // side button

    // Body with a soft floor shadow.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -30), blur: 90, color: NSColor.black.withAlphaComponent(0.25).cgColor)
    ctx.addPath(roundedPath(body, bodyRadius))
    ctx.setFillColor(hex(0x2C2C2E).cgColor)
    ctx.fillPath()
    ctx.restoreGState()
    // Brushed titanium: a horizontal gradient that is lighter at the edges, as light catches the rounded sides.
    ctx.saveGState()
    ctx.addPath(roundedPath(body, bodyRadius)); ctx.clip()
    let metal = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                           colors: [hex(0x9A9AA0).cgColor, hex(0x4A4A4E).cgColor, hex(0x3A3A3D).cgColor,
                                    hex(0x4A4A4E).cgColor, hex(0x9A9AA0).cgColor] as CFArray,
                           locations: [0, 0.04, 0.5, 0.96, 1])!
    ctx.drawLinearGradient(metal, start: CGPoint(x: body.minX, y: 0), end: CGPoint(x: body.maxX, y: 0), options: [])
    ctx.restoreGState()
    // Bright rim on the outer edge
    ctx.addPath(roundedPath(body.insetBy(dx: 1.5, dy: 1.5), bodyRadius - 1.5))
    ctx.setStrokeColor(hex(0xC7C7CC).withAlphaComponent(0.7).cgColor)
    ctx.setLineWidth(3)
    ctx.strokePath()
    // Black glass bezel
    ctx.addPath(roundedPath(glass, screenRadius + bezel))
    ctx.setFillColor(hex(0x050505).cgColor)
    ctx.fillPath()
    // Screen
    ctx.saveGState()
    ctx.addPath(roundedPath(screen, screenRadius))
    ctx.clip()
    ctx.draw(shot, in: screen)
    ctx.restoreGState()
    // Faint glass reflection across the top of the bezel
    ctx.addPath(roundedPath(glass.insetBy(dx: 2, dy: 2), screenRadius + bezel - 2))
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.08).cgColor)
    ctx.setLineWidth(2)
    ctx.strokePath()
    // The simulator screenshot already shows the Dynamic Island.
    NSGraphicsContext.restoreGraphicsState()
    let png = rep.representation(using: .png, properties: [:])!
    try! png.write(to: outDir.appendingPathComponent(lang).appendingPathComponent(slide.shot + ".png"))
    print("wrote \(lang)/\(slide.shot).png")
}
