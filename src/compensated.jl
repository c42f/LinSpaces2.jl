module C

using Base.Test

# Error free transformations, as described in
# [LaLo05] "Solving Triangular Systems More Accurately and Efficiently", Ph. Langlois and N. Louvet
#
# Notation:
#
#    ⊕ ≡ floating point add
#    ⊖ ≡ floating point subtract
#    ⊗ ≡ floating point multiply
#    ⊘ ≡ floating point divide

function twosum{T<:AbstractFloat}(a::T, b::T)
    x = a+b
    z = x-a
    y = (a-(x-z)) + (b-z)
    (x,y)
end


# Split a floating point number into high and low bits
function split(a::Float64)
    z = a*134217729 #(2^27 + 1)
    x = z - (z-a)
    y = a - x
    (x,y)
end

function fast_split(a::Float64)
    ah = Float64(Float32(a))
    ah, a - ah
end

twoproduct(a,b) = twoproduct(promote(a,b)...)
function twoproduct{T}(a::T,b::T)
    x = a*b
    ah,al = split(a)
    bh,bl = split(b)
    y = al*bl - (((x - ah*bh) - al*bh) - ah*bl)
    (x,y)
end

approx_twoproduct(a,b) = approx_twoproduct(promote(a,b)...)
function approx_twoproduct{T}(a::T,b::T)
    x = a*b
    ah,al = fast_split(a)
    bh,bl = fast_split(b)
    y = al*bl - (((x - ah*bh) - al*bh) - ah*bl)
    (x,y)
end


function approxtwodiv(a,b)
    x = a/b
    v,w = twoproduct(x,b)
    y = (a-v-w)/b
    (x,y)
end


@testset "twosum" begin
    for i=1:1000
        a,b = rand(2)
        x,y = twosum(a,b)

        @test abs(y) < eps(x)
        @test big(a)+big(b) == big(x)+big(y)
    end
end


@testset "twoproduct" begin
    for i=1:1000
        a,b = rand(2)
        x,y = twoproduct(a,b)

        @test abs(y) < eps(x)
        @test big(a)*big(b) == big(x)+big(y)
    end
end

@testset "approxtwodiv" begin
    for i=1:1000
        a,b = rand(2)
        x,y = approxtwodiv(a,b)

        @test abs(y) < eps(x)
        @test abs(big(a)/big(b) - (big(x)+big(y))) < max(eps(a),eps(b))
    end
end


# Want correctly rounded version of
#
#   a * (N-i)/(N-1) + b * (i-1)/(N-1)
#
# Rearrange:
#
# (Ah + Al) * (N-i) + (Bh + Bl) * (i-1)
#
#   R ≡ c + (Mh + Ml) * i
#
#   We have:
#
#       abs(Ml) < eps(Mh) ⇒ abs(Ml⊗i) < 2*eps(Mh⊗i)
#       ... FIXME
#
#   xh,xl = twoproduct(Mh, i)
#   y = xl + Ml*i
#   zh,zl = twosum(c, xh)
#
#

immutable LinSpace{T} <: Range{T}
    a::T
    b::T
    c::T
    Mh::T
    Ml::T
    N::Int
end

macro myshow(ex)
    s = string(ex)
    quote
        println($s * " = " * string(map(x->@sprintf("%a",x), $(esc(ex)))))
    end
end

function LinSpace{T<:AbstractFloat}(a::T,b::T,N::Integer)
    M = (big(b) - big(a)) / (N-1)
    Mh = Float64(M)
    Ml = Float64(M - Mh)
    #@myshow Mh,Ml
    #=
    if abs(a) < abs(b)
        a,b = b,a
    end
    =#
    LinSpace(a,b, a, Mh, Ml, N)
end

LinSpace{T}(a::T,b::T,N) = LinSpace(promote(float(a),float(b))..., N)

Base.size(L::LinSpace) = (L.N,)
Base.linearindexing(L::LinSpace) = Base.LinearFast()

function Base.getindex(L::LinSpace, i::Int)
    # xh+xl = Mh*i
    # yh+yl = Ml*i
    # zh+zl ≈ (Mh+Ml)*(i-1)
    # rh+rl = c + zh
    xh,xl = twoproduct(L.Mh, i-1)
    yh,yl = twoproduct(L.Ml, i-1)
    zh,zl = xh, xl + yh
    rh,rl = twosum(L.c, zh)

    rh + (rl + zl)
    #=
    xl += L.Ml*i
    zh,zl = twosum(L.c, xh)
    zl += xl
    zh + zl
    =#
end

Base.step(L::LinSpace) = L.Mh

function bigindex(L::LinSpace, i::Int)
    big(L.a)*(big(L.N-i)/(L.N-1)) + big(L.b)*(big(i-1)/(L.N-1))
end


function verify(a, b, N, L)
    for i= 1:N
        x = bigindex(L, i)
        d = L[i] - Float64(x)
        if d != 0
            # @show (x - Float64(x))/eps(Float64(x))
            return L, i
        end
    end
    return nothing
end

badly_rounded_cases = []
for i=1:1000
    a = rand()
    b = rand()
    N = rand(1:10000)
    ret = verify(a,b,N, LinSpace(a,b,N))
    if ret !== nothing
        println("(LinSpace($a, $b, $N), $(ret[2]))")
        push!(badly_rounded_cases, ret)
    end
end

L,i = badly_rounded_cases[1]
@myshow bigindex(L,i)
@myshow L[i] - bigindex(L,i)


#=
pf(x) = @printf("%a\n", x)

# Float64 - 53 bits significand
# Float32 - 24 bits significand

a = 0x1.1111111111111p0
b = 0x1.1111111111111p0

af = Float64(Float32(a))
bf = Float64(Float32(b))
ar = a - af
br = b - bf

m  = af*bf # exact
mr = af*ar + bf*br + ar*br # approximate, but with extra bits

#pf(m)
#pf(mr)

@show BigFloat(a) * BigFloat(b)
@show BigFloat(m) + BigFloat(mr)
=#


end

L = C.L
