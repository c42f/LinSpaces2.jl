using LinSpaces2

function bench_fill(N, L)
    B = zeros(Float64, length(L))
    for i=1:N
        for j=1:length(L)
            B[j] = L[j]
        end
    end
end

function bench_collect(N, L)
    for i=1:N
        collect(L)
    end
end

function bench_sum(N, L)
    s = 0.0
    for i=1:N
        for j=1:length(L)
            s += L[j]
        end
        s /= length(L)
    end
    s
end

function bench_simd_sum(L)
    s = zero(eltype(L))
    @inbounds @simd for x in L
        s += x
    end
    s
end

L1 = linspace(0.0, 100000.0, 100000)
L2 = linspace2(0.0, 100000.0, 100000)
N = 100

println("bench_fill")
bench_fill(1, L1)
bench_fill(1, L2)
@time bench_fill(N, L1)
@time bench_fill(N, L2)

println("bench_sum")
bench_sum(1, L1)
bench_sum(1, L2)
@time bench_sum(N, L1)
@time bench_sum(N, L2)

println("bench_collect")
bench_collect(1, L1)
bench_collect(1, L2)
@time bench_collect(N, L1)
@time bench_collect(N, L2)

println("bench_simd_sum")
bench_simd_sum(linspace(1,5,10^7))
bench_simd_sum(linspace2(1,5,10^7))
@time bench_simd_sum(linspace(1,5,10^7))
@time bench_simd_sum(linspace2(1,5,10^7))

function bench_mult_sum(N, L)
    a = first(L)
    b = last(L)
    len = length(L)
    mult = Float64(1/(N-1))
    s = 0.0
    for i=1:N
        for j=1:length(L)
            l = (len-j)*mult*a + (j-1)*mult*b
            s += l
        end
        s /= length(L)
    end
    s
end

function bench_div_sum(N, L)
    a = first(L)
    b = last(L)
    len = length(L)
    divisor = Float64(N-1.0)
    s = 0.0
    for i=1:N
        for j=1:length(L)
            l = ((len-j)*a + (j-1)*b)/divisor
            s += l
        end
        s /= length(L)
    end
    s
end

println("bench_div_sum & bench_mult_sum")
bench_div_sum(1, L1)
bench_mult_sum(1, L1)
@time bench_div_sum(N, L1)
@time bench_mult_sum(N, L1)


