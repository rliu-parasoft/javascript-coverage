---
parasoftVersion: 2026.1.0
productVersion: 10.7.5
schemaVersion: 13
suite:
  $type: TestSuite
  name: Coverage
  hasEnvironmentConfig: true
  environmentConfig:
    environments:
    - variables:
      - name: OpenAPI
        value: http://localhost:8050/openapi.yml
      - name: AUT_SERVER_URL
        value: http://localhost:3000
      - name: BASE_URL
        value: http://localhost:8050
      name: Server Env Config
      active: true
  lastModifiedBy: lyao
  notes: "Covers all operations defined in http://localhost:8050/openapi.yml (Coverage\
    \ API v1.0): session lifecycle (start/stop via GET and POST), coverage retrieval/removal\
    \ by session id, bulk coverage cleanup, and agent status/config/info endpoints."
  runMode: 1
  tests:
  - $type: TestSuite
    name: /info
    testID: 340
    tests:
    - $type: RESTClientToolTest
      name: 01 Get agent info GET
      reportingSettings:
        requirementsTracking:
          comment: "Get agent info (operationId: getAgentInfo)."
      testID: 341
      tool:
        $type: RESTClient
        iconName: RESTClient
        name: /info - GET
        outputTools:
        - $type: GenericAssertionTool
          iconName: XMLAssertor
          name: JSON Assertor
          wrappedTool:
            $type: XMLAssertionTool
            iconName: XMLAssertor
            name: XML Assertor
            errorsOutput:
              name: Errors
            assertions:
            - $type: ValueAssertion
              timestamp: 1789366071737
              name: tool id
              extractEntireElement: true
              Assertion_XPath: /root/tool-id/string()
              value:
                name: Value
                value:
                  fixedValue:
                    $type: StringTestValue
                    value: parasoft-jscov
            message:
              $type: ExpectedXMLMessage
              message: true
          conversionStrategy:
            dataFormatName: JSON
            conversionStrategyId: JSON
            conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
        formJson:
          value:
            $type: ElementValue
            writeType: true
            type:
              $type: ElementType
              localName: root
              bodyType:
                $type: ComplexType
                attributes:
                - ns: ""
                  name: type
                  fixed: object
                  contentType:
                    $type: StringType
                  required: true
                name: rootType
                compositor: true
                compositorObj:
                  $type: AllCompositor
            replacedColumn: ""
            values:
            - $type: ComplexValue
              replacedColumn: ""
              attributes:
              - replacedColumn: ""
                value:
                  $type: StringValue
                  replacedColumn: ""
                  value: object
                useValue: true
              compositorValue: true
              compositorValueObj:
                replacedColumn: ""
                values:
                  $type: CompositorValueSetCollectionSet
                  set:
                  - $type: CompositorValueSet
          elementTypeName: root
        hasServiceInfo: true
        serviceInfo:
          serviceDescriptor:
            $type: StandardServiceDescriptor
            location: http://localhost:8050/openapi.yml
        jsonBuilder:
          hasValue: true
          value:
            $type: JSONObjectValue
            nameIsNull: true
        schemaURL:
          MessagingClient_SchemaLocation: "${OpenAPI}"
        formInput:
          value:
            $type: ElementValue
            writeType: true
            type:
              $type: ElementType
              localName: ""
              bodyType:
                $type: ComplexType
                name: anonymous
                compositor: true
                compositorObj:
                  $type: SequenceCompositor
            replacedColumn: ""
            values:
            - $type: ComplexValue
              replacedColumn: ""
              compositorValue: true
              compositorValueObj:
                replacedColumn: ""
                values:
                  $type: CompositorValueSetCollectionSet
                  set:
                  - $type: CompositorValueSet
        jmsMessageOutputProvider:
          $type: JMSMessageOutputProvider
          jmsOutputProviderRequest:
            $type: JMSOutputProvider
            name: Request Object
            menuName: Object
          jmsOutputProviderResponse:
            $type: JMSOutputProvider
            name: Response Message Object
            menuName: Message Object
        validResponseRange:
          validResponseRange:
            values:
            - $type: ScriptedValue
            fixedValue:
              $type: StringTestValue
              validResponseRange: 200
        router:
          values:
          - $type: ScriptedValue
          fixedValue:
            $type: StringTestValue
            HTTPClient_Endpoint: http://localhost:8050/info
        transportProperties:
          manager:
            protocol: 1
            properties:
            - $type: HTTPClientHTTPProperties
              followRedirects:
                bool: true
              common:
                method:
                  values:
                  - $type: ScriptedValue
                  fixedValue:
                    $type: HTTPMethodTestValue
                    method: GET
              keepAlive1_1:
                bool: true
            - $type: HTTPClientHTTPProperties
              followRedirects:
                bool: true
              common:
                method:
                  values:
                  - $type: ScriptedValue
                  fixedValue:
                    $type: HTTPMethodTestValue
                    method: GET
              protocol: 1
              keepAlive1_1:
                bool: true
          messageExchangePattern:
            inverted: true
        outputProviders:
          requestHeader:
            $type: HTTPNamedToolOutputProvider
            menuName: Transport Header
            name: Request Transport Header
          responseHeader:
            $type: HTTPNamedToolOutputProvider
            menuName: Transport Header
            name: Response Transport Header
          xmlRequestOutput:
            $type: NamedXMLToolOutputProvider
            menuName: Traffic
            name: Request Traffic
          trafficOutput:
            m_name: Traffic Stream
          objectOutput:
            $type: ObjectOutputProvider
            outputTools:
            - $type: TrafficViewer
              iconName: TrafficViewer
              name: Traffic Viewer
            name: Traffic Object
        formXML:
          doctype: ""
        literal:
          use: 1
          text:
            MessagingClient_LiteralMessage: ""
            type: application/json
          dataSource:
            columnName: session_id
        mode: Literal
        literalQuery:
          isPropertiesRef: true
        literalPath:
          pathElements:
          - values:
            - $type: ScriptedValue
            fixedValue:
              $type: StringTestValue
              value: info
        resourceMethod:
          resourceId: /info
          httpMethod: GET
        resourceMode: 3
        baseUrl:
          values:
          - $type: ScriptedValue
          - $type: WadlTestValue
            value: http://localhost:8050
          fixedValue:
            $type: StringTestValue
            value: http://localhost:8050
          selectedIndex: 1
  - $type: TestSuite
    name: /status
    testID: 176
    tests:
    - $type: RESTClientToolTest
      name: 01 Get status GET
      reportingSettings:
        requirementsTracking:
          comment: "Get the current agent status (operationId: getStatus)."
      testID: 177
      tool:
        $type: RESTClient
        iconName: RESTClient
        name: without session
        outputTools:
        - $type: GenericAssertionTool
          iconName: XMLAssertor
          name: JSON Assertor
          wrappedTool:
            $type: XMLAssertionTool
            iconName: XMLAssertor
            name: XML Assertor
            errorsOutput:
              name: Errors
            assertions:
            - $type: ValueAssertion
              timestamp: 1789351133591
              name: session
              extractEntireElement: true
              Assertion_XPath: /root/string()
              value:
                name: Value
                value:
                  fixedValue:
                    $type: StringTestValue
                    value: "null"
            message:
              $type: ExpectedXMLMessage
              message: true
          conversionStrategy:
            dataFormatName: JSON
            conversionStrategyId: JSON
            conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
        formJson:
          value:
            $type: ElementValue
            writeType: true
            hasReference: true
            qnameAsString: :root
            replacedColumn: ""
            values:
            - $type: ComplexValue
              replacedColumn: ""
              attributes:
              - replacedColumn: ""
                value:
                  $type: StringValue
                  replacedColumn: ""
                  value: object
                useValue: true
              compositorValue: true
              compositorValueObj:
                replacedColumn: ""
                values:
                  $type: CompositorValueSetCollectionSet
                  set:
                  - $type: CompositorValueSet
          elementTypeName: root
        hasServiceInfo: true
        serviceInfo:
          serviceDescriptor:
            $type: StandardServiceDescriptor
            location: http://localhost:8050/openapi.yml
        jsonBuilder:
          hasValue: true
          value:
            $type: JSONObjectValue
            nameIsNull: true
        schemaURL:
          MessagingClient_SchemaLocation: "${OpenAPI}"
        formInput:
          value:
            $type: ElementValue
            writeType: true
            hasReference: true
            qnameAsString: ":"
            replacedColumn: ""
            values:
            - $type: ComplexValue
              replacedColumn: ""
              compositorValue: true
              compositorValueObj:
                replacedColumn: ""
                values:
                  $type: CompositorValueSetCollectionSet
                  set:
                  - $type: CompositorValueSet
        jmsMessageOutputProvider:
          $type: JMSMessageOutputProvider
          jmsOutputProviderRequest:
            $type: JMSOutputProvider
            name: Request Object
            menuName: Object
          jmsOutputProviderResponse:
            $type: JMSOutputProvider
            name: Response Message Object
            menuName: Message Object
        validResponseRange:
          validResponseRange:
            values:
            - $type: ScriptedValue
            fixedValue:
              $type: StringTestValue
              validResponseRange: 200
        router:
          values:
          - $type: ScriptedValue
          fixedValue:
            $type: StringTestValue
            HTTPClient_Endpoint: http://localhost:8050/status
        transportProperties:
          manager:
            protocol: 1
            properties:
            - $type: HTTPClientHTTPProperties
              followRedirects:
                bool: true
              common:
                method:
                  values:
                  - $type: ScriptedValue
                  fixedValue:
                    $type: HTTPMethodTestValue
                    method: GET
              keepAlive1_1:
                bool: true
            - $type: HTTPClientHTTPProperties
              followRedirects:
                bool: true
              common:
                method:
                  values:
                  - $type: ScriptedValue
                  fixedValue:
                    $type: HTTPMethodTestValue
                    method: GET
              protocol: 1
              keepAlive1_1:
                bool: true
          messageExchangePattern:
            inverted: true
        outputProviders:
          requestHeader:
            $type: HTTPNamedToolOutputProvider
            menuName: Transport Header
            name: Request Transport Header
          responseHeader:
            $type: HTTPNamedToolOutputProvider
            menuName: Transport Header
            name: Response Transport Header
          xmlRequestOutput:
            $type: NamedXMLToolOutputProvider
            menuName: Traffic
            name: Request Traffic
          trafficOutput:
            m_name: Traffic Stream
          objectOutput:
            $type: ObjectOutputProvider
            outputTools:
            - $type: TrafficViewer
              iconName: TrafficViewer
              name: Traffic Viewer
            name: Traffic Object
        formXML:
          doctype: ""
        literal:
          use: 1
          text:
            MessagingClient_LiteralMessage: ""
            type: application/json
          dataSource:
            columnName: session_id
        mode: Literal
        literalQuery:
          isPropertiesRef: true
        literalPath:
          pathElements:
          - values:
            - $type: ScriptedValue
            fixedValue:
              $type: StringTestValue
              value: status
        resourceMethod:
          resourceId: /status
          httpMethod: GET
        resourceMode: 3
        baseUrl:
          values:
          - $type: ScriptedValue
          - $type: WadlTestValue
            value: http://localhost:8050
          fixedValue:
            $type: StringTestValue
            value: http://localhost:8050
          selectedIndex: 1
    - $type: RESTClientToolTest
      name: Start session 2
      reportingSettings:
        requirementsTracking:
          comment: "Prerequisite: start a session so it can be stopped in the next\
            \ test."
      testID: 178
      tool:
        $type: RESTClient
        iconName: RESTClient
        name: /session/start - GET
        outputTools:
        - $type: GenericDataBank
          iconName: XMLDataBank
          name: JSON Data Bank
          wrappedTool:
            $type: XMLtoDataSource
            iconName: XMLDataBank
            name: XML Data Bank
            selectedXPaths:
            - elementOption: 1
              contentOption: 1
              XMLDataBank_ExtractXPath: "/root/session[1]/text()"
              mode: 1
            canonicalizeOutput: true
            xmlMessage: true
            virtualDSCreator:
              writableColumns:
              - customName: session_id
          conversionStrategy:
            dataFormatName: JSON
            conversionStrategyId: JSON
            conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
        formJson:
          value:
            $type: ElementValue
            writeType: true
            hasReference: true
            qnameAsString: :root
            replacedColumn: ""
            values:
            - $type: ComplexValue
              replacedColumn: ""
              attributes:
              - replacedColumn: ""
                value:
                  $type: StringValue
                  replacedColumn: ""
                  value: object
                useValue: true
              compositorValue: true
              compositorValueObj:
                replacedColumn: ""
                values:
                  $type: CompositorValueSetCollectionSet
                  set:
                  - $type: CompositorValueSet
          elementTypeName: root
        hasServiceInfo: true
        serviceInfo:
          serviceDescriptor:
            $type: StandardServiceDescriptor
            location: http://localhost:8050/openapi.yml
        jsonBuilder:
          hasValue: true
          value:
            $type: JSONObjectValue
            nameIsNull: true
        schemaURL:
          MessagingClient_SchemaLocation: "${OpenAPI}"
        formInput:
          value:
            $type: ElementValue
            writeType: true
            hasReference: true
            qnameAsString: ":"
            replacedColumn: ""
            values:
            - $type: ComplexValue
              replacedColumn: ""
              compositorValue: true
              compositorValueObj:
                replacedColumn: ""
                values:
                  $type: CompositorValueSetCollectionSet
                  set:
                  - $type: CompositorValueSet
        jmsMessageOutputProvider:
          $type: JMSMessageOutputProvider
          jmsOutputProviderRequest:
            $type: JMSOutputProvider
            name: Request Object
            menuName: Object
          jmsOutputProviderResponse:
            $type: JMSOutputProvider
            name: Response Message Object
            menuName: Message Object
        validResponseRange:
          validResponseRange:
            values:
            - $type: ScriptedValue
            fixedValue:
              $type: StringTestValue
              validResponseRange: 200
        router:
          values:
          - $type: ScriptedValue
          fixedValue:
            $type: StringTestValue
            HTTPClient_Endpoint: http://localhost:8050/session/start
        transportProperties:
          manager:
            protocol: 1
            properties:
            - $type: HTTPClientHTTPProperties
              followRedirects:
                bool: true
              common:
                method:
                  values:
                  - $type: ScriptedValue
                  fixedValue:
                    $type: HTTPMethodTestValue
                    method: GET
              keepAlive1_1:
                bool: true
            - $type: HTTPClientHTTPProperties
              followRedirects:
                bool: true
              common:
                method:
                  values:
                  - $type: ScriptedValue
                  fixedValue:
                    $type: HTTPMethodTestValue
                    method: GET
              protocol: 1
              keepAlive1_1:
                bool: true
          messageExchangePattern:
            inverted: true
        outputProviders:
          requestHeader:
            $type: HTTPNamedToolOutputProvider
            menuName: Transport Header
            name: Request Transport Header
          responseHeader:
            $type: HTTPNamedToolOutputProvider
            menuName: Transport Header
            name: Response Transport Header
          xmlRequestOutput:
            $type: NamedXMLToolOutputProvider
            menuName: Traffic
            name: Request Traffic
          trafficOutput:
            m_name: Traffic Stream
          objectOutput:
            $type: ObjectOutputProvider
            outputTools:
            - $type: TrafficViewer
              iconName: TrafficViewer
              name: Traffic Viewer
            name: Traffic Object
        formXML:
          doctype: ""
        literal:
          use: 1
          text:
            MessagingClient_LiteralMessage: ""
            type: application/json
          dataSource:
            columnName: session_id
        mode: Literal
        literalQuery:
          isPropertiesRef: true
        literalPath:
          pathElements:
          - values:
            - $type: ScriptedValue
            fixedValue:
              $type: StringTestValue
              value: session
          - values:
            - $type: ScriptedValue
            fixedValue:
              $type: StringTestValue
              value: start
        resourceMethod:
          resourceId: /session/start
          httpMethod: GET
        resourceMode: 3
        baseUrl:
          values:
          - $type: ScriptedValue
          - $type: WadlTestValue
            value: http://localhost:8050
          fixedValue:
            $type: StringTestValue
            value: http://localhost:8050
          selectedIndex: 1
    - $type: RESTClientToolTest
      name: Get status GET 2
      reportingSettings:
        requirementsTracking:
          comment: "Get the current agent status (operationId: getStatus)."
      testID: 179
      tool:
        $type: RESTClient
        iconName: RESTClient
        name: /status - GET with session
        outputTools:
        - $type: GenericAssertionTool
          iconName: XMLAssertor
          name: JSON Assertor
          wrappedTool:
            $type: XMLAssertionTool
            iconName: XMLAssertor
            name: XML Assertor
            errorsOutput:
              name: Errors
            assertions:
            - $type: ValueAssertion
              timestamp: 1789366921658
              name: session
              extractEntireElement: true
              Assertion_XPath: /root/session/string()
              value:
                name: Value
                value:
                  fixedValue:
                    $type: StringTestValue
                  parameterizedValue:
                    column: session_id
                  selectedIndex: -2
            message:
              $type: ExpectedXMLMessage
              message: true
          conversionStrategy:
            dataFormatName: JSON
            conversionStrategyId: JSON
            conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
        formJson:
          value:
            $type: ElementValue
            writeType: true
            hasReference: true
            qnameAsString: :root
            replacedColumn: ""
            values:
            - $type: ComplexValue
              replacedColumn: ""
              attributes:
              - replacedColumn: ""
                value:
                  $type: StringValue
                  replacedColumn: ""
                  value: object
                useValue: true
              compositorValue: true
              compositorValueObj:
                replacedColumn: ""
                values:
                  $type: CompositorValueSetCollectionSet
                  set:
                  - $type: CompositorValueSet
          elementTypeName: root
        hasServiceInfo: true
        serviceInfo:
          serviceDescriptor:
            $type: StandardServiceDescriptor
            location: http://localhost:8050/openapi.yml
        jsonBuilder:
          hasValue: true
          value:
            $type: JSONObjectValue
            nameIsNull: true
        schemaURL:
          MessagingClient_SchemaLocation: "${OpenAPI}"
        formInput:
          value:
            $type: ElementValue
            writeType: true
            hasReference: true
            qnameAsString: ":"
            replacedColumn: ""
            values:
            - $type: ComplexValue
              replacedColumn: ""
              compositorValue: true
              compositorValueObj:
                replacedColumn: ""
                values:
                  $type: CompositorValueSetCollectionSet
                  set:
                  - $type: CompositorValueSet
        jmsMessageOutputProvider:
          $type: JMSMessageOutputProvider
          jmsOutputProviderRequest:
            $type: JMSOutputProvider
            name: Request Object
            menuName: Object
          jmsOutputProviderResponse:
            $type: JMSOutputProvider
            name: Response Message Object
            menuName: Message Object
        validResponseRange:
          validResponseRange:
            values:
            - $type: ScriptedValue
            fixedValue:
              $type: StringTestValue
              validResponseRange: 200
        router:
          values:
          - $type: ScriptedValue
          fixedValue:
            $type: StringTestValue
            HTTPClient_Endpoint: http://localhost:8050/status
        transportProperties:
          manager:
            protocol: 1
            properties:
            - $type: HTTPClientHTTPProperties
              followRedirects:
                bool: true
              common:
                method:
                  values:
                  - $type: ScriptedValue
                  fixedValue:
                    $type: HTTPMethodTestValue
                    method: GET
              keepAlive1_1:
                bool: true
            - $type: HTTPClientHTTPProperties
              followRedirects:
                bool: true
              common:
                method:
                  values:
                  - $type: ScriptedValue
                  fixedValue:
                    $type: HTTPMethodTestValue
                    method: GET
              protocol: 1
              keepAlive1_1:
                bool: true
          messageExchangePattern:
            inverted: true
        outputProviders:
          requestHeader:
            $type: HTTPNamedToolOutputProvider
            menuName: Transport Header
            name: Request Transport Header
          responseHeader:
            $type: HTTPNamedToolOutputProvider
            menuName: Transport Header
            name: Response Transport Header
          xmlRequestOutput:
            $type: NamedXMLToolOutputProvider
            menuName: Traffic
            name: Request Traffic
          trafficOutput:
            m_name: Traffic Stream
          objectOutput:
            $type: ObjectOutputProvider
            outputTools:
            - $type: TrafficViewer
              iconName: TrafficViewer
              name: Traffic Viewer
            name: Traffic Object
        formXML:
          doctype: ""
        literal:
          use: 1
          text:
            MessagingClient_LiteralMessage: ""
            type: application/json
          dataSource:
            columnName: session_id
        mode: Literal
        literalQuery:
          isPropertiesRef: true
        literalPath:
          pathElements:
          - values:
            - $type: ScriptedValue
            fixedValue:
              $type: StringTestValue
              value: status
        resourceMethod:
          resourceId: /status
          httpMethod: GET
        resourceMode: 3
        baseUrl:
          values:
          - $type: ScriptedValue
          - $type: WadlTestValue
            value: http://localhost:8050
          fixedValue:
            $type: StringTestValue
            value: http://localhost:8050
          selectedIndex: 1
    - $type: RESTClientToolTest
      name: Stop session 2
      reportingSettings:
        requirementsTracking:
          comment: "POST /session/stop - success case (operationId: stopSessionPostMethod)."
      testID: 180
      tool:
        $type: RESTClient
        iconName: RESTClient
        name: /session/stop - POST
        outputTools:
        - $type: GenericAssertionTool
          iconName: XMLAssertor
          name: JSON Assertor
          wrappedTool:
            $type: XMLAssertionTool
            iconName: XMLAssertor
            name: XML Assertor
            errorsOutput:
              name: Errors
            assertions:
            - $type: ValueAssertion
              timestamp: 1789366556609
              name: session
              extractEntireElement: true
              Assertion_XPath: /root/session/string()
              value:
                name: Value
                value:
                  fixedValue:
                    $type: StringTestValue
                    value: "null"
                  parameterizedValue:
                    column: session_id
            message:
              $type: ExpectedXMLMessage
              message: true
          conversionStrategy:
            dataFormatName: JSON
            conversionStrategyId: JSON
            conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
        formJson:
          value:
            $type: ElementValue
            writeType: true
            hasReference: true
            qnameAsString: :root
            replacedColumn: ""
            values:
            - $type: ComplexValue
              replacedColumn: ""
              attributes:
              - replacedColumn: ""
                value:
                  $type: StringValue
                  replacedColumn: ""
                  value: object
                useValue: true
              compositorValue: true
              compositorValueObj:
                replacedColumn: ""
                values:
                  $type: CompositorValueSetCollectionSet
                  set:
                  - $type: CompositorValueSet
          elementTypeName: root
        hasServiceInfo: true
        serviceInfo:
          serviceDescriptor:
            $type: StandardServiceDescriptor
            location: http://localhost:8050/openapi.yml
        jsonBuilder:
          hasValue: true
          value:
            $type: JSONObjectValue
            nameIsNull: true
        schemaURL:
          MessagingClient_SchemaLocation: "${OpenAPI}"
        formInput:
          value:
            $type: ElementValue
            writeType: true
            hasReference: true
            qnameAsString: ":"
            replacedColumn: ""
            values:
            - $type: ComplexValue
              replacedColumn: ""
              compositorValue: true
              compositorValueObj:
                replacedColumn: ""
                values:
                  $type: CompositorValueSetCollectionSet
                  set:
                  - $type: CompositorValueSet
        jmsMessageOutputProvider:
          $type: JMSMessageOutputProvider
          jmsOutputProviderRequest:
            $type: JMSOutputProvider
            name: Request Object
            menuName: Object
          jmsOutputProviderResponse:
            $type: JMSOutputProvider
            name: Response Message Object
            menuName: Message Object
        validResponseRange:
          validResponseRange:
            values:
            - $type: ScriptedValue
            fixedValue:
              $type: StringTestValue
              validResponseRange: 200
        router:
          values:
          - $type: ScriptedValue
          fixedValue:
            $type: StringTestValue
            HTTPClient_Endpoint: http://localhost:8050/session/stop
        transportProperties:
          manager:
            protocol: 1
            properties:
            - $type: HTTPClientHTTPProperties
              followRedirects:
                bool: true
              common:
                method:
                  values:
                  - $type: ScriptedValue
                  fixedValue:
                    $type: HTTPMethodTestValue
                    method: POST
              keepAlive1_1:
                bool: true
            - $type: HTTPClientHTTPProperties
              followRedirects:
                bool: true
              common:
                method:
                  values:
                  - $type: ScriptedValue
                  fixedValue:
                    $type: HTTPMethodTestValue
                    method: POST
              protocol: 1
              keepAlive1_1:
                bool: true
          messageExchangePattern:
            inverted: true
        outputProviders:
          requestHeader:
            $type: HTTPNamedToolOutputProvider
            menuName: Transport Header
            name: Request Transport Header
          responseHeader:
            $type: HTTPNamedToolOutputProvider
            menuName: Transport Header
            name: Response Transport Header
          xmlRequestOutput:
            $type: NamedXMLToolOutputProvider
            menuName: Traffic
            name: Request Traffic
          trafficOutput:
            m_name: Traffic Stream
          objectOutput:
            $type: ObjectOutputProvider
            outputTools:
            - $type: TrafficViewer
              iconName: TrafficViewer
              name: Traffic Viewer
            name: Traffic Object
        formXML:
          doctype: ""
        literal:
          use: 1
          text:
            MessagingClient_LiteralMessage: ""
            type: application/json
          dataSource:
            columnName: session_id
        mode: Literal
        literalQuery:
          isPropertiesRef: true
        literalPath:
          pathElements:
          - values:
            - $type: ScriptedValue
            fixedValue:
              $type: StringTestValue
              value: session
          - values:
            - $type: ScriptedValue
            fixedValue:
              $type: StringTestValue
              value: stop
        resourceMethod:
          resourceId: /session/stop
          httpMethod: POST
        resourceMode: 3
        baseUrl:
          values:
          - $type: ScriptedValue
          - $type: WadlTestValue
            value: http://localhost:8050
          fixedValue:
            $type: StringTestValue
            value: http://localhost:8050
          selectedIndex: 1
  - $type: TestSuite
    name: /config
    testID: 181
    tests:
    - $type: RESTClientToolTest
      name: 01 Get config GET
      reportingSettings:
        requirementsTracking:
          comment: "Get agent configuration properties (operationId: getAgentConfig)."
      testID: 182
      tool:
        $type: RESTClient
        iconName: RESTClient
        name: /config - GET
        outputTools:
        - $type: GenericAssertionTool
          iconName: XMLAssertor
          name: JSON Assertor
          wrappedTool:
            $type: XMLAssertionTool
            iconName: XMLAssertor
            name: XML Assertor
            errorsOutput:
              name: Errors
            assertions:
            - $type: ValueAssertion
              timestamp: 1789366046141
              name: port
              extractEntireElement: true
              Assertion_XPath: /root/restServerPort/string()
              value:
                name: Value
                value:
                  fixedValue:
                    $type: StringTestValue
                    value: 8050
            message:
              $type: ExpectedXMLMessage
              message: true
          conversionStrategy:
            dataFormatName: JSON
            conversionStrategyId: JSON
            conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
        - $type: GenericDataBank
          iconName: XMLDataBank
          name: JSON Data Bank
          wrappedTool:
            $type: XMLtoDataSource
            iconName: XMLDataBank
            name: XML Data Bank
            selectedXPaths:
            - elementOption: 1
              contentOption: 1
              XMLDataBank_ExtractXPath: "/root/runtimeData[1]/text()"
              mode: 1
            canonicalizeOutput: true
            xmlMessage: true
            virtualDSCreator:
              writableColumns:
              - customName: runtimeData_path
          conversionStrategy:
            dataFormatName: JSON
            conversionStrategyId: JSON
            conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
        formJson:
          value:
            $type: ElementValue
            writeType: true
            hasReference: true
            qnameAsString: :root
            replacedColumn: ""
            values:
            - $type: ComplexValue
              replacedColumn: ""
              attributes:
              - replacedColumn: ""
                value:
                  $type: StringValue
                  replacedColumn: ""
                  value: object
                useValue: true
              compositorValue: true
              compositorValueObj:
                replacedColumn: ""
                values:
                  $type: CompositorValueSetCollectionSet
                  set:
                  - $type: CompositorValueSet
          elementTypeName: root
        hasServiceInfo: true
        serviceInfo:
          serviceDescriptor:
            $type: StandardServiceDescriptor
            location: http://localhost:8050/openapi.yml
        jsonBuilder:
          hasValue: true
          value:
            $type: JSONObjectValue
            nameIsNull: true
        schemaURL:
          MessagingClient_SchemaLocation: "${OpenAPI}"
        formInput:
          value:
            $type: ElementValue
            writeType: true
            hasReference: true
            qnameAsString: ":"
            replacedColumn: ""
            values:
            - $type: ComplexValue
              replacedColumn: ""
              compositorValue: true
              compositorValueObj:
                replacedColumn: ""
                values:
                  $type: CompositorValueSetCollectionSet
                  set:
                  - $type: CompositorValueSet
        jmsMessageOutputProvider:
          $type: JMSMessageOutputProvider
          jmsOutputProviderRequest:
            $type: JMSOutputProvider
            name: Request Object
            menuName: Object
          jmsOutputProviderResponse:
            $type: JMSOutputProvider
            name: Response Message Object
            menuName: Message Object
        validResponseRange:
          validResponseRange:
            values:
            - $type: ScriptedValue
            fixedValue:
              $type: StringTestValue
              validResponseRange: 200
        router:
          values:
          - $type: ScriptedValue
          fixedValue:
            $type: StringTestValue
            HTTPClient_Endpoint: http://localhost:8050/config
        transportProperties:
          manager:
            protocol: 1
            properties:
            - $type: HTTPClientHTTPProperties
              followRedirects:
                bool: true
              common:
                method:
                  values:
                  - $type: ScriptedValue
                  fixedValue:
                    $type: HTTPMethodTestValue
                    method: GET
              keepAlive1_1:
                bool: true
            - $type: HTTPClientHTTPProperties
              followRedirects:
                bool: true
              common:
                method:
                  values:
                  - $type: ScriptedValue
                  fixedValue:
                    $type: HTTPMethodTestValue
                    method: GET
              protocol: 1
              keepAlive1_1:
                bool: true
          messageExchangePattern:
            inverted: true
        outputProviders:
          requestHeader:
            $type: HTTPNamedToolOutputProvider
            menuName: Transport Header
            name: Request Transport Header
          responseHeader:
            $type: HTTPNamedToolOutputProvider
            menuName: Transport Header
            name: Response Transport Header
          xmlRequestOutput:
            $type: NamedXMLToolOutputProvider
            menuName: Traffic
            name: Request Traffic
          trafficOutput:
            m_name: Traffic Stream
          objectOutput:
            $type: ObjectOutputProvider
            outputTools:
            - $type: TrafficViewer
              iconName: TrafficViewer
              name: Traffic Viewer
            name: Traffic Object
        formXML:
          doctype: ""
        literal:
          use: 1
          text:
            MessagingClient_LiteralMessage: ""
            type: application/json
          dataSource:
            columnName: session_id
        mode: Literal
        literalQuery:
          isPropertiesRef: true
        literalPath:
          pathElements:
          - values:
            - $type: ScriptedValue
            fixedValue:
              $type: StringTestValue
              value: config
        resourceMethod:
          resourceId: /config
          httpMethod: GET
        resourceMode: 3
        baseUrl:
          values:
          - $type: ScriptedValue
          - $type: WadlTestValue
            value: http://localhost:8050
          fixedValue:
            $type: StringTestValue
            value: http://localhost:8050
          selectedIndex: 1
  - $type: TestSuite
    name: /session/start
    testID: 25
    tests:
    - $type: TestSuite
      name: GET
      testID: 586
      tearDownTests:
      - $type: RESTClientToolTest
        name: DELETE coverage 200 skipped and deleted 2
        reportingSettings:
          requirementsTracking:
            comment: "DELETE /coverage - success case, removes remaining inactive\
              \ session coverage (operationId: deleteAllCoverageFiles)."
        testID: 598
        tool:
          $type: RESTClient
          iconName: RESTClient
          name: /coverage - DELETE
          outputTools:
          - $type: GenericAssertionTool
            iconName: XMLAssertor
            name: JSON Assertor
            wrappedTool:
              $type: XMLAssertionTool
              iconName: XMLAssertor
              name: XML Assertor
              errorsOutput:
                name: Errors
              message:
                $type: ExpectedXMLMessage
                message: true
            conversionStrategy:
              dataFormatName: JSON
              conversionStrategyId: JSON
              conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
          formJson:
            value:
              $type: ElementValue
              writeType: true
              hasReference: true
              qnameAsString: :root
              replacedColumn: ""
              values:
              - $type: ComplexValue
                replacedColumn: ""
                attributes:
                - replacedColumn: ""
                  value:
                    $type: StringValue
                    replacedColumn: ""
                    value: object
                  useValue: true
                compositorValue: true
                compositorValueObj:
                  replacedColumn: ""
                  values:
                    $type: CompositorValueSetCollectionSet
                    set:
                    - $type: CompositorValueSet
            elementTypeName: root
          hasServiceInfo: true
          serviceInfo:
            serviceDescriptor:
              $type: StandardServiceDescriptor
              location: http://localhost:8050/openapi.yml
            serviceName: ""
            versionName: ""
          jsonBuilder:
            hasValue: true
            value:
              $type: JSONObjectValue
              nameIsNull: true
          schemaURL:
            MessagingClient_SchemaLocation: "${OpenAPI}"
          formInput:
            value:
              $type: ElementValue
              writeType: true
              hasReference: true
              qnameAsString: ":"
              replacedColumn: ""
              values:
              - $type: ComplexValue
                replacedColumn: ""
                compositorValue: true
                compositorValueObj:
                  replacedColumn: ""
                  values:
                    $type: CompositorValueSetCollectionSet
                    set:
                    - $type: CompositorValueSet
          jmsMessageOutputProvider:
            $type: JMSMessageOutputProvider
            jmsOutputProviderRequest:
              $type: JMSOutputProvider
              name: Request Object
              menuName: Object
            jmsOutputProviderResponse:
              $type: JMSOutputProvider
              name: Response Message Object
              menuName: Message Object
          validResponseRange:
            validResponseRange:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                validResponseRange: 200
          router:
            values:
            - $type: ScriptedValue
            fixedValue:
              $type: StringTestValue
              HTTPClient_Endpoint: http://localhost:8050/coverage
          transportProperties:
            manager:
              protocol: 1
              properties:
              - $type: HTTPClientHTTPProperties
                followRedirects:
                  bool: true
                common:
                  method:
                    values:
                    - $type: ScriptedValue
                    fixedValue:
                      $type: HTTPMethodTestValue
                      method: DELETE
                keepAlive1_1:
                  bool: true
              - $type: HTTPClientHTTPProperties
                followRedirects:
                  bool: true
                common:
                  method:
                    values:
                    - $type: ScriptedValue
                    fixedValue:
                      $type: HTTPMethodTestValue
                      method: DELETE
                protocol: 1
                keepAlive1_1:
                  bool: true
            messageExchangePattern:
              inverted: true
          outputProviders:
            requestHeader:
              $type: HTTPNamedToolOutputProvider
              menuName: Transport Header
              name: Request Transport Header
            responseHeader:
              $type: HTTPNamedToolOutputProvider
              menuName: Transport Header
              name: Response Transport Header
            xmlRequestOutput:
              $type: NamedXMLToolOutputProvider
              menuName: Traffic
              name: Request Traffic
            trafficOutput:
              m_name: Traffic Stream
            objectOutput:
              $type: ObjectOutputProvider
              outputTools:
              - $type: TrafficViewer
                iconName: TrafficViewer
                name: Traffic Viewer
              name: Traffic Object
          formXML:
            doctype: ""
          literal:
            use: 1
            text:
              MessagingClient_LiteralMessage: ""
              type: application/json
            dataSource:
              columnName: session_id
          mode: Literal
          literalQuery:
            isPropertiesRef: true
          literalPath:
            pathElements:
            - values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                value: coverage
          resourceMethod:
            resourceId: /coverage
            httpMethod: DELETE
          resourceMode: 3
          baseUrl:
            values:
            - $type: ScriptedValue
            - $type: WadlTestValue
              value: http://localhost:8050
            fixedValue:
              $type: StringTestValue
              value: http://localhost:8050
            selectedIndex: 1
      tests:
      - $type: RESTClientToolTest
        name: 01 Start session GET 200
        reportingSettings:
          requirementsTracking:
            comment: "GET /session/start - success case (operationId: startSession);\
              \ extracts session ID."
        testID: 587
        tool:
          $type: RESTClient
          iconName: RESTClient
          name: 200
          outputTools:
          - $type: GenericDataBank
            iconName: XMLDataBank
            name: JSON Data Bank
            wrappedTool:
              $type: XMLtoDataSource
              iconName: XMLDataBank
              name: XML Data Bank
              selectedXPaths:
              - XMLDataBank_ExtractXPath: /root/session
                mode: 1
              canonicalizeOutput: true
              xmlMessage: true
              virtualDSCreator:
                writableColumns:
                - customName: session_id
            conversionStrategy:
              dataFormatName: JSON
              conversionStrategyId: JSON
              conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
          - $type: GenericAssertionTool
            iconName: XMLAssertor
            name: JSON Assertor
            wrappedTool:
              $type: XMLAssertionTool
              iconName: XMLAssertor
              name: XML Assertor
              errorsOutput:
                name: Errors
              assertions:
              - $type: ValueAssertion
                timestamp: 1789366118775
                name: Value Assertion
                extractEntireElement: true
                Assertion_XPath: /root/session/string()
                value:
                  name: Value
                  value:
                    fixedValue:
                      $type: StringTestValue
                    parameterizedValue:
                      column: session_id
                    selectedIndex: -2
              message:
                $type: ExpectedXMLMessage
                message: true
            conversionStrategy:
              dataFormatName: JSON
              conversionStrategyId: JSON
              conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
          formJson:
            value:
              $type: ElementValue
              writeType: true
              hasReference: true
              qnameAsString: :root
              replacedColumn: ""
              values:
              - $type: ComplexValue
                replacedColumn: ""
                attributes:
                - replacedColumn: ""
                  value:
                    $type: StringValue
                    replacedColumn: ""
                    value: object
                  useValue: true
                compositorValue: true
                compositorValueObj:
                  replacedColumn: ""
                  values:
                    $type: CompositorValueSetCollectionSet
                    set:
                    - $type: CompositorValueSet
            elementTypeName: root
          hasServiceInfo: true
          serviceInfo:
            serviceDescriptor:
              $type: StandardServiceDescriptor
              location: http://localhost:8050/openapi.yml
            serviceName: ""
            versionName: ""
          jsonBuilder:
            hasValue: true
            value:
              $type: JSONObjectValue
              nameIsNull: true
          schemaURL:
            MessagingClient_SchemaLocation: "${OpenAPI}"
          formInput:
            value:
              $type: ElementValue
              writeType: true
              hasReference: true
              qnameAsString: ":"
              replacedColumn: ""
              values:
              - $type: ComplexValue
                replacedColumn: ""
                compositorValue: true
                compositorValueObj:
                  replacedColumn: ""
                  values:
                    $type: CompositorValueSetCollectionSet
                    set:
                    - $type: CompositorValueSet
          jmsMessageOutputProvider:
            $type: JMSMessageOutputProvider
            jmsOutputProviderRequest:
              $type: JMSOutputProvider
              name: Request Object
              menuName: Object
            jmsOutputProviderResponse:
              $type: JMSOutputProvider
              name: Response Message Object
              menuName: Message Object
          validResponseRange:
            validResponseRange:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                validResponseRange: 200
          router:
            values:
            - $type: ScriptedValue
            fixedValue:
              $type: StringTestValue
              HTTPClient_Endpoint: http://localhost:8050/session/start
          transportProperties:
            manager:
              protocol: 1
              properties:
              - $type: HTTPClientHTTPProperties
                followRedirects:
                  bool: true
                common:
                  method:
                    values:
                    - $type: ScriptedValue
                    fixedValue:
                      $type: HTTPMethodTestValue
                      method: GET
                keepAlive1_1:
                  bool: true
              - $type: HTTPClientHTTPProperties
                followRedirects:
                  bool: true
                common:
                  method:
                    values:
                    - $type: ScriptedValue
                    fixedValue:
                      $type: HTTPMethodTestValue
                      method: GET
                protocol: 1
                keepAlive1_1:
                  bool: true
            messageExchangePattern:
              inverted: true
          outputProviders:
            requestHeader:
              $type: HTTPNamedToolOutputProvider
              menuName: Transport Header
              name: Request Transport Header
            responseHeader:
              $type: HTTPNamedToolOutputProvider
              menuName: Transport Header
              name: Response Transport Header
            xmlRequestOutput:
              $type: NamedXMLToolOutputProvider
              menuName: Traffic
              name: Request Traffic
            trafficOutput:
              m_name: Traffic Stream
            objectOutput:
              $type: ObjectOutputProvider
              outputTools:
              - $type: TrafficViewer
                iconName: TrafficViewer
                name: Traffic Viewer
              name: Traffic Object
          formXML:
            doctype: ""
          literal:
            use: 1
            text:
              MessagingClient_LiteralMessage: ""
              type: application/json
            dataSource:
              columnName: session_id
          mode: Literal
          literalQuery:
            isPropertiesRef: true
          literalPath:
            pathElements:
            - values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                value: session
            - values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                value: start
          resourceMethod:
            resourceId: /session/start
            httpMethod: GET
          resourceMode: 3
          baseUrl:
            values:
            - $type: ScriptedValue
            - $type: WadlTestValue
              value: http://localhost:8050
            fixedValue:
              $type: StringTestValue
              value: http://localhost:8050
            selectedIndex: 1
      - $type: RESTClientToolTest
        name: 02 Start session GET 400 (best-effort trigger)
        reportingSettings:
          requirementsTracking:
            comment: "GET /session/start - documented 400 branch, attempted by starting\
              \ again while session_id is still active. Actual server behavior for\
              \ a duplicate start is not guaranteed to be 400; kept as best-effort\
              \ trigger."
        testID: 588
        tool:
          $type: RESTClient
          iconName: RESTClient
          name: 400 already started
          outputTools:
          - $type: GenericAssertionTool
            iconName: XMLAssertor
            name: JSON Assertor
            wrappedTool:
              $type: XMLAssertionTool
              iconName: XMLAssertor
              name: XML Assertor
              errorsOutput:
                name: Errors
              assertions:
              - $type: ValueAssertion
                timestamp: 1789366145244
                name: message code
                extractEntireElement: true
                Assertion_XPath: /root/messageCode/string()
                value:
                  name: Value
                  value:
                    fixedValue:
                      $type: StringTestValue
                      value: 150
              - $type: StringComparisonAssertion
                timestamp: 1789635077973
                name: message
                extractEntireElement: true
                Assertion_XPath: /root/message/string()
                comparisonMode: 2
                value:
                  name: String Comparison Assertion
                  value:
                    fixedValue:
                      $type: StringTestValue
                      value: 'is already started for user '
              message:
                $type: ExpectedXMLMessage
                message: true
            conversionStrategy:
              dataFormatName: JSON
              conversionStrategyId: JSON
              conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
          formJson:
            value:
              $type: ElementValue
              writeType: true
              hasReference: true
              qnameAsString: :root
              replacedColumn: ""
              values:
              - $type: ComplexValue
                replacedColumn: ""
                attributes:
                - replacedColumn: ""
                  value:
                    $type: StringValue
                    replacedColumn: ""
                    value: object
                  useValue: true
                compositorValue: true
                compositorValueObj:
                  replacedColumn: ""
                  values:
                    $type: CompositorValueSetCollectionSet
                    set:
                    - $type: CompositorValueSet
            elementTypeName: root
          hasServiceInfo: true
          serviceInfo:
            serviceDescriptor:
              $type: StandardServiceDescriptor
              location: http://localhost:8050/openapi.yml
            serviceName: ""
            versionName: ""
          jsonBuilder:
            hasValue: true
            value:
              $type: JSONObjectValue
              nameIsNull: true
          schemaURL:
            MessagingClient_SchemaLocation: "${OpenAPI}"
          formInput:
            value:
              $type: ElementValue
              writeType: true
              hasReference: true
              qnameAsString: ":"
              replacedColumn: ""
              values:
              - $type: ComplexValue
                replacedColumn: ""
                compositorValue: true
                compositorValueObj:
                  replacedColumn: ""
                  values:
                    $type: CompositorValueSetCollectionSet
                    set:
                    - $type: CompositorValueSet
          jmsMessageOutputProvider:
            $type: JMSMessageOutputProvider
            jmsOutputProviderRequest:
              $type: JMSOutputProvider
              name: Request Object
              menuName: Object
            jmsOutputProviderResponse:
              $type: JMSOutputProvider
              name: Response Message Object
              menuName: Message Object
          validResponseRange:
            validResponseRange:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                validResponseRange: 400
          router:
            values:
            - $type: ScriptedValue
            fixedValue:
              $type: StringTestValue
              HTTPClient_Endpoint: http://localhost:8050/session/start
          transportProperties:
            manager:
              protocol: 1
              properties:
              - $type: HTTPClientHTTPProperties
                followRedirects:
                  bool: true
                common:
                  method:
                    values:
                    - $type: ScriptedValue
                    fixedValue:
                      $type: HTTPMethodTestValue
                      method: GET
                keepAlive1_1:
                  bool: true
              - $type: HTTPClientHTTPProperties
                followRedirects:
                  bool: true
                common:
                  method:
                    values:
                    - $type: ScriptedValue
                    fixedValue:
                      $type: HTTPMethodTestValue
                      method: GET
                protocol: 1
                keepAlive1_1:
                  bool: true
            messageExchangePattern:
              inverted: true
          outputProviders:
            requestHeader:
              $type: HTTPNamedToolOutputProvider
              menuName: Transport Header
              name: Request Transport Header
            responseHeader:
              $type: HTTPNamedToolOutputProvider
              menuName: Transport Header
              name: Response Transport Header
            xmlRequestOutput:
              $type: NamedXMLToolOutputProvider
              menuName: Traffic
              name: Request Traffic
            trafficOutput:
              m_name: Traffic Stream
            objectOutput:
              $type: ObjectOutputProvider
              outputTools:
              - $type: TrafficViewer
                iconName: TrafficViewer
                name: Traffic Viewer
              name: Traffic Object
          formXML:
            doctype: ""
          literal:
            use: 1
            text:
              MessagingClient_LiteralMessage: ""
              type: application/json
            dataSource:
              columnName: session_id
          mode: Literal
          literalQuery:
            isPropertiesRef: true
          literalPath:
            pathElements:
            - values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                value: session
            - values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                value: start
          resourceMethod:
            resourceId: /session/start
            httpMethod: GET
          resourceMode: 3
          baseUrl:
            values:
            - $type: ScriptedValue
            - $type: WadlTestValue
              value: http://localhost:8050
            fixedValue:
              $type: StringTestValue
              value: http://localhost:8050
            selectedIndex: 1
      - $type: TestSuite
        name: 500
        testID: 589
        setUpTests:
        - $type: RESTClientToolTest
          name: 04 Stop session GET (cleanup)
          reportingSettings:
            requirementsTracking:
              comment: "Cleanup: stop the session started above before exercising\
                \ the POST variant."
          testID: 600
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: /session/stop - GET
            outputTools:
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789366326097
                  name: session
                  extractEntireElement: true
                  Assertion_XPath: /root/session/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: "null"
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
              serviceName: ""
              versionName: ""
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: "200,404"
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/session/stop
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: session
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: stop
            resourceMethod:
              resourceId: /session/stop
              httpMethod: GET
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
        - $type: RESTClientToolTest
          name: 01 Get config GET
          reportingSettings:
            requirementsTracking:
              comment: "Get agent configuration properties (operationId: getAgentConfig)."
          testID: 601
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: /config - GET
            outputTools:
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789366046141
                  name: port
                  extractEntireElement: true
                  Assertion_XPath: /root/restServerPort/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: 8050
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            - $type: GenericDataBank
              iconName: XMLDataBank
              name: JSON Data Bank
              wrappedTool:
                $type: XMLtoDataSource
                iconName: XMLDataBank
                name: XML Data Bank
                selectedXPaths:
                - elementOption: 1
                  contentOption: 1
                  XMLDataBank_ExtractXPath: "/root/runtimeData[1]/text()"
                  mode: 1
                canonicalizeOutput: true
                xmlMessage: true
                virtualDSCreator:
                  writableColumns:
                  - customName: runtimeData_path
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
              serviceName: ""
              versionName: ""
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 200
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/config
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: runtimeData_path
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: config
            resourceMethod:
              resourceId: /config
              httpMethod: GET
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
        - $type: ToolTest
          name: Extension Tool
          testID: 602
          tool:
            $type: MethodTool
            iconName: Method
            name: rename__default__ dir
            method:
              hasCode: true
              code:
                $type: JythonCode
                input:
                  useText: true
                  textInput:
                    $type: ScriptingTextInput
                    text: |-
                      from com.parasoft.api import Application
                      from java.nio.file import Files, Paths

                      USER_DIR   = '__default__'
                      RENAME_DIR = '__default__copy'

                      def _plain_name(v, label):
                          if not isinstance(v, basestring) or not v or '/' in v or '\\' in v or v in ('.', '..') or '\0' in v:
                              raise RuntimeError('invalid %s: %r' % (label, v))

                      def _runtime_data(context):
                          dv = context.getDataSourceValue('runtimeData_path')
                          if dv is None:
                              raise RuntimeError('runtimeData_path is empty; check the JSON Data Bank on GET /config')
                          s = unicode(dv.toString())
                          parts = s.split(', ', 1)
                          value = parts[1] if len(parts) == 2 and parts[0].startswith('com.parasoft.data.') else s
                          return value.strip()

                      def renameDir(input, context):
                          _plain_name(USER_DIR, 'USER_DIR')
                          _plain_name(RENAME_DIR, 'RENAME_DIR')
                          if USER_DIR == RENAME_DIR:
                              raise RuntimeError('USER_DIR and RENAME_DIR must differ')

                          parent = Paths.get(_runtime_data(context))
                          src = parent.resolve(USER_DIR)
                          dst = parent.resolve(RENAME_DIR)
                          if not Files.exists(src):
                              raise RuntimeError('source not found: %s' % src)
                          if Files.exists(dst):
                              raise RuntimeError('target already exists: %s' % dst)
                          Files.move(src, dst)
                          Application.showMessage('renamed: %s -> %s' % (src, dst))
                          return '%s -> %s' % (src.toAbsolutePath(), dst.toAbsolutePath())
              hasMethodId: true
              methodId:
                $type: JythonMethodIdentifier
                methodName: renameDir
          writeInput: true
          inputType: InputUsable
          input:
            use: 1
            text:
              text: ""
              type: text/plain
            dataSource:
              columnName: runtimeData_path
        - $type: ToolTest
          name: Extension Tool
          testID: 603
          tool:
            $type: MethodTool
            iconName: Method
            name: create __default__ file
            method:
              hasCode: true
              code:
                $type: JythonCode
                input:
                  useText: true
                  textInput:
                    $type: ScriptingTextInput
                    text: "from com.parasoft.api import Application\r\nfrom java.nio.file\
                      \ import Files, Paths, StandardOpenOption\r\nfrom java.lang\
                      \ import String\r\nfrom java.nio.charset import StandardCharsets\r\
                      \n\r\nFILE_NAME    = '__default__'\r\nFILE_CONTENT = ''\r\n\r\
                      \ndef _plain_name(v, label):\r\n    if not isinstance(v, basestring)\
                      \ or not v or '/' in v or '\\\\' in v or v in ('.', '..') or\
                      \ '\\0' in v:\r\n        raise RuntimeError('invalid %s: %r'\
                      \ % (label, v))\r\n\r\ndef _runtime_data(context):\r\n    dv\
                      \ = context.getDataSourceValue('runtimeData_path')\r\n    if\
                      \ dv is None:\r\n        raise RuntimeError('runtimeData_path\
                      \ is empty; check the JSON Data Bank on GET /config')\r\n  \
                      \  # DataValue.toString() format: \"com.parasoft.data.DataValue@<hash>,\
                      \ <value>\"\r\n    s = unicode(dv.toString())\r\n    parts =\
                      \ s.split(', ', 1)\r\n    value = parts[1] if len(parts) ==\
                      \ 2 and parts[0].startswith('com.parasoft.data.') else s\r\n\
                      \    return value.strip()\r\n\r\ndef createFile(input, context):\r\
                      \n    _plain_name(FILE_NAME, 'FILE_NAME')\r\n    runtime_data\
                      \ = _runtime_data(context)\r\n    Application.showMessage('runtime_data\
                      \ = %s' % runtime_data)\r\n\r\n    parent = Paths.get(runtime_data)\r\
                      \n    Files.createDirectories(parent)\r\n    target = parent.resolve(FILE_NAME)\r\
                      \n    bytes_ = String(FILE_CONTENT).getBytes(StandardCharsets.UTF_8)\r\
                      \n    Files.write(target, bytes_,\r\n                StandardOpenOption.CREATE,\r\
                      \n                StandardOpenOption.WRITE,\r\n            \
                      \    StandardOpenOption.TRUNCATE_EXISTING)\r\n    result = str(target.toAbsolutePath())\r\
                      \n    Application.showMessage('created: %s' % result)\r\n  \
                      \  return result"
              hasMethodId: true
              methodId:
                $type: JythonMethodIdentifier
                methodName: createFile
          writeInput: true
          inputType: InputUsable
          input:
            use: 1
            text:
              text: ""
              type: text/plain
            dataSource:
              columnName: runtimeData_path
        tearDownTests:
        - $type: ToolTest
          name: Extension Tool
          testID: 605
          tool:
            $type: MethodTool
            iconName: Method
            name: delete __default__ file
            method:
              hasCode: true
              code:
                $type: JythonCode
                input:
                  useText: true
                  textInput:
                    $type: ScriptingTextInput
                    text: "from com.parasoft.api import Application\r\nfrom java.nio.file\
                      \ import Files, Paths\r\n\r\nFILE_NAME = '__default__'\r\n\r\
                      \ndef _plain_name(v, label):\r\n    if not isinstance(v, basestring)\
                      \ or not v or '/' in v or '\\\\' in v or v in ('.', '..') or\
                      \ '\\0' in v:\r\n        raise RuntimeError('invalid %s: %r'\
                      \ % (label, v))\r\n\r\ndef _runtime_data(context):\r\n    dv\
                      \ = context.getDataSourceValue('runtimeData_path')\r\n    if\
                      \ dv is None:\r\n        raise RuntimeError('runtimeData_path\
                      \ is empty; check the JSON Data Bank on GET /config')\r\n  \
                      \  s = unicode(dv.toString())\r\n    parts = s.split(', ', 1)\r\
                      \n    value = parts[1] if len(parts) == 2 and parts[0].startswith('com.parasoft.data.')\
                      \ else s\r\n    return value.strip()\r\n\r\ndef deleteFile(input,\
                      \ context):\r\n    _plain_name(FILE_NAME, 'FILE_NAME')\r\n \
                      \   target = Paths.get(_runtime_data(context)).resolve(FILE_NAME)\r\
                      \n    existed = Files.deleteIfExists(target)\r\n    Application.showMessage('%s:\
                      \ %s' % ('deleted' if existed else 'not present', target))\r\
                      \n    return str(target.toAbsolutePath())"
              hasMethodId: true
              methodId:
                $type: JythonMethodIdentifier
                methodName: deleteFile
          writeInput: true
          inputType: InputUsable
          input:
            use: 1
            text:
              text: ""
              type: text/plain
            dataSource:
              columnName: runtimeData_path
        - $type: ToolTest
          name: Rename__default__ dir 2
          testID: 606
          tool:
            $type: MethodTool
            iconName: Method
            name: rename__default__ dir back
            method:
              hasCode: true
              code:
                $type: JythonCode
                input:
                  useText: true
                  textInput:
                    $type: ScriptingTextInput
                    text: |-
                      from com.parasoft.api import Application
                      from java.nio.file import Files, Paths

                      USER_DIR   = '__default__copy'
                      RENAME_DIR = '__default__'

                      def _plain_name(v, label):
                          if not isinstance(v, basestring) or not v or '/' in v or '\\' in v or v in ('.', '..') or '\0' in v:
                              raise RuntimeError('invalid %s: %r' % (label, v))

                      def _runtime_data(context):
                          dv = context.getDataSourceValue('runtimeData_path')
                          if dv is None:
                              raise RuntimeError('runtimeData_path is empty; check the JSON Data Bank on GET /config')
                          s = unicode(dv.toString())
                          parts = s.split(', ', 1)
                          value = parts[1] if len(parts) == 2 and parts[0].startswith('com.parasoft.data.') else s
                          return value.strip()

                      def renameDir(input, context):
                          _plain_name(USER_DIR, 'USER_DIR')
                          _plain_name(RENAME_DIR, 'RENAME_DIR')
                          if USER_DIR == RENAME_DIR:
                              raise RuntimeError('USER_DIR and RENAME_DIR must differ')

                          parent = Paths.get(_runtime_data(context))
                          src = parent.resolve(USER_DIR)
                          dst = parent.resolve(RENAME_DIR)
                          if not Files.exists(src):
                              raise RuntimeError('source not found: %s' % src)
                          if Files.exists(dst):
                              raise RuntimeError('target already exists: %s' % dst)
                          Files.move(src, dst)
                          Application.showMessage('renamed: %s -> %s' % (src, dst))
                          return '%s -> %s' % (src.toAbsolutePath(), dst.toAbsolutePath())
              hasMethodId: true
              methodId:
                $type: JythonMethodIdentifier
                methodName: renameDir
          writeInput: true
          inputType: InputUsable
          input:
            use: 1
            text:
              text: ""
              type: text/plain
            dataSource:
              columnName: runtimeData_path
        tests:
        - $type: RESTClientToolTest
          name: "03 Start session GET 500 (documented, not reliably triggerable)"
          reportingSettings:
            requirementsTracking:
              comment: GET /session/start - documented 500 branch. Requires a server-side
                fault; kept as a documentation placeholder.
          testID: 594
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: __default__ existed already
            outputTools:
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789366284246
                  name: message code
                  extractEntireElement: true
                  Assertion_XPath: /root/messageCode/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: 701
                - $type: StringComparisonAssertion
                  timestamp: 1789547807782
                  name: message
                  extractEntireElement: true
                  Assertion_XPath: /root/message/string()
                  comparisonMode: 2
                  value:
                    name: String Comparison Assertion
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: "ailed to start a session for user '__default__': EEXIST:\
                          \ file already exists"
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
              serviceName: ""
              versionName: ""
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 500
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/session/start
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: session
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: start
            resourceMethod:
              resourceId: /session/start
              httpMethod: GET
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
    - $type: TestSuite
      name: POST
      testID: 607
      tearDownTests:
      - $type: RESTClientToolTest
        name: 08 Stop session POST (cleanup)
        reportingSettings:
          requirementsTracking:
            comment: "Cleanup: stop the session started for the POST test."
        testID: 621
        tool:
          $type: RESTClient
          iconName: RESTClient
          name: /session/stop - POST
          outputTools:
          - $type: GenericAssertionTool
            iconName: XMLAssertor
            name: JSON Assertor
            wrappedTool:
              $type: XMLAssertionTool
              iconName: XMLAssertor
              name: XML Assertor
              errorsOutput:
                name: Errors
              message:
                $type: ExpectedXMLMessage
                message: true
            conversionStrategy:
              dataFormatName: JSON
              conversionStrategyId: JSON
              conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
          formJson:
            value:
              $type: ElementValue
              writeType: true
              hasReference: true
              qnameAsString: :root
              replacedColumn: ""
              values:
              - $type: ComplexValue
                replacedColumn: ""
                attributes:
                - replacedColumn: ""
                  value:
                    $type: StringValue
                    replacedColumn: ""
                    value: object
                  useValue: true
                compositorValue: true
                compositorValueObj:
                  replacedColumn: ""
                  values:
                    $type: CompositorValueSetCollectionSet
                    set:
                    - $type: CompositorValueSet
            elementTypeName: root
          hasServiceInfo: true
          serviceInfo:
            serviceDescriptor:
              $type: StandardServiceDescriptor
              location: http://localhost:8050/openapi.yml
            serviceName: ""
            versionName: ""
          jsonBuilder:
            hasValue: true
            value:
              $type: JSONObjectValue
              nameIsNull: true
          schemaURL:
            MessagingClient_SchemaLocation: "${OpenAPI}"
          formInput:
            value:
              $type: ElementValue
              writeType: true
              hasReference: true
              qnameAsString: ":"
              replacedColumn: ""
              values:
              - $type: ComplexValue
                replacedColumn: ""
                compositorValue: true
                compositorValueObj:
                  replacedColumn: ""
                  values:
                    $type: CompositorValueSetCollectionSet
                    set:
                    - $type: CompositorValueSet
          jmsMessageOutputProvider:
            $type: JMSMessageOutputProvider
            jmsOutputProviderRequest:
              $type: JMSOutputProvider
              name: Request Object
              menuName: Object
            jmsOutputProviderResponse:
              $type: JMSOutputProvider
              name: Response Message Object
              menuName: Message Object
          validResponseRange:
            validResponseRange:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                validResponseRange: "200,404"
          router:
            values:
            - $type: ScriptedValue
            fixedValue:
              $type: StringTestValue
              HTTPClient_Endpoint: http://localhost:8050/session/stop
          transportProperties:
            manager:
              protocol: 1
              properties:
              - $type: HTTPClientHTTPProperties
                followRedirects:
                  bool: true
                common:
                  method:
                    values:
                    - $type: ScriptedValue
                    fixedValue:
                      $type: HTTPMethodTestValue
                      method: POST
                keepAlive1_1:
                  bool: true
              - $type: HTTPClientHTTPProperties
                followRedirects:
                  bool: true
                common:
                  method:
                    values:
                    - $type: ScriptedValue
                    fixedValue:
                      $type: HTTPMethodTestValue
                      method: POST
                protocol: 1
                keepAlive1_1:
                  bool: true
            messageExchangePattern:
              inverted: true
          outputProviders:
            requestHeader:
              $type: HTTPNamedToolOutputProvider
              menuName: Transport Header
              name: Request Transport Header
            responseHeader:
              $type: HTTPNamedToolOutputProvider
              menuName: Transport Header
              name: Response Transport Header
            xmlRequestOutput:
              $type: NamedXMLToolOutputProvider
              menuName: Traffic
              name: Request Traffic
            trafficOutput:
              m_name: Traffic Stream
            objectOutput:
              $type: ObjectOutputProvider
              outputTools:
              - $type: TrafficViewer
                iconName: TrafficViewer
                name: Traffic Viewer
              name: Traffic Object
          formXML:
            doctype: ""
          literal:
            use: 1
            text:
              MessagingClient_LiteralMessage: ""
              type: application/json
            dataSource:
              columnName: session_id
          mode: Literal
          literalQuery:
            isPropertiesRef: true
          literalPath:
            pathElements:
            - values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                value: session
            - values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                value: stop
          resourceMethod:
            resourceId: /session/stop
            httpMethod: POST
          resourceMode: 3
          baseUrl:
            values:
            - $type: ScriptedValue
            - $type: WadlTestValue
              value: http://localhost:8050
            fixedValue:
              $type: StringTestValue
              value: http://localhost:8050
            selectedIndex: 1
      - $type: RESTClientToolTest
        name: 17 DELETE all coverage 200
        reportingSettings:
          requirementsTracking:
            comment: "DELETE /coverage - success case, removes remaining inactive\
              \ session coverage (operationId: deleteAllCoverageFiles)."
        testID: 622
        tool:
          $type: RESTClient
          iconName: RESTClient
          name: /coverage - DELETE
          outputTools:
          - $type: GenericAssertionTool
            iconName: XMLAssertor
            name: JSON Assertor
            wrappedTool:
              $type: XMLAssertionTool
              iconName: XMLAssertor
              name: XML Assertor
              errorsOutput:
                name: Errors
              assertions:
              - $type: HasChildrenAssertion
                timestamp: 1789636825224
                name: skipped
                extractEntireElement: true
                Assertion_XPath: /root/skipped
              - $type: HasChildrenAssertion
                timestamp: 1789636838850
                name: deleted
                extractEntireElement: true
                Assertion_XPath: /root/deleted
                value:
                  fixedValue:
                    $type: BooleanFieldTestValue
                    value: true
              message:
                $type: ExpectedXMLMessage
                message: true
            conversionStrategy:
              dataFormatName: JSON
              conversionStrategyId: JSON
              conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
          formJson:
            value:
              $type: ElementValue
              writeType: true
              hasReference: true
              qnameAsString: :root
              replacedColumn: ""
              values:
              - $type: ComplexValue
                replacedColumn: ""
                attributes:
                - replacedColumn: ""
                  value:
                    $type: StringValue
                    replacedColumn: ""
                    value: object
                  useValue: true
                compositorValue: true
                compositorValueObj:
                  replacedColumn: ""
                  values:
                    $type: CompositorValueSetCollectionSet
                    set:
                    - $type: CompositorValueSet
            elementTypeName: root
          hasServiceInfo: true
          serviceInfo:
            serviceDescriptor:
              $type: StandardServiceDescriptor
              location: http://localhost:8050/openapi.yml
            serviceName: ""
            versionName: ""
          jsonBuilder:
            hasValue: true
            value:
              $type: JSONObjectValue
              nameIsNull: true
          schemaURL:
            MessagingClient_SchemaLocation: "${OpenAPI}"
          formInput:
            value:
              $type: ElementValue
              writeType: true
              hasReference: true
              qnameAsString: ":"
              replacedColumn: ""
              values:
              - $type: ComplexValue
                replacedColumn: ""
                compositorValue: true
                compositorValueObj:
                  replacedColumn: ""
                  values:
                    $type: CompositorValueSetCollectionSet
                    set:
                    - $type: CompositorValueSet
          jmsMessageOutputProvider:
            $type: JMSMessageOutputProvider
            jmsOutputProviderRequest:
              $type: JMSOutputProvider
              name: Request Object
              menuName: Object
            jmsOutputProviderResponse:
              $type: JMSOutputProvider
              name: Response Message Object
              menuName: Message Object
          validResponseRange:
            validResponseRange:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                validResponseRange: 200
          router:
            values:
            - $type: ScriptedValue
            fixedValue:
              $type: StringTestValue
              HTTPClient_Endpoint: http://localhost:8050/coverage
          transportProperties:
            manager:
              protocol: 1
              properties:
              - $type: HTTPClientHTTPProperties
                followRedirects:
                  bool: true
                common:
                  method:
                    values:
                    - $type: ScriptedValue
                    fixedValue:
                      $type: HTTPMethodTestValue
                      method: DELETE
                keepAlive1_1:
                  bool: true
              - $type: HTTPClientHTTPProperties
                followRedirects:
                  bool: true
                common:
                  method:
                    values:
                    - $type: ScriptedValue
                    fixedValue:
                      $type: HTTPMethodTestValue
                      method: DELETE
                protocol: 1
                keepAlive1_1:
                  bool: true
            messageExchangePattern:
              inverted: true
          outputProviders:
            requestHeader:
              $type: HTTPNamedToolOutputProvider
              menuName: Transport Header
              name: Request Transport Header
            responseHeader:
              $type: HTTPNamedToolOutputProvider
              menuName: Transport Header
              name: Response Transport Header
            xmlRequestOutput:
              $type: NamedXMLToolOutputProvider
              menuName: Traffic
              name: Request Traffic
            trafficOutput:
              m_name: Traffic Stream
            objectOutput:
              $type: ObjectOutputProvider
              outputTools:
              - $type: TrafficViewer
                iconName: TrafficViewer
                name: Traffic Viewer
              name: Traffic Object
          formXML:
            doctype: ""
          literal:
            use: 1
            text:
              MessagingClient_LiteralMessage: ""
              type: application/json
            dataSource:
              columnName: session_id
          mode: Literal
          literalQuery:
            isPropertiesRef: true
          literalPath:
            pathElements:
            - values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                value: coverage
          resourceMethod:
            resourceId: /coverage
            httpMethod: DELETE
          resourceMode: 3
          baseUrl:
            values:
            - $type: ScriptedValue
            - $type: WadlTestValue
              value: http://localhost:8050
            fixedValue:
              $type: StringTestValue
              value: http://localhost:8050
            selectedIndex: 1
      tests:
      - $type: RESTClientToolTest
        name: 05 Start session POST 200
        reportingSettings:
          requirementsTracking:
            comment: "POST /session/start - success case (operationId: startSessionPostMethod);\
              \ extracts session ID."
        testID: 608
        tool:
          $type: RESTClient
          iconName: RESTClient
          name: 200
          outputTools:
          - $type: GenericDataBank
            iconName: XMLDataBank
            name: JSON Data Bank
            wrappedTool:
              $type: XMLtoDataSource
              iconName: XMLDataBank
              name: XML Data Bank
              selectedXPaths:
              - XMLDataBank_ExtractXPath: /root/session
                mode: 1
              canonicalizeOutput: true
              xmlMessage: true
              virtualDSCreator:
                writableColumns:
                - customName: session_id_post
            conversionStrategy:
              dataFormatName: JSON
              conversionStrategyId: JSON
              conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
          - $type: GenericAssertionTool
            iconName: XMLAssertor
            name: JSON Assertor
            wrappedTool:
              $type: XMLAssertionTool
              iconName: XMLAssertor
              name: XML Assertor
              errorsOutput:
                name: Errors
              message:
                $type: ExpectedXMLMessage
                message: true
            conversionStrategy:
              dataFormatName: JSON
              conversionStrategyId: JSON
              conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
          formJson:
            value:
              $type: ElementValue
              writeType: true
              hasReference: true
              qnameAsString: :root
              replacedColumn: ""
              values:
              - $type: ComplexValue
                replacedColumn: ""
                attributes:
                - replacedColumn: ""
                  value:
                    $type: StringValue
                    replacedColumn: ""
                    value: object
                  useValue: true
                compositorValue: true
                compositorValueObj:
                  replacedColumn: ""
                  values:
                    $type: CompositorValueSetCollectionSet
                    set:
                    - $type: CompositorValueSet
            elementTypeName: root
          hasServiceInfo: true
          serviceInfo:
            serviceDescriptor:
              $type: StandardServiceDescriptor
              location: http://localhost:8050/openapi.yml
          jsonBuilder:
            hasValue: true
            value:
              $type: JSONObjectValue
              nameIsNull: true
          schemaURL:
            MessagingClient_SchemaLocation: "${OpenAPI}"
          formInput:
            value:
              $type: ElementValue
              writeType: true
              hasReference: true
              qnameAsString: ":"
              replacedColumn: ""
              values:
              - $type: ComplexValue
                replacedColumn: ""
                compositorValue: true
                compositorValueObj:
                  replacedColumn: ""
                  values:
                    $type: CompositorValueSetCollectionSet
                    set:
                    - $type: CompositorValueSet
          jmsMessageOutputProvider:
            $type: JMSMessageOutputProvider
            jmsOutputProviderRequest:
              $type: JMSOutputProvider
              name: Request Object
              menuName: Object
            jmsOutputProviderResponse:
              $type: JMSOutputProvider
              name: Response Message Object
              menuName: Message Object
          validResponseRange:
            validResponseRange:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                validResponseRange: 200
          router:
            values:
            - $type: ScriptedValue
            fixedValue:
              $type: StringTestValue
              HTTPClient_Endpoint: http://localhost:8050/session/start
          transportProperties:
            manager:
              protocol: 1
              properties:
              - $type: HTTPClientHTTPProperties
                followRedirects:
                  bool: true
                common:
                  method:
                    values:
                    - $type: ScriptedValue
                    fixedValue:
                      $type: HTTPMethodTestValue
                      method: POST
                keepAlive1_1:
                  bool: true
              - $type: HTTPClientHTTPProperties
                followRedirects:
                  bool: true
                common:
                  method:
                    values:
                    - $type: ScriptedValue
                    fixedValue:
                      $type: HTTPMethodTestValue
                      method: POST
                protocol: 1
                keepAlive1_1:
                  bool: true
            messageExchangePattern:
              inverted: true
          outputProviders:
            requestHeader:
              $type: HTTPNamedToolOutputProvider
              menuName: Transport Header
              name: Request Transport Header
            responseHeader:
              $type: HTTPNamedToolOutputProvider
              menuName: Transport Header
              name: Response Transport Header
            xmlRequestOutput:
              $type: NamedXMLToolOutputProvider
              menuName: Traffic
              name: Request Traffic
            trafficOutput:
              m_name: Traffic Stream
            objectOutput:
              $type: ObjectOutputProvider
              outputTools:
              - $type: TrafficViewer
                iconName: TrafficViewer
                name: Traffic Viewer
              name: Traffic Object
          formXML:
            doctype: ""
          literal:
            use: 1
            text:
              MessagingClient_LiteralMessage: ""
              type: application/json
            dataSource:
              columnName: session_id
          mode: Literal
          literalQuery:
            isPropertiesRef: true
          literalPath:
            pathElements:
            - values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                value: session
            - values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                value: start
          resourceMethod:
            resourceId: /session/start
            httpMethod: POST
          resourceMode: 3
          baseUrl:
            values:
            - $type: ScriptedValue
            - $type: WadlTestValue
              value: http://localhost:8050
            fixedValue:
              $type: StringTestValue
              value: http://localhost:8050
            selectedIndex: 1
      - $type: RESTClientToolTest
        name: 06 Start session POST 400 (best-effort trigger)
        reportingSettings:
          requirementsTracking:
            comment: "POST /session/start - documented 400 branch, attempted by starting\
              \ again while session_id_post is still active. Best-effort trigger;\
              \ actual behavior not guaranteed."
        testID: 609
        tool:
          $type: RESTClient
          iconName: RESTClient
          name: 400 already started
          outputTools:
          - $type: GenericAssertionTool
            iconName: XMLAssertor
            name: JSON Assertor
            wrappedTool:
              $type: XMLAssertionTool
              iconName: XMLAssertor
              name: XML Assertor
              errorsOutput:
                name: Errors
              message:
                $type: ExpectedXMLMessage
                message: true
            conversionStrategy:
              dataFormatName: JSON
              conversionStrategyId: JSON
              conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
          formJson:
            value:
              $type: ElementValue
              writeType: true
              hasReference: true
              qnameAsString: :root
              replacedColumn: ""
              values:
              - $type: ComplexValue
                replacedColumn: ""
                attributes:
                - replacedColumn: ""
                  value:
                    $type: StringValue
                    replacedColumn: ""
                    value: object
                  useValue: true
                compositorValue: true
                compositorValueObj:
                  replacedColumn: ""
                  values:
                    $type: CompositorValueSetCollectionSet
                    set:
                    - $type: CompositorValueSet
            elementTypeName: root
          hasServiceInfo: true
          serviceInfo:
            serviceDescriptor:
              $type: StandardServiceDescriptor
              location: http://localhost:8050/openapi.yml
          jsonBuilder:
            hasValue: true
            value:
              $type: JSONObjectValue
              nameIsNull: true
          schemaURL:
            MessagingClient_SchemaLocation: "${OpenAPI}"
          formInput:
            value:
              $type: ElementValue
              writeType: true
              hasReference: true
              qnameAsString: ":"
              replacedColumn: ""
              values:
              - $type: ComplexValue
                replacedColumn: ""
                compositorValue: true
                compositorValueObj:
                  replacedColumn: ""
                  values:
                    $type: CompositorValueSetCollectionSet
                    set:
                    - $type: CompositorValueSet
          jmsMessageOutputProvider:
            $type: JMSMessageOutputProvider
            jmsOutputProviderRequest:
              $type: JMSOutputProvider
              name: Request Object
              menuName: Object
            jmsOutputProviderResponse:
              $type: JMSOutputProvider
              name: Response Message Object
              menuName: Message Object
          validResponseRange:
            validResponseRange:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                validResponseRange: 400
          router:
            values:
            - $type: ScriptedValue
            fixedValue:
              $type: StringTestValue
              HTTPClient_Endpoint: http://localhost:8050/session/start
          transportProperties:
            manager:
              protocol: 1
              properties:
              - $type: HTTPClientHTTPProperties
                followRedirects:
                  bool: true
                common:
                  method:
                    values:
                    - $type: ScriptedValue
                    fixedValue:
                      $type: HTTPMethodTestValue
                      method: POST
                keepAlive1_1:
                  bool: true
              - $type: HTTPClientHTTPProperties
                followRedirects:
                  bool: true
                common:
                  method:
                    values:
                    - $type: ScriptedValue
                    fixedValue:
                      $type: HTTPMethodTestValue
                      method: POST
                protocol: 1
                keepAlive1_1:
                  bool: true
            messageExchangePattern:
              inverted: true
          outputProviders:
            requestHeader:
              $type: HTTPNamedToolOutputProvider
              menuName: Transport Header
              name: Request Transport Header
            responseHeader:
              $type: HTTPNamedToolOutputProvider
              menuName: Transport Header
              name: Response Transport Header
            xmlRequestOutput:
              $type: NamedXMLToolOutputProvider
              menuName: Traffic
              name: Request Traffic
            trafficOutput:
              m_name: Traffic Stream
            objectOutput:
              $type: ObjectOutputProvider
              outputTools:
              - $type: TrafficViewer
                iconName: TrafficViewer
                name: Traffic Viewer
              name: Traffic Object
          formXML:
            doctype: ""
          literal:
            use: 1
            text:
              MessagingClient_LiteralMessage: ""
              type: application/json
            dataSource:
              columnName: session_id
          mode: Literal
          literalQuery:
            isPropertiesRef: true
          literalPath:
            pathElements:
            - values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                value: session
            - values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                value: start
          resourceMethod:
            resourceId: /session/start
            httpMethod: POST
          resourceMode: 3
          baseUrl:
            values:
            - $type: ScriptedValue
            - $type: WadlTestValue
              value: http://localhost:8050
            fixedValue:
              $type: StringTestValue
              value: http://localhost:8050
            selectedIndex: 1
      - $type: TestSuite
        name: 500
        testID: 610
        setUpTests:
        - $type: RESTClientToolTest
          name: 04 Stop session GET (cleanup)
          reportingSettings:
            requirementsTracking:
              comment: "Cleanup: stop the session started above before exercising\
                \ the POST variant."
          testID: 626
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: /session/stop - POST
            outputTools:
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789366326097
                  name: session
                  extractEntireElement: true
                  Assertion_XPath: /root/session/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: "null"
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
              serviceName: ""
              versionName: ""
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: "200,404"
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/session/stop
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: session
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: stop
            resourceMethod:
              resourceId: /session/stop
              httpMethod: GET
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
        - $type: RESTClientToolTest
          name: 01 Get config GET
          reportingSettings:
            requirementsTracking:
              comment: "Get agent configuration properties (operationId: getAgentConfig)."
          testID: 627
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: /config - GET
            outputTools:
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789366046141
                  name: port
                  extractEntireElement: true
                  Assertion_XPath: /root/restServerPort/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: 8050
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            - $type: GenericDataBank
              iconName: XMLDataBank
              name: JSON Data Bank
              wrappedTool:
                $type: XMLtoDataSource
                iconName: XMLDataBank
                name: XML Data Bank
                selectedXPaths:
                - elementOption: 1
                  contentOption: 1
                  XMLDataBank_ExtractXPath: "/root/runtimeData[1]/text()"
                  mode: 1
                canonicalizeOutput: true
                xmlMessage: true
                virtualDSCreator:
                  writableColumns:
                  - customName: runtimeData_path
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
              serviceName: ""
              versionName: ""
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 200
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/config
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: runtimeData_path
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: config
            resourceMethod:
              resourceId: /config
              httpMethod: GET
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
        - $type: ToolTest
          name: Extension Tool
          testID: 628
          tool:
            $type: MethodTool
            iconName: Method
            name: rename__default__ dir
            method:
              hasCode: true
              code:
                $type: JythonCode
                input:
                  useText: true
                  textInput:
                    $type: ScriptingTextInput
                    text: |-
                      from com.parasoft.api import Application
                      from java.nio.file import Files, Paths

                      USER_DIR   = '__default__'
                      RENAME_DIR = '__default__copy'

                      def _plain_name(v, label):
                          if not isinstance(v, basestring) or not v or '/' in v or '\\' in v or v in ('.', '..') or '\0' in v:
                              raise RuntimeError('invalid %s: %r' % (label, v))

                      def _runtime_data(context):
                          dv = context.getDataSourceValue('runtimeData_path')
                          if dv is None:
                              raise RuntimeError('runtimeData_path is empty; check the JSON Data Bank on GET /config')
                          s = unicode(dv.toString())
                          parts = s.split(', ', 1)
                          value = parts[1] if len(parts) == 2 and parts[0].startswith('com.parasoft.data.') else s
                          return value.strip()

                      def renameDir(input, context):
                          _plain_name(USER_DIR, 'USER_DIR')
                          _plain_name(RENAME_DIR, 'RENAME_DIR')
                          if USER_DIR == RENAME_DIR:
                              raise RuntimeError('USER_DIR and RENAME_DIR must differ')

                          parent = Paths.get(_runtime_data(context))
                          src = parent.resolve(USER_DIR)
                          dst = parent.resolve(RENAME_DIR)
                          if not Files.exists(src):
                              raise RuntimeError('source not found: %s' % src)
                          if Files.exists(dst):
                              raise RuntimeError('target already exists: %s' % dst)
                          Files.move(src, dst)
                          Application.showMessage('renamed: %s -> %s' % (src, dst))
                          return '%s -> %s' % (src.toAbsolutePath(), dst.toAbsolutePath())
              hasMethodId: true
              methodId:
                $type: JythonMethodIdentifier
                methodName: renameDir
          writeInput: true
          inputType: InputUsable
          input:
            use: 1
            text:
              text: ""
              type: text/plain
            dataSource:
              columnName: runtimeData_path
        - $type: ToolTest
          name: Extension Tool
          testID: 629
          tool:
            $type: MethodTool
            iconName: Method
            name: create __default__ file
            method:
              hasCode: true
              code:
                $type: JythonCode
                input:
                  useText: true
                  textInput:
                    $type: ScriptingTextInput
                    text: "from com.parasoft.api import Application\r\nfrom java.nio.file\
                      \ import Files, Paths, StandardOpenOption\r\nfrom java.lang\
                      \ import String\r\nfrom java.nio.charset import StandardCharsets\r\
                      \n\r\nFILE_NAME    = '__default__'\r\nFILE_CONTENT = ''\r\n\r\
                      \ndef _plain_name(v, label):\r\n    if not isinstance(v, basestring)\
                      \ or not v or '/' in v or '\\\\' in v or v in ('.', '..') or\
                      \ '\\0' in v:\r\n        raise RuntimeError('invalid %s: %r'\
                      \ % (label, v))\r\n\r\ndef _runtime_data(context):\r\n    dv\
                      \ = context.getDataSourceValue('runtimeData_path')\r\n    if\
                      \ dv is None:\r\n        raise RuntimeError('runtimeData_path\
                      \ is empty; check the JSON Data Bank on GET /config')\r\n  \
                      \  # DataValue.toString() format: \"com.parasoft.data.DataValue@<hash>,\
                      \ <value>\"\r\n    s = unicode(dv.toString())\r\n    parts =\
                      \ s.split(', ', 1)\r\n    value = parts[1] if len(parts) ==\
                      \ 2 and parts[0].startswith('com.parasoft.data.') else s\r\n\
                      \    return value.strip()\r\n\r\ndef createFile(input, context):\r\
                      \n    _plain_name(FILE_NAME, 'FILE_NAME')\r\n    runtime_data\
                      \ = _runtime_data(context)\r\n    Application.showMessage('runtime_data\
                      \ = %s' % runtime_data)\r\n\r\n    parent = Paths.get(runtime_data)\r\
                      \n    Files.createDirectories(parent)\r\n    target = parent.resolve(FILE_NAME)\r\
                      \n    bytes_ = String(FILE_CONTENT).getBytes(StandardCharsets.UTF_8)\r\
                      \n    Files.write(target, bytes_,\r\n                StandardOpenOption.CREATE,\r\
                      \n                StandardOpenOption.WRITE,\r\n            \
                      \    StandardOpenOption.TRUNCATE_EXISTING)\r\n    result = str(target.toAbsolutePath())\r\
                      \n    Application.showMessage('created: %s' % result)\r\n  \
                      \  return result"
              hasMethodId: true
              methodId:
                $type: JythonMethodIdentifier
                methodName: createFile
          writeInput: true
          inputType: InputUsable
          input:
            use: 1
            text:
              text: ""
              type: text/plain
            dataSource:
              columnName: runtimeData_path
        tearDownTests:
        - $type: ToolTest
          name: Extension Tool
          testID: 630
          tool:
            $type: MethodTool
            iconName: Method
            name: delete __default__ file
            method:
              hasCode: true
              code:
                $type: JythonCode
                input:
                  useText: true
                  textInput:
                    $type: ScriptingTextInput
                    text: "from com.parasoft.api import Application\r\nfrom java.nio.file\
                      \ import Files, Paths\r\n\r\nFILE_NAME = '__default__'\r\n\r\
                      \ndef _plain_name(v, label):\r\n    if not isinstance(v, basestring)\
                      \ or not v or '/' in v or '\\\\' in v or v in ('.', '..') or\
                      \ '\\0' in v:\r\n        raise RuntimeError('invalid %s: %r'\
                      \ % (label, v))\r\n\r\ndef _runtime_data(context):\r\n    dv\
                      \ = context.getDataSourceValue('runtimeData_path')\r\n    if\
                      \ dv is None:\r\n        raise RuntimeError('runtimeData_path\
                      \ is empty; check the JSON Data Bank on GET /config')\r\n  \
                      \  s = unicode(dv.toString())\r\n    parts = s.split(', ', 1)\r\
                      \n    value = parts[1] if len(parts) == 2 and parts[0].startswith('com.parasoft.data.')\
                      \ else s\r\n    return value.strip()\r\n\r\ndef deleteFile(input,\
                      \ context):\r\n    _plain_name(FILE_NAME, 'FILE_NAME')\r\n \
                      \   target = Paths.get(_runtime_data(context)).resolve(FILE_NAME)\r\
                      \n    existed = Files.deleteIfExists(target)\r\n    Application.showMessage('%s:\
                      \ %s' % ('deleted' if existed else 'not present', target))\r\
                      \n    return str(target.toAbsolutePath())"
              hasMethodId: true
              methodId:
                $type: JythonMethodIdentifier
                methodName: deleteFile
          writeInput: true
          inputType: InputUsable
          input:
            use: 1
            text:
              text: ""
              type: text/plain
            dataSource:
              columnName: runtimeData_path
        - $type: ToolTest
          name: Rename__default__ dir 2
          testID: 631
          tool:
            $type: MethodTool
            iconName: Method
            name: rename__default__ dir back
            method:
              hasCode: true
              code:
                $type: JythonCode
                input:
                  useText: true
                  textInput:
                    $type: ScriptingTextInput
                    text: "from com.parasoft.api import Application\r\nfrom java.nio.file\
                      \ import Files, Paths\r\n\r\nUSER_DIR   = '__default__copy'\r\
                      \nRENAME_DIR = '__default__'\r\n\r\ndef _plain_name(v, label):\r\
                      \n    if not isinstance(v, basestring) or not v or '/' in v\
                      \ or '\\\\' in v or v in ('.', '..') or '\\0' in v:\r\n    \
                      \    raise RuntimeError('invalid %s: %r' % (label, v))\r\n\r\
                      \ndef _runtime_data(context):\r\n    dv = context.getDataSourceValue('runtimeData_path')\r\
                      \n    if dv is None:\r\n        raise RuntimeError('runtimeData_path\
                      \ is empty; check the JSON Data Bank on GET /config')\r\n  \
                      \  s = unicode(dv.toString())\r\n    parts = s.split(', ', 1)\r\
                      \n    value = parts[1] if len(parts) == 2 and parts[0].startswith('com.parasoft.data.')\
                      \ else s\r\n    return value.strip()\r\n\r\ndef renameDir(input,\
                      \ context):\r\n    _plain_name(USER_DIR, 'USER_DIR')\r\n   \
                      \ _plain_name(RENAME_DIR, 'RENAME_DIR')\r\n    if USER_DIR ==\
                      \ RENAME_DIR:\r\n        raise RuntimeError('USER_DIR and RENAME_DIR\
                      \ must differ')\r\n\r\n    parent = Paths.get(_runtime_data(context))\r\
                      \n    src = parent.resolve(USER_DIR)\r\n    dst = parent.resolve(RENAME_DIR)\r\
                      \n    if not Files.exists(src):\r\n        raise RuntimeError('source\
                      \ not found: %s' % src)\r\n    if Files.exists(dst):\r\n   \
                      \     raise RuntimeError('target already exists: %s' % dst)\r\
                      \n    Files.move(src, dst)\r\n    Application.showMessage('renamed:\
                      \ %s -> %s' % (src, dst))\r\n    return '%s -> %s' % (src.toAbsolutePath(),\
                      \ dst.toAbsolutePath())"
              hasMethodId: true
              methodId:
                $type: JythonMethodIdentifier
                methodName: renameDir
          writeInput: true
          inputType: InputUsable
          input:
            use: 1
            text:
              text: ""
              type: text/plain
            dataSource:
              columnName: runtimeData_path
        tests:
        - $type: RESTClientToolTest
          name: "03 Start session GET 500 (documented, not reliably triggerable)"
          reportingSettings:
            requirementsTracking:
              comment: GET /session/start - documented 500 branch. Requires a server-side
                fault; kept as a documentation placeholder.
          testID: 615
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: __default__ existed already
            outputTools:
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789366284246
                  name: message code
                  extractEntireElement: true
                  Assertion_XPath: /root/messageCode/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: 701
                - $type: StringComparisonAssertion
                  timestamp: 1789547807782
                  name: message
                  extractEntireElement: true
                  Assertion_XPath: /root/message/string()
                  comparisonMode: 2
                  value:
                    name: String Comparison Assertion
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: "ailed to start a session for user '__default__': EEXIST:\
                          \ file already exists"
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
              serviceName: ""
              versionName: ""
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 500
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/session/start
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: session
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: start
            resourceMethod:
              resourceId: /session/start
              httpMethod: POST
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
  - $type: TestSuite
    name: /session/stop
    testID: 211
    tests:
    - $type: TestSuite
      name: GET
      testID: 643
      tests:
      - $type: TestSuite
        name: 200
        testID: 648
        setUpTests:
        - $type: RESTClientToolTest
          name: Start session GET (prereq) 2
          reportingSettings:
            requirementsTracking:
              comment: "Prerequisite: start a session so it can be stopped in the\
                \ next test."
          testID: 650
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: /session/start - GET
            outputTools:
            - $type: GenericDataBank
              iconName: XMLDataBank
              name: JSON Data Bank
              wrappedTool:
                $type: XMLtoDataSource
                iconName: XMLDataBank
                name: XML Data Bank
                selectedXPaths:
                - elementOption: 1
                  contentOption: 1
                  XMLDataBank_ExtractXPath: "/root/session[1]/text()"
                  mode: 1
                canonicalizeOutput: true
                xmlMessage: true
                virtualDSCreator:
                  writableColumns:
                  - customName: session_id
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 200
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/session/start
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: session
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: start
            resourceMethod:
              resourceId: /session/start
              httpMethod: GET
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
        tests:
        - $type: RESTClientToolTest
          name: 02 Stop session GET 200
          reportingSettings:
            requirementsTracking:
              comment: "GET /session/stop - success case (operationId: stopSessionGetMethod)."
          testID: 649
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: /session/stop - GET
            outputTools:
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789366556609
                  name: session
                  extractEntireElement: true
                  Assertion_XPath: /root/session/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: "null"
                      parameterizedValue:
                        column: session_id
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 200
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/session/stop
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: session
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: stop
            resourceMethod:
              resourceId: /session/stop
              httpMethod: GET
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
      - $type: RESTClientToolTest
        name: 03 Stop session GET 404
        reportingSettings:
          requirementsTracking:
            comment: "GET /session/stop - not found branch, calling again with no\
              \ active session."
        testID: 652
        tool:
          $type: RESTClient
          iconName: RESTClient
          name: 404
          outputTools:
          - $type: GenericAssertionTool
            iconName: XMLAssertor
            name: JSON Assertor
            wrappedTool:
              $type: XMLAssertionTool
              iconName: XMLAssertor
              name: XML Assertor
              errorsOutput:
                name: Errors
              assertions:
              - $type: ValueAssertion
                timestamp: 1789366568013
                name: message code
                extractEntireElement: true
                Assertion_XPath: /root/messageCode/string()
                value:
                  name: Value
                  value:
                    fixedValue:
                      $type: StringTestValue
                      value: 200
              - $type: ValueAssertion
                timestamp: 1789366747542
                name: message
                extractEntireElement: true
                Assertion_XPath: /root/message/string()
                value:
                  name: Value
                  value:
                    fixedValue:
                      $type: StringTestValue
                      value: Cannot stop a session for user '__default__' because
                        it was not started
              message:
                $type: ExpectedXMLMessage
                message: true
            conversionStrategy:
              dataFormatName: JSON
              conversionStrategyId: JSON
              conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
          formJson:
            value:
              $type: ElementValue
              writeType: true
              hasReference: true
              qnameAsString: :root
              replacedColumn: ""
              values:
              - $type: ComplexValue
                replacedColumn: ""
                attributes:
                - replacedColumn: ""
                  value:
                    $type: StringValue
                    replacedColumn: ""
                    value: object
                  useValue: true
                compositorValue: true
                compositorValueObj:
                  replacedColumn: ""
                  values:
                    $type: CompositorValueSetCollectionSet
                    set:
                    - $type: CompositorValueSet
            elementTypeName: root
          hasServiceInfo: true
          serviceInfo:
            serviceDescriptor:
              $type: StandardServiceDescriptor
              location: http://localhost:8050/openapi.yml
          jsonBuilder:
            hasValue: true
            value:
              $type: JSONObjectValue
              nameIsNull: true
          schemaURL:
            MessagingClient_SchemaLocation: "${OpenAPI}"
          formInput:
            value:
              $type: ElementValue
              writeType: true
              hasReference: true
              qnameAsString: ":"
              replacedColumn: ""
              values:
              - $type: ComplexValue
                replacedColumn: ""
                compositorValue: true
                compositorValueObj:
                  replacedColumn: ""
                  values:
                    $type: CompositorValueSetCollectionSet
                    set:
                    - $type: CompositorValueSet
          jmsMessageOutputProvider:
            $type: JMSMessageOutputProvider
            jmsOutputProviderRequest:
              $type: JMSOutputProvider
              name: Request Object
              menuName: Object
            jmsOutputProviderResponse:
              $type: JMSOutputProvider
              name: Response Message Object
              menuName: Message Object
          validResponseRange:
            validResponseRange:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                validResponseRange: 404
          router:
            values:
            - $type: ScriptedValue
            fixedValue:
              $type: StringTestValue
              HTTPClient_Endpoint: http://localhost:8050/session/stop
          transportProperties:
            manager:
              protocol: 1
              properties:
              - $type: HTTPClientHTTPProperties
                followRedirects:
                  bool: true
                common:
                  method:
                    values:
                    - $type: ScriptedValue
                    fixedValue:
                      $type: HTTPMethodTestValue
                      method: GET
                keepAlive1_1:
                  bool: true
              - $type: HTTPClientHTTPProperties
                followRedirects:
                  bool: true
                common:
                  method:
                    values:
                    - $type: ScriptedValue
                    fixedValue:
                      $type: HTTPMethodTestValue
                      method: GET
                protocol: 1
                keepAlive1_1:
                  bool: true
            messageExchangePattern:
              inverted: true
          outputProviders:
            requestHeader:
              $type: HTTPNamedToolOutputProvider
              menuName: Transport Header
              name: Request Transport Header
            responseHeader:
              $type: HTTPNamedToolOutputProvider
              menuName: Transport Header
              name: Response Transport Header
            xmlRequestOutput:
              $type: NamedXMLToolOutputProvider
              menuName: Traffic
              name: Request Traffic
            trafficOutput:
              m_name: Traffic Stream
            objectOutput:
              $type: ObjectOutputProvider
              outputTools:
              - $type: TrafficViewer
                iconName: TrafficViewer
                name: Traffic Viewer
              name: Traffic Object
          formXML:
            doctype: ""
          literal:
            use: 1
            text:
              MessagingClient_LiteralMessage: ""
              type: application/json
            dataSource:
              columnName: session_id
          mode: Literal
          literalQuery:
            isPropertiesRef: true
          literalPath:
            pathElements:
            - values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                value: session
            - values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                value: stop
          resourceMethod:
            resourceId: /session/stop
            httpMethod: GET
          resourceMode: 3
          baseUrl:
            values:
            - $type: ScriptedValue
            - $type: WadlTestValue
              value: http://localhost:8050
            fixedValue:
              $type: StringTestValue
              value: http://localhost:8050
            selectedIndex: 1
    - $type: TestSuite
      name: POST
      testID: 653
      tests:
      - $type: TestSuite
        name: 200
        testID: 654
        setUpTests:
        - $type: RESTClientToolTest
          name: 05 Start session GET (prereq)
          reportingSettings:
            requirementsTracking:
              comment: "Prerequisite: start another session so it can be stopped via\
                \ POST."
          testID: 661
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: /session/start - POST
            outputTools:
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            - $type: GenericDataBank
              iconName: XMLDataBank
              name: JSON Data Bank
              wrappedTool:
                $type: XMLtoDataSource
                iconName: XMLDataBank
                name: XML Data Bank
                selectedXPaths:
                - elementOption: 1
                  contentOption: 1
                  XMLDataBank_ExtractXPath: "/root/session[1]/text()"
                  mode: 1
                canonicalizeOutput: true
                xmlMessage: true
                virtualDSCreator:
                  writableColumns:
                  - customName: session_id
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 200
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/session/start
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: session
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: start
            resourceMethod:
              resourceId: /session/start
              httpMethod: POST
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
        tests:
        - $type: RESTClientToolTest
          name: 06 Stop session POST 200
          reportingSettings:
            requirementsTracking:
              comment: "POST /session/stop - success case (operationId: stopSessionPostMethod)."
          testID: 658
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: /session/stop - GET
            outputTools:
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789366556609
                  name: session
                  extractEntireElement: true
                  Assertion_XPath: /root/session/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: "null"
                      parameterizedValue:
                        column: session_id
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 200
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/session/stop
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: POST
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: POST
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: session
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: stop
            resourceMethod:
              resourceId: /session/stop
              httpMethod: POST
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
      - $type: RESTClientToolTest
        name: 07 Stop session POST 404
        reportingSettings:
          requirementsTracking:
            comment: "POST /session/stop - not found branch, calling again with no\
              \ active session."
        testID: 662
        tool:
          $type: RESTClient
          iconName: RESTClient
          name: 404
          outputTools:
          - $type: GenericAssertionTool
            iconName: XMLAssertor
            name: JSON Assertor
            wrappedTool:
              $type: XMLAssertionTool
              iconName: XMLAssertor
              name: XML Assertor
              errorsOutput:
                name: Errors
              assertions:
              - $type: ValueAssertion
                timestamp: 1789366568013
                name: message code
                extractEntireElement: true
                Assertion_XPath: /root/messageCode/string()
                value:
                  name: Value
                  value:
                    fixedValue:
                      $type: StringTestValue
                      value: 200
              - $type: ValueAssertion
                timestamp: 1789366747542
                name: message
                extractEntireElement: true
                Assertion_XPath: /root/message/string()
                value:
                  name: Value
                  value:
                    fixedValue:
                      $type: StringTestValue
                      value: Cannot stop a session for user '__default__' because
                        it was not started
              message:
                $type: ExpectedXMLMessage
                message: true
            conversionStrategy:
              dataFormatName: JSON
              conversionStrategyId: JSON
              conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
          formJson:
            value:
              $type: ElementValue
              writeType: true
              hasReference: true
              qnameAsString: :root
              replacedColumn: ""
              values:
              - $type: ComplexValue
                replacedColumn: ""
                attributes:
                - replacedColumn: ""
                  value:
                    $type: StringValue
                    replacedColumn: ""
                    value: object
                  useValue: true
                compositorValue: true
                compositorValueObj:
                  replacedColumn: ""
                  values:
                    $type: CompositorValueSetCollectionSet
                    set:
                    - $type: CompositorValueSet
            elementTypeName: root
          hasServiceInfo: true
          serviceInfo:
            serviceDescriptor:
              $type: StandardServiceDescriptor
              location: http://localhost:8050/openapi.yml
          jsonBuilder:
            hasValue: true
            value:
              $type: JSONObjectValue
              nameIsNull: true
          schemaURL:
            MessagingClient_SchemaLocation: "${OpenAPI}"
          formInput:
            value:
              $type: ElementValue
              writeType: true
              hasReference: true
              qnameAsString: ":"
              replacedColumn: ""
              values:
              - $type: ComplexValue
                replacedColumn: ""
                compositorValue: true
                compositorValueObj:
                  replacedColumn: ""
                  values:
                    $type: CompositorValueSetCollectionSet
                    set:
                    - $type: CompositorValueSet
          jmsMessageOutputProvider:
            $type: JMSMessageOutputProvider
            jmsOutputProviderRequest:
              $type: JMSOutputProvider
              name: Request Object
              menuName: Object
            jmsOutputProviderResponse:
              $type: JMSOutputProvider
              name: Response Message Object
              menuName: Message Object
          validResponseRange:
            validResponseRange:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                validResponseRange: 404
          router:
            values:
            - $type: ScriptedValue
            fixedValue:
              $type: StringTestValue
              HTTPClient_Endpoint: http://localhost:8050/session/stop
          transportProperties:
            manager:
              protocol: 1
              properties:
              - $type: HTTPClientHTTPProperties
                followRedirects:
                  bool: true
                common:
                  method:
                    values:
                    - $type: ScriptedValue
                    fixedValue:
                      $type: HTTPMethodTestValue
                      method: POST
                keepAlive1_1:
                  bool: true
              - $type: HTTPClientHTTPProperties
                followRedirects:
                  bool: true
                common:
                  method:
                    values:
                    - $type: ScriptedValue
                    fixedValue:
                      $type: HTTPMethodTestValue
                      method: POST
                protocol: 1
                keepAlive1_1:
                  bool: true
            messageExchangePattern:
              inverted: true
          outputProviders:
            requestHeader:
              $type: HTTPNamedToolOutputProvider
              menuName: Transport Header
              name: Request Transport Header
            responseHeader:
              $type: HTTPNamedToolOutputProvider
              menuName: Transport Header
              name: Response Transport Header
            xmlRequestOutput:
              $type: NamedXMLToolOutputProvider
              menuName: Traffic
              name: Request Traffic
            trafficOutput:
              m_name: Traffic Stream
            objectOutput:
              $type: ObjectOutputProvider
              outputTools:
              - $type: TrafficViewer
                iconName: TrafficViewer
                name: Traffic Viewer
              name: Traffic Object
          formXML:
            doctype: ""
          literal:
            use: 1
            text:
              MessagingClient_LiteralMessage: ""
              type: application/json
            dataSource:
              columnName: session_id
          mode: Literal
          literalQuery:
            isPropertiesRef: true
          literalPath:
            pathElements:
            - values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                value: session
            - values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                value: stop
          resourceMethod:
            resourceId: /session/stop
            httpMethod: POST
          resourceMode: 3
          baseUrl:
            values:
            - $type: ScriptedValue
            - $type: WadlTestValue
              value: http://localhost:8050
            fixedValue:
              $type: StringTestValue
              value: http://localhost:8050
            selectedIndex: 1
  - $type: TestSuite
    name: /coverage
    testID: 185
    tests:
    - $type: TestSuite
      name: /coverage - GET
      testID: 400
      tests:
      - $type: TestSuite
        name: 200
        testID: 578
        setUpTests:
        - $type: RESTClientToolTest
          name: 00 Start main session GET 2
          reportingSettings:
            requirementsTracking:
              comment: "Prerequisite: start the main session and extract its ID for\
                \ GET/DELETE by-id tests."
          testID: 584
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: /session/start - GET
            outputTools:
            - $type: GenericDataBank
              iconName: XMLDataBank
              name: JSON Data Bank
              wrappedTool:
                $type: XMLtoDataSource
                iconName: XMLDataBank
                name: XML Data Bank
                selectedXPaths:
                - XMLDataBank_ExtractXPath: /root/session
                  mode: 1
                canonicalizeOutput: true
                xmlMessage: true
                virtualDSCreator:
                  writableColumns:
                  - customName: session_id
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789351155438
                  name: Value Assertion
                  extractEntireElement: true
                  Assertion_XPath: /root/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                      parameterizedValue:
                        column: session_id
                      selectedIndex: -2
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
              serviceName: ""
              versionName: ""
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 200
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/session/start
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: runtimeData_path
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: session
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: start
            resourceMethod:
              resourceId: /session/start
              httpMethod: GET
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
        tests:
        - $type: RESTClientToolTest
          name: 02 GET coverage list 200
          reportingSettings:
            requirementsTracking:
              comment: "GET /coverage - success case (operationId: getCoverageList)."
          testID: 579
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: 200
            outputTools:
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 200
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/coverage
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: coverage
            resourceMethod:
              resourceId: /coverage
              httpMethod: GET
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
      - $type: TestSuite
        name: 404
        testID: 402
        setUpTests:
        - $type: RESTClientToolTest
          name: 01 Get config GET
          reportingSettings:
            requirementsTracking:
              comment: "Get agent configuration properties (operationId: getAgentConfig)."
          testID: 405
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: /config - GET
            outputTools:
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789366046141
                  name: port
                  extractEntireElement: true
                  Assertion_XPath: /root/restServerPort/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: 8050
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            - $type: GenericDataBank
              iconName: XMLDataBank
              name: JSON Data Bank
              wrappedTool:
                $type: XMLtoDataSource
                iconName: XMLDataBank
                name: XML Data Bank
                selectedXPaths:
                - elementOption: 1
                  contentOption: 1
                  XMLDataBank_ExtractXPath: "/root/runtimeData[1]/text()"
                  mode: 1
                canonicalizeOutput: true
                xmlMessage: true
                virtualDSCreator:
                  writableColumns:
                  - customName: runtimeData_path
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
              serviceName: ""
              versionName: ""
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 200
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/config
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: runtimeData_path
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: config
            resourceMethod:
              resourceId: /config
              httpMethod: GET
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
        - $type: ToolTest
          name: Extension Tool
          testID: 406
          tool:
            $type: MethodTool
            iconName: Method
            name: rename__default__ dir
            method:
              hasCode: true
              code:
                $type: JythonCode
                input:
                  useText: true
                  textInput:
                    $type: ScriptingTextInput
                    text: |-
                      from com.parasoft.api import Application
                      from java.nio.file import Files, Paths

                      USER_DIR   = '__default__'
                      RENAME_DIR = '__default__copy'

                      def _plain_name(v, label):
                          if not isinstance(v, basestring) or not v or '/' in v or '\\' in v or v in ('.', '..') or '\0' in v:
                              raise RuntimeError('invalid %s: %r' % (label, v))

                      def _runtime_data(context):
                          dv = context.getDataSourceValue('runtimeData_path')
                          if dv is None:
                              raise RuntimeError('runtimeData_path is empty; check the JSON Data Bank on GET /config')
                          s = unicode(dv.toString())
                          parts = s.split(', ', 1)
                          value = parts[1] if len(parts) == 2 and parts[0].startswith('com.parasoft.data.') else s
                          return value.strip()

                      def renameDir(input, context):
                          _plain_name(USER_DIR, 'USER_DIR')
                          _plain_name(RENAME_DIR, 'RENAME_DIR')
                          if USER_DIR == RENAME_DIR:
                              raise RuntimeError('USER_DIR and RENAME_DIR must differ')

                          parent = Paths.get(_runtime_data(context))
                          src = parent.resolve(USER_DIR)
                          dst = parent.resolve(RENAME_DIR)
                          if not Files.exists(src):
                              raise RuntimeError('source not found: %s' % src)
                          if Files.exists(dst):
                              raise RuntimeError('target already exists: %s' % dst)
                          Files.move(src, dst)
                          Application.showMessage('renamed: %s -> %s' % (src, dst))
                          return '%s -> %s' % (src.toAbsolutePath(), dst.toAbsolutePath())
              hasMethodId: true
              methodId:
                $type: JythonMethodIdentifier
                methodName: renameDir
          writeInput: true
          inputType: InputUsable
          input:
            use: 1
            text:
              text: ""
              type: text/plain
            dataSource:
              columnName: runtimeData_path
        tearDownTests:
        - $type: ToolTest
          name: Rename__default__ dir 2
          testID: 407
          tool:
            $type: MethodTool
            iconName: Method
            name: rename__default__ dir back
            method:
              hasCode: true
              code:
                $type: JythonCode
                input:
                  useText: true
                  textInput:
                    $type: ScriptingTextInput
                    text: "from com.parasoft.api import Application\r\nfrom java.nio.file\
                      \ import Files, Paths\r\n\r\nUSER_DIR   = '__default__copy'\r\
                      \nRENAME_DIR = '__default__'\r\n\r\ndef _plain_name(v, label):\r\
                      \n    if not isinstance(v, basestring) or not v or '/' in v\
                      \ or '\\\\' in v or v in ('.', '..') or '\\0' in v:\r\n    \
                      \    raise RuntimeError('invalid %s: %r' % (label, v))\r\n\r\
                      \ndef _runtime_data(context):\r\n    dv = context.getDataSourceValue('runtimeData_path')\r\
                      \n    if dv is None:\r\n        raise RuntimeError('runtimeData_path\
                      \ is empty; check the JSON Data Bank on GET /config')\r\n  \
                      \  s = unicode(dv.toString())\r\n    parts = s.split(', ', 1)\r\
                      \n    value = parts[1] if len(parts) == 2 and parts[0].startswith('com.parasoft.data.')\
                      \ else s\r\n    return value.strip()\r\n\r\ndef renameDir(input,\
                      \ context):\r\n    _plain_name(USER_DIR, 'USER_DIR')\r\n   \
                      \ _plain_name(RENAME_DIR, 'RENAME_DIR')\r\n    if USER_DIR ==\
                      \ RENAME_DIR:\r\n        raise RuntimeError('USER_DIR and RENAME_DIR\
                      \ must differ')\r\n\r\n    parent = Paths.get(_runtime_data(context))\r\
                      \n    src = parent.resolve(USER_DIR)\r\n    dst = parent.resolve(RENAME_DIR)\r\
                      \n    if not Files.exists(src):\r\n        raise RuntimeError('source\
                      \ not found: %s' % src)\r\n    if Files.exists(dst):\r\n   \
                      \     raise RuntimeError('target already exists: %s' % dst)\r\
                      \n    Files.move(src, dst)\r\n    Application.showMessage('renamed:\
                      \ %s -> %s' % (src, dst))\r\n    return '%s -> %s' % (src.toAbsolutePath(),\
                      \ dst.toAbsolutePath())"
              hasMethodId: true
              methodId:
                $type: JythonMethodIdentifier
                methodName: renameDir
          writeInput: true
          inputType: InputUsable
          input:
            use: 1
            text:
              text: ""
              type: text/plain
            dataSource:
              columnName: runtimeData_path
        - $type: RESTClientToolTest
          name: 02 Stop session GET 200
          reportingSettings:
            requirementsTracking:
              comment: "GET /session/stop - success case (operationId: stopSessionGetMethod)."
          testID: 408
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: /session/stop - GET
            outputTools:
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789366556609
                  name: session
                  extractEntireElement: true
                  Assertion_XPath: /root/session/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: "null"
                      parameterizedValue:
                        column: session_id
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
              serviceName: ""
              versionName: ""
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 200
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/session/stop
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: session
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: stop
            resourceMethod:
              resourceId: /session/stop
              httpMethod: GET
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
        runMode: 1
        tests:
        - $type: RESTClientToolTest
          name: "03 GET coverage list 404 (documented, not reliably triggerable)"
          reportingSettings:
            requirementsTracking:
              comment: GET /coverage - documented 404 branch ($ref 404WithErrorMessage).
                Server state to reproduce this is not controllable from the client;
                kept as a documentation placeholder.
          testID: 403
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: ' __default__ was not found'
            outputTools:
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789351369708
                  name: message code
                  extractEntireElement: true
                  Assertion_XPath: /root/messageCode/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: 401
                - $type: ValueAssertion
                  timestamp: 1789351384650
                  name: message
                  extractEntireElement: true
                  Assertion_XPath: /root/message/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: Cannot get coverage because user '__default__' was
                          not found
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 404
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/coverage
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: coverage
            resourceMethod:
              resourceId: /coverage
              httpMethod: GET
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
      - $type: TestSuite
        name: 500
        testID: 409
        setUpTests:
        - $type: RESTClientToolTest
          name: 01 Get config GET
          reportingSettings:
            requirementsTracking:
              comment: "Get agent configuration properties (operationId: getAgentConfig)."
          testID: 411
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: /config - GET
            outputTools:
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789366046141
                  name: port
                  extractEntireElement: true
                  Assertion_XPath: /root/restServerPort/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: 8050
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            - $type: GenericDataBank
              iconName: XMLDataBank
              name: JSON Data Bank
              wrappedTool:
                $type: XMLtoDataSource
                iconName: XMLDataBank
                name: XML Data Bank
                selectedXPaths:
                - elementOption: 1
                  contentOption: 1
                  XMLDataBank_ExtractXPath: "/root/runtimeData[1]/text()"
                  mode: 1
                canonicalizeOutput: true
                xmlMessage: true
                virtualDSCreator:
                  writableColumns:
                  - customName: runtimeData_path
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
              serviceName: ""
              versionName: ""
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 200
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/config
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: runtimeData_path
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: config
            resourceMethod:
              resourceId: /config
              httpMethod: GET
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
        - $type: ToolTest
          name: Extension Tool
          testID: 413
          tool:
            $type: MethodTool
            iconName: Method
            name: rename__default__ dir
            method:
              hasCode: true
              code:
                $type: JythonCode
                input:
                  useText: true
                  textInput:
                    $type: ScriptingTextInput
                    text: |-
                      from com.parasoft.api import Application
                      from java.nio.file import Files, Paths

                      USER_DIR   = '__default__'
                      RENAME_DIR = '__default__copy'

                      def _plain_name(v, label):
                          if not isinstance(v, basestring) or not v or '/' in v or '\\' in v or v in ('.', '..') or '\0' in v:
                              raise RuntimeError('invalid %s: %r' % (label, v))

                      def _runtime_data(context):
                          dv = context.getDataSourceValue('runtimeData_path')
                          if dv is None:
                              raise RuntimeError('runtimeData_path is empty; check the JSON Data Bank on GET /config')
                          s = unicode(dv.toString())
                          parts = s.split(', ', 1)
                          value = parts[1] if len(parts) == 2 and parts[0].startswith('com.parasoft.data.') else s
                          return value.strip()

                      def renameDir(input, context):
                          _plain_name(USER_DIR, 'USER_DIR')
                          _plain_name(RENAME_DIR, 'RENAME_DIR')
                          if USER_DIR == RENAME_DIR:
                              raise RuntimeError('USER_DIR and RENAME_DIR must differ')

                          parent = Paths.get(_runtime_data(context))
                          src = parent.resolve(USER_DIR)
                          dst = parent.resolve(RENAME_DIR)
                          if not Files.exists(src):
                              raise RuntimeError('source not found: %s' % src)
                          if Files.exists(dst):
                              raise RuntimeError('target already exists: %s' % dst)
                          Files.move(src, dst)
                          Application.showMessage('renamed: %s -> %s' % (src, dst))
                          return '%s -> %s' % (src.toAbsolutePath(), dst.toAbsolutePath())
              hasMethodId: true
              methodId:
                $type: JythonMethodIdentifier
                methodName: renameDir
          writeInput: true
          inputType: InputUsable
          input:
            use: 1
            text:
              text: ""
              type: text/plain
            dataSource:
              columnName: runtimeData_path
        - $type: ToolTest
          name: Extension Tool
          testID: 516
          tool:
            $type: MethodTool
            iconName: Method
            name: create __default__ file
            method:
              hasCode: true
              code:
                $type: JythonCode
                input:
                  useText: true
                  textInput:
                    $type: ScriptingTextInput
                    text: "from com.parasoft.api import Application\r\nfrom java.nio.file\
                      \ import Files, Paths, StandardOpenOption\r\nfrom java.lang\
                      \ import String\r\nfrom java.nio.charset import StandardCharsets\r\
                      \n\r\nFILE_NAME    = '__default__'\r\nFILE_CONTENT = ''\r\n\r\
                      \ndef _plain_name(v, label):\r\n    if not isinstance(v, basestring)\
                      \ or not v or '/' in v or '\\\\' in v or v in ('.', '..') or\
                      \ '\\0' in v:\r\n        raise RuntimeError('invalid %s: %r'\
                      \ % (label, v))\r\n\r\ndef _runtime_data(context):\r\n    dv\
                      \ = context.getDataSourceValue('runtimeData_path')\r\n    if\
                      \ dv is None:\r\n        raise RuntimeError('runtimeData_path\
                      \ is empty; check the JSON Data Bank on GET /config')\r\n  \
                      \  # DataValue.toString() format: \"com.parasoft.data.DataValue@<hash>,\
                      \ <value>\"\r\n    s = unicode(dv.toString())\r\n    parts =\
                      \ s.split(', ', 1)\r\n    value = parts[1] if len(parts) ==\
                      \ 2 and parts[0].startswith('com.parasoft.data.') else s\r\n\
                      \    return value.strip()\r\n\r\ndef createFile(input, context):\r\
                      \n    _plain_name(FILE_NAME, 'FILE_NAME')\r\n    runtime_data\
                      \ = _runtime_data(context)\r\n    Application.showMessage('runtime_data\
                      \ = %s' % runtime_data)\r\n\r\n    parent = Paths.get(runtime_data)\r\
                      \n    Files.createDirectories(parent)\r\n    target = parent.resolve(FILE_NAME)\r\
                      \n    bytes_ = String(FILE_CONTENT).getBytes(StandardCharsets.UTF_8)\r\
                      \n    Files.write(target, bytes_,\r\n                StandardOpenOption.CREATE,\r\
                      \n                StandardOpenOption.WRITE,\r\n            \
                      \    StandardOpenOption.TRUNCATE_EXISTING)\r\n    result = str(target.toAbsolutePath())\r\
                      \n    Application.showMessage('created: %s' % result)\r\n  \
                      \  return result"
              hasMethodId: true
              methodId:
                $type: JythonMethodIdentifier
                methodName: createFile
          writeInput: true
          inputType: InputUsable
          input:
            use: 1
            text:
              text: ""
              type: text/plain
            dataSource:
              columnName: runtimeData_path
        tearDownTests:
        - $type: ToolTest
          name: Extension Tool
          testID: 517
          tool:
            $type: MethodTool
            iconName: Method
            name: delete __default__ file
            method:
              hasCode: true
              code:
                $type: JythonCode
                input:
                  useText: true
                  textInput:
                    $type: ScriptingTextInput
                    text: "from com.parasoft.api import Application\r\nfrom java.nio.file\
                      \ import Files, Paths\r\n\r\nFILE_NAME = '__default__'\r\n\r\
                      \ndef _plain_name(v, label):\r\n    if not isinstance(v, basestring)\
                      \ or not v or '/' in v or '\\\\' in v or v in ('.', '..') or\
                      \ '\\0' in v:\r\n        raise RuntimeError('invalid %s: %r'\
                      \ % (label, v))\r\n\r\ndef _runtime_data(context):\r\n    dv\
                      \ = context.getDataSourceValue('runtimeData_path')\r\n    if\
                      \ dv is None:\r\n        raise RuntimeError('runtimeData_path\
                      \ is empty; check the JSON Data Bank on GET /config')\r\n  \
                      \  s = unicode(dv.toString())\r\n    parts = s.split(', ', 1)\r\
                      \n    value = parts[1] if len(parts) == 2 and parts[0].startswith('com.parasoft.data.')\
                      \ else s\r\n    return value.strip()\r\n\r\ndef deleteFile(input,\
                      \ context):\r\n    _plain_name(FILE_NAME, 'FILE_NAME')\r\n \
                      \   target = Paths.get(_runtime_data(context)).resolve(FILE_NAME)\r\
                      \n    existed = Files.deleteIfExists(target)\r\n    Application.showMessage('%s:\
                      \ %s' % ('deleted' if existed else 'not present', target))\r\
                      \n    return str(target.toAbsolutePath())"
              hasMethodId: true
              methodId:
                $type: JythonMethodIdentifier
                methodName: deleteFile
          writeInput: true
          inputType: InputUsable
          input:
            use: 1
            text:
              text: ""
              type: text/plain
            dataSource:
              columnName: runtimeData_path
        - $type: ToolTest
          name: Rename__default__ dir 2
          testID: 414
          tool:
            $type: MethodTool
            iconName: Method
            name: rename__default__ dir back
            method:
              hasCode: true
              code:
                $type: JythonCode
                input:
                  useText: true
                  textInput:
                    $type: ScriptingTextInput
                    text: "from com.parasoft.api import Application\r\nfrom java.nio.file\
                      \ import Files, Paths\r\n\r\nUSER_DIR   = '__default__copy'\r\
                      \nRENAME_DIR = '__default__'\r\n\r\ndef _plain_name(v, label):\r\
                      \n    if not isinstance(v, basestring) or not v or '/' in v\
                      \ or '\\\\' in v or v in ('.', '..') or '\\0' in v:\r\n    \
                      \    raise RuntimeError('invalid %s: %r' % (label, v))\r\n\r\
                      \ndef _runtime_data(context):\r\n    dv = context.getDataSourceValue('runtimeData_path')\r\
                      \n    if dv is None:\r\n        raise RuntimeError('runtimeData_path\
                      \ is empty; check the JSON Data Bank on GET /config')\r\n  \
                      \  s = unicode(dv.toString())\r\n    parts = s.split(', ', 1)\r\
                      \n    value = parts[1] if len(parts) == 2 and parts[0].startswith('com.parasoft.data.')\
                      \ else s\r\n    return value.strip()\r\n\r\ndef renameDir(input,\
                      \ context):\r\n    _plain_name(USER_DIR, 'USER_DIR')\r\n   \
                      \ _plain_name(RENAME_DIR, 'RENAME_DIR')\r\n    if USER_DIR ==\
                      \ RENAME_DIR:\r\n        raise RuntimeError('USER_DIR and RENAME_DIR\
                      \ must differ')\r\n\r\n    parent = Paths.get(_runtime_data(context))\r\
                      \n    src = parent.resolve(USER_DIR)\r\n    dst = parent.resolve(RENAME_DIR)\r\
                      \n    if not Files.exists(src):\r\n        raise RuntimeError('source\
                      \ not found: %s' % src)\r\n    if Files.exists(dst):\r\n   \
                      \     raise RuntimeError('target already exists: %s' % dst)\r\
                      \n    Files.move(src, dst)\r\n    Application.showMessage('renamed:\
                      \ %s -> %s' % (src, dst))\r\n    return '%s -> %s' % (src.toAbsolutePath(),\
                      \ dst.toAbsolutePath())"
              hasMethodId: true
              methodId:
                $type: JythonMethodIdentifier
                methodName: renameDir
          writeInput: true
          inputType: InputUsable
          input:
            use: 1
            text:
              text: ""
              type: text/plain
            dataSource:
              columnName: runtimeData_path
        tests:
        - $type: RESTClientToolTest
          name: "04 GET coverage list 500 (documented, not reliably triggerable)"
          reportingSettings:
            requirementsTracking:
              comment: GET /coverage - documented 500 branch ($ref 500WithErrorMessage).
                Requires a server-side fault; kept as a documentation placeholder.
          testID: 410
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: ' __default__ existed already'
            outputTools:
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789351836777
                  name: message code
                  extractEntireElement: true
                  Assertion_XPath: /root/messageCode/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: 701
                - $type: StringComparisonAssertion
                  timestamp: 1789551012441
                  name: message
                  extractEntireElement: true
                  Assertion_XPath: /root/message/string()
                  comparisonMode: 2
                  value:
                    name: String Comparison Assertion
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: "Failed to get coverage: ENOTDIR: not a directory,\
                          \ scandir"
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 500
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/coverage
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: coverage
            resourceMethod:
              resourceId: /coverage
              httpMethod: GET
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
    - $type: TestSuite
      name: "/coverage/{id} - GET"
      testID: 251
      tests:
      - $type: TestSuite
        name: 200
        testID: 724
        browserOptions:
          browserType:
            useDefault: false
            type:
              $type: SingleBrowserType
              typeValue: 3
        setUpTests:
        - $type: RESTClientToolTest
          name: 200 2
          reportingSettings:
            requirementsTracking:
              comment: "GET /session/start - success case (operationId: startSession);\
                \ extracts session ID."
          testID: 726
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: /session/start - GET
            outputTools:
            - $type: GenericDataBank
              iconName: XMLDataBank
              name: JSON Data Bank
              wrappedTool:
                $type: XMLtoDataSource
                iconName: XMLDataBank
                name: XML Data Bank
                selectedXPaths:
                - XMLDataBank_ExtractXPath: /root/session
                  mode: 1
                canonicalizeOutput: true
                xmlMessage: true
                virtualDSCreator:
                  writableColumns:
                  - customName: session_id
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789366118775
                  name: Value Assertion
                  extractEntireElement: true
                  Assertion_XPath: /root/session/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                      parameterizedValue:
                        column: session_id
                      selectedIndex: -2
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
              serviceName: ""
              versionName: ""
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 200
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/session/start
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: session
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: start
            resourceMethod:
              resourceId: /session/start
              httpMethod: GET
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
        - $type: RESTClientToolTest
          name: 02 Stop session GET 200
          reportingSettings:
            requirementsTracking:
              comment: "GET /session/stop - success case (operationId: stopSessionGetMethod)."
          testID: 866
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: /session/stop - GET
            outputTools:
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789366556609
                  name: session
                  extractEntireElement: true
                  Assertion_XPath: /root/session/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: "null"
                      parameterizedValue:
                        column: session_id
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
              serviceName: ""
              versionName: ""
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 200
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/session/stop
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: session
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: stop
            resourceMethod:
              resourceId: /session/stop
              httpMethod: GET
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
        tests:
        - $type: RESTClientToolTest
          name: 08 GET coverage by id 200
          reportingSettings:
            requirementsTracking:
              comment: "GET /coverage/{id} - success case, downloads the ZIP archive\
                \ (operationId: getCoverageBySessionId)."
          testID: 729
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: 200
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 200
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: "http://localhost:8050/coverage/${session_id}"
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                  showRequestHeaders: true
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: coverage
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: "${session_id}"
            constrainedPath:
              pathParameters:
              - $type: ElementValue
                writeType: true
                type:
                  $type: ElementType
                  localName: id
                  bodyType:
                    $type: StringType
                replacedColumn: ""
                values:
                - $type: StringValue
                  replacedColumn: ""
                  value: "${session_id}"
            resourceMethod:
              resourceId: "/coverage/{id}"
              httpMethod: GET
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
        - $type: TestSuite
          name: 'compare the expected and actual runtime-data json '
          testID: 850
          setUpTests:
          - $type: ToolTest
            name: Extension Tool
            testID: 855
            tool:
              $type: MethodTool
              iconName: Method
              name: delete existed runtime-data files
              method:
                hasCode: true
                code:
                  $type: JythonCode
                  input:
                    useText: true
                    textInput:
                      $type: ScriptingTextInput
                      text: "from com.parasoft.api import Application\r\nfrom java.lang\
                        \ import System\r\nfrom java.io import File\r\nfrom java.util.regex\
                        \ import Pattern\r\n\r\n\r\nZIP_PATTERN = Pattern.compile(\r\
                        \n    r'^runtime_coverage_[0-9]{8}_[0-9]{4}_[0-9]+\\.zip$',\r\
                        \n    Pattern.CASE_INSENSITIVE\r\n)\r\n\r\n\r\ndef _downloads_dir():\r\
                        \n    user_home = System.getProperty('user.home')\r\n    return\
                        \ File(user_home, 'Downloads')\r\n\r\n\r\ndef _is_coverage_zip(file_object):\r\
                        \n    return (\r\n        file_object is not None\r\n    \
                        \    and file_object.isFile()\r\n        and ZIP_PATTERN.matcher(file_object.getName()).matches()\r\
                        \n    )\r\n\r\n\r\ndef _delete_tree(file_object):\r\n    if\
                        \ file_object.isDirectory():\r\n        children = file_object.listFiles()\r\
                        \n\r\n        if children is not None:\r\n            for\
                        \ child in children:\r\n                _delete_tree(child)\r\
                        \n\r\n    if not file_object.delete():\r\n        raise RuntimeError(\r\
                        \n            'Cannot delete: %s'\r\n            % file_object.getAbsolutePath()\r\
                        \n        )\r\n\r\n\r\ndef cleanupCoverageZips(input, context):\r\
                        \n    downloads_dir = _downloads_dir()\r\n\r\n    if not downloads_dir.exists():\r\
                        \n        message = (\r\n            'Downloads directory\
                        \ does not exist: %s'\r\n            % downloads_dir.getAbsolutePath()\r\
                        \n        )\r\n        Application.showMessage(message)\r\n\
                        \        return message\r\n\r\n    deleted_zips = []\r\n\r\
                        \n    files = downloads_dir.listFiles()\r\n\r\n    if files\
                        \ is not None:\r\n        for file_object in files:\r\n  \
                        \          if _is_coverage_zip(file_object):\r\n         \
                        \       if not file_object.delete():\r\n                 \
                        \   raise RuntimeError(\r\n                        'Cannot\
                        \ delete old coverage ZIP: %s'\r\n                       \
                        \ % file_object.getAbsolutePath()\r\n                    )\r\
                        \n\r\n                deleted_zips.append(file_object.getName())\r\
                        \n\r\n    runtime_data_dir = File(downloads_dir, 'runtime-data')\r\
                        \n\r\n    if runtime_data_dir.exists():\r\n        _delete_tree(runtime_data_dir)\r\
                        \n        runtime_message = (\r\n            'Deleted runtime-data:\
                        \ %s'\r\n            % runtime_data_dir.getAbsolutePath()\r\
                        \n        )\r\n    else:\r\n        runtime_message = 'runtime-data\
                        \ does not exist; skipped'\r\n\r\n    if deleted_zips:\r\n\
                        \        zip_message = (\r\n            'Deleted old coverage\
                        \ ZIP files: %s'\r\n            % ', '.join(deleted_zips)\r\
                        \n        )\r\n    else:\r\n        zip_message = 'No old\
                        \ coverage ZIP found'\r\n\r\n    message = zip_message + ';\
                        \ ' + runtime_message\r\n    Application.showMessage(message)\r\
                        \n\r\n    return message"
                hasMethodId: true
                methodId:
                  $type: JythonMethodIdentifier
                  methodName: cleanupCoverageZips
            writeInput: true
            inputType: InputUsable
            input:
              use: 1
              text:
                text: ""
                type: text/plain
              dataSource:
                columnName: runtimeData_path
          - $type: RESTClientToolTest
            name: 200 2
            reportingSettings:
              requirementsTracking:
                comment: "GET /session/start - success case (operationId: startSession);\
                  \ extracts session ID."
            testID: 856
            tool:
              $type: RESTClient
              iconName: RESTClient
              name: /session/start - GET
              outputTools:
              - $type: GenericDataBank
                iconName: XMLDataBank
                name: JSON Data Bank
                wrappedTool:
                  $type: XMLtoDataSource
                  iconName: XMLDataBank
                  name: XML Data Bank
                  selectedXPaths:
                  - XMLDataBank_ExtractXPath: /root/session
                    mode: 1
                  canonicalizeOutput: true
                  xmlMessage: true
                  virtualDSCreator:
                    writableColumns:
                    - customName: session_id
                conversionStrategy:
                  dataFormatName: JSON
                  conversionStrategyId: JSON
                  conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
              - $type: GenericAssertionTool
                iconName: XMLAssertor
                name: JSON Assertor
                wrappedTool:
                  $type: XMLAssertionTool
                  iconName: XMLAssertor
                  name: XML Assertor
                  errorsOutput:
                    name: Errors
                  assertions:
                  - $type: ValueAssertion
                    timestamp: 1789366118775
                    name: Value Assertion
                    extractEntireElement: true
                    Assertion_XPath: /root/session/string()
                    value:
                      name: Value
                      value:
                        fixedValue:
                          $type: StringTestValue
                        parameterizedValue:
                          column: session_id
                        selectedIndex: -2
                  message:
                    $type: ExpectedXMLMessage
                    message: true
                conversionStrategy:
                  dataFormatName: JSON
                  conversionStrategyId: JSON
                  conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
              formJson:
                value:
                  $type: ElementValue
                  writeType: true
                  hasReference: true
                  qnameAsString: :root
                  replacedColumn: ""
                  values:
                  - $type: ComplexValue
                    replacedColumn: ""
                    attributes:
                    - replacedColumn: ""
                      value:
                        $type: StringValue
                        replacedColumn: ""
                        value: object
                      useValue: true
                    compositorValue: true
                    compositorValueObj:
                      replacedColumn: ""
                      values:
                        $type: CompositorValueSetCollectionSet
                        set:
                        - $type: CompositorValueSet
                elementTypeName: root
              hasServiceInfo: true
              serviceInfo:
                serviceDescriptor:
                  $type: StandardServiceDescriptor
                  location: http://localhost:8050/openapi.yml
                serviceName: ""
                versionName: ""
              jsonBuilder:
                hasValue: true
                value:
                  $type: JSONObjectValue
                  nameIsNull: true
              schemaURL:
                MessagingClient_SchemaLocation: "${OpenAPI}"
              formInput:
                value:
                  $type: ElementValue
                  writeType: true
                  hasReference: true
                  qnameAsString: ":"
                  replacedColumn: ""
                  values:
                  - $type: ComplexValue
                    replacedColumn: ""
                    compositorValue: true
                    compositorValueObj:
                      replacedColumn: ""
                      values:
                        $type: CompositorValueSetCollectionSet
                        set:
                        - $type: CompositorValueSet
              jmsMessageOutputProvider:
                $type: JMSMessageOutputProvider
                jmsOutputProviderRequest:
                  $type: JMSOutputProvider
                  name: Request Object
                  menuName: Object
                jmsOutputProviderResponse:
                  $type: JMSOutputProvider
                  name: Response Message Object
                  menuName: Message Object
              validResponseRange:
                validResponseRange:
                  values:
                  - $type: ScriptedValue
                  fixedValue:
                    $type: StringTestValue
                    validResponseRange: 200
              router:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  HTTPClient_Endpoint: http://localhost:8050/session/start
              transportProperties:
                manager:
                  protocol: 1
                  properties:
                  - $type: HTTPClientHTTPProperties
                    followRedirects:
                      bool: true
                    common:
                      method:
                        values:
                        - $type: ScriptedValue
                        fixedValue:
                          $type: HTTPMethodTestValue
                          method: GET
                    keepAlive1_1:
                      bool: true
                  - $type: HTTPClientHTTPProperties
                    followRedirects:
                      bool: true
                    common:
                      method:
                        values:
                        - $type: ScriptedValue
                        fixedValue:
                          $type: HTTPMethodTestValue
                          method: GET
                    protocol: 1
                    keepAlive1_1:
                      bool: true
                messageExchangePattern:
                  inverted: true
              outputProviders:
                requestHeader:
                  $type: HTTPNamedToolOutputProvider
                  menuName: Transport Header
                  name: Request Transport Header
                responseHeader:
                  $type: HTTPNamedToolOutputProvider
                  menuName: Transport Header
                  name: Response Transport Header
                xmlRequestOutput:
                  $type: NamedXMLToolOutputProvider
                  menuName: Traffic
                  name: Request Traffic
                trafficOutput:
                  m_name: Traffic Stream
                objectOutput:
                  $type: ObjectOutputProvider
                  outputTools:
                  - $type: TrafficViewer
                    iconName: TrafficViewer
                    name: Traffic Viewer
                  name: Traffic Object
              formXML:
                doctype: ""
              literal:
                use: 1
                text:
                  MessagingClient_LiteralMessage: ""
                  type: application/json
                dataSource:
                  columnName: session_id
              mode: Literal
              literalQuery:
                isPropertiesRef: true
              literalPath:
                pathElements:
                - values:
                  - $type: ScriptedValue
                  fixedValue:
                    $type: StringTestValue
                    value: session
                - values:
                  - $type: ScriptedValue
                  fixedValue:
                    $type: StringTestValue
                    value: start
              resourceMethod:
                resourceId: /session/start
                httpMethod: GET
              resourceMode: 3
              baseUrl:
                values:
                - $type: ScriptedValue
                - $type: WadlTestValue
                  value: http://localhost:8050
                fixedValue:
                  $type: StringTestValue
                  value: http://localhost:8050
                selectedIndex: 1
          - $type: RESTClientToolTest
            name: REST Client
            testID: 857
            tool:
              $type: RESTClient
              iconName: RESTClient
              name: /api/health - GET
              formJson:
                value:
                  $type: ElementValue
                  writeType: true
                  hasReference: true
                  qnameAsString: :root
                  replacedColumn: ""
                  values:
                  - $type: ComplexValue
                    replacedColumn: ""
                    attributes:
                    - replacedColumn: ""
                      value:
                        $type: StringValue
                        replacedColumn: ""
                        value: object
                      useValue: true
                    compositorValue: true
                    compositorValueObj:
                      replacedColumn: ""
                      values:
                        $type: CompositorValueSetCollectionSet
                        set:
                        - $type: CompositorValueSet
                elementTypeName: root
              jsonBuilder:
                hasValue: true
                value:
                  $type: JSONObjectValue
                  nameIsNull: true
              formInput:
                value:
                  $type: ElementValue
                  writeType: true
                  hasReference: true
                  qnameAsString: ":"
                  replacedColumn: ""
                  values:
                  - $type: ComplexValue
                    replacedColumn: ""
                    compositorValue: true
                    compositorValueObj:
                      replacedColumn: ""
                      values:
                        $type: CompositorValueSetCollectionSet
                        set:
                        - $type: CompositorValueSet
              constrainToSchema: false
              jmsMessageOutputProvider:
                $type: JMSMessageOutputProvider
                jmsOutputProviderRequest:
                  $type: JMSOutputProvider
                  name: Request Object
                  menuName: Object
                jmsOutputProviderResponse:
                  $type: JMSOutputProvider
                  name: Response Message Object
                  menuName: Message Object
              router:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  HTTPClient_Endpoint: "${AUT_SERVER_URL}/api/health"
              transportProperties:
                manager:
                  protocol: 1
                  properties:
                  - $type: HTTPClientHTTPProperties
                    followRedirects:
                      bool: true
                    common:
                      method:
                        values:
                        - $type: ScriptedValue
                        fixedValue:
                          $type: HTTPMethodTestValue
                          method: GET
                    protocol: 1
                    keepAlive1_1:
                      bool: true
                messageExchangePattern:
                  inverted: true
              outputProviders:
                requestHeader:
                  $type: HTTPNamedToolOutputProvider
                  menuName: Transport Header
                  name: Request Transport Header
                responseHeader:
                  $type: HTTPNamedToolOutputProvider
                  menuName: Transport Header
                  name: Response Transport Header
                xmlRequestOutput:
                  $type: NamedXMLToolOutputProvider
                  menuName: Traffic
                  name: Request Traffic
                trafficOutput:
                  m_name: Traffic Stream
                objectOutput:
                  $type: ObjectOutputProvider
                  outputTools:
                  - $type: TrafficViewer
                    iconName: TrafficViewer
                    name: Traffic Viewer
                  name: Traffic Object
              formXML:
                doctype: ""
              literal:
                use: 1
                text:
                  MessagingClient_LiteralMessage: ""
                  type: application/json
                dataSource:
                  columnName: runtimeData_path
              mode: Literal
              literalQuery:
                isPropertiesRef: true
              literalPath:
                pathElements:
                - values:
                  - $type: ScriptedValue
                  fixedValue:
                    $type: StringTestValue
                    value: api
                - values:
                  - $type: ScriptedValue
                  fixedValue:
                    $type: StringTestValue
                    value: health
              resourceMethod:
                httpMethod: GET
              baseUrl:
                values:
                - $type: ScriptedValue
                - $type: WadlTestValue
                fixedValue:
                  $type: StringTestValue
                selectedIndex: 1
          - $type: RESTClientToolTest
            name: /api/health - GET 2
            testID: 858
            tool:
              $type: RESTClient
              iconName: RESTClient
              name: /api/greetings/tester- GET
              formJson:
                value:
                  $type: ElementValue
                  writeType: true
                  hasReference: true
                  qnameAsString: :root
                  replacedColumn: ""
                  values:
                  - $type: ComplexValue
                    replacedColumn: ""
                    attributes:
                    - replacedColumn: ""
                      value:
                        $type: StringValue
                        replacedColumn: ""
                        value: object
                      useValue: true
                    compositorValue: true
                    compositorValueObj:
                      replacedColumn: ""
                      values:
                        $type: CompositorValueSetCollectionSet
                        set:
                        - $type: CompositorValueSet
                elementTypeName: root
              jsonBuilder:
                hasValue: true
                value:
                  $type: JSONObjectValue
                  nameIsNull: true
              formInput:
                value:
                  $type: ElementValue
                  writeType: true
                  hasReference: true
                  qnameAsString: ":"
                  replacedColumn: ""
                  values:
                  - $type: ComplexValue
                    replacedColumn: ""
                    compositorValue: true
                    compositorValueObj:
                      replacedColumn: ""
                      values:
                        $type: CompositorValueSetCollectionSet
                        set:
                        - $type: CompositorValueSet
              constrainToSchema: false
              jmsMessageOutputProvider:
                $type: JMSMessageOutputProvider
                jmsOutputProviderRequest:
                  $type: JMSOutputProvider
                  name: Request Object
                  menuName: Object
                jmsOutputProviderResponse:
                  $type: JMSOutputProvider
                  name: Response Message Object
                  menuName: Message Object
              router:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  HTTPClient_Endpoint: "${AUT_SERVER_URL}/api/greetings/tester"
              transportProperties:
                manager:
                  protocol: 1
                  properties:
                  - $type: HTTPClientHTTPProperties
                    followRedirects:
                      bool: true
                    common:
                      method:
                        values:
                        - $type: ScriptedValue
                        fixedValue:
                          $type: HTTPMethodTestValue
                          method: GET
                    protocol: 1
                    keepAlive1_1:
                      bool: true
                messageExchangePattern:
                  inverted: true
              outputProviders:
                requestHeader:
                  $type: HTTPNamedToolOutputProvider
                  menuName: Transport Header
                  name: Request Transport Header
                responseHeader:
                  $type: HTTPNamedToolOutputProvider
                  menuName: Transport Header
                  name: Response Transport Header
                xmlRequestOutput:
                  $type: NamedXMLToolOutputProvider
                  menuName: Traffic
                  name: Request Traffic
                trafficOutput:
                  m_name: Traffic Stream
                objectOutput:
                  $type: ObjectOutputProvider
                  outputTools:
                  - $type: TrafficViewer
                    iconName: TrafficViewer
                    name: Traffic Viewer
                  name: Traffic Object
              formXML:
                doctype: ""
              literal:
                use: 1
                text:
                  MessagingClient_LiteralMessage: ""
                  type: application/json
                dataSource:
                  columnName: runtimeData_path
              mode: Literal
              literalQuery:
                isPropertiesRef: true
              literalPath:
                pathElements:
                - values:
                  - $type: ScriptedValue
                  fixedValue:
                    $type: StringTestValue
                    value: api
                - values:
                  - $type: ScriptedValue
                  fixedValue:
                    $type: StringTestValue
                    value: greetings
                - values:
                  - $type: ScriptedValue
                  fixedValue:
                    $type: StringTestValue
                    value: tester
              resourceMethod:
                httpMethod: GET
              baseUrl:
                values:
                - $type: ScriptedValue
                - $type: WadlTestValue
                fixedValue:
                  $type: StringTestValue
                selectedIndex: 1
          - $type: RESTClientToolTest
            name: 02 Stop session GET 200
            reportingSettings:
              requirementsTracking:
                comment: "GET /session/stop - success case (operationId: stopSessionGetMethod)."
            testID: 865
            tool:
              $type: RESTClient
              iconName: RESTClient
              name: /session/stop - GET
              outputTools:
              - $type: GenericAssertionTool
                iconName: XMLAssertor
                name: JSON Assertor
                wrappedTool:
                  $type: XMLAssertionTool
                  iconName: XMLAssertor
                  name: XML Assertor
                  errorsOutput:
                    name: Errors
                  assertions:
                  - $type: ValueAssertion
                    timestamp: 1789366556609
                    name: session
                    extractEntireElement: true
                    Assertion_XPath: /root/session/string()
                    value:
                      name: Value
                      value:
                        fixedValue:
                          $type: StringTestValue
                          value: "null"
                        parameterizedValue:
                          column: session_id
                  message:
                    $type: ExpectedXMLMessage
                    message: true
                conversionStrategy:
                  dataFormatName: JSON
                  conversionStrategyId: JSON
                  conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
              formJson:
                value:
                  $type: ElementValue
                  writeType: true
                  hasReference: true
                  qnameAsString: :root
                  replacedColumn: ""
                  values:
                  - $type: ComplexValue
                    replacedColumn: ""
                    attributes:
                    - replacedColumn: ""
                      value:
                        $type: StringValue
                        replacedColumn: ""
                        value: object
                      useValue: true
                    compositorValue: true
                    compositorValueObj:
                      replacedColumn: ""
                      values:
                        $type: CompositorValueSetCollectionSet
                        set:
                        - $type: CompositorValueSet
                elementTypeName: root
              hasServiceInfo: true
              serviceInfo:
                serviceDescriptor:
                  $type: StandardServiceDescriptor
                  location: http://localhost:8050/openapi.yml
                serviceName: ""
                versionName: ""
              jsonBuilder:
                hasValue: true
                value:
                  $type: JSONObjectValue
                  nameIsNull: true
              schemaURL:
                MessagingClient_SchemaLocation: "${OpenAPI}"
              formInput:
                value:
                  $type: ElementValue
                  writeType: true
                  hasReference: true
                  qnameAsString: ":"
                  replacedColumn: ""
                  values:
                  - $type: ComplexValue
                    replacedColumn: ""
                    compositorValue: true
                    compositorValueObj:
                      replacedColumn: ""
                      values:
                        $type: CompositorValueSetCollectionSet
                        set:
                        - $type: CompositorValueSet
              jmsMessageOutputProvider:
                $type: JMSMessageOutputProvider
                jmsOutputProviderRequest:
                  $type: JMSOutputProvider
                  name: Request Object
                  menuName: Object
                jmsOutputProviderResponse:
                  $type: JMSOutputProvider
                  name: Response Message Object
                  menuName: Message Object
              validResponseRange:
                validResponseRange:
                  values:
                  - $type: ScriptedValue
                  fixedValue:
                    $type: StringTestValue
                    validResponseRange: 200
              router:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  HTTPClient_Endpoint: http://localhost:8050/session/stop
              transportProperties:
                manager:
                  protocol: 1
                  properties:
                  - $type: HTTPClientHTTPProperties
                    followRedirects:
                      bool: true
                    common:
                      method:
                        values:
                        - $type: ScriptedValue
                        fixedValue:
                          $type: HTTPMethodTestValue
                          method: GET
                    keepAlive1_1:
                      bool: true
                  - $type: HTTPClientHTTPProperties
                    followRedirects:
                      bool: true
                    common:
                      method:
                        values:
                        - $type: ScriptedValue
                        fixedValue:
                          $type: HTTPMethodTestValue
                          method: GET
                    protocol: 1
                    keepAlive1_1:
                      bool: true
                messageExchangePattern:
                  inverted: true
              outputProviders:
                requestHeader:
                  $type: HTTPNamedToolOutputProvider
                  menuName: Transport Header
                  name: Request Transport Header
                responseHeader:
                  $type: HTTPNamedToolOutputProvider
                  menuName: Transport Header
                  name: Response Transport Header
                xmlRequestOutput:
                  $type: NamedXMLToolOutputProvider
                  menuName: Traffic
                  name: Request Traffic
                trafficOutput:
                  m_name: Traffic Stream
                objectOutput:
                  $type: ObjectOutputProvider
                  outputTools:
                  - $type: TrafficViewer
                    iconName: TrafficViewer
                    name: Traffic Viewer
                  name: Traffic Object
              formXML:
                doctype: ""
              literal:
                use: 1
                text:
                  MessagingClient_LiteralMessage: ""
                  type: application/json
                dataSource:
                  columnName: session_id
              mode: Literal
              literalQuery:
                isPropertiesRef: true
              literalPath:
                pathElements:
                - values:
                  - $type: ScriptedValue
                  fixedValue:
                    $type: StringTestValue
                    value: session
                - values:
                  - $type: ScriptedValue
                  fixedValue:
                    $type: StringTestValue
                    value: stop
              resourceMethod:
                resourceId: /session/stop
                httpMethod: GET
              resourceMode: 3
              baseUrl:
                values:
                - $type: ScriptedValue
                - $type: WadlTestValue
                  value: http://localhost:8050
                fixedValue:
                  $type: StringTestValue
                  value: http://localhost:8050
                selectedIndex: 1
          - $type: BrowserTest
            name: Browser Playback Tool
            testID: 862
            tool:
              $type: BrowserTestingTool
              iconName: BrowserTest
              name: download the runtime-data zip
              commands:
              - windowIdentifier:
                  BrowserTestingTool_WindowName: ""
                action:
                  $type: NavigateAction
                  url:
                    values:
                    - $type: ScriptedValue
                    fixedValue:
                      $type: StringTestValue
                      BrowserTestingTool_NavigateURL: "${BASE_URL}/coverage/${session_id}"
              delaySettings:
                delays:
                - $type: ElementDelay
                  windowIdentifier:
                    WindowName: ""
                  elementState: 1
                  specifiedLocator:
                    criteria:
                      $type: AttributeCriteria
                      elementName: any
                      attributeName: ""
              originalCommand: true
              command:
                windowIdentifier:
                  BrowserTestingTool_WindowName: ""
                action:
                  $type: UnknownAction
                  location:
                    criteria:
                      $type: AttributeCriteria
                      elementName: any
                      attributeName: id
                  action: ""
              browserContents: true
              contents:
                windowContents:
                - parentUrl: ""
                  charSet: windows-1252
                  url: "data:,"
                  html: !!binary |-
                    H4sIAAAAAAAA/7PJKMnNsbPJSE1MsbPRh1BJ+SmVQA6UAisAAAqSH0gnAAAA
                  isTopLevelWindow: true
                browserType:
                  $type: SingleBrowserType
                  typeValue: 3
              browserOutputProvider:
                screenshotProviders:
                - $type: ScreenshotOutputProvider
                  name: Screenshot of Window 1
                  windowIdentifier:
                    WindowName: ""
                    WindowIndex: 0
                contents:
                  $type: BrowserContentsOutputProvider
                  outputTools:
                  - $type: BrowserContentsViewer
                    iconName: BrowserContentsViewer
                    name: Browser Contents Viewer
                  name: Browser Contents
                traffic:
                  $type: NamedToolOutputProvider
                  outputTools:
                  - $type: TrafficViewer
                    iconName: TrafficViewer
                    name: Traffic Viewer
                    showRequestHeaders: true
                    showResponseHeaders: true
                  name: HTTP Traffic
          - $type: ToolTest
            name: Extension Tool
            testID: 863
            tool:
              $type: MethodTool
              iconName: Method
              name: unizp runtime-data zip file
              method:
                hasCode: true
                code:
                  $type: JythonCode
                  input:
                    useText: true
                    textInput:
                      $type: ScriptingTextInput
                      text: "from com.parasoft.api import Application\r\nfrom java.lang\
                        \ import System, Thread, String\r\nfrom java.io import (\r\
                        \n    File,\r\n    FileInputStream,\r\n    FileOutputStream,\r\
                        \n    BufferedInputStream,\r\n    BufferedOutputStream,\r\n\
                        \    ByteArrayOutputStream\r\n)\r\nfrom java.nio.file import\
                        \ Paths\r\nfrom java.util.regex import Pattern\r\nfrom java.util.zip\
                        \ import ZipInputStream\r\nfrom jarray import zeros\r\n\r\n\
                        \r\nWAIT_TIMEOUT_MS = 120000\r\nPOLL_INTERVAL_MS = 1000\r\n\
                        \r\nZIP_PATTERN = Pattern.compile(\r\n    r'^runtime_coverage_[0-9]{8}_[0-9]{4}_[0-9]+\\\
                        .zip$',\r\n    Pattern.CASE_INSENSITIVE\r\n)\r\n\r\n\r\ndef\
                        \ _data_value_text(value):\r\n    if value is None:\r\n  \
                        \      return None\r\n\r\n    text = unicode(value.toString())\r\
                        \n    parts = text.split(', ', 1)\r\n\r\n    if len(parts)\
                        \ == 2 and parts[0].startswith('com.parasoft.data.'):\r\n\
                        \        text = parts[1]\r\n\r\n    return text.strip()\r\n\
                        \r\n\r\ndef _session_id(context):\r\n    value = context.getDataSourceValue('session_id')\r\
                        \n    session_id = _data_value_text(value)\r\n\r\n    if not\
                        \ session_id:\r\n        raise RuntimeError(\r\n         \
                        \   'session_id is empty; check the session_id Data Bank column'\r\
                        \n        )\r\n\r\n    return session_id\r\n\r\n\r\ndef _downloads_dir():\r\
                        \n    user_home = System.getProperty('user.home')\r\n    return\
                        \ File(user_home, 'Downloads')\r\n\r\n\r\ndef _is_coverage_zip(file_object):\r\
                        \n    return (\r\n        file_object is not None\r\n    \
                        \    and file_object.isFile()\r\n        and ZIP_PATTERN.matcher(file_object.getName()).matches()\r\
                        \n    )\r\n\r\n\r\ndef _find_latest_zip():\r\n    downloads_dir\
                        \ = _downloads_dir()\r\n    files = downloads_dir.listFiles()\r\
                        \n\r\n    if files is None:\r\n        return None\r\n\r\n\
                        \    latest_zip = None\r\n\r\n    for file_object in files:\r\
                        \n        if not _is_coverage_zip(file_object):\r\n      \
                        \      continue\r\n\r\n        if (\r\n            latest_zip\
                        \ is None\r\n            or file_object.lastModified() > latest_zip.lastModified()\r\
                        \n        ):\r\n            latest_zip = file_object\r\n\r\
                        \n    return latest_zip\r\n\r\n\r\ndef _wait_for_zip():\r\n\
                        \    deadline = System.currentTimeMillis() + WAIT_TIMEOUT_MS\r\
                        \n    previous_path = None\r\n    previous_size = -1\r\n \
                        \   stable_count = 0\r\n\r\n    while System.currentTimeMillis()\
                        \ < deadline:\r\n        zip_file = _find_latest_zip()\r\n\
                        \r\n        if zip_file is not None:\r\n            current_path\
                        \ = zip_file.getAbsolutePath()\r\n            current_size\
                        \ = zip_file.length()\r\n\r\n            if (\r\n        \
                        \        current_path == previous_path\r\n               \
                        \ and current_size > 0\r\n                and current_size\
                        \ == previous_size\r\n            ):\r\n                stable_count\
                        \ += 1\r\n\r\n                if stable_count >= 2:\r\n  \
                        \                  return zip_file\r\n            else:\r\n\
                        \                previous_path = current_path\r\n        \
                        \        previous_size = current_size\r\n                stable_count\
                        \ = 0\r\n\r\n        Thread.sleep(POLL_INTERVAL_MS)\r\n\r\n\
                        \    raise RuntimeError(\r\n        'No completed coverage\
                        \ ZIP found within %d ms in %s'\r\n        % (WAIT_TIMEOUT_MS,\
                        \ _downloads_dir().getAbsolutePath())\r\n    )\r\n\r\n\r\n\
                        def _safe_zip_target(root_file, entry_name):\r\n    normalized_name\
                        \ = entry_name.replace('\\\\', '/')\r\n\r\n    if normalized_name.startswith('/'):\r\
                        \n        raise RuntimeError('unsafe ZIP entry: %s' % entry_name)\r\
                        \n\r\n    entry_path = Paths.get(normalized_name)\r\n\r\n\
                        \    if entry_path.isAbsolute():\r\n        raise RuntimeError('unsafe\
                        \ ZIP entry: %s' % entry_name)\r\n\r\n    root_path = root_file.toPath().toAbsolutePath().normalize()\r\
                        \n    target_path = root_path.resolve(entry_path).normalize()\r\
                        \n\r\n    root_canonical = root_file.getCanonicalPath()\r\n\
                        \    target_canonical = target_path.toFile().getCanonicalPath()\r\
                        \n    root_prefix = root_canonical + File.separator\r\n\r\n\
                        \    if (\r\n        target_canonical != root_canonical\r\n\
                        \        and not target_canonical.startswith(root_prefix)\r\
                        \n    ):\r\n        raise RuntimeError('unsafe ZIP entry:\
                        \ %s' % entry_name)\r\n\r\n    return target_path.toFile()\r\
                        \n\r\n\r\ndef _extract_zip(zip_file):\r\n    output_dir =\
                        \ _downloads_dir()\r\n\r\n    if not output_dir.exists() and\
                        \ not output_dir.mkdirs():\r\n        raise RuntimeError(\r\
                        \n            'Cannot create output directory: %s'\r\n   \
                        \         % output_dir.getAbsolutePath()\r\n        )\r\n\r\
                        \n    input_stream = ZipInputStream(\r\n        BufferedInputStream(FileInputStream(zip_file))\r\
                        \n    )\r\n\r\n    try:\r\n        buffer = zeros(8192, 'b')\r\
                        \n        entry = input_stream.getNextEntry()\r\n\r\n    \
                        \    while entry is not None:\r\n            target_file =\
                        \ _safe_zip_target(\r\n                output_dir,\r\n   \
                        \             entry.getName()\r\n            )\r\n\r\n   \
                        \         if entry.isDirectory():\r\n                if not\
                        \ target_file.exists() and not target_file.mkdirs():\r\n \
                        \                   raise RuntimeError(\r\n              \
                        \          'Cannot create directory: %s'\r\n             \
                        \           % target_file.getAbsolutePath()\r\n          \
                        \          )\r\n            else:\r\n                parent_dir\
                        \ = target_file.getParentFile()\r\n\r\n                if\
                        \ (\r\n                    parent_dir is not None\r\n    \
                        \                and not parent_dir.exists()\r\n         \
                        \           and not parent_dir.mkdirs()\r\n              \
                        \  ):\r\n                    raise RuntimeError(\r\n     \
                        \                   'Cannot create directory: %s'\r\n    \
                        \                    % parent_dir.getAbsolutePath()\r\n  \
                        \                  )\r\n\r\n                output_stream\
                        \ = BufferedOutputStream(\r\n                    FileOutputStream(target_file)\r\
                        \n                )\r\n\r\n                try:\r\n      \
                        \              count = input_stream.read(buffer)\r\n\r\n \
                        \                   while count != -1:\r\n               \
                        \         if count > 0:\r\n                            output_stream.write(buffer,\
                        \ 0, count)\r\n\r\n                        count = input_stream.read(buffer)\r\
                        \n                finally:\r\n                    output_stream.close()\r\
                        \n\r\n            input_stream.closeEntry()\r\n          \
                        \  entry = input_stream.getNextEntry()\r\n    finally:\r\n\
                        \        input_stream.close()\r\n\r\n\r\ndef _find_json_files(directory,\
                        \ result):\r\n    if directory is None or not directory.exists():\r\
                        \n        return\r\n\r\n    children = directory.listFiles()\r\
                        \n\r\n    if children is None:\r\n        return\r\n\r\n \
                        \   for child in children:\r\n        if child.isDirectory():\r\
                        \n            _find_json_files(child, result)\r\n        elif\
                        \ (\r\n            child.isFile()\r\n            and child.getName().lower().endswith('.json')\r\
                        \n        ):\r\n            result.append(child)\r\n\r\n\r\
                        \ndef _find_session_json(output_dir, session_id):\r\n    runtime_dir\
                        \ = File(\r\n        File(output_dir, 'runtime-data'),\r\n\
                        \        '__default__'\r\n    )\r\n\r\n    if not runtime_dir.exists()\
                        \ or not runtime_dir.isDirectory():\r\n        raise RuntimeError(\r\
                        \n            'runtime-data\\\\__default__ was not found:\
                        \ %s'\r\n            % runtime_dir.getAbsolutePath()\r\n \
                        \       )\r\n\r\n    json_files = []\r\n    _find_json_files(runtime_dir,\
                        \ json_files)\r\n\r\n    if not json_files:\r\n        raise\
                        \ RuntimeError(\r\n            'No JSON file found under:\
                        \ %s'\r\n            % runtime_dir.getAbsolutePath()\r\n \
                        \       )\r\n\r\n    session_text = unicode(session_id)\r\n\
                        \r\n    for json_file in json_files:\r\n        if session_text\
                        \ in json_file.getName():\r\n            return json_file\r\
                        \n\r\n    if len(json_files) == 1:\r\n        return json_files[0]\r\
                        \n\r\n    names = []\r\n\r\n    for json_file in json_files:\r\
                        \n        names.append(json_file.getName())\r\n\r\n    raise\
                        \ RuntimeError(\r\n        'Multiple JSON files found, but\
                        \ none matches session_id %s: %s'\r\n        % (session_id,\
                        \ ', '.join(names))\r\n    )\r\n\r\n\r\ndef _read_utf8(file_path):\r\
                        \n    input_stream = FileInputStream(file_path)\r\n    output_stream\
                        \ = ByteArrayOutputStream()\r\n\r\n    try:\r\n        buffer\
                        \ = zeros(8192, 'b')\r\n\r\n        while True:\r\n      \
                        \      count = input_stream.read(buffer)\r\n\r\n         \
                        \   if count == -1:\r\n                break\r\n\r\n     \
                        \       if count > 0:\r\n                output_stream.write(buffer,\
                        \ 0, count)\r\n\r\n        data = output_stream.toByteArray()\r\
                        \n        return unicode(String(data, 'UTF-8'))\r\n    finally:\r\
                        \n        input_stream.close()\r\n        output_stream.close()\r\
                        \n\r\n\r\ndef extractCoverageJson(input, context):\r\n   \
                        \ session_id = _session_id(context)\r\n    zip_file = _wait_for_zip()\r\
                        \n\r\n    Application.showMessage(\r\n        'Using coverage\
                        \ ZIP: %s'\r\n        % zip_file.getAbsolutePath()\r\n   \
                        \ )\r\n\r\n    _extract_zip(zip_file)\r\n\r\n    json_file\
                        \ = _find_session_json(\r\n        _downloads_dir(),\r\n \
                        \       session_id\r\n    )\r\n\r\n    json_content = _read_utf8(json_file)\r\
                        \n\r\n    Application.showMessage(\r\n        'Coverage JSON\
                        \ found: %s'\r\n        % json_file.getAbsolutePath()\r\n\
                        \    )\r\n\r\n    return json_content"
                hasMethodId: true
                methodId:
                  $type: JythonMethodIdentifier
                  methodName: extractCoverageJson
            writeInput: true
            inputType: InputUsable
            input:
              use: 1
              text:
                text: ""
                type: text/plain
              dataSource:
                columnName: runtimeData_path
          tests:
          - $type: ToolTest
            name: Diff
            testID: 861
            tool:
              $type: DiffTool
              iconName: Diff
              name: Diff
              differs:
              - $type: TextDiffer
              - $type: JSONDiffer
              source:
                file: true
                fileObj:
                  resolveVariablePath: true
                  backupPath: "C:\\Users\\ysl13\\Downloads\\runtime-data\\__default__${session_id}.json"
                  path: "${USERPROFILE}\\Downloads\\runtime-data\\__default__\\${session_id}.json"
                optionsSource: 2
              mode: 3
            writeInput: true
            inputType: InputUsable
            input:
              use: 2
              text:
                text: ""
                type: text/plain
              file:
                isEmpty: false
                location:
                  path: runtime-data\ts-webpack-babel-loader-express-server\expected-runtime.json
              dataSource:
                columnName: runtimeData_path
      - $type: RESTClientToolTest
        name: 09 GET coverage by id 404
        reportingSettings:
          requirementsTracking:
            comment: "GET /coverage/{id} - not found branch, using a well-formed but\
              \ nonexistent session ID."
        testID: 253
        tool:
          $type: RESTClient
          iconName: RESTClient
          name: 404
          outputTools:
          - $type: GenericAssertionTool
            iconName: XMLAssertor
            name: JSON Assertor
            wrappedTool:
              $type: XMLAssertionTool
              iconName: XMLAssertor
              name: XML Assertor
              errorsOutput:
                name: Errors
              assertions:
              - $type: ValueAssertion
                timestamp: 1789352719776
                name: message code
                extractEntireElement: true
                Assertion_XPath: /root/messageCode/string()
                value:
                  name: Value
                  value:
                    fixedValue:
                      $type: StringTestValue
                      value: 400
              - $type: ValueAssertion
                timestamp: 1789352768500
                name: message
                extractEntireElement: true
                Assertion_XPath: /root/message/string()
                value:
                  name: Value
                  value:
                    fixedValue:
                      $type: StringTestValue
                      value: Cannot get coverage because session 'runtime_coverage_00000000_0000_0'
                        was not found
              message:
                $type: ExpectedXMLMessage
                message: true
            conversionStrategy:
              dataFormatName: JSON
              conversionStrategyId: JSON
              conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
          formJson:
            value:
              $type: ElementValue
              writeType: true
              hasReference: true
              qnameAsString: :root
              replacedColumn: ""
              values:
              - $type: ComplexValue
                replacedColumn: ""
                attributes:
                - replacedColumn: ""
                  value:
                    $type: StringValue
                    replacedColumn: ""
                    value: object
                  useValue: true
                compositorValue: true
                compositorValueObj:
                  replacedColumn: ""
                  values:
                    $type: CompositorValueSetCollectionSet
                    set:
                    - $type: CompositorValueSet
            elementTypeName: root
          hasServiceInfo: true
          serviceInfo:
            serviceDescriptor:
              $type: StandardServiceDescriptor
              location: http://localhost:8050/openapi.yml
          jsonBuilder:
            hasValue: true
            value:
              $type: JSONObjectValue
              nameIsNull: true
          schemaURL:
            MessagingClient_SchemaLocation: "${OpenAPI}"
          formInput:
            value:
              $type: ElementValue
              writeType: true
              hasReference: true
              qnameAsString: ":"
              replacedColumn: ""
              values:
              - $type: ComplexValue
                replacedColumn: ""
                compositorValue: true
                compositorValueObj:
                  replacedColumn: ""
                  values:
                    $type: CompositorValueSetCollectionSet
                    set:
                    - $type: CompositorValueSet
          jmsMessageOutputProvider:
            $type: JMSMessageOutputProvider
            jmsOutputProviderRequest:
              $type: JMSOutputProvider
              name: Request Object
              menuName: Object
            jmsOutputProviderResponse:
              $type: JMSOutputProvider
              name: Response Message Object
              menuName: Message Object
          validResponseRange:
            validResponseRange:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                validResponseRange: 404
          router:
            values:
            - $type: ScriptedValue
            fixedValue:
              $type: StringTestValue
              HTTPClient_Endpoint: http://localhost:8050/coverage/runtime_coverage_00000000_0000_0
          transportProperties:
            manager:
              protocol: 1
              properties:
              - $type: HTTPClientHTTPProperties
                followRedirects:
                  bool: true
                common:
                  method:
                    values:
                    - $type: ScriptedValue
                    fixedValue:
                      $type: HTTPMethodTestValue
                      method: GET
                keepAlive1_1:
                  bool: true
              - $type: HTTPClientHTTPProperties
                followRedirects:
                  bool: true
                common:
                  method:
                    values:
                    - $type: ScriptedValue
                    fixedValue:
                      $type: HTTPMethodTestValue
                      method: GET
                protocol: 1
                keepAlive1_1:
                  bool: true
            messageExchangePattern:
              inverted: true
          outputProviders:
            requestHeader:
              $type: HTTPNamedToolOutputProvider
              menuName: Transport Header
              name: Request Transport Header
            responseHeader:
              $type: HTTPNamedToolOutputProvider
              menuName: Transport Header
              name: Response Transport Header
            xmlRequestOutput:
              $type: NamedXMLToolOutputProvider
              menuName: Traffic
              name: Request Traffic
            trafficOutput:
              m_name: Traffic Stream
            objectOutput:
              $type: ObjectOutputProvider
              outputTools:
              - $type: TrafficViewer
                iconName: TrafficViewer
                name: Traffic Viewer
              name: Traffic Object
          formXML:
            doctype: ""
          literal:
            use: 1
            text:
              MessagingClient_LiteralMessage: ""
              type: application/json
            dataSource:
              columnName: session_id
          mode: Literal
          literalQuery:
            isPropertiesRef: true
          literalPath:
            pathElements:
            - values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                value: coverage
            - values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                value: runtime_coverage_00000000_0000_0
          constrainedPath:
            pathParameters:
            - $type: ElementValue
              writeType: true
              hasReference: true
              qnameAsString: :id
              replacedColumn: ""
              values:
              - $type: StringValue
                replacedColumn: ""
                value: runtime_coverage_00000000_0000_0
          resourceMethod:
            resourceId: "/coverage/{id}"
            httpMethod: GET
          resourceMode: 3
          baseUrl:
            values:
            - $type: ScriptedValue
            - $type: WadlTestValue
              value: http://localhost:8050
            fixedValue:
              $type: StringTestValue
              value: http://localhost:8050
            selectedIndex: 1
      - $type: TestSuite
        name: 405
        testID: 346
        setUpTests:
        - $type: RESTClientToolTest
          name: 01 Get config GET
          reportingSettings:
            requirementsTracking:
              comment: "Get agent configuration properties (operationId: getAgentConfig)."
          testID: 395
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: /config - GET
            outputTools:
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789366046141
                  name: port
                  extractEntireElement: true
                  Assertion_XPath: /root/restServerPort/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: 8050
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            - $type: GenericDataBank
              iconName: XMLDataBank
              name: JSON Data Bank
              wrappedTool:
                $type: XMLtoDataSource
                iconName: XMLDataBank
                name: XML Data Bank
                selectedXPaths:
                - elementOption: 1
                  contentOption: 1
                  XMLDataBank_ExtractXPath: "/root/runtimeData[1]/text()"
                  mode: 1
                canonicalizeOutput: true
                xmlMessage: true
                virtualDSCreator:
                  writableColumns:
                  - customName: runtimeData_path
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
              serviceName: ""
              versionName: ""
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 200
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/config
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: runtimeData_path
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: config
            resourceMethod:
              resourceId: /config
              httpMethod: GET
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
        - $type: ToolTest
          name: Extension Tool
          testID: 393
          tool:
            $type: MethodTool
            iconName: Method
            name: rename version.json
            method:
              hasCode: true
              code:
                $type: JythonCode
                input:
                  useText: true
                  textInput:
                    $type: ScriptingTextInput
                    text: "from com.parasoft.api import Application\r\nfrom java.nio.file\
                      \ import Files, Paths\r\n\r\nFILE_NAME     = 'version.json'\r\
                      \nNEW_FILE_NAME = 'version.json.bak'\r\n\r\ndef _plain_name(v,\
                      \ label):\r\n    if not isinstance(label, basestring):\r\n \
                      \       raise RuntimeError(\r\n            '_plain_name misuse:\
                      \ label must be a str, got %s (%r); '\r\n            'check\
                      \ the call site — args are (value, label_str), not (value, context)'\r\
                      \n            % (type(label).__name__, label))\r\n    if not\
                      \ isinstance(v, basestring) or not v or '/' in v or '\\\\' in\
                      \ v or v in ('.', '..') or '\\0' in v:\r\n        raise RuntimeError('invalid\
                      \ %s: %r' % (label, v))\r\n\r\ndef _runtime_data(context):\r\
                      \n    dv = context.getDataSourceValue('runtimeData_path')\r\n\
                      \    if dv is None:\r\n        raise RuntimeError('runtimeData_path\
                      \ is empty; check the JSON Data Bank on GET /config')\r\n  \
                      \  # DataValue.toString() format: \"com.parasoft.data.DataValue@<hash>,\
                      \ <value>\"\r\n    s = unicode(dv.toString())\r\n    parts =\
                      \ s.split(', ', 1)\r\n    value = parts[1] if len(parts) ==\
                      \ 2 and parts[0].startswith('com.parasoft.data.') else s\r\n\
                      \    return value.strip()\r\n\r\ndef renameFile(input, context):\r\
                      \n    _plain_name(FILE_NAME, 'FILE_NAME')\r\n    _plain_name(NEW_FILE_NAME,\
                      \ 'NEW_FILE_NAME')\r\n    if FILE_NAME == NEW_FILE_NAME:\r\n\
                      \        raise RuntimeError('FILE_NAME and NEW_FILE_NAME must\
                      \ differ')\r\n\r\n    parent = Paths.get(_runtime_data(context))\r\
                      \n    src = parent.resolve(FILE_NAME)\r\n    dst = parent.resolve(NEW_FILE_NAME)\r\
                      \n    if not Files.exists(src):\r\n        raise RuntimeError('source\
                      \ file not found: %s' % src)\r\n    if Files.isDirectory(src):\r\
                      \n        raise RuntimeError('source is a directory, not a file:\
                      \ %s' % src)\r\n    if Files.exists(dst):\r\n        raise RuntimeError('target\
                      \ already exists: %s' % dst)\r\n\r\n    Files.move(src, dst)\r\
                      \n    Application.showMessage('renamed file: %s -> %s' % (src,\
                      \ dst))\r\n    return '%s -> %s' % (src.toAbsolutePath(), dst.toAbsolutePath())"
              hasMethodId: true
              methodId:
                $type: JythonMethodIdentifier
                methodName: renameFile
          writeInput: true
          inputType: InputUsable
          input:
            use: 1
            text:
              text: ""
              type: text/plain
            dataSource:
              columnName: runtimeData_path
        tearDownTests:
        - $type: ToolTest
          name: rename version.json 2
          testID: 394
          tool:
            $type: MethodTool
            iconName: Method
            name: rename version.json back
            method:
              hasCode: true
              code:
                $type: JythonCode
                input:
                  useText: true
                  textInput:
                    $type: ScriptingTextInput
                    text: |-
                      from com.parasoft.api import Application
                      from java.nio.file import Files, Paths

                      FILE_NAME     = 'version.json.bak'
                      NEW_FILE_NAME = 'version.json'

                      def _plain_name(v, label):
                          if not isinstance(label, basestring):
                              raise RuntimeError(
                                  '_plain_name misuse: label must be a str, got %s (%r); '
                                  'check the call site — args are (value, label_str), not (value, context)'
                                  % (type(label).__name__, label))
                          if not isinstance(v, basestring) or not v or '/' in v or '\\' in v or v in ('.', '..') or '\0' in v:
                              raise RuntimeError('invalid %s: %r' % (label, v))

                      def _runtime_data(context):
                          dv = context.getDataSourceValue('runtimeData_path')
                          if dv is None:
                              raise RuntimeError('runtimeData_path is empty; check the JSON Data Bank on GET /config')
                          # DataValue.toString() format: "com.parasoft.data.DataValue@<hash>, <value>"
                          s = unicode(dv.toString())
                          parts = s.split(', ', 1)
                          value = parts[1] if len(parts) == 2 and parts[0].startswith('com.parasoft.data.') else s
                          return value.strip()

                      def renameFile(input, context):
                          _plain_name(FILE_NAME, 'FILE_NAME')
                          _plain_name(NEW_FILE_NAME, 'NEW_FILE_NAME')
                          if FILE_NAME == NEW_FILE_NAME:
                              raise RuntimeError('FILE_NAME and NEW_FILE_NAME must differ')

                          parent = Paths.get(_runtime_data(context))
                          src = parent.resolve(FILE_NAME)
                          dst = parent.resolve(NEW_FILE_NAME)
                          if not Files.exists(src):
                              raise RuntimeError('source file not found: %s' % src)
                          if Files.isDirectory(src):
                              raise RuntimeError('source is a directory, not a file: %s' % src)
                          if Files.exists(dst):
                              raise RuntimeError('target already exists: %s' % dst)

                          Files.move(src, dst)
                          Application.showMessage('renamed file: %s -> %s' % (src, dst))
                          return '%s -> %s' % (src.toAbsolutePath(), dst.toAbsolutePath())
              hasMethodId: true
              methodId:
                $type: JythonMethodIdentifier
                methodName: renameFile
          writeInput: true
          inputType: InputUsable
          input:
            use: 1
            text:
              text: ""
              type: text/plain
            dataSource:
              columnName: runtimeData_path
        tests:
        - $type: RESTClientToolTest
          name: "10 GET coverage by id 405 (documented, not reliably triggerable)"
          reportingSettings:
            requirementsTracking:
              comment: "GET /coverage/{id} - documented 405 branch (agent uses this\
                \ when version.json is missing while creating the archive). Requires\
                \ a corrupted AUT install; kept as a documentation placeholder."
          testID: 348
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: version json file does not existed
            outputTools:
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789352954860
                  name: 'message code '
                  extractEntireElement: true
                  Assertion_XPath: /root/messageCode/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: 701
                - $type: StringComparisonAssertion
                  timestamp: 1789634279167
                  name: message
                  extractEntireElement: true
                  Assertion_XPath: /root/message/string()
                  comparisonMode: 4
                  value:
                    name: String Comparison Assertion
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: "Agent version file not found: "
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 405
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: "http://localhost:8050/coverage/${session_id}"
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: coverage
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: "${session_id}"
            constrainedPath:
              pathParameters:
              - $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :id
                replacedColumn: ""
                values:
                - $type: StringValue
                  replacedColumn: ""
                  value: "${session_id}"
            resourceMethod:
              resourceId: "/coverage/{id}"
              httpMethod: GET
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
    - $type: TestSuite
      name: /coverage - DELETE
      testID: 195
      tests:
      - $type: TestSuite
        name: skipped and deleted
        testID: 426
        setUpTests:
        - $type: RESTClientToolTest
          name: 00 Start main session GET 2
          reportingSettings:
            requirementsTracking:
              comment: "Prerequisite: start the main session and extract its ID for\
                \ GET/DELETE by-id tests."
          testID: 432
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: /session/start - GET 1st
            outputTools:
            - $type: GenericDataBank
              iconName: XMLDataBank
              name: JSON Data Bank
              wrappedTool:
                $type: XMLtoDataSource
                iconName: XMLDataBank
                name: XML Data Bank
                selectedXPaths:
                - XMLDataBank_ExtractXPath: /root/session
                  mode: 1
                canonicalizeOutput: true
                xmlMessage: true
                virtualDSCreator:
                  writableColumns:
                  - customName: session_id
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789351155438
                  name: Value Assertion
                  extractEntireElement: true
                  Assertion_XPath: /root/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                      parameterizedValue:
                        column: session_id
                      selectedIndex: -2
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
              serviceName: ""
              versionName: ""
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 200
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/session/start
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: session
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: start
            resourceMethod:
              resourceId: /session/start
              httpMethod: GET
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
        - $type: RESTClientToolTest
          name: 07 Stop main session GET
          reportingSettings:
            requirementsTracking:
              comment: "Prerequisite: stop the main session so it satisfies the precondition\
                \ for GET/DELETE /coverage/{id} success cases."
          testID: 433
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: /session/stop - GET 1st
            outputTools:
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789353114687
                  name: seesion
                  extractEntireElement: true
                  Assertion_XPath: /root/session/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: "null"
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
              serviceName: ""
              versionName: ""
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 200
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/session/stop
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: session
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: stop
            resourceMethod:
              resourceId: /session/stop
              httpMethod: GET
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
        - $type: RESTClientToolTest
          name: Start main session GET 2
          reportingSettings:
            requirementsTracking:
              comment: "Prerequisite: start the main session and extract its ID for\
                \ GET/DELETE by-id tests."
          testID: 429
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: /session/start - GET 2nd
            outputTools:
            - $type: GenericDataBank
              iconName: XMLDataBank
              name: JSON Data Bank
              wrappedTool:
                $type: XMLtoDataSource
                iconName: XMLDataBank
                name: XML Data Bank
                selectedXPaths:
                - XMLDataBank_ExtractXPath: /root/session
                  mode: 1
                canonicalizeOutput: true
                xmlMessage: true
                virtualDSCreator:
                  writableColumns:
                  - customName: session_id
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789351155438
                  name: Value Assertion
                  extractEntireElement: true
                  Assertion_XPath: /root/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                      parameterizedValue:
                        column: session_id
                      selectedIndex: -2
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
              serviceName: ""
              versionName: ""
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 200
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/session/start
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: session
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: start
            resourceMethod:
              resourceId: /session/start
              httpMethod: GET
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
        tearDownTests:
        - $type: RESTClientToolTest
          name: Stop main session 2
          reportingSettings:
            requirementsTracking:
              comment: "Prerequisite: stop the main session so it satisfies the precondition\
                \ for GET/DELETE /coverage/{id} success cases."
          testID: 438
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: /session/stop - GET
            outputTools:
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789353114687
                  name: seesion
                  extractEntireElement: true
                  Assertion_XPath: /root/session/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: "null"
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 200
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/session/stop
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: session
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: stop
            resourceMethod:
              resourceId: /session/stop
              httpMethod: GET
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
        tests:
        - $type: RESTClientToolTest
          name: 17 DELETE all coverage 200
          reportingSettings:
            requirementsTracking:
              comment: "DELETE /coverage - success case, removes remaining inactive\
                \ session coverage (operationId: deleteAllCoverageFiles)."
          testID: 435
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: 200
            outputTools:
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: HasChildrenAssertion
                  timestamp: 1789636873908
                  name: skipped
                  extractEntireElement: true
                  Assertion_XPath: /root/skipped
                  value:
                    fixedValue:
                      $type: BooleanFieldTestValue
                      value: true
                - $type: HasChildrenAssertion
                  timestamp: 1789636891588
                  name: deleted
                  extractEntireElement: true
                  Assertion_XPath: /root/deleted
                  value:
                    fixedValue:
                      $type: BooleanFieldTestValue
                      value: true
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 200
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/coverage
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: DELETE
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: DELETE
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: coverage
            resourceMethod:
              resourceId: /coverage
              httpMethod: DELETE
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
      - $type: RESTClientToolTest
        name: DELETE all coverage 200 skipped 3
        reportingSettings:
          requirementsTracking:
            comment: "DELETE /coverage - success case, removes remaining inactive\
              \ session coverage (operationId: deleteAllCoverageFiles)."
        testID: 371
        tool:
          $type: RESTClient
          iconName: RESTClient
          name: deleted - 200
          outputTools:
          - $type: GenericAssertionTool
            iconName: XMLAssertor
            name: JSON Assertor
            wrappedTool:
              $type: XMLAssertionTool
              iconName: XMLAssertor
              name: XML Assertor
              errorsOutput:
                name: Errors
              assertions:
              - $type: StringComparisonAssertion
                timestamp: 1789636426306
                name: not contain skipped
                extractEntireElement: true
                Assertion_XPath: /root/string()
                comparisonMode: 3
                value:
                  name: String Comparison Assertion
                  value:
                    fixedValue:
                      $type: StringTestValue
                      value: skipped
              - $type: HasChildrenAssertion
                timestamp: 1789636573480
                name: deleted
                extractEntireElement: true
                Assertion_XPath: /root/deleted
                value:
                  fixedValue:
                    $type: BooleanFieldTestValue
                    value: true
              message:
                $type: ExpectedXMLMessage
                message: true
            conversionStrategy:
              dataFormatName: JSON
              conversionStrategyId: JSON
              conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
          formJson:
            value:
              $type: ElementValue
              writeType: true
              hasReference: true
              qnameAsString: :root
              replacedColumn: ""
              values:
              - $type: ComplexValue
                replacedColumn: ""
                attributes:
                - replacedColumn: ""
                  value:
                    $type: StringValue
                    replacedColumn: ""
                    value: object
                  useValue: true
                compositorValue: true
                compositorValueObj:
                  replacedColumn: ""
                  values:
                    $type: CompositorValueSetCollectionSet
                    set:
                    - $type: CompositorValueSet
            elementTypeName: root
          hasServiceInfo: true
          serviceInfo:
            serviceDescriptor:
              $type: StandardServiceDescriptor
              location: http://localhost:8050/openapi.yml
          jsonBuilder:
            hasValue: true
            value:
              $type: JSONObjectValue
              nameIsNull: true
          schemaURL:
            MessagingClient_SchemaLocation: "${OpenAPI}"
          formInput:
            value:
              $type: ElementValue
              writeType: true
              hasReference: true
              qnameAsString: ":"
              replacedColumn: ""
              values:
              - $type: ComplexValue
                replacedColumn: ""
                compositorValue: true
                compositorValueObj:
                  replacedColumn: ""
                  values:
                    $type: CompositorValueSetCollectionSet
                    set:
                    - $type: CompositorValueSet
          jmsMessageOutputProvider:
            $type: JMSMessageOutputProvider
            jmsOutputProviderRequest:
              $type: JMSOutputProvider
              name: Request Object
              menuName: Object
            jmsOutputProviderResponse:
              $type: JMSOutputProvider
              name: Response Message Object
              menuName: Message Object
          validResponseRange:
            validResponseRange:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                validResponseRange: 200
          router:
            values:
            - $type: ScriptedValue
            fixedValue:
              $type: StringTestValue
              HTTPClient_Endpoint: http://localhost:8050/coverage
          transportProperties:
            manager:
              protocol: 1
              properties:
              - $type: HTTPClientHTTPProperties
                followRedirects:
                  bool: true
                common:
                  method:
                    values:
                    - $type: ScriptedValue
                    fixedValue:
                      $type: HTTPMethodTestValue
                      method: DELETE
                keepAlive1_1:
                  bool: true
              - $type: HTTPClientHTTPProperties
                followRedirects:
                  bool: true
                common:
                  method:
                    values:
                    - $type: ScriptedValue
                    fixedValue:
                      $type: HTTPMethodTestValue
                      method: DELETE
                protocol: 1
                keepAlive1_1:
                  bool: true
            messageExchangePattern:
              inverted: true
          outputProviders:
            requestHeader:
              $type: HTTPNamedToolOutputProvider
              menuName: Transport Header
              name: Request Transport Header
            responseHeader:
              $type: HTTPNamedToolOutputProvider
              menuName: Transport Header
              name: Response Transport Header
            xmlRequestOutput:
              $type: NamedXMLToolOutputProvider
              menuName: Traffic
              name: Request Traffic
            trafficOutput:
              m_name: Traffic Stream
            objectOutput:
              $type: ObjectOutputProvider
              outputTools:
              - $type: TrafficViewer
                iconName: TrafficViewer
                name: Traffic Viewer
              name: Traffic Object
          formXML:
            doctype: ""
          literal:
            use: 1
            text:
              MessagingClient_LiteralMessage: ""
              type: application/json
            dataSource:
              columnName: session_id
          mode: Literal
          literalQuery:
            isPropertiesRef: true
          literalPath:
            pathElements:
            - values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                value: coverage
          resourceMethod:
            resourceId: /coverage
            httpMethod: DELETE
          resourceMode: 3
          baseUrl:
            values:
            - $type: ScriptedValue
            - $type: WadlTestValue
              value: http://localhost:8050
            fixedValue:
              $type: StringTestValue
              value: http://localhost:8050
            selectedIndex: 1
      - $type: TestSuite
        name: skipped
        testID: 441
        setUpTests:
        - $type: RESTClientToolTest
          name: Start main session GET 3
          reportingSettings:
            requirementsTracking:
              comment: "Prerequisite: start the main session and extract its ID for\
                \ GET/DELETE by-id tests."
          testID: 447
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: /session/start - GET
            outputTools:
            - $type: GenericDataBank
              iconName: XMLDataBank
              name: JSON Data Bank
              wrappedTool:
                $type: XMLtoDataSource
                iconName: XMLDataBank
                name: XML Data Bank
                selectedXPaths:
                - XMLDataBank_ExtractXPath: /root/session
                  mode: 1
                canonicalizeOutput: true
                xmlMessage: true
                virtualDSCreator:
                  writableColumns:
                  - customName: session_id
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789351155438
                  name: Value Assertion
                  extractEntireElement: true
                  Assertion_XPath: /root/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                      parameterizedValue:
                        column: session_id
                      selectedIndex: -2
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 200
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/session/start
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: session
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: start
            resourceMethod:
              resourceId: /session/start
              httpMethod: GET
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
        tearDownTests:
        - $type: RESTClientToolTest
          name: 07 Stop main session GET
          reportingSettings:
            requirementsTracking:
              comment: "Prerequisite: stop the main session so it satisfies the precondition\
                \ for GET/DELETE /coverage/{id} success cases."
          testID: 450
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: /session/stop - GET
            outputTools:
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789353114687
                  name: seesion
                  extractEntireElement: true
                  Assertion_XPath: /root/session/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: "null"
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
              serviceName: ""
              versionName: ""
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 200
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/session/stop
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: session
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: stop
            resourceMethod:
              resourceId: /session/stop
              httpMethod: GET
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
        tests:
        - $type: RESTClientToolTest
          name: DELETE all coverage 200 skipped 2
          reportingSettings:
            requirementsTracking:
              comment: "DELETE /coverage - success case, removes remaining inactive\
                \ session coverage (operationId: deleteAllCoverageFiles)."
          testID: 444
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: 200
            outputTools:
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: HasChildrenAssertion
                  timestamp: 1789637026725
                  name: deleted
                  extractEntireElement: true
                  Assertion_XPath: /root/deleted
                - $type: HasChildrenAssertion
                  timestamp: 1789637040506
                  name: skipped
                  extractEntireElement: true
                  Assertion_XPath: /root/skipped
                  value:
                    fixedValue:
                      $type: BooleanFieldTestValue
                      value: true
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 200
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/coverage
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: DELETE
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: DELETE
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: coverage
            resourceMethod:
              resourceId: /coverage
              httpMethod: DELETE
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
      - $type: TestSuite
        name: 404
        testID: 354
        setUpTests:
        - $type: ToolTest
          name: Extension Tool
          testID: 455
          tool:
            $type: MethodTool
            iconName: Method
            name: rename__default__ dir
            method:
              hasCode: true
              code:
                $type: JythonCode
                input:
                  useText: true
                  textInput:
                    $type: ScriptingTextInput
                    text: |-
                      from com.parasoft.api import Application
                      from java.nio.file import Files, Paths

                      USER_DIR   = '__default__'
                      RENAME_DIR = '__default__copy'

                      def _plain_name(v, label):
                          if not isinstance(v, basestring) or not v or '/' in v or '\\' in v or v in ('.', '..') or '\0' in v:
                              raise RuntimeError('invalid %s: %r' % (label, v))

                      def _runtime_data(context):
                          dv = context.getDataSourceValue('runtimeData_path')
                          if dv is None:
                              raise RuntimeError('runtimeData_path is empty; check the JSON Data Bank on GET /config')
                          s = unicode(dv.toString())
                          parts = s.split(', ', 1)
                          value = parts[1] if len(parts) == 2 and parts[0].startswith('com.parasoft.data.') else s
                          return value.strip()

                      def renameDir(input, context):
                          _plain_name(USER_DIR, 'USER_DIR')
                          _plain_name(RENAME_DIR, 'RENAME_DIR')
                          if USER_DIR == RENAME_DIR:
                              raise RuntimeError('USER_DIR and RENAME_DIR must differ')

                          parent = Paths.get(_runtime_data(context))
                          src = parent.resolve(USER_DIR)
                          dst = parent.resolve(RENAME_DIR)
                          if not Files.exists(src):
                              raise RuntimeError('source not found: %s' % src)
                          if Files.exists(dst):
                              raise RuntimeError('target already exists: %s' % dst)
                          Files.move(src, dst)
                          Application.showMessage('renamed: %s -> %s' % (src, dst))
                          return '%s -> %s' % (src.toAbsolutePath(), dst.toAbsolutePath())
              hasMethodId: true
              methodId:
                $type: JythonMethodIdentifier
                methodName: renameDir
          writeInput: true
          inputType: InputUsable
          input:
            use: 1
            text:
              text: ""
              type: text/plain
            dataSource:
              columnName: runtimeData_path
        tearDownTests:
        - $type: ToolTest
          name: Rename__default__ dir 2
          testID: 456
          tool:
            $type: MethodTool
            iconName: Method
            name: rename__default__ dir back
            method:
              hasCode: true
              code:
                $type: JythonCode
                input:
                  useText: true
                  textInput:
                    $type: ScriptingTextInput
                    text: "from com.parasoft.api import Application\r\nfrom java.nio.file\
                      \ import Files, Paths\r\n\r\nUSER_DIR   = '__default__copy'\r\
                      \nRENAME_DIR = '__default__'\r\n\r\ndef _plain_name(v, label):\r\
                      \n    if not isinstance(v, basestring) or not v or '/' in v\
                      \ or '\\\\' in v or v in ('.', '..') or '\\0' in v:\r\n    \
                      \    raise RuntimeError('invalid %s: %r' % (label, v))\r\n\r\
                      \ndef _runtime_data(context):\r\n    dv = context.getDataSourceValue('runtimeData_path')\r\
                      \n    if dv is None:\r\n        raise RuntimeError('runtimeData_path\
                      \ is empty; check the JSON Data Bank on GET /config')\r\n  \
                      \  s = unicode(dv.toString())\r\n    parts = s.split(', ', 1)\r\
                      \n    value = parts[1] if len(parts) == 2 and parts[0].startswith('com.parasoft.data.')\
                      \ else s\r\n    return value.strip()\r\n\r\ndef renameDir(input,\
                      \ context):\r\n    _plain_name(USER_DIR, 'USER_DIR')\r\n   \
                      \ _plain_name(RENAME_DIR, 'RENAME_DIR')\r\n    if USER_DIR ==\
                      \ RENAME_DIR:\r\n        raise RuntimeError('USER_DIR and RENAME_DIR\
                      \ must differ')\r\n\r\n    parent = Paths.get(_runtime_data(context))\r\
                      \n    src = parent.resolve(USER_DIR)\r\n    dst = parent.resolve(RENAME_DIR)\r\
                      \n    if not Files.exists(src):\r\n        raise RuntimeError('source\
                      \ not found: %s' % src)\r\n    if Files.exists(dst):\r\n   \
                      \     raise RuntimeError('target already exists: %s' % dst)\r\
                      \n    Files.move(src, dst)\r\n    Application.showMessage('renamed:\
                      \ %s -> %s' % (src, dst))\r\n    return '%s -> %s' % (src.toAbsolutePath(),\
                      \ dst.toAbsolutePath())"
              hasMethodId: true
              methodId:
                $type: JythonMethodIdentifier
                methodName: renameDir
          writeInput: true
          inputType: InputUsable
          input:
            use: 1
            text:
              text: ""
              type: text/plain
            dataSource:
              columnName: runtimeData_path
        tests:
        - $type: RESTClientToolTest
          name: 18 DELETE all coverage 404 (documented)
          reportingSettings:
            requirementsTracking:
              comment: "DELETE /coverage - documented 404 branch (\"cannot delete\
                \ non existing session\"), called again once nothing remains."
          testID: 355
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: _default__ is not found
            outputTools:
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789355079283
                  name: message code
                  extractEntireElement: true
                  Assertion_XPath: /root/messageCode/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: 307
                - $type: ValueAssertion
                  timestamp: 1789355094334
                  name: message
                  extractEntireElement: true
                  Assertion_XPath: /root/message/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: Cannot delete coverage because user '__default__' is
                          not found
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 404
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/coverage
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: DELETE
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: DELETE
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: coverage
            resourceMethod:
              resourceId: /coverage
              httpMethod: DELETE
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
    - $type: TestSuite
      name: "/coverage/{id} - DELETE"
      testID: 205
      tests:
      - $type: TestSuite
        name: 200
        testID: 473
        setUpTests:
        - $type: RESTClientToolTest
          name: Start main session GET 3
          reportingSettings:
            requirementsTracking:
              comment: "Prerequisite: start the main session and extract its ID for\
                \ GET/DELETE by-id tests."
          testID: 477
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: /session/start - GET
            outputTools:
            - $type: GenericDataBank
              iconName: XMLDataBank
              name: JSON Data Bank
              wrappedTool:
                $type: XMLtoDataSource
                iconName: XMLDataBank
                name: XML Data Bank
                selectedXPaths:
                - XMLDataBank_ExtractXPath: /root/session
                  mode: 1
                canonicalizeOutput: true
                xmlMessage: true
                virtualDSCreator:
                  writableColumns:
                  - customName: session_id
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789351155438
                  name: Value Assertion
                  extractEntireElement: true
                  Assertion_XPath: /root/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                      parameterizedValue:
                        column: session_id
                      selectedIndex: -2
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
              serviceName: ""
              versionName: ""
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 200
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/session/start
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: session
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: start
            resourceMethod:
              resourceId: /session/start
              httpMethod: GET
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
        - $type: RESTClientToolTest
          name: 07 Stop main session GET
          reportingSettings:
            requirementsTracking:
              comment: "Prerequisite: stop the main session so it satisfies the precondition\
                \ for GET/DELETE /coverage/{id} success cases."
          testID: 479
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: /session/stop - GET
            outputTools:
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789353114687
                  name: seesion
                  extractEntireElement: true
                  Assertion_XPath: /root/session/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: "null"
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
              serviceName: ""
              versionName: ""
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 200
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/session/stop
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: session
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: stop
            resourceMethod:
              resourceId: /session/stop
              httpMethod: GET
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
        tests:
        - $type: RESTClientToolTest
          name: 14 DELETE coverage by id 200
          reportingSettings:
            requirementsTracking:
              comment: "DELETE /coverage/{id} - success case, removes the stopped\
                \ main session's coverage (operationId: removeCoverageBySessionId)."
          testID: 474
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: 200
            outputTools:
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789355907545
                  name: deleted
                  extractEntireElement: true
                  Assertion_XPath: /root/deleted/item/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                      parameterizedValue:
                        column: session_id
                      selectedIndex: -2
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
              serviceName: ""
              versionName: ""
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 200
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: "http://localhost:8050/coverage/${session_id}"
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: DELETE
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: DELETE
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: coverage
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: "${session_id}"
            constrainedPath:
              pathParameters:
              - $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :id
                replacedColumn: ""
                values:
                - $type: StringValue
                  replacedColumn: ""
                  value: "${session_id}"
            resourceMethod:
              resourceId: "/coverage/{id}"
              httpMethod: DELETE
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
      - $type: TestSuite
        name: 400
        testID: 458
        setUpTests:
        - $type: RESTClientToolTest
          name: Start main session GET 3
          reportingSettings:
            requirementsTracking:
              comment: "Prerequisite: start the main session and extract its ID for\
                \ GET/DELETE by-id tests."
          testID: 462
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: /session/start - GET
            outputTools:
            - $type: GenericDataBank
              iconName: XMLDataBank
              name: JSON Data Bank
              wrappedTool:
                $type: XMLtoDataSource
                iconName: XMLDataBank
                name: XML Data Bank
                selectedXPaths:
                - XMLDataBank_ExtractXPath: /root/session
                  mode: 1
                canonicalizeOutput: true
                xmlMessage: true
                virtualDSCreator:
                  writableColumns:
                  - customName: session_id
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789351155438
                  name: Value Assertion
                  extractEntireElement: true
                  Assertion_XPath: /root/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                      parameterizedValue:
                        column: session_id
                      selectedIndex: -2
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
              serviceName: ""
              versionName: ""
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 200
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/session/start
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: session
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: start
            resourceMethod:
              resourceId: /session/start
              httpMethod: GET
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
        tearDownTests:
        - $type: RESTClientToolTest
          name: 07 Stop main session GET
          reportingSettings:
            requirementsTracking:
              comment: "Prerequisite: stop the main session so it satisfies the precondition\
                \ for GET/DELETE /coverage/{id} success cases."
          testID: 466
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: /session/stop - GET
            outputTools:
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789353114687
                  name: seesion
                  extractEntireElement: true
                  Assertion_XPath: /root/session/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: "null"
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
              serviceName: ""
              versionName: ""
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 200
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/session/stop
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: GET
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: session
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: stop
            resourceMethod:
              resourceId: /session/stop
              httpMethod: GET
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
        tests:
        - $type: RESTClientToolTest
          name: 12 DELETE coverage by id 400 (active session)
          reportingSettings:
            requirementsTracking:
              comment: "DELETE /coverage/{id} - bad request branch, triggered because\
                \ session_id_active is still active."
          testFlowLogic:
            dependencyLogic:
              success: 0
          testID: 459
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: active session
            outputTools:
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789356013752
                  name: id
                  extractEntireElement: true
                  Assertion_XPath: /root/skipped/item/id/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                      parameterizedValue:
                        column: session_id
                      selectedIndex: -2
                - $type: ValueAssertion
                  timestamp: 1789356060283
                  name: reason
                  extractEntireElement: true
                  Assertion_XPath: /root/skipped/item/reason/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: Cannot delete session because it is not finished yet
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 400
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: "http://localhost:8050/coverage/${session_id_active}"
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: DELETE
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: DELETE
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: coverage
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: "${session_id_active}"
            constrainedPath:
              pathParameters:
              - $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :id
                replacedColumn: ""
                values:
                - $type: StringValue
                  replacedColumn: ""
                  value: "${session_id}"
            resourceMethod:
              resourceId: "/coverage/{id}"
              httpMethod: DELETE
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
        - $type: RESTClientToolTest
          name: 13 DELETE coverage by id 404
          reportingSettings:
            requirementsTracking:
              comment: "DELETE /coverage/{id} - not found branch, using a well-formed\
                \ but nonexistent session ID."
          testID: 552
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: sessionId not found
            outputTools:
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: ValueAssertion
                  timestamp: 1789356195044
                  name: message
                  extractEntireElement: true
                  Assertion_XPath: /root/skipped/item/reason/string()
                  value:
                    name: Value
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: Cannot delete session because it was not found
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 400
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/coverage/runtime_coverage_00000000_0000_0
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: DELETE
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: DELETE
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: coverage
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: runtime_coverage_00000000_0000_0
            constrainedPath:
              pathParameters:
              - $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :id
                replacedColumn: ""
                values:
                - $type: StringValue
                  replacedColumn: ""
                  value: runtime_coverage_00000000_0000_0
            resourceMethod:
              resourceId: "/coverage/{id}"
              httpMethod: DELETE
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
      - $type: TestSuite
        name: 404
        testID: 559
        setUpTests:
        - $type: ToolTest
          name: Extension Tool
          testID: 565
          tool:
            $type: MethodTool
            iconName: Method
            name: rename__default__ dir
            method:
              hasCode: true
              code:
                $type: JythonCode
                input:
                  useText: true
                  textInput:
                    $type: ScriptingTextInput
                    text: |-
                      from com.parasoft.api import Application
                      from java.nio.file import Files, Paths

                      USER_DIR   = '__default__'
                      RENAME_DIR = '__default__copy'

                      def _plain_name(v, label):
                          if not isinstance(v, basestring) or not v or '/' in v or '\\' in v or v in ('.', '..') or '\0' in v:
                              raise RuntimeError('invalid %s: %r' % (label, v))

                      def _runtime_data(context):
                          dv = context.getDataSourceValue('runtimeData_path')
                          if dv is None:
                              raise RuntimeError('runtimeData_path is empty; check the JSON Data Bank on GET /config')
                          s = unicode(dv.toString())
                          parts = s.split(', ', 1)
                          value = parts[1] if len(parts) == 2 and parts[0].startswith('com.parasoft.data.') else s
                          return value.strip()

                      def renameDir(input, context):
                          _plain_name(USER_DIR, 'USER_DIR')
                          _plain_name(RENAME_DIR, 'RENAME_DIR')
                          if USER_DIR == RENAME_DIR:
                              raise RuntimeError('USER_DIR and RENAME_DIR must differ')

                          parent = Paths.get(_runtime_data(context))
                          src = parent.resolve(USER_DIR)
                          dst = parent.resolve(RENAME_DIR)
                          if not Files.exists(src):
                              raise RuntimeError('source not found: %s' % src)
                          if Files.exists(dst):
                              raise RuntimeError('target already exists: %s' % dst)
                          Files.move(src, dst)
                          Application.showMessage('renamed: %s -> %s' % (src, dst))
                          return '%s -> %s' % (src.toAbsolutePath(), dst.toAbsolutePath())
              hasMethodId: true
              methodId:
                $type: JythonMethodIdentifier
                methodName: renameDir
          writeInput: true
          inputType: InputUsable
          input:
            use: 1
            text:
              text: ""
              type: text/plain
            dataSource:
              columnName: runtimeData_path
        tearDownTests:
        - $type: ToolTest
          name: Rename__default__ dir 2
          testID: 567
          tool:
            $type: MethodTool
            iconName: Method
            name: rename__default__ dir back
            method:
              hasCode: true
              code:
                $type: JythonCode
                input:
                  useText: true
                  textInput:
                    $type: ScriptingTextInput
                    text: |-
                      from com.parasoft.api import Application
                      from java.nio.file import Files, Paths

                      USER_DIR   = '__default__copy'
                      RENAME_DIR = '__default__'

                      def _plain_name(v, label):
                          if not isinstance(v, basestring) or not v or '/' in v or '\\' in v or v in ('.', '..') or '\0' in v:
                              raise RuntimeError('invalid %s: %r' % (label, v))

                      def _runtime_data(context):
                          dv = context.getDataSourceValue('runtimeData_path')
                          if dv is None:
                              raise RuntimeError('runtimeData_path is empty; check the JSON Data Bank on GET /config')
                          s = unicode(dv.toString())
                          parts = s.split(', ', 1)
                          value = parts[1] if len(parts) == 2 and parts[0].startswith('com.parasoft.data.') else s
                          return value.strip()

                      def renameDir(input, context):
                          _plain_name(USER_DIR, 'USER_DIR')
                          _plain_name(RENAME_DIR, 'RENAME_DIR')
                          if USER_DIR == RENAME_DIR:
                              raise RuntimeError('USER_DIR and RENAME_DIR must differ')

                          parent = Paths.get(_runtime_data(context))
                          src = parent.resolve(USER_DIR)
                          dst = parent.resolve(RENAME_DIR)
                          if not Files.exists(src):
                              raise RuntimeError('source not found: %s' % src)
                          if Files.exists(dst):
                              raise RuntimeError('target already exists: %s' % dst)
                          Files.move(src, dst)
                          Application.showMessage('renamed: %s -> %s' % (src, dst))
                          return '%s -> %s' % (src.toAbsolutePath(), dst.toAbsolutePath())
              hasMethodId: true
              methodId:
                $type: JythonMethodIdentifier
                methodName: renameDir
          writeInput: true
          inputType: InputUsable
          input:
            use: 1
            text:
              text: ""
              type: text/plain
            dataSource:
              columnName: runtimeData_path
        tests:
        - $type: RESTClientToolTest
          name: 13 DELETE coverage by id 404
          reportingSettings:
            requirementsTracking:
              comment: "DELETE /coverage/{id} - not found branch, using a well-formed\
                \ but nonexistent session ID."
          testID: 560
          tool:
            $type: RESTClient
            iconName: RESTClient
            name: __default__ was not found
            outputTools:
            - $type: GenericAssertionTool
              iconName: XMLAssertor
              name: JSON Assertor
              wrappedTool:
                $type: XMLAssertionTool
                iconName: XMLAssertor
                name: XML Assertor
                errorsOutput:
                  name: Errors
                assertions:
                - $type: StringComparisonAssertion
                  timestamp: 1789639650717
                  name: messageCode
                  extractEntireElement: true
                  Assertion_XPath: /root/messageCode/string()
                  value:
                    name: String Comparison Assertion
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: 307
                - $type: StringComparisonAssertion
                  timestamp: 1789639663775
                  name: message
                  extractEntireElement: true
                  Assertion_XPath: /root/message/string()
                  value:
                    name: String Comparison Assertion
                    value:
                      fixedValue:
                        $type: StringTestValue
                        value: Cannot delete coverage because user '__default__' is
                          not found
                message:
                  $type: ExpectedXMLMessage
                  message: true
              conversionStrategy:
                dataFormatName: JSON
                conversionStrategyId: JSON
                conversionStrategyClassName: com.parasoft.xml.convert.json.JsonConversionStrategy
            formJson:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :root
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  attributes:
                  - replacedColumn: ""
                    value:
                      $type: StringValue
                      replacedColumn: ""
                      value: object
                    useValue: true
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
              elementTypeName: root
            hasServiceInfo: true
            serviceInfo:
              serviceDescriptor:
                $type: StandardServiceDescriptor
                location: http://localhost:8050/openapi.yml
            jsonBuilder:
              hasValue: true
              value:
                $type: JSONObjectValue
                nameIsNull: true
            schemaURL:
              MessagingClient_SchemaLocation: "${OpenAPI}"
            formInput:
              value:
                $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: ":"
                replacedColumn: ""
                values:
                - $type: ComplexValue
                  replacedColumn: ""
                  compositorValue: true
                  compositorValueObj:
                    replacedColumn: ""
                    values:
                      $type: CompositorValueSetCollectionSet
                      set:
                      - $type: CompositorValueSet
            jmsMessageOutputProvider:
              $type: JMSMessageOutputProvider
              jmsOutputProviderRequest:
                $type: JMSOutputProvider
                name: Request Object
                menuName: Object
              jmsOutputProviderResponse:
                $type: JMSOutputProvider
                name: Response Message Object
                menuName: Message Object
            validResponseRange:
              validResponseRange:
                values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  validResponseRange: 404
            router:
              values:
              - $type: ScriptedValue
              fixedValue:
                $type: StringTestValue
                HTTPClient_Endpoint: http://localhost:8050/coverage/runtime_coverage_00000000_0000_0
            transportProperties:
              manager:
                protocol: 1
                properties:
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: DELETE
                  keepAlive1_1:
                    bool: true
                - $type: HTTPClientHTTPProperties
                  followRedirects:
                    bool: true
                  common:
                    method:
                      values:
                      - $type: ScriptedValue
                      fixedValue:
                        $type: HTTPMethodTestValue
                        method: DELETE
                  protocol: 1
                  keepAlive1_1:
                    bool: true
              messageExchangePattern:
                inverted: true
            outputProviders:
              requestHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Request Transport Header
              responseHeader:
                $type: HTTPNamedToolOutputProvider
                menuName: Transport Header
                name: Response Transport Header
              xmlRequestOutput:
                $type: NamedXMLToolOutputProvider
                menuName: Traffic
                name: Request Traffic
              trafficOutput:
                m_name: Traffic Stream
              objectOutput:
                $type: ObjectOutputProvider
                outputTools:
                - $type: TrafficViewer
                  iconName: TrafficViewer
                  name: Traffic Viewer
                name: Traffic Object
            formXML:
              doctype: ""
            literal:
              use: 1
              text:
                MessagingClient_LiteralMessage: ""
                type: application/json
              dataSource:
                columnName: session_id
            mode: Literal
            literalQuery:
              isPropertiesRef: true
            literalPath:
              pathElements:
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: coverage
              - values:
                - $type: ScriptedValue
                fixedValue:
                  $type: StringTestValue
                  value: runtime_coverage_00000000_0000_0
            constrainedPath:
              pathParameters:
              - $type: ElementValue
                writeType: true
                hasReference: true
                qnameAsString: :id
                replacedColumn: ""
                values:
                - $type: StringValue
                  replacedColumn: ""
                  value: runtime_coverage_00000000_0000_0
            resourceMethod:
              resourceId: "/coverage/{id}"
              httpMethod: DELETE
            resourceMode: 3
            baseUrl:
              values:
              - $type: ScriptedValue
              - $type: WadlTestValue
                value: http://localhost:8050
              fixedValue:
                $type: StringTestValue
                value: http://localhost:8050
              selectedIndex: 1
