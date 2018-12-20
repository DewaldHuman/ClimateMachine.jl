module ParametersType
using Unitful

export @parameter, ParametersType

"""
    Parameter{sym} <: Base.AbstractIrrational

Number type representing a constant parameter value denoted by the symbol `sym`.

!!! note

AbstractIrrational is used here inorder to inherit the behavior from the Base.
Parameters need not be Irrational numbers.

"""
struct Parameter{sym} <: Base.AbstractIrrational end

Base.show(io::IO, x::Parameter{S}) where {S} = print(io, "$(string(x))")

Base.:(==)(x::Parameter, y::Parameter) = (getval(x) == getval(y))
Base.:<(x::Parameter, y::Parameter) = (getval(x) < getval(y))
Base.:<=(x::Parameter, y::Parameter) = (getval(x) <= getval(y))
Base.hash(x::Parameter, h::UInt) = 3*objectid(x) - h
Base.widen(::Type{T}) where {T<:Parameter} = T
Base.round(x::Parameter, r::RoundingMode) = round(float(x), r)
getval() = nothing

"""
    @parameter sym val desc doexport=false
    @parameter(sym, val, desc, doexport-false)

Define a new `Parameter` value, `sym`, with value `val` and description string
`desc`. If `doexport == true` then `sym` is exported, e.g., the command
`export \$sym` is added
"""
macro parameter(sym, val, desc, doexport=false)
  esym = esc(sym)
  qsym = esc(Expr(:quote, sym))
  ev = @eval(__module__, $val)

  exportcmd = doexport ? :(export $sym) : ()

  quote
    $exportcmd
    const $esym = Parameter{$qsym}()
    Base.Float64(::Parameter{$qsym}) = $(Float64(ustrip(ev)))
    Base.Float32(::Parameter{$qsym}) = $(Float32(ustrip(ev)))
    Base.string(::Parameter{$qsym}) = $(string(ev))
    ParametersType.getval(::Parameter{$qsym}) = $(esc(ev))
    """
        $($qsym)

    $($desc)

    # Examples
    ```
    julia> $($qsym)
    $($(string(ev)))
    ```
    """
    $sym
  end
end

end
