package com.parasoft.jscov.coverage.istanbul;

import com.parasoft.jscov.coverage.istanbul.dto.IstanbulSourceFileCoverageDto;
import com.parasoft.jscov.coverage.istanbul.dto.IstanbulSourceFileCoverageDto.BranchDto;
import com.parasoft.jscov.coverage.istanbul.dto.IstanbulSourceFileCoverageDto.FunctionDto;
import com.parasoft.jscov.coverage.istanbul.dto.IstanbulSourceFileCoverageDto.IstanbulProjectDto;
import com.parasoft.jscov.coverage.istanbul.dto.IstanbulSourceFileCoverageDto.PositionDto;
import com.parasoft.jscov.coverage.istanbul.dto.IstanbulSourceFileCoverageDto.RangeDto;
import com.parasoft.jscov.i18n.CommonMessages;
import com.parasoft.xtest.common.nls.NLS;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class IstanbulJsonCoverageReaderTest {

    private static final String SAMPLE_JSON = """
            {
                "path": "E:/javascript-coverage-samples/ts-vite-npm-esm/src/math.ts",
                "statementMap": {
                    "0": {
                        "start": {
                            "line": 2,
                            "column": 15
                        },
                        "end": {
                            "line": 2,
                            "column": null
                        }
                    },
                    "1": {
                        "start": {
                            "line": 2,
                            "column": 33
                        },
                        "end": {
                            "line": 2,
                            "column": null
                        }
                    },
                    "2": {
                        "start": {
                            "line": 6,
                            "column": 19
                        },
                        "end": {
                            "line": 6,
                            "column": null
                        }
                    },
                    "3": {
                        "start": {
                            "line": 8,
                            "column": 4
                        },
                        "end": {
                            "line": 8,
                            "column": null
                        }
                    }
                },
                "fnMap": {
                    "0": {
                        "name": "(anonymous_0)",
                        "decl": {
                            "start": {
                                "line": 2,
                                "column": 15
                            },
                            "end": {
                                "line": 2,
                                "column": 16
                            }
                        },
                        "loc": {
                            "start": {
                                "line": 2,
                                "column": 33
                            },
                            "end": {
                                "line": 2,
                                "column": null
                            }
                        }
                    },
                    "1": {
                        "name": "(anonymous_1)",
                        "decl": {
                            "start": {
                                "line": 4,
                                "column": 2
                            },
                            "end": {
                                "line": 4,
                                "column": 9
                            }
                        },
                        "loc": {
                            "start": {
                                "line": 4,
                                "column": 48
                            },
                            "end": {
                                "line": 9,
                                "column": null
                            }
                        }
                    }
                },
                "branchMap": {
                    "0": {
                        "loc": {
                            "start": {
                                "line": 2,
                                "column": 16
                            },
                            "end": {
                                "line": 2,
                                "column": 23
                            }
                        },
                        "type": "default-arg",
                        "locations": [
                            {
                                "start": {
                                    "line": 2,
                                    "column": 20
                                },
                                "end": {
                                    "line": 2,
                                    "column": 23
                                }
                            }
                        ]
                    },
                    "1": {
                        "loc": {
                            "start": {
                                "line": 2,
                                "column": 23
                            },
                            "end": {
                                "line": 2,
                                "column": 33
                            }
                        },
                        "type": "default-arg",
                        "locations": [
                            {
                                "start": {
                                    "line": 2,
                                    "column": 27
                                },
                                "end": {
                                    "line": 2,
                                    "column": 33
                                }
                            }
                        ]
                    },
                    "2": {
                        "loc": {
                            "start": {
                                "line": 6,
                                "column": 19
                            },
                            "end": {
                                "line": 6,
                                "column": null
                            }
                        },
                        "type": "cond-expr",
                        "locations": [
                            {
                                "start": {
                                    "line": 6,
                                    "column": 27
                                },
                                "end": {
                                    "line": 6,
                                    "column": 35
                                }
                            },
                            {
                                "start": {
                                    "line": 6,
                                    "column": 35
                                },
                                "end": {
                                    "line": 6,
                                    "column": null
                                }
                            }
                        ]
                    }
                },
                "s": {
                    "0": 0,
                    "1": 0,
                    "2": 0,
                    "3": 0
                },
                "f": {
                    "0": 0,
                    "1": 0
                },
                "b": {
                    "0": [
                        0
                    ],
                    "1": [
                        0
                    ],
                    "2": [
                        0,
                        0
                    ]
                },
                "project": {
                    "name": "ts-vite-npm-esm",
                    "root": "E:/javascript-coverage-samples/ts-vite-npm-esm"
                }
            }
            """;

    @Test
    void read_parsesRealCoverageJsonIntoFullyPopulatedDto(@TempDir Path tempDir) throws IOException {
        Path jsonFile = tempDir.resolve("math.ts-c74bd6f9-c531-5ddf-b78d-e7fedf1f257d.json");
        Files.writeString(jsonFile, SAMPLE_JSON, StandardCharsets.UTF_8);

        IstanbulSourceFileCoverageDto dto = IstanbulJsonCoverageReader.read(jsonFile);

        assertNotNull(dto);

        // --- top-level scalars ---
        assertEquals(
                "E:/javascript-coverage-samples/ts-vite-npm-esm/src/math.ts",
                dto.getPath());

        // --- project ---
        IstanbulProjectDto project = dto.getProject();
        assertNotNull(project);
        assertEquals("ts-vite-npm-esm", project.getName());
        assertEquals(
                "E:/javascript-coverage-samples/ts-vite-npm-esm",
                project.getRoot());

        // --- statementMap ---
        Map<String, RangeDto> statementMap = dto.getStatementMap();
        assertNotNull(statementMap);
        assertEquals(4, statementMap.size());
        assertPosition(statementMap.get("0").getStart(), 2, 15);
        assertPosition(statementMap.get("0").getEnd(), 2, null);
        assertPosition(statementMap.get("1").getStart(), 2, 33);
        assertPosition(statementMap.get("1").getEnd(), 2, null);
        assertPosition(statementMap.get("2").getStart(), 6, 19);
        assertPosition(statementMap.get("2").getEnd(), 6, null);
        assertPosition(statementMap.get("3").getStart(), 8, 4);
        assertPosition(statementMap.get("3").getEnd(), 8, null);

        // --- fnMap ---
        Map<String, FunctionDto> fnMap = dto.getFnMap();
        assertNotNull(fnMap);
        assertEquals(2, fnMap.size());

        FunctionDto fn0 = fnMap.get("0");
        assertEquals("(anonymous_0)", fn0.getName());
        assertPosition(fn0.getDecl().getStart(), 2, 15);
        assertPosition(fn0.getDecl().getEnd(), 2, 16);
        assertPosition(fn0.getLoc().getStart(), 2, 33);
        assertPosition(fn0.getLoc().getEnd(), 2, null);

        FunctionDto fn1 = fnMap.get("1");
        assertEquals("(anonymous_1)", fn1.getName());
        assertPosition(fn1.getDecl().getStart(), 4, 2);
        assertPosition(fn1.getDecl().getEnd(), 4, 9);
        assertPosition(fn1.getLoc().getStart(), 4, 48);
        assertPosition(fn1.getLoc().getEnd(), 9, null);

        // --- branchMap ---
        Map<String, BranchDto> branchMap = dto.getBranchMap();
        assertNotNull(branchMap);
        assertEquals(3, branchMap.size());

        BranchDto branch0 = branchMap.get("0");
        assertEquals("default-arg", branch0.getType());
        assertPosition(branch0.getLoc().getStart(), 2, 16);
        assertPosition(branch0.getLoc().getEnd(), 2, 23);
        assertEquals(1, branch0.getLocations().size());
        assertPosition(branch0.getLocations().get(0).getStart(), 2, 20);
        assertPosition(branch0.getLocations().get(0).getEnd(), 2, 23);

        BranchDto branch1 = branchMap.get("1");
        assertEquals("default-arg", branch1.getType());
        assertPosition(branch1.getLoc().getStart(), 2, 23);
        assertPosition(branch1.getLoc().getEnd(), 2, 33);
        assertEquals(1, branch1.getLocations().size());
        assertPosition(branch1.getLocations().get(0).getStart(), 2, 27);
        assertPosition(branch1.getLocations().get(0).getEnd(), 2, 33);

        BranchDto branch2 = branchMap.get("2");
        assertEquals("cond-expr", branch2.getType());
        assertPosition(branch2.getLoc().getStart(), 6, 19);
        assertPosition(branch2.getLoc().getEnd(), 6, null);
        assertEquals(2, branch2.getLocations().size());
        assertPosition(branch2.getLocations().get(0).getStart(), 6, 27);
        assertPosition(branch2.getLocations().get(0).getEnd(), 6, 35);
        assertPosition(branch2.getLocations().get(1).getStart(), 6, 35);
        assertPosition(branch2.getLocations().get(1).getEnd(), 6, null);

        // --- counters ---
        assertEquals(Map.of("0", 0, "1", 0, "2", 0, "3", 0), dto.getS());
        assertEquals(Map.of("0", 0, "1", 0), dto.getF());
        assertEquals(
                Map.of("0", List.of(0), "1", List.of(0), "2", List.of(0, 0)),
                dto.getB());
    }

    @Test
    void read_nullPath_throwsNullPointerException() {
        assertThrows(NullPointerException.class, () -> IstanbulJsonCoverageReader.read(null));
    }

    @Test
    void read_missingFile_throwsIOException(@TempDir Path tempDir) {
        Path missing = tempDir.resolve("does-not-exist.json");
        assertThrows(IOException.class, () -> IstanbulJsonCoverageReader.read(missing));
    }

    @Test
    void read_emptyObject_throwsIOException(@TempDir Path tempDir) throws IOException {
        Path jsonFile = tempDir.resolve("empty.json");
        Files.writeString(jsonFile, "{}", StandardCharsets.UTF_8);

        IOException exception = assertThrows(IOException.class,
                () -> IstanbulJsonCoverageReader.read(jsonFile));

        assertTrue(exception.getMessage().startsWith(
                NLS.getFormatted(CommonMessages.INVALID_ISTANBUL_COVERAGE_JSON, jsonFile, "").trim()));
    }

    private static void assertPosition(PositionDto pos, Integer expectedLine, Integer expectedColumn) {
        assertNotNull(pos);
        assertEquals(expectedLine, pos.getLine());
        assertEquals(expectedColumn, pos.getColumn());
    }
}

