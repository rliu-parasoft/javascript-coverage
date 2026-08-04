package com.parasoft.jscov.coverage;

import com.parasoft.xtest.coverage.api.results.ILineCoverageInfoBuilder;
import org.junit.jupiter.api.Test;
import org.mockito.InOrder;

import java.util.List;

import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verifyNoMoreInteractions;

class CoverageBuilderAdapterTest {

    @Test
    void addStaticCoverage_addsCoverageItemsInOrder() {
        ILineCoverageInfoBuilder builder = mock(ILineCoverageInfoBuilder.class);
        CoverableItemNode child = new CoverableItemNode(
                "child", "child-id", List.of(8), List.of());
        CoverableItemNode root = new CoverableItemNode(
                "root", "root-id", List.of(3, 5), List.of(child));

        CoverageBuilderAdapter.addStaticCoverage(builder, List.of(root));

        InOrder order = inOrder(builder);
        order.verify(builder).startCoverableItem("root", "root-id");
        order.verify(builder).addCoverableLine(3);
        order.verify(builder).addCoverableLine(5);
        order.verify(builder).startCoverableItem("child", "child-id");
        order.verify(builder).addCoverableLine(8);
        order.verify(builder, times(2)).endCoverableItem();
        verifyNoMoreInteractions(builder);
    }
}
