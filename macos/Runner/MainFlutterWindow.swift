import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()

    // Configure window after awakeFromNib
    DispatchQueue.main.async { [weak self] in
      self?.configureWindow()
    }
  }

  private func configureWindow() {
    // No minimum size constraint - let the system manage freely

    // Configure window properties
    self.isRestorable = true  // Remember window state between launches
    self.setFrameAutosaveName("GeckoMainWindow")  // Persist window frame in NSUserDefaults
    self.title = "Ğecko"     // Set window title

    // Only set default size on first launch (no saved frame yet)
    if !self.setFrameUsingName("GeckoMainWindow") {
      // No forced size - let macOS decide the default window size
    }

    // Make sure the window is properly displayed
    self.makeKeyAndOrderFront(nil)
  }
}
