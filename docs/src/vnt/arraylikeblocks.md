# [Array-like blocks](@id array-like-blocks)

In a number of VNT use cases, it is necessary to associate multiple indices in a `VarNamedTuple` with an object that is not necessarily the same number of elements.

Consider, for example, a case where `x[1:3]` has a `Dirichlet` prior.
With a `Dict{VarName,Distribution}`, we can do this:

!!! note
    We'll make a 'fake' Dirichlet struct here to avoid importing Distributions.

```@example 1
using Varnames

struct Dirichlet{T}
    α::Vector{T}
end

d = Dict{VarName,Dirichlet}(@varname(x[1:3]) => Dirichlet(ones(3)))
```

but we incur all the costs associated with the use of a `Dict`, as described before.

With a `VarNamedTuple`, we cannot store this directly:

```julia
vnt.data.x = some_array
vnt.data.x[1:3] = Dirichlet(ones(3))  # will error
```

because `Dirichlet` is not an array, and `setindex!` will fail.
Nor can we write

```julia
vnt.data.x = some_array
vnt.data.x[1:3] .= Dirichlet(ones(3))
```

because although this will not error, it is semantically different: this means that every element `x[1]`, `x[2]`, and `x[3]` will be assigned the same `Dirichlet(ones(3))` object, which is not what we want.

The current solution to this is to use `ArrayLikeBlock`s, which are thin wrappers around the actual value, but additionally also store the indices used to set the value.
The second and third arguments here are the indices (positional and keyword) used to set the value, and the fourth argument is the size of the block.

```@example 1
using Varnames: ArrayLikeBlock

alb = ArrayLikeBlock(Dirichlet(ones(3)), 1:3, (;), (3,))
```

We then set this `ArrayLikeBlock` in all the relevant indices.
The extra information in the `ArrayLikeBlock` allows us to forbid partial indexing into it later on.
In particular, we want to ensure that users can only retrieve the entire block at once, and not e.g. just `x[1]` or `x[2:3]`.

## Getting and setting: in practice

As a user you should not have to deal with `ArrayLikeBlock`s directly.
Under the hood, `templated_setindex!!` will automatically wrap values in `ArrayLikeBlock`s when necessary:

```@example 1
x = zeros(5)
vnt = templated_setindex!!(
    VarNamedTuple(), Dirichlet(ones(3)), @varname(x[1:3]), x
)
```

You can access the value again as long as you refer to the full range:

```@example 1
vnt[@varname(x[1:3])]
```

Because we provided template information, you can access this via any other combination of indexing, as long as it refers to all three indices:

```@example 1
vnt[@varname(x[begin:(end - 2)])]
```

However, if you try to access only part of the block, you will get an error:

```@repl 1
vnt[@varname(x[1])]
```

Furthermore, if you set a value into any of the indices covered by the block, the entire block is invalidated and thus removed:

```@example 1
struct Normal end # Again a fake struct to avoid importing Distributions.

vnt = templated_setindex!!(vnt, Normal(), @varname(x[2]), x)
```
