package com.parasoft.jscov.coverage;

import java.util.Arrays;
import java.util.Optional;

public enum StaticCoverageSchemaVersion {
    V1_0("1.0", 1);

    private final String value;
    private final int priority;

    StaticCoverageSchemaVersion(String value, int priority) {
        this.value = value;
        this.priority = priority;
    }

    public String getValue() {
        return value;
    }

    public int getPriority() {
        return priority;
    }

    public static Optional<StaticCoverageSchemaVersion> fromValue(String value) {
        return Arrays.stream(values())
                .filter(version -> version.value.equals(value))
                .findFirst();
    }
}
