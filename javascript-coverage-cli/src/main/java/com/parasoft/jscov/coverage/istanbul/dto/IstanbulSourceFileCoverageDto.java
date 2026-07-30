package com.parasoft.jscov.coverage.istanbul.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.util.List;
import java.util.Map;

@JsonIgnoreProperties(ignoreUnknown = true)
public class IstanbulSourceFileCoverageDto
{
    private String path;
    private IstanbulProjectDto project;
    private Map<String, RangeDto> statementMap;
    private Map<String, FunctionDto> fnMap;
    private Map<String, BranchDto> branchMap;
    private Map<String, Integer> s;
    private Map<String, Integer> f;
    private Map<String, List<Integer>> b;

    public String getPath()
    {
        return path;
    }

    public void setPath(String path)
    {
        this.path = path;
    }

    public IstanbulProjectDto getProject()
    {
        return project;
    }

    public void setProject(IstanbulProjectDto project)
    {
        this.project = project;
    }

    public Map<String, RangeDto> getStatementMap()
    {
        return statementMap;
    }

    public void setStatementMap(Map<String, RangeDto> statementMap)
    {
        this.statementMap = statementMap;
    }

    public Map<String, FunctionDto> getFnMap()
    {
        return fnMap;
    }

    public void setFnMap(Map<String, FunctionDto> fnMap)
    {
        this.fnMap = fnMap;
    }

    public Map<String, BranchDto> getBranchMap()
    {
        return branchMap;
    }

    public void setBranchMap(Map<String, BranchDto> branchMap)
    {
        this.branchMap = branchMap;
    }

    public Map<String, Integer> getS()
    {
        return s;
    }

    public void setS(Map<String, Integer> s)
    {
        this.s = s;
    }

    public Map<String, Integer> getF()
    {
        return f;
    }

    public void setF(Map<String, Integer> f)
    {
        this.f = f;
    }

    public Map<String, List<Integer>> getB()
    {
        return b;
    }

    public void setB(Map<String, List<Integer>> b)
    {
        this.b = b;
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class BranchDto
    {
        private RangeDto loc;
        private String type;
        private List<RangeDto> locations;

        public RangeDto getLoc()
        {
            return loc;
        }

        public void setLoc(RangeDto loc)
        {
            this.loc = loc;
        }

        public String getType()
        {
            return type;
        }

        public void setType(String type)
        {
            this.type = type;
        }

        public List<RangeDto> getLocations()
        {
            return locations;
        }

        public void setLocations(List<RangeDto> locations)
        {
            this.locations = locations;
        }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class FunctionDto
    {
        private String name;
        private RangeDto decl;
        private RangeDto loc;

        public String getName()
        {
            return name;
        }

        public void setName(String name)
        {
            this.name = name;
        }

        public RangeDto getDecl()
        {
            return decl;
        }

        public void setDecl(RangeDto decl)
        {
            this.decl = decl;
        }

        public RangeDto getLoc()
        {
            return loc;
        }

        public void setLoc(RangeDto loc)
        {
            this.loc = loc;
        }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class RangeDto
    {
        private PositionDto start;
        private PositionDto end;

        public PositionDto getStart()
        {
            return start;
        }

        public void setStart(PositionDto start)
        {
            this.start = start;
        }

        public PositionDto getEnd()
        {
            return end;
        }

        public void setEnd(PositionDto end)
        {
            this.end = end;
        }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class PositionDto
    {
        private Integer line;
        private Integer column;

        public Integer getLine()
        {
            return line;
        }

        public void setLine(Integer line)
        {
            this.line = line;
        }

        public Integer getColumn()
        {
            return column;
        }

        public void setColumn(Integer column)
        {
            this.column = column;
        }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class IstanbulProjectDto
    {
        private String name;
        private String root;

        public String getName()
        {
            return name;
        }

        public void setName(String name)
        {
            this.name = name;
        }

        public String getRoot()
        {
            return root;
        }

        public void setRoot(String root)
        {
            this.root = root;
        }
    }
}
