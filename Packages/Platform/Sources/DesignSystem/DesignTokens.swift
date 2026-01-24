import SwiftUI

#if canImport(AppKit)
import AppKit
#endif

public enum DesignTokens {
  public enum Colors {
    private static func hex(_ hex: UInt32, alpha: Double = 1) -> Color {
      let r = Double((hex >> 16) & 0xFF) / 255.0
      let g = Double((hex >> 8) & 0xFF) / 255.0
      let b = Double(hex & 0xFF) / 255.0
      return Color(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }

    public static var accent: Color {
      dynamicColor(light: hex(0x2B6BFF), dark: hex(0x6B8CFF), name: "DesignTokens.accent")
    }

    public static var accentPressed: Color {
      dynamicColor(light: hex(0x1A4CCD), dark: hex(0x4A63D6), name: "DesignTokens.accentPressed")
    }

    public static var background: Color {
      dynamicColor(light: hex(0xF7F8FA), dark: hex(0x0E1117), name: "DesignTokens.background")
    }

    public static var surface: Color {
      dynamicColor(light: hex(0xFFFFFF), dark: hex(0x161A22), name: "DesignTokens.surface")
    }

    public static var surfaceAccent: Color {
      dynamicColor(light: hex(0xE8EFFF), dark: hex(0x1B2233), name: "DesignTokens.surfaceAccent")
    }

    public static var text: Color {
      dynamicColor(light: hex(0x0F1115), dark: hex(0xF3F4F6), name: "DesignTokens.text")
    }

    public static var mutedText: Color {
      dynamicColor(light: hex(0x50535A), dark: hex(0xA9AEB8), name: "DesignTokens.mutedText")
    }

    public static var border: Color {
      dynamicColor(
        light: hex(0x0F1115, alpha: 0.08),
        dark: hex(0xF3F4F6, alpha: 0.12),
        name: "DesignTokens.border"
      )
    }

    public static var success: Color {
      dynamicColor(light: hex(0x2BB673), dark: hex(0x42C788), name: "DesignTokens.success")
    }

    public static var warning: Color {
      dynamicColor(light: hex(0xF6A500), dark: hex(0xFFBD33), name: "DesignTokens.warning")
    }

    public static var danger: Color {
      dynamicColor(light: hex(0xE94F37), dark: hex(0xF16956), name: "DesignTokens.danger")
    }

    public static var info: Color {
      dynamicColor(light: hex(0x3C7BEA), dark: hex(0x5E94F0), name: "DesignTokens.info")
    }

    #if canImport(AppKit)
    private static func dynamicColor(light: Color, dark: Color, name: String) -> Color {
      let nsColor = NSColor(name: NSColor.Name(name)) { appearance in
        let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        return NSColor(isDark ? dark : light)
      }
      return Color(nsColor: nsColor)
    }
    #elseif canImport(UIKit)
    private static func dynamicColor(light: Color, dark: Color, name: String) -> Color {
      Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
      })
    }
    #else
    private static func dynamicColor(light: Color, dark: Color, name: String) -> Color {
      light
    }
    #endif
  }

  public enum Typography {
    public struct Style {
      public let size: CGFloat
      public let weight: Font.Weight
      public let lineHeight: CGFloat

      public init(size: CGFloat, weight: Font.Weight, lineHeight: CGFloat) {
        self.size = size
        self.weight = weight
        self.lineHeight = lineHeight
      }

      public var font: Font {
        .system(size: size, weight: weight, design: .default)
      }
    }

    public static var display: Style { Style(size: 32, weight: .semibold, lineHeight: 40) }
    public static var title1: Style { Style(size: 24, weight: .semibold, lineHeight: 32) }
    public static var title2: Style { Style(size: 20, weight: .semibold, lineHeight: 28) }
    public static var headline: Style { Style(size: 16, weight: .semibold, lineHeight: 22) }
    public static var body: Style { Style(size: 14, weight: .regular, lineHeight: 20) }
    public static var callout: Style { Style(size: 13, weight: .regular, lineHeight: 18) }
    public static var caption: Style { Style(size: 12, weight: .regular, lineHeight: 16) }
    public static var button: Style { Style(size: 14, weight: .semibold, lineHeight: 18) }
  }

  public enum Spacing {
    public static let x1: CGFloat = 4
    public static let x2: CGFloat = 8
    public static let x3: CGFloat = 12
    public static let x4: CGFloat = 16
    public static let x5: CGFloat = 20
    public static let x6: CGFloat = 24
    public static let x8: CGFloat = 32
    public static let x10: CGFloat = 40
    public static let x12: CGFloat = 48
    public static let x16: CGFloat = 64
  }

  public enum Radius {
    public static let control: CGFloat = 8
    public static let card: CGFloat = 10
    public static let pill: CGFloat = 999
  }
}
