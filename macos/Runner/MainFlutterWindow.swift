import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: false)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()

    // Hide window at launch to avoid size glitch;
    // window_manager will show it after applying the correct size
    self.orderOut(nil)
  }
}
