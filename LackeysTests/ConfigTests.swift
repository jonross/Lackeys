import Foundation
import XCTest

@testable import Lackeys

class ConfigTests: XCTestCase {
    
    override func setUpWithError() throws {
        Key.setup()
    }

    let e = Engine()

    func testBindingScope() {
        check("in", "line 1: missing list of application names")
        var c = check("in Slack", nil)
        XCTAssert(c.scopes == ["Slack"])
        c = check("in   Google Chrome,    iTerm  ", nil)
        XCTAssert(c.scopes == ["Google Chrome", "iTerm"])
    }

    func testEmptyConfigs() {
        check("", nil)
        check("# this is a comment", nil)
        check("# this is a comment\n   # and some\n\n   \n \t #   whitespace\n\n", nil)
    }

    func testConfigErrors() {
        check("bind", 
                "line 1: bind syntax is: bind [leader] <chord> to <action>")
        check("bind Control M Control N",
                "line 1: bind syntax is: bind [leader] <chord> to <action>")
        check("bind L1 T to",
                "line 1: bind command is missing action")
        check("bind L1 T to open iTerm",
                "line 1: leader L1 is unset")
        check("leader L1 Option Slash\nbind L1 to send X",
                "line 2: bind command is missing a key chord")
    }

    /// Assert that parsing a given configuration file excerpt generates the expected errors
    /// (or specify `nil` if no errors expected.)

    @discardableResult
    func check(_ configText: String, _ expectedErrors: String?) -> Config {
        let config = Config(forEngine: e)
        config.apply(configText)
        if expectedErrors == nil {
            XCTAssert(config.errors.count == 0)
        }
        else {
            let actualErrors = config.errors.joined(separator: "\n")
            XCTAssert(actualErrors == expectedErrors!, "Expected\n\(expectedErrors!)\nbut got\n\(actualErrors)")
        }
        return config
    }
}


