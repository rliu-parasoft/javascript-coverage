## parasoft-istanbul-lib-instrument

Parasoft fork of `istanbul-lib-instrument`.

This package provides the JavaScript instrumentation logic used by the integration module in
this repository. It is packaged as an npm tarball with the Parasoft package name and version, so
consumers can install it directly or reference it via npm overrides.

It provides 2 "modes" of instrumentation.

-   The old API that is mostly unchanged (except for incompatibilities noted) and
    performs the instrumentation using babel as a library.

-   A `programVisitor` function for the Babel AST that can be used by a Babel plugin
    to emit instrumentation for ES6 code directly without any source map
    processing. This is the preferred path for babel users. The Babel plugin is
    called `babel-plugin-istanbul`.

Behavior and implementation details are inherited from the upstream library unless otherwise
documented in this repository.
