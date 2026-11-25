import Foundation

/// Where focus should land in the category list.
nonisolated enum CategoryFocusRule {
    /// Swiping left from the grid lands on whichever row is level with the
    /// card, which is rarely the category being shown. Entering the list
    /// (from nothing focused in it) jumps to the selected category instead;
    /// moving up and down inside the list is left alone.
    /// Returns the row to focus, or nil to keep focus where it is.
    static func redirect(from old: String?, to new: String?, selected: String) -> String? {
        guard old == nil, let new, new != selected else { return nil }
        return selected
    }
}
