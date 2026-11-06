import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics

nonisolated enum QRCodeGenerator {
    /// A crisp QR code as a CGImage, scaled with integer pixels so it stays sharp.
    static func image(for payload: String, scale: CGFloat = 12) -> CGImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: scale, y: scale)) else {
            return nil
        }
        return CIContext().createCGImage(output, from: output.extent)
    }
}
