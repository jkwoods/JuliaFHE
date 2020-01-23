Pkg.add("StaticArrays")
module PublicKey

using StaticArrays

export Pk


struct Pk
    #parameters
    lam::Int64
    rho::Int64
    eta::Int64
    gam::Int64
    Theta::Int64
    alpha::Int64
    tau::Int64
    l::Int64
    n::Int64

    #initlized inside
    rhoi::Int64
    theta::Int64
    kap::Int64
    alphai::Int64
    logl::Int64
    #p::SVector{l,BigInt}
    #pi::BigInt
    #q0::BigInt
    #x0::BigInt
    #x::SVector{tau,BigInt}
    #xi::SVector{l,BigInt}
    #ii::SVector{l,BigInt}
    #B::Int64 #l
    #s::SMatrix{l,Theta,Int64,(l*Theta)}
    #rv_s::SMatrix{Theta,l,Int64,(l*Theta)}
    #u::SVector{Theta,BigInt} #TODO check types of u,y,o
    #y::SVector{Theta,Float64}
    #o::SVector{Theta,BigInt}
    #                                                                             n, rhoi,    theta,     kap,           alphai,     logl,                  p, pi, q0, x0, x, xi, ii, B, s, rv_s, u, y, o
    Pk(lam,rho,eta,gam,Theta,alpha,tau,l) = new(lam,rho,eta,gam,Theta,alpha,tau,l,4,(lam+rho),(Theta+l),(64*(gam÷64+1)),(alpha+lam),(round(Int64,log(2,l))))#,,,,,,,                   l,)
end

#helper functions

#function make_p(x::Pk)
#    p = []
#end


end
