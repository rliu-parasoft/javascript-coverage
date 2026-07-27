package com.parasoft.jscov.coverage;

import java.io.File;
import java.util.*;

public final class FileCoverage {
    private final File fileLocation;
    private final String referenceId;
    private final Map<String, String> attrs;
    private final List<CoverableItemNode> staticItems;

    public FileCoverage(
            File fileLocation,
            String referenceId,
            List<CoverableItemNode> staticItems) {
        this.fileLocation = Objects.requireNonNull(fileLocation, "fileLocation  must not be null");
        this.referenceId = Objects.requireNonNull(referenceId, "referenceId  must not be null");
        this.staticItems = Collections.unmodifiableList(new ArrayList<>(staticItems));
        this.attrs = new HashMap<>();
    }

    public File getFileLocation() {
        return fileLocation;
    }

    public String getReferenceId() {
        return referenceId;
    }

    public List<CoverableItemNode> getStaticItems() {
        return staticItems;
    }

    public void addAttribute(String sName, String sValue) {
        this.attrs.put(sName, sValue);
    }

    public Properties getLocationProperties() {
        Properties props = new Properties();
        props.setProperty("uri", referenceId);
        if (!attrs.isEmpty()) {
            for (Map.Entry<String, String> attrEntry : attrs.entrySet()) {
                props.setProperty(attrEntry.getKey(), attrEntry.getValue());
            }
        }
        return props;
    }
}
