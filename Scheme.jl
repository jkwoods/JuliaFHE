
module Scheme
include("Private.jl")
export generate

function generate(lam,rho,eta,gam,Theta,alpha,tau,l)
    rhoi    = rho+lam
    alphai  = alpha+lam
    theta   = Theta÷l
    kap     = 64*(gam÷64+1)
    logl    = round(Int64,log(2,l))
    p       = rand((2^(eta-1):2^eta),l)
    pi      = reduce(*,p)

    q0      = 2^gam
    #TODO MAKE q0

    x0      = pi*q0
    x       = make_deltas()
    xi      = make_deltas()
    ii      = make_deltas()

    s       =
    rv_s    = transpose(s)

    u       = make_u()
    o       = make_deltas()

    Encrypt = function(m::Array)
        b   = rand((-2^alpha:2^self.alpha),tau)
        bi  = rand((-2^alphai:2^self.alphai),l)

        sum = reduce(+,(m .+ xi)) + reduce(+, (b .* x)) + reduce(+,(bi .* ii)) #TODO check if broadcasting is what we want here

        return mod_near(sum,x0)
    end

    Decrypt = function(c)
        [mod_near(c,p[i]) % 2 for i in 1:l]
    end

    Recrypt = function(c)
        -1
    end

    Add = function(a,b)
        (a+b) % x0
    end

    Mult = function(a,b)
        (a*b) % x0
    end


    end


    return Encrypt, Decrypt, Recrypt, Add, Mult



end





end
