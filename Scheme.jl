
module Scheme
import(Random)
import(Primes)
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
    measure = 100#(2^gam)÷pi
    prime_gen = random_primes(0,2^(lam^2))
    while q0 > measure
        q0prime1 = prime_gen()
        q0prime2 = prime_gen()
        q0 = q0prime1*q0prime2
    end

    x0      = pi*q0
    x       = make_deltas()
    xi      = make_deltas()
    ii      = make_deltas()

    s       = zeros(Int64,l,Theta)
    for i=1:l
        s[i,i] = 1
    end
    for t=2:theta
        shuffled = Random.shuffle([i for i=1:l])
        for j=1:l
            k = (l*t)+shuffled[i]
            s[j,k] = 1;
    end

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

#HELPER
function mod_near(a,b)
    quotient_near = (2*a+b)÷(2*b)
    return a-b*quotient_near
end

function make_u()


end

function make_deltas()


end

function random_primes(lo,hi)
    list = Primes.primes(lo,hi)
    function p()
        list[rand(1:length(list))]
    end
    return p
end







end
