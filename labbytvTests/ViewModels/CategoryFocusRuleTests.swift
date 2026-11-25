import Testing
@testable import labbytv

struct CategoryFocusRuleTests {
    @Test func enteringTheListJumpsToTheSelectedCategory() {
        #expect(CategoryFocusRule.redirect(from: nil, to: "7", selected: "3") == "3")
    }

    @Test func enteringOnTheSelectedRowStaysPut() {
        #expect(CategoryFocusRule.redirect(from: nil, to: "3", selected: "3") == nil)
    }

    @Test func movingInsideTheListIsLeftAlone() {
        #expect(CategoryFocusRule.redirect(from: "3", to: "4", selected: "3") == nil)
    }

    @Test func leavingTheListIsLeftAlone() {
        #expect(CategoryFocusRule.redirect(from: "3", to: nil, selected: "3") == nil)
    }
}
