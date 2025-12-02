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
    // Set default window size to 700x800
    let defaultSize = NSSize(width: 440, height: 800)
    
    // Center the window on screen
    if let screen = NSScreen.main {
      let screenFrame = screen.visibleFrame
      let x = (screenFrame.width - defaultSize.width) / 2 + screenFrame.minX
      let y = (screenFrame.height - defaultSize.height) / 2 + screenFrame.minY
      let windowFrame = NSRect(x: x, y: y, width: defaultSize.width, height: defaultSize.height)
      self.setFrame(windowFrame, display: true, animate: false)
    } else {
      // Fallback if no screen available
      let windowFrame = NSRect(x: 100, y: 100, width: defaultSize.width, height: defaultSize.height)
      self.setFrame(windowFrame, display: true, animate: false)
    }
    
    // Set minimum window size (allows resizing but not smaller than this)
    self.minSize = NSSize(width: 300, height: 700)
    
    // Configure window properties
    self.isRestorable = true  // Remember window state between launches
    self.title = "Ğecko"     // Set window title
    
    // Make sure the window is properly displayed
    self.makeKeyAndOrderFront(nil)
  }
}
