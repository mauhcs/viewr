import CoreGraphics
import UIKit

// MARK: - UIImage

extension UIImage {

  // MARK: - Private

  /// The PNG or JPEG data representation of the image or `nil` if the conversion failed.
  private var data: Data? {
    #if swift(>=4.2)
    return self.pngData() ?? self.jpegData(compressionQuality: Constant.jpegCompressionQuality)
    #else
    return UIImagePNGRepresentation(self) ??
      UIImageJPEGRepresentation(self, Constant.jpegCompressionQuality)
    #endif  // swift(>=4.2)
  }
}

// MARK: - Constants

private enum Constant {
  static let jpegCompressionQuality: CGFloat = 0.8
}
