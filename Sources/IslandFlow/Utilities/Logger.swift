import Foundation
import os.log

public enum Logger {
    private static let subsystem = "com.islandflow.app"
    
    public static let app = os.Logger(subsystem: subsystem, category: "App")
    public static let window = os.Logger(subsystem: subsystem, category: "Window")
    public static let screen = os.Logger(subsystem: subsystem, category: "Screen")
    public static let state = os.Logger(subsystem: subsystem, category: "State")
}
