import CoreGraphics

/// sRGB color for annotations (AppKit-free).
public struct AnnotationColor: Equatable, Sendable {
    public var red: CGFloat
    public var green: CGFloat
    public var blue: CGFloat
    public var alpha: CGFloat

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// Default accent — amber #FFB520.
    public static let amber = AnnotationColor(red: 1, green: 181 / 255, blue: 32 / 255)
    public static let red = AnnotationColor(red: 1, green: 0.2, blue: 0.2)
    public static let blue = AnnotationColor(red: 0.2, green: 0.45, blue: 1)
    public static let black = AnnotationColor(red: 0, green: 0, blue: 0)
    public static let white = AnnotationColor(red: 1, green: 1, blue: 1)

    public var cgColor: CGColor {
        CGColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
    }
}
