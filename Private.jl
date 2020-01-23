module Private
import(Primes)
import(Random)
export mod_near, make_u, make_deltas, random_primes

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
