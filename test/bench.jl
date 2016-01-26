using LinSpaces2

function bench_fill(N, linspc)
    B = zeros(Float64, length(linspc))
    for i=1:N
        for j=1:length(linspc)
            B[j] = linspc[j]
        end
    end
end

function bench_collect(N, linspc)
    for i=1:N
        collect(linspc)
    end
end

function bench_sum(N, linspc)
    s = 0.0
    for i=1:N
        for j=1:length(linspc)
            s += linspc[j]
        end
        s /= length(linspc)
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


function bench_mult_sum(N, linspc)
    a = first(linspc)
    b = last(linspc)
    len = length(linspc)
    mult = Float64(1/(N-1))
    s = 0.0
    for i=1:N
        for j=1:length(linspc)
            l = (len-j)*mult*a + (j-1)*mult*b
            s += l
        end
        s /= length(linspc)
    end
    s
end

function bench_div_sum(N, linspc)
    a = first(linspc)
    b = last(linspc)
    len = length(linspc)
    divisor = Float64(N-1.0)
    s = 0.0
    for i=1:N
        for j=1:length(linspc)
            l = ((len-j)*a + (j-1)*b)/divisor
            s += l
        end
        s /= length(linspc)
    end
    s
end

println("bench_div_sum & bench_mult_sum")
bench_div_sum(1, L1)
bench_mult_sum(1, L1)
@time bench_div_sum(N, L1)
@time bench_mult_sum(N, L1)


