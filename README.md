# Varnames.jl

This package provides two types, `VarName` and `VarNamedTuple`, along with associated functionality.

These types were originally developed for use in Turing.jl, and the code is directly lifted from its dependencies.
However, they are general enough to be useful in other contexts and so have been extracted into a separate package.

## `VarName`

A `VarName`, most simply, is a data structure which represents an address which can be assigned to.
That is to say, it is a representation of an expression which can be used on the left-hand side of an assignment.
These include plain symbols (`x` and `y`), along with indexed expressions (`x[1]`), property accesses (`x.y`), and combinations thereof (`x[1].y`).

## `VarNamedTuple`

A `VarNamedTuple` is a mapping from `VarName`s to values.
They are more general than `NamedTuple`s in that they can contain `VarName`s which are not valid `Symbol`s, such as `x[1]` or `x.y`.
Unlike `Dict`s, `VarNamedTuple`s are designed to retain the relationship between sibling `VarName`s.
For example, you can store `x[1]` and `x[2]` in a `VarNamedTuple`, and then access `x[1:2]`, or even `x[:]` or `x` (as long as the `VarNamedTuple` knows that `x` is a length-2 vector).

`VarNamedTuple`s are also much more performant than `Dict`s, and in the case where only `Symbol`s are used, they have identical performance to `NamedTuple`s, making them a zero-cost abstraction.
