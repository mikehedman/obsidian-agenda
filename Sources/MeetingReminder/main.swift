import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let scheduler = Scheduler()
scheduler.start()
app.run()
