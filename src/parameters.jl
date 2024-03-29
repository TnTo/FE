import Base.@kwdef

@kwdef mutable struct Parameters
    # Initialization
    seed::Int = 8686
    T::Int = 300
    p0::Int = 100
    δ0::Float
    σ0::Float
    β0::Float = 1.05

    # Not to calibrate
    NH::Int = 2000
    NFC::Int = 250
    NFK::Int = 50
    NK::Int = 60
    NL::Int = 60
    Σ::Float = 0.08
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
    χC::Int = 5
    χK::Int = 5
    χH::Int = 20
    ρW::Float = 1.01
    ρH::Float = 2.0
    ρC::Float = 1.1
    ρK::Float = 1.0
    ρF::Float = 2.0
    ν3::Float = 0.0
    ν4::Float = 0.0
    ν0::Float = 0.0
    ν1::Float = 0.0
    k::Float = 3.0

    # To calibrate
    e0::Float
    e1::Float
    ay::Float
    av::Float
    Θ::Float
    ρQ::Float
    λ::Float
    ν2::Float
    τF::Float
    τT::Float
    ϵ0::Float
    ϵ1::Float
    ζ::Float
    b0::Float
    b1::Float
    b2::Float
    k0::Float
end

Parameters() = Parameters(
    σ0=1.0,
    δ0=0.75,
    e0=6.0,
    e1=0.5,
    ay=5.0,
    av=1.1,
    Θ=0.5,
    ρQ=0.1,
    λ=0.1,
    ν2=0.2,
    τF=5.0,
    τT=5.0,
    ϵ0=0.5,
    ϵ1=5.0,
    ζ=3.0,
    b0=2.0,
    b1=3.0,
    b2=2.0,
    k0=3.0
)