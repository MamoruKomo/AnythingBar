import Testing
@testable import AnythingBarCore

@Test
func appNameIsStable() {
    #expect(BuildInfo.appName == "AnythingBar")
}
