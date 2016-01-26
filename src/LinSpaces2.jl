module LinSpaces2

export linspace2

import Base:
    getindex, unsafe_getindex, length,
    isempty, step,
    first, last, start, done, next

immutable LinSpace2{T<:AbstractFloat} <: Range{T}
    _start::T
    _stop::T
    len::T
    mult::T
end

function linspace2{T<:AbstractFloat}(start::T, stop::T, len::T)
    # Setup.  TODO: Need to copy some additional sanity checks from the real
    # LinSpace here.
    N1 = len-1
    mult = 1/N1
    # Compute values at ends according to formula used in getindex().
    # Unfortunately it's possible to have N1*mult == prevfloat(one(T))
    # in addition to the expected N1*mult == 1.  In IEEE round-to-nearest mode,
    # we can prove that these are the only possibilites and that optionally
    # modifying the stored end points by 1ulp is enough to bring the *computed*
    # end points back to the desired values.
    _start = N1*mult*start == start ? start : nextfloat(start)
    _stop  = N1*mult*stop  == stop  ? stop  : nextfloat(stop)

    LinSpace2(_start, _stop, len, mult)
end

function linspace2{T<:AbstractFloat}(start::T, stop::T, len::Real)
    T_len = convert(T, len)
    T_len == len || throw(InexactError())
    linspace2(start, stop, T_len)
end
linspace2(start::Real, stop::Real, len::Real=50) =
    linspace2(promote(AbstractFloat(start), AbstractFloat(stop))..., len)


@inline getindex{T}(r::LinSpace2{T}, i::Integer) = (checkbounds(r, i); unsafe_getindex(r, i))
@inline unsafe_getindex{T}(r::LinSpace2{T}, i::Integer) =
    (r.len-i)*r.mult*r._start + (i-1)*r.mult*r._stop

isempty{T}(r::LinSpace2{T}) = length(r) == 0

step{T}(r::LinSpace2{T}) = (r._stop - r._start)*r.mult

length{T}(r::LinSpace2{T}) = Integer(r.len + signbit(r.len - 1))

first{T}(r::LinSpace2{T}) = unsafe_getindex(r,1)
last{T}(r::LinSpace2{T}) = unsafe_getindex(r,r.len)

start{T}(r::LinSpace2{T}) = 1
done{T}(r::LinSpace2{T}, i::Int) = length(r) < i
@inline next{T}(r::LinSpace2{T}, i::Int) = (unsafe_getindex(r,i), i+1)


end # module
