
module Scheme
    import(Random)
    import(Primes)
    export generate

    #TODO make sure types are not being converted/this is still (relatively) fast
    #TODO put pri stuff in the right places, etc

    function generate(p_lam,p_rho,p_eta,p_gam,p_Theta,p_alpha,p_tau,p_l)
        lam::BigInt     = p_lam
        rho::BigInt     = p_rho
        eta::BigInt     = p_eta
        gam::BigInt     = p_gam
        Theta::Int64    = p_Theta
        alpha::BigInt   = p_alpha
        tau::Int64      = p_tau
        l::Int64        = p_l
        n::Int64        = 4

        rhoi::BigInt         = rho+lam
        alphai::BigInt       = alpha+lam
        theta::Int64         = Theta÷l
        kap::BigInt          = 64*(gam÷64+1)
        logl::Int64          = round(Int64,log(2,l))
        p_gen                = list()
        p::Array{BigInt,1}   = [p_gen() for i=1:l]
        pi::BigInt           = reduce(*,p)

        q0::BigInt           = 2^gam
        measure::BigInt      = fld(q0,pi)
        while q0 > measure
            q0prime1::BigInt = random_prime(0,2^(lam^2))
            q0prime2::BigInt = random_prime(0,2^(lam^2))
            q0               = q0prime1*q0prime2
        end

        x0::BigInt           = pi*q0

        s::Array{Int64,2}    = zeros(Int64,l,Theta)
        for i=1:l
            s[i,i] = 1
        end
        for t=1:(theta-1)
            shuffled::Array{Int64,1} = Random.shuffle([i for i=1:l])
            for j=1:l
                k = (l*t)+shuffled[j]
                s[j,k] = 1;
            end
        end

        e_range::BigInt      = fld(2^(lam+logl+(l*eta)),pi) #-1

        x::Array{BigInt,1}   = make_deltas(tau,x0,(rhoi-1),rhoi,e_range,l,p,pi,s,0)
        xi::Array{BigInt,1}  = make_deltas(l,x0,rho,rhoi,e_range,l,p,pi,s,1)
        ii::Array{BigInt,1}  = make_deltas(l,x0,rho,rhoi,e_range,l,p,pi,s,2)

        u::Array{BigInt,1}   = make_u(p,l,Theta,kap,s)
        o::Array{BigInt,1}   = make_deltas(Theta,x0,rho,rhoi,e_range,l,p,pi,s,3)

        Encrypt = function(m::Array{Int64,1})
            b::Array{BigInt,1}   = rand((-(2^alpha)+1:2^alpha),tau)
            bi::Array{BigInt,1}  = rand((-(2^alphai)+1:2^alphai),l)

            sum::BigInt = reduce(+,(m .* xi)) + reduce(+, (b .* x)) + reduce(+,(bi .* ii)) #TODO check if broadcasting is what we want here

            return mod_near(sum,x0)
        end

        Decrypt = function(c::BigInt)
            [mod(mod_near(c,p[i]),2) for i in 1:l]
        end

        Decrypt_sq = function(c::BigInt)
            #expand
            z::Array{Float64,1} = zeros(Int64,Theta)
            kap2::BigInt = 2^kap

            for i=1:Theta
                yi = u[i]//kap2
                zi = c * yi
                zim = mod(zi,2)

                #multiply by 2^n bits of precision
                zi_int::Int64 = Base.trunc(Int64, zim*(2^(n+1)))

                zi_flt::Float64 = zi_int / (2^(n+1))

                z[i] = zi_flt
            end

            m::Array{} = [mod(round(sum([s[j,i]*z[i] for i=1:Theta])),2) + mod(c,2) for j=1:l]
            println(m)

            return m

        end

        Recrypt = function(c::BigInt)
            #expand
            z::Array{Int64,2} = zeros(Int64,Theta,n+1)
            kap2::BigInt = 2^kap

            for i=1:Theta
                yi = u[i]//kap2
                zi = c * yi
                zim = mod(zi,2)

                #multiply by 2^n bits of precision
                zi_int::Int64 = Base.trunc(Int64, zim*(2^n)) #TODO THIS IS THE PROBLEM FIX IT - bits of precision are too low

                zi_bin::Array{Int64,1} = to_binary(zi_int, (n+1))
                #println(zi_bin)

                z[i,:] = zi_bin
            end

            z_sk::Array{BigInt,2} = [z[i,j]*o[i] for i=1:Theta, j=1:(n+1)]

            TEMP::Array{Array{Int64,1},2} = [Decrypt(z_sk[i,j]) for i=1:Theta, j=1:(n+1)]
#=
            for i=1:Theta
                print(z[i,:])
                for j=1:(n+1)
                    print(findall(x->x==1, TEMP[i,j]))
                end
                print("s =", s[:,i])
                print("\n\n\n")
            end =#

            a::Array{BigInt,1} = zeros(Int64,n+1)
            #print(z)


            for i=1:Theta
                #println(z[i,:])
                #print("s =", s[:,i])
                a = sum_binary(a,z_sk[i,:])
                #println([Decrypt(a[i]) for i=1:(n+1)],"\n")
                #println("\n\n")
            end


            round::BigInt = a[length(a)] + a[length(a)-1] + (c & 1)

            return round

        end

        Add = function(a::BigInt,b::BigInt)
            mod(a+b,x0)
        end

        Mult = function(a::BigInt,b::BigInt)
            mod(a*b,x0)
        end

        KeyCorrect = function()
            a = rho >= 2*lam #brute force noise attack
            if !a
                println("rho >= ", 2*lam)
            end
            b = eta >= alphai + rhoi + 2 + logl #correct decryption
            if !b
                println("eta >= ", alphai + rhoi + 2 + logl)
            end
            c = eta >= rho * (lam*(log(lam)^2)) #squashed decryption circuit
            if !c
                println("eta >= ", rho * (lam*(log(lam)^2)))
            end
            #d = gamma lattice attacks
            e = alpha * tau >= gam + lam
            if !e
                println("alpha * tau >= ", gam + lam)
            end
            f = tau >= l * (rhoi+2) + lam
            if !f
                println("tau >= ", l * (rhoi+2) + lam)
            end
            return a & b & c & e & f
        end

        return Encrypt, Decrypt, Decrypt_sq, Recrypt, Add, Mult, KeyCorrect

    end


    #HELPER
    function mod_near(a::BigInt,b::BigInt)
        quotient_near::BigInt = fld((2*a+b),(2*b))
        ans::BigInt = a-b*quotient_near
        return ans
    end

    function to_binary(a::Int64, bits::Int64) #[0,1,...,n] = [LSB, ... MSB]
        str = split(bitstring(a),"")
        result::Array{Int64,1} = [parse(Int64, str[length(str)-i]) for i=0:(bits-1)]
        return result
    end

    function sum_binary(a::Array{BigInt,1}, b::Array{BigInt,1})
        c::Array{BigInt,1} = zeros(BigInt, length(a))

        c[1] = a[1]+b[1]
        carry::BigInt = a[1]*b[1]

        for i=2:(length(a)-1)
            carry2 = (a[i]+b[i])*carry+a[i]*b[i]
            c[i] = a[i]+b[i]+carry
            carry = carry2
        end
        c[length(a)] = a[length(a)]+b[length(a)]+carry
        return c
    end

    function kd(i,j)
        if i==j
            return 1::Int64
        else
            return 0::Int64
        end
    end

    function mul_inv(a::BigInt,b::BigInt)
        b0::BigInt = b
        x0::BigInt, x1::BigInt = 0, 1
        if b == 1
            return 1
        end
        while a > 1
            q::BigInt = fld(a,b)
            a, b = b, mod(a,b)
            x0, x1 = (x1 - q * x0), x0
        end
        if x1 < 0
            x1 += b0
        end
        return x1
    end

    function CRT(pi::BigInt,n::Array{BigInt,1},a::Array{BigInt,1}) #Chinese Remainder Thm
        sum::BigInt = 0
        #prod = pi
        for i=1:length(n)
            p::BigInt = fld(pi,n[i])
            sum += a[i] * mul_inv(p,n[i]) * p
        end
        return mod(sum,pi)
    end

    function make_u(p::Array{BigInt,1},l::Int64,Theta::Int64,kap::BigInt,s::Array{Int64,2})
        kapsq::BigInt = 2^(kap+1)

        seed = time() #TODO better seed
        u::Array{BigInt,1} = pseudo_random_ints(seed,Theta,kapsq)

        for j=1:l
            xpj::BigInt = fld((2^kap),p[j])
            u_mults::Array{BigInt,1} = [s[j,i]*u[i] for i=1:Theta]
            u_sum::BigInt = mod(reduce(+, u_mults),kapsq)

            indicies = findall(x->x==1, s[j,:])

            while u_sum != xpj
                #pick random index
                v = indicies[1]

                #change corresponding using
                u_mults[v] = 0
                v_sum::BigInt = reduce(+, u_mults)
                new_u::BigInt = kapsq - v_sum + xpj
                while new_u < 0
                    new_u += kapsq
                end
                while new_u >= kapsq
                    new_u -= kapsq
                end

                u[v] = new_u

                #redo for while check
                u_mults = [s[j,i]*u[i] for i=1:Theta]
                u_sum = mod(reduce(+, u_mults),kapsq)
            end
        end
        return u
    end

    function make_deltas(len::Int64,x0::BigInt,var_rho::BigInt,rhoi::BigInt,e_range::BigInt,l::Int64,p::Array{BigInt,1},pi::BigInt,s::Array{Int64,2},switch::Int64)
        #make PRI
        seed = time() #TODO better seed
        Chi::Array{BigInt,1} = pseudo_random_ints(seed,len,x0)

        #make deltas
        r::Array{BigInt,2} = rand((-(2^var_rho)+1:(2^var_rho)-1),len,l)
        E::Array{BigInt,1} = rand((1:e_range),len)
        twor::Array{BigInt,2} = r .* 2

        crts::Array{BigInt,1} = zeros(BigInt,len)
        if switch == 0
            crts = [CRT(pi,p,twor[i,:]) for i=1:len]
        elseif switch == 1
            crts = [CRT(pi,p,[twor[i,j]+kd(i,j) for j=1:l]) for i=1:len]
        elseif switch == 2
            rhoisq::BigInt = 2^(rhoi+1)
            crts = [CRT(pi,p,[twor[i,j]+(kd(i,j)*rhoisq) for j=1:l]) for i=1:len]
        else #o
            crts = [CRT(pi,p,[twor[i,j]+s[j,i] for j=1:l]) for i=1:len]
        end

        temp::Array{BigInt,1} = [mod(Chi[i],pi) for i=1:len] #Chi .% pi #check if we can condense
        deltas::Array{BigInt,1} = temp .+ (E .* pi) .- crts

        #make the list of PRI - deltas
        x::Array{BigInt,1} = Chi .- deltas
        return x
    end

    function pseudo_random_ints(seed,len::Int64,range::BigInt)
        #seed!(seed) TODO
        return rand(1:range, len)
    end

    function random_prime(lo,hi::BigInt)
        possible::BigInt = rand((lo+1):hi)
        while !Primes.isprime(possible)
            possible = rand(lo:hi)
        end
        return possible
    end

    function list()
        list::Array{BigInt,1} = [16967745967382654577261305657625288750375494148422602908032714381312669064079352590762281296177971479066170484247003411689064407320234400571036970984379939588153259355675390483332872944575327486922834037928412073655893073959875426852319912777249049392754751703057842073192457780913092426031454330969492240615520203911106955441720090114932372172172330791541235646783101316764062611956267080916217585458564655979326751121443695386026398938510635990058889814010247395414452179394010300211292550856183810203454968435815004167822117265858944089650006022877342701582312158207402604478930986713842997154663, 18735477134858935502090299044086560015269297217262314351933352000514954465330016031201222798054663761054531051346881988054037176062505758558832904305513192970506391795712019625828284073515875166670215223087404649280957985361781720336188908450953560525164625362249173587694351641061379999297261795105917874598351926846781192969013089371879149676006966505861053709007874401672508031498984622857807881450699388006916988476870955199767882022417045895245030406172732257743636290323459188250458622381346277861661521028758869666192392522215831717555005415202390604039645675950630773635805435412100460394841, 14627680411197166077311085787198783424365172673207461931687980299472635223725811289563370640117344452426982417608701704967620602447496048640806462916000555000392161516670946617277712636839420937845871781435803714347265823015671234545568289651104562598012593159589732540613035088499946639280302190595752229959281003303917255675268778408099515698618015593815315090070144936051883703967176025380925935440540122403367767271898480096539547743591134655385727276259397244653866486730451541517894677351643783030121312609721659134601177324728934598268801394778520439984783922987795500074722561431327940464643, 27068620903121640137551008440641930817676406475163111869970117118128185704006217480894072928057530455815375888384222818803971975071737594551075636334938694071172179324846776317985823065819240359141190571447951296463402672777158789315577161367375251238457029428385564438713194651166538174203893012021030284808698880751080744196836327970873721345699954694473076062807589023557420052721194426014444127927462570991873308003992652327405238360769351667432807688801954764784436879506429532061359439096578671340781781734196472604379746167228118990720723569800245522534582106191122718360748095196755011673623, 14369468774890567367076228048321855171243363336964590682237714439179639827216091962650320784087770854768316020962590417226608676425138277612482757741960653019977717697404157590858587791130399462400771902221510489215924329290168050853975711252401378005502231139394146019152261715260855607197797825394621604127228446091008475630350459877038184014276384295682281061752740041353541608113324259688945906254619783239296130627431019462567103657694986325244366149199669736845050557417732145423404325808166674809379480790745444612209368824439464374599950516284627749258878445410865620883950496329404020274453, 19183063301583426200567932366848018202320161233485145813675226962914695249496238212930326207887940058237381062853920442501278571937408380185343579670168895303563704851251389781779963128755249746811451320684677477842085828063327750471169807192953226416761637821174117915540916395760820768894572442866654712901621988598805366346395855880257458023248536001378896260977481788119857254505117275676033169782643632703651981293206881833611109981310041682880597919639067184732139718495480743466879809515483472851869436774802197925845913239398315092870125009920168687640365984642068233617455976254652083168493, 20006773012937240830861006724315757829537358960635153292217170882835709740840698501302885514190606161194195923693848649657733002888849727833395599890422312186036801438177484984564230971132418174426866988261394789463878511414984424191430113278553531852168355856316132897649749620025509529861257994958215361974260835992381909442614957761327738007749204380975275181328994234845021891753675921936194555679283499780932917590188304907792847059686090334065438568153822034969449309942586826421284658627486938102814482760312837592929461508325711493753131754516652979314219150254353015876069728838665333903729, 15163302729918241488815183039065611002830441538045800211519589991571130639846515890700690729926060613245314705050824240439105621847834005748102613465307786314457469575299965682714168206526449444458277578242739754771684442205023176962041126081523647703020102111978471614165064343108928900590616870283920817782359029574066358871621248657602506002304486257594549007432844492167302126973316545795134886629960820642390032235472876594072484886110577445531761271886633735918486618504069900114532547783069642798398770888271383537438644009039371416980690242286149089344172100573292918427283630685766473493733, 14444584371029060678088959749763910336633086942110388201134086177172112025194827387459365619346716241798028388961068038161126065098916167755803535160395345649021144276050863026905807924069087003038789218398484893255333091150853492688955974747341339968206126763821139481910758546437699138196944546085165778363357390690161151905046024140764575865651946227303415199115560805061655569255532488456862697372474873332336052720002358388287238754462184140273413823588155697134588668365734629581216318859081577875487570037042675731071349490249652810018252014499286267976648618329744142304688530101663550536899, 24318270284792283592721477902558538648599693819608218656206504229249106819277271619408490782241120521436590368348450611794850169533640513052126990006992873899153076290893637085337191149587465515766131506574274640156569137956189774483208515268647615584523206179402020092443118143126962328316352184368661601562345549618435336503114512311329382619560709758919113873843872983017457585320098483098531725887373924546199505323200451086533750623858286358012355111721634172403980430938854918614074046102195293675563471313505112541363316453917204799619570929302518614467218977080619045771698779722216224403419, 17278910705140580208779570102650348533688570262158365930648720311858726382979934107548458596566775783653285710002898504796694550540153103095688315056013161954324135754051098435529839448330230695909077550863068452445494919492635969595817078396973486085838659487999301032439290017220050638791261340303059220075998542481362927759738274473492131063573955322666174524636300088188377029282325497058297007990875730945104522985728467730444998520610052773454279686674404856232099305845967110625008547523366413424696556303852221811222293187393301191950165154411931594294125355538875528969563338199206363913457]
        list = Random.shuffle(list)
        i = 0

        return function get_prime_from_list()
            i += 1
            return list[i]::BigInt
        end
    end

end
