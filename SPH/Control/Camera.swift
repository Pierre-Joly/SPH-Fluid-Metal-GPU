import CoreGraphics

protocol Camera: Transformable {
  var projectionMatrix: float4x4 { get }
  var viewMatrix: float4x4 { get }
  mutating func update(size: CGSize)
}

struct OrthographicCamera: Camera {
  var transform = Transform()
  var aspect: CGFloat = 1
  var viewSize: CGFloat = 1
    var near: Float = -1.0
  var far: Float = 1

  var viewMatrix: float4x4 {
    (float4x4(translation: position) *
    float4x4(rotation: rotation)).inverse
  }

  var projectionMatrix: float4x4 {
    let rect = CGRect(
      x: -viewSize * aspect * 0.5,
      y: viewSize * 0.5,
      width: viewSize * aspect,
      height: viewSize)
    return float4x4(orthographic: rect, near: near, far: far)
  }

  mutating func update(size: CGSize) {
    aspect = size.width / size.height
  }
}
