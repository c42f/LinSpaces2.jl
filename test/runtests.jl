using LinSpaces2
using Base.Test

# nextfloat-based start point in limited Float32 precision
x1,xN,N = 0.1f0, 1.0f0, 50
for i=1:1000000
    @test linspace2(x1,xN,N)[1] == x1
    @test linspace2(x1,xN,N)[N] == xN
    x1 = nextfloat(x1)
end


# Uniformly distributed endpoints
for i=1:1000000
    x1,xN,N = rand(), rand(), rand(2:10000)
    @test linspace2(x1,xN,N)[1] == x1
    @test linspace2(x1,xN,N)[N] == xN
end

# Log distributed endpoints
for i=1:1000000
    x1,xN,N = -log(rand()), -log(rand()), rand(2:10000)
    @test linspace2(x1,xN,N)[1] == x1
    @test linspace2(x1,xN,N)[N] == xN
end

