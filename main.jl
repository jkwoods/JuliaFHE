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
zero = [0,0,0,0,0,0,1,0,0,0]

println("Encrypt")
c1 = Encrypt(one)
c0 = Encrypt(zero)
#cb = Encrypt(br)

println(Decrypt(c1))
println(Decrypt(c0))

#Decrypt_sq(c0)

println(Decrypt(Recrypt(c1)))
println(Decrypt(Recrypt(c0)))

a = Mult(c1,c0)
println(Decrypt(a))

a = Recrypt(a)
println(Decrypt(a))

b = Add(c1,c0)
println(Decrypt(b))

b = Recrypt(b)
println(Decrypt(b))

#=
a = Mult(c1,a)
println(Decrypt(a))

b = Mult(a,c1)
println(Decrypt(b))

a = Recrypt(a)
println(Decrypt(a))

g = Mult(a,c1)
println(Decrypt(g))

g = Recrypt(g)
println(Decrypt(g))=#

function test()
    lam = 52
    rho = 41
    eta = 1558
    gam = 1600000
    Theta = 555
    alpha = 1476
    tau = 661
    l = 37

    Encrypt, Decrypt, Recrypt, Add, Mult, KeyCorrect = Scheme.generate(lam,rho,eta,gam,Theta,alpha,tau,l)
    println("Key Time")
    @time Encrypt, Decrypt, Recrypt, Add, Mult, KeyCorrect = Scheme.generate(lam,rho,eta,gam,Theta,alpha,tau,l)

    a = [0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0]
    b = [0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0]
    ca = Encrypt(a)
    println("Encrypt Time")
    @time cb = Encrypt(b)

    Decrypt(ca)
    println("Decrypt Time")
    @time Decrypt(cb)

    ra = Recrypt(ca)
    println("Recrypt Time")
    @time rb = Recrypt(cb)


end

test()
