// Vision OCR: ocr <image>... -> "path<TAB>line | line" per image
import Foundation
import Vision
import AppKit
for path in CommandLine.arguments.dropFirst() {
  guard let img = NSImage(contentsOfFile: path), let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else { print("\(path)\tLOAD_ERROR"); continue }
  let req = VNRecognizeTextRequest()
  req.recognitionLevel = .accurate
  req.usesLanguageCorrection = false
  try? VNImageRequestHandler(cgImage: cg, options: [:]).perform([req])
  let lines = (req.results ?? []).compactMap { $0.topCandidates(1).first?.string }
  print("\(path)\t\(lines.joined(separator: " | "))")
}
