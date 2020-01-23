
module Scheme

export generate

function generate(x)






    Encrypt = function(m::Array)
        b   = rand((-2^alpha:2^self.alpha),tau)
        bi  = rand((-2^alphai:2^self.alphai),l)

        sum = reduce(+,(m .+ xi)) + reduce(+, (b .* x)) + reduce(+,(bi .* ii)) #TODO check if broadcasting is what we want here

        return modNear(sum,x0)
    end

    Decrypt = function(c)
        [modNear(c,p[i]) % 2 for i in 1:l]
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
