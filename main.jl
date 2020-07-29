include("Scheme.jl")
println("Running Tests")
println("Making Scheme")


function test()
    lam = 42
    rho = 26
    eta = 988
    gam = 290000
    Theta = 150
    alpha = 936
    tau = 188
    l = 10

    Encrypt, Decrypt, Recrypt, Add, Mult, KeyCorrect = Scheme.generate(lam,rho,eta,gam,Theta,alpha,tau,l)
    println("Key Time")
    @time Encrypt, Decrypt, Recrypt, Add, Mult, KeyCorrect = Scheme.generate(lam,rho,eta,gam,Theta,alpha,tau,l)

    a = rand(0:1,l)
    b = rand(0:1,l)

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
