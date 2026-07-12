import Testing
@testable import TUISuite

@Test func tuiSuiteCanBeInitialized() {
}

@Test func keyInputDescriptionsAreNonRecursive() {
    let descriptions: [(KeyInput, String)] = [
        (.char("x"), "'x'"),
        (.fn(5), "F5"),
        (.up, "↑"),
        (.down, "↓"),
        (.left, "←"),
        (.right, "→"),
        (.home, "Home"),
        (.end, "End"),
        (.pageUp, "Page Up"),
        (.pageDown, "Page Down"),
        (.insert, "Insert"),
        (.delete, "Delete"),
        (.escape, "Escape"),
        (.enter, "Enter"),
        (.backspace, "Backspace"),
        (.tab, "Tab"),
    ]

    for (key, expected) in descriptions {
        #expect(key.description == expected)
    }
}

@Test func kittyKeyboardEventsAreRecognized() {
    let cases: [([UInt8], KeyInput, KeyModifiers)] = [
        (Array("\u{1B}[99;5u".utf8), .char("c"), [.ctrl]),
        (Array("\u{1B}[97:65;6u".utf8), .char("a"), [.shift, .ctrl]),
        (Array("\u{1B}[57376;1u".utf8), .fn(13), []),
    ]

    for (bytes, expectedKey, expectedModifiers) in cases {
        guard case let .key(event)? = InputParser.parseEvent(from: bytes) else {
            Issue.record("Expected a key event for \(bytes)")
            continue
        }
        #expect(event.key == expectedKey)
        #expect(event.modifiers == expectedModifiers)
    }
}

@Test func legacyArrowsAndFunctionKeysAreRecognized() {
    let cases: [([UInt8], KeyInput, KeyModifiers)] = [
        (Array("\u{1B}[A".utf8), .up, []),
        (Array("\u{1B}[1;5D".utf8), .left, [.ctrl]),
        (Array("\u{1B}OP".utf8), .fn(1), []),
        (Array("\u{1B}[15~".utf8), .fn(5), []),
    ]

    for (bytes, expectedKey, expectedModifiers) in cases {
        guard case let .key(event)? = InputParser.parseEvent(from: bytes) else {
            Issue.record("Expected a key event for \(bytes)")
            continue
        }
        #expect(event.key == expectedKey)
        #expect(event.modifiers == expectedModifiers)
    }
}
