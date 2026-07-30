package com.parasoft.jscov.coverage.istanbul.dto;

import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.Objects;
import java.util.Set;

public final class FunctionLineCoverageDto
{
    private final String fnId;
    private final String fnName;
    private final Set<Integer> lines;

    public FunctionLineCoverageDto(String fnId, String fnName, Set<Integer> lines)
    {
        this.fnId = Objects.requireNonNull(fnId, "fnId must not be null");
        this.fnName = Objects.requireNonNull(fnName, "fnName must not be null");
        this.lines = Collections.unmodifiableSet(new LinkedHashSet<>(lines));
    }

    public String getFnId()
    {
        return fnId;
    }

    public String getFnName()
    {
        return fnName;
    }

    public Set<Integer> getLines()
    {
        return lines;
    }
}
