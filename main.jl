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
