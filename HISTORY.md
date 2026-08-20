# 0.1.1

Added the `Draw` struct, which bundles a `VarNamedTuple` of parameter values with a `NamedTuple` of extra information, as well as the accessor functions `parameters` and `extras`.
This is intended to represent a single MCMC sample.

`Draw` is structurally the same as what used to be called `ParamsWithStats` in DynamicPPL.

# 0.1.0

Initial release.
This is a direct port of code from AbstractPPL and DynamicPPL, with one major change: `@vn` is now an alias for `@varname`, which is hopefully helpful since it gets used quite a lot.
