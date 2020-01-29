include("Scheme.jl")
println("Running Tests")
println("Making Scheme")


lam     = 12
rho     = 26
eta     = 1988
gam     = 147456
Theta   = 150
alpha   = 936
tau     = 412
l       = 10

Encrypt, Decrypt, Recrypt, Add, Mult, KeyCorrect = Scheme.generate(lam,rho,eta,gam,Theta,alpha,tau,l)
println("Key Made")

println(KeyCorrect())

one  = [1,1,1,1,1,1,1,1,1,1]
zero = [0,1,1,0,0,1,1,1,0,0]
br =   [1,1,1,1,0,0,0,1,1,0]

println("Encrypt")
c1 = Encrypt(one)
c0 = Encrypt(zero)
cb = Encrypt(br)

a = Mult(c1,c0)
println(Decrypt(a))

b = Mult(a,c1)
println(Decrypt(b))

a = Recrypt(a)
println(Decrypt(a))

b = Mult(a,c1)
println(Decrypt(b))
