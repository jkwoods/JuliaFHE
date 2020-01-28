include("Scheme.jl")
println("Running Tests")
println("Making Scheme")


lam     = 12
rho     = 26
eta     = 1988
gam     = 147456
Theta   = 150
alpha   = 936
tau     = 188
l       = 10

Encrypt, Decrypt, Recrypt, Add, Mult = Scheme.generate(lam,rho,eta,gam,Theta,alpha,tau,l)
println("Key Made")

one = [1,0,1,1,0,0,0,1,1,1]
zero = [0,0,0,0,0,1,1,1,0,0]

println("Encrypt")
c1 = Encrypt(one)
c0 = Encrypt(zero)

a = c1+c0

println("Decrypt")

dc1 = Decrypt(c1)
da = Decrypt(a)

println(dc1)
println(da)
