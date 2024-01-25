import Base.@kwdef

@kwdef mutable struct Parameters
    # Initialization
    seed::Int = 8686
    T::Int = 500
    p0::Int = 100
    δ0::Float
    σ0::Float

    # Not to calibrate
    NH::Int = 2000
    NFC::Int = 250
    NFK::Int = 50
    NK::Int = 60
    Σ::Float = 0.01
    σM::Int = 10
    AR::Int = 780
    A0::Int = 180
    σ_::Float = 10
    Γ_::Float = 0.08
    τC::Float = 0.2
    τS::Float = 0.25
    τI::Float = 0.0
    τM::Float = 0.45
    ϕ::Float = 0.9
    δ_::Float = 0.03
    α1::Float = 0.5
    α2::Float = 0.25
    α3::Float = 0.25
    ψ_::Float = 0.02
    u_::Float = 0.8
    ω_::Float = 0.05
    k::Float = 60.0
    χC::Int = 5
    χK::Int = 5
    χH::Int = 20
    ρW::Float = 1.05

    # To calibrate
    e0::Float
    e1::Float
    ρH::Float
    a::Float
    ρC::Float
    ρK::Float
    ρF::Float
    Θ::Float
    ρΠ::Float
    ρQ::Float
    λ::Float
    ν0::Float
    ν1::Float
    ν2::Float
    ν3::Float
    ν4::Float
    τF::Float
    τT::Float
    ϵ0::Float
    ϵ1::Float
    ζ::Float
    b0::Float
    b1::Float
    b2::Float
end

Parameters() = Parameters(
    σ0=1.0,
    δ0=0.5,
    e0=1.0,
    e1=1.0,
    ρH=1.1,
    a=1.0,
    ρC=1.1,
    ρK=1.05,
    ρF=1.0,
    Θ=1.0,
    ρΠ=0.5,
    ρQ=0.1,
    λ=0.5,
    ν0=1.0,
    ν1=1.0,
    ν2=0.1,
    ν3=0.1,
    ν4=0.1,
    τF=1.0,
    τT=0.0,
    ϵ0=0.5,
    ϵ1=1.0,
    ζ=1.0,
    b0=1.0,
    b1=1.0,
    b2=1.0
)