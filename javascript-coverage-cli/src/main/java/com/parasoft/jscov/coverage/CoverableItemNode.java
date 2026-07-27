package com.parasoft.jscov.coverage;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Objects;

public final class CoverableItemNode {
    private final String displayName;
    private final String itemId;
    private final List<Integer> coverableLines;
    private final List<CoverableItemNode> children;

    public CoverableItemNode(
            String displayName,
            String itemId,
            List<Integer> coverableLines,
            List<CoverableItemNode> children) {
        this.displayName = Objects.requireNonNull(displayName, "displayName must not be null");
        this.itemId = Objects.requireNonNull(itemId, "itemId must not be null");
        this.coverableLines = Collections.unmodifiableList(new ArrayList<>(coverableLines));
        this.children = Collections.unmodifiableList(new ArrayList<>(children));
    }

    public String getDisplayName() {
        return displayName;
    }

    public String getItemId() {
        return itemId;
    }

    public List<Integer> getCoverableLines() {
        return coverableLines;
    }

    public List<CoverableItemNode> getChildren() {
        return children;
    }
}
