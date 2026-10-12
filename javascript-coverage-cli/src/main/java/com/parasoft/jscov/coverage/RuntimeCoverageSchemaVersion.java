package com.parasoft.jscov.coverage;

import java.util.Arrays;
import java.util.Optional;

public enum RuntimeCoverageSchemaVersion {
    V1_0("1.0");

    private final String value;

    RuntimeCoverageSchemaVersion(String value) {
        this.value = value;
    }

    public String getValue() {
        return value;
    }

    public static Optional<RuntimeCoverageSchemaVersion> fromValue(String value) {
        return Arrays.stream(values())
                .filter(version -> version.value.equals(value))
                .findFirst();
    }
}
