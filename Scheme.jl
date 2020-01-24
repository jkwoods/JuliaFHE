
module Scheme
    import(Random)
    import(Primes)
    export generate

    #TODO make sure types are not being converted/this is still (relatively) fast
    function generate(lam,rho,eta,gam,Theta,alpha,tau,l)
        rhoi    = rho+lam
        alphai  = alpha+lam
        theta   = Theta÷l
        kap     = 64*(gam÷64+1)
        logl    = round(Int64,log(2,l))
        p       = [big(rand(2^(eta-1):2^eta)) for i=1:l]
        pi      = reduce(*,p)

        q0      = 2^big(gam)
        measure = q0÷pi
        prime_gen = random_primes(0,2^(lam^2))
        while q0 > measure
            q0prime1 = prime_gen()
            q0prime2 = prime_gen()
            q0 = q0prime1*q0prime2
        end

        x0      = pi*q0

        e_range = (2^(lam+logl+(l*eta))) ÷ pi
        x       = make_deltas(tau,x0,(rhoi+1),rhoi,e_range,l,p,pi,rv_s,0)
        xi      = make_deltas(l,x0,rho,rhoi,e_range,l,p,pi,rv_s,1)
        ii      = make_deltas(l,x0,rho,rhoi,e_range,l,p,pi,rv_s,2)

        s       = zeros(Int64,l,Theta)
        for i=1:l
            s[i,i] = 1
        end
        for t=1:(theta-1)
            shuffled = Random.shuffle([i for i=1:l])
            for j=1:l
                k = (l*t)+shuffled[j]
                s[j,k] = 1;
            end
        end

        rv_s    = transpose(s)

        u       = make_u(p,l,Theta,kap)
        o       = make_deltas(Theta,x0,rho,rhoi,e_range,l,p,pi,rv_s,3)

        Encrypt = function(m)
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

        return Encrypt, Decrypt, Recrypt, Add, Mult

    end


    #HELPER
    function mod_near(a,b)
        quotient_near = (2*a+b)÷(2*b)
        return a-b*quotient_near
    end

    function kd(i,j)
        if i==j
            return 1
        else
            return 0
        end
    end

    function mul_inv(a,b)
        b0 = b
        x0, x1 = 0, 1
        if b == 1
            return 1
        end
        while a > 1
            q = a ÷ b
            a, b = b, (a % b)
            x0, x1 = (x1 - q * x0), x0
        end
        if x1 < 0
            x1 += b0
        end
        return x1
    end

    function CRT(pi,n,a) #Chinese Remainder Thm
        sum = reduce(+, [a[i] * mul_inv(p,n[i]) * (pi ÷ n[i]) for i=1:length(n)])
        return sum % pi
    end

    function make_u(p,l,Theta,kap)
        kapsq = 2^(kap+1)

        seed = time() #TODO better seed
        u_draft = pseudo_random_ints(seed,Theta,kapsq)

        for j=1:l
            xpj = (2^kap)÷p[j]  #TODO correct div? need floor?
            u_mults = [s[j,i]*u[i] for i=1:Theta]
            u_sum = reduce(+, u_mults) % kapsq

            while u_sum != xpj
                #pick random index
                v = rand(1:l) #this is done differently than before, make sure ok

                #change corresponding using
                u_mults[v] = 0
                v_sum = reduce(+, u_mults)
                new_u = kapsq - v_sum + xpj
                while new_u < 0
                    new_u += kapsq
                end
                while new_u >= kapsq
                    new_u -= kapsq
                end

                u_draft[v] = new_u

                #redo for while check
                u_mults = [s[j,i]*u[i] for i=1:Theta]
                u_sum = reduce(+, u_mults) % kapsq
            end
        end
        return u_draft
    end

    function make_deltas(len,x0,var_rho,rhoi,e_range,l,p,pi,rv_s,switch)
        #make PRI
        seed = time() #TODO better seed
        Chi = pseudo_random_ints(seed,len,x0)

        #make deltas
        r = rand(((-2)^(var_rho+1):2^var_rho),len,l)
        E = rand((0:e_range),len)
        twor = r .* 2

        if switch == 0
            crts = [CRT(pi,p,twor) for j=1:len]
        elseif switch == 1
            crts = [CRT(pi,p,[twor[i]+kd(i,j) for i=1:l]) for j=1:len]
        elseif switch == 2
            rhoisq = 2^(rhoi+1)
            crts = [CRT(pi,p,[twor[i]+(kd(i,j)*rhoisq) for i=1:l]) for j=1:len]
        else #o
            crts = [CRT(pi,p,[twor[i]+rv_s[j,i] for i=1:l]) for j=1:len]
        end

        temp = Chi .% pi #check if we can condense
        deltas = temp .+ (E .* pi) .-crts

        #make the list of PRI - deltas
        x = Chi .- deltas
        return x
    end

    function pseudo_random_ints(seed,len,range)
        new_rand = Random.MersenneTwister(seed)
        return rand(new_rand, 1:range, len)
    end

    function random_primes(lo,hi)
        list = Primes.primes(lo,hi)
        function p()
            list[rand(1:length(list))]
        end
        return p
    end

end
