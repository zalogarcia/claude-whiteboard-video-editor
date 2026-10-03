// Face + body pose per frame with Apple Vision. Usage: pose <frame.jpg>...  -> JSON lines
// Coordinates are normalized 0..1 with origin TOP-LEFT.
import Foundation
import Vision
import AppKit

func pt(_ p: CGPoint) -> [Double] { [Double(p.x), Double(1 - p.y)] }
let names: [(VNHumanBodyPoseObservation.JointName, String)] = [
  (.nose, "nose"), (.neck, "neck"), (.leftEye, "lEye"), (.rightEye, "rEye"), (.leftEar, "lEar"), (.rightEar, "rEar"),
  (.leftShoulder, "lSh"), (.rightShoulder, "rSh"), (.leftElbow, "lEl"), (.rightElbow, "rEl"),
  (.leftWrist, "lWr"), (.rightWrist, "rWr"), (.root, "root"), (.leftHip, "lHip"), (.rightHip, "rHip")]
for path in CommandLine.arguments.dropFirst() {
  guard let img = NSImage(contentsOfFile: path), let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    print("{\"path\":\"\(path)\",\"error\":\"load\"}"); continue }
  let face = VNDetectFaceRectanglesRequest()
  let body = VNDetectHumanBodyPoseRequest()
  let human = VNDetectHumanRectanglesRequest(); human.upperBodyOnly = false
  let h = VNImageRequestHandler(cgImage: cg, options: [:])
  try? h.perform([face, body, human])
  var out: [String: Any] = ["path": (path as NSString).lastPathComponent]
  if let f = (face.results ?? []).max(by: { $0.boundingBox.width < $1.boundingBox.width }) {
    let b = f.boundingBox
    out["face"] = [Double(b.minX), Double(1 - b.maxY), Double(b.width), Double(b.height), Double(f.confidence)]
  }
  if let hr = (human.results ?? []).max(by: { $0.boundingBox.width * $0.boundingBox.height < $1.boundingBox.width * $1.boundingBox.height }) {
    let b = hr.boundingBox
    out["body"] = [Double(b.minX), Double(1 - b.maxY), Double(b.width), Double(b.height), Double(hr.confidence)]
  }
  if let o = (body.results ?? []).first, let pts = try? o.recognizedPoints(.all) {
    var j: [String: [Double]] = [:]
    for (n, s) in names { if let p = pts[n], p.confidence > 0.2 { j[s] = pt(p.location) + [Double(p.confidence)] } }
    out["joints"] = j
  }
  let data = try! JSONSerialization.data(withJSONObject: out, options: [.sortedKeys])
  print(String(data: data, encoding: .utf8)!)
}
