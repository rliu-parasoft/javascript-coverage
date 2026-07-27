package com.parasoft.jscov.coverage;

import com.parasoft.xtest.coverage.api.results.ILineCoverageInfoBuilder;

import java.util.List;

final class CoverageBuilderAdapter {
    static void addStaticCoverage(ILineCoverageInfoBuilder builder, List<CoverableItemNode> staticItems) {
        for (CoverableItemNode item : staticItems) {
            appendCoverableItem(builder, item);
        }
    }

    private static void appendCoverableItem(ILineCoverageInfoBuilder builder, CoverableItemNode item) {
        builder.startCoverableItem(item.getDisplayName(), item.getItemId());
        for (Integer line : item.getCoverableLines()) {
            builder.addCoverableLine(line);
        }
        for (CoverableItemNode child : item.getChildren()) {
            appendCoverableItem(builder, child);
        }
        builder.endCoverableItem();
    }
}
