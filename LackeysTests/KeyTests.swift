import Foundation
import Carbon.HIToolbox
import XCTest

@testable import Lackeys

class KeyTests: XCTestCase {
    
    override func setUpWithError() throws {
        Key.setup()
    }

    func testKeyRegistry() throws {
        XCTAssert(Key.findByName(name: "") == nil)
        XCTAssert(Key.findByName(name: "foo") == nil)
        XCTAssert(Key.findByCode(code: 999999) == nil)
        
        let t = Key.findByName(name: "T")!
        XCTAssert(t.name == "T", "name is \(t.name)")
        XCTAssert(t.code == kVK_ANSI_T, "code is \(t.code)")
        XCTAssert(t.flags.isEmpty)
        XCTAssert(t == Key.findByCode(code: t.code))
        
        let shift = Key.findByName(name: "Shift")!
        XCTAssert(shift.name == "Shift", "name is \(shift.name)")
        XCTAssert(shift.code == kVK_Shift, "code is \(shift.code)")
        XCTAssert(shift.flags == .maskShift)
        XCTAssert(shift == Key.findByCode(code: shift.code))
    }
    
    func testCGEventFlagsBehavesAsHoped() throws {
        let flags = CGEventFlags([.maskControl, .maskShift])
        XCTAssert(flags == CGEventFlags([.maskControl]).union(CGEventFlags([.maskShift])))
    }
    
    func testChordsWithNoModifiers() throws {
        for keyName in ["A", "1", "UpArrow", "Slash"] {
            verifyChord(desc: keyName, keyName: keyName, flags: [])
        }
    }
    
    func testChordsWithEachModifier() throws {
        for keyName in ["A", "1", "UpArrow", "Slash"] {
            for modKey in Key.MODIFIERS {
                verifyChord(desc: "\(modKey.name) \(keyName)", keyName: keyName, flags: modKey.flags)
            }
        }
    }
    
    func testChordsWithMixedModifiers() throws {
        verifyChord(desc: "Shift command K", keyName: "K", flags: [.maskShift, .maskCommand])
        verifyChord(desc: "shift Option L", keyName: "L", flags: [.maskShift, .maskAlternate])
        verifyChord(desc: "Control COMMAND M", keyName: "M", flags: [.maskCommand, .maskControl])
    }
    
    func testChordEdgeCases() throws {
        verifyChord(desc: "   x   ", keyName: "X", flags: [])
        verifyChord(desc: " SHIFT Command command    Shift y ", keyName: "Y", flags: [.maskShift, .maskCommand])
    }
    
    func testChordErrors() throws {
        verifyError(desc: "", error: Chord.emptyChordError)
        verifyError(desc: "xx", error: Chord.unknownKeyError("xx"))
        verifyError(desc: "Control xx", error: Chord.unknownKeyError("xx"))
        verifyError(desc: "xx y", error: Chord.unknownModifierError("xx"))
        verifyError(desc: "Shift", error: Chord.mustEndWithKeyError)
        verifyError(desc: "Shift Control", error: Chord.mustEndWithKeyError)
        verifyError(desc: "a shift a", error: Chord.mustBeModifiersError)
        verifyError(desc: "shift a shift a", error: Chord.mustBeModifiersError)
    }

    /// Support method; parse a `Chord` description and ensure it has the expected key name and flags.
    
    private func verifyChord(desc: String, keyName: String, flags: CGEventFlags) {
        let (chord, error) = Chord.parseWithErrorFrom(desc)
        print(chord, error)
        if error != nil {
            XCTFail("Unexpected chord parse error: " + error!)
        }
        XCTAssert(chord!.key == Key.findByName(name: keyName))
        XCTAssert(chord!.flags == flags)
    }

    /// Support method to check error messages for parsing invalid `Chord` descriptions.
    
    private func verifyError(desc: String, error: String) {
        let (chord, err) = Chord.parseWithErrorFrom(desc)
        XCTAssert(chord == nil)
        XCTAssert(err == error, "actual error is \(err!)")
    }
    
    static let mustBeModifiersError = "all keys in a chord except the last must be modifier keys"

}
