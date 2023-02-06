import Foundation
import XCTest

@testable import Lackeys


class MiscTests: XCTestCase {
    
    let windows: [CGRect] = [
        CGRect.parse("100 100 200 100")!,
        CGRect.parse("-200 -100 200 100")!
    ]

    let screens: [CGRect] = [
        CGRect.parse("0 0 500 400")!,
        CGRect.parse("-300 -200 500 400")!
    ]

    func testAmounts() {
        let lit10 = Amount.parse("10")!
        XCTAssert(lit10.raw == 10.0)
        XCTAssert(lit10.actual(20) == 10.0)

        let pct = Amount.parse("50%")!
        XCTAssert(pct.raw == 0.5)
        XCTAssert(pct.actual(20) == 10.0)
    }

    func testInvalidTweaks() {
        // empty
        tweak(0, "", nil)
        // not a number
        tweak(0, "0 0 0 broken", nil)
        // too many
        tweak(0, "0 0 0 0 0", nil)
    }

    func testAbsoluteTweaks() {
        // window vanshes
        tweak(0, "0 0 0 0", "0 0 0 0")
        // window vanshes
        tweak(0, "+0 +0 -0 -0", "0 0 0 0")
    }

    func testTweaksPositiveWindow() {
        // no change
        tweak(0, ".+0 . .-0 .", "100 100 200 100")
        // move over by 50, 40
        tweak(0, ".+50 .+40 .-0 .-0", "150 140 200 100")
        // top half of screen
        tweak(0, "0% 0% 100% 50%", "0 0 500 200")
        // full screen
        tweak(0, "0% 0% 100% 100%", "0 0 500 400")
        // middle 80% of screen
        tweak(0, "10% 10% 80% 80%", "50 40 400 320")
        // top right box of 4x4 grid
        tweak(0, "75% 0% 25% 25%", "375 0 125 100")
        // fill width
        tweak(0, "0% .+0 100% .+0", "0 100 500 100")
        // fill height
        tweak(0, ".+0 0% .+0 100%", "100 0 200 400")
        // fill except for small border
        tweak(0, "10 10 *-20 *-20", "10 10 480 380")
        // small window in the lower right
        tweak(0, "*-50 *-50 40 40", "450 350 40 40")
    }

    func testTweaksNegativeWindow() {
        // no change
        tweak(1, ".+0 . .-0 .", "-200 -100 200 100")
        // move over by 50, 40
        tweak(1, ".+50 .+40 .-0 .-0", "-150 -60 200 100")
        // top half of screen
        tweak(1, "0% 0% 100% 50%", "-300 -200 500 200")
        // full screen
        tweak(1, "0% 0% 100% 100%", "-300 -200 500 400")
        // middle 80% of screen
        tweak(1, "10% 10% 80% 80%", "-250 -160 400 320")
        // top right box of 4x4 grid
        tweak(1, "75% 0% 25% 25%", "75 -200 125 100")
        // fill width
        tweak(1, "0% .+0 100% .+0", "-300 -100 500 100")
        // fill height
        tweak(1, ".+0 0% .+0 100%", "-200 -200 200 400")
        // fill except for small border -- BROKEN
        // tweak(1, "10 10 *-20 *-20", "10 10 480 380")
        // small window in the lower right -- BROKEN
        // tweak(1, "*-50 *-50 40 40", "150 150 40 40")
    }

    private func tweak(_ index: Int, _ s : String, _ expected: String?) {
        if let tweaks = Tweaks.parse(s) {
            let newBounds = tweaks.tweak(windows[index], within: screens[index])
            XCTAssert("\(newBounds)" == expected, "Expected \(expected!) but got \(newBounds)")
        }
        else {
            if expected != nil {
                XCTFail("Unexpected parse failure for \(s)")
            }
        }
    }

    func testStringCleaving() {
        XCTAssert("".cleave("") == ("", ""))
        XCTAssert("foobar".cleave("") == ("foobar", ""))
        XCTAssert("".cleave("foobar") == ("", ""))
        XCTAssert("foobar".cleave("fo") == ("", "obar"))
        XCTAssert("foobar".cleave("ob") == ("fo", "ar"))
        XCTAssert("foobar".cleave("ar") == ("foob", ""))
    }
}
