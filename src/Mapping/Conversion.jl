"""
Uses UK Ordnance Survey "A Guide to Coordinate Systems in Great Britain"
https://www.ordnancesurvey.co.uk/documents/resources/guide-coordinate-systems-great-britain.pdf

Worked example (Airy1830)
E = 651409.903 # meters
N = 313177.270 # meters

"""
function OSENtoLLA(E,N)
    # Airy 1830
    a = 6377563.396
    b = 6356256.909
    e2 = (a^2 - b^2)/a^2
    E0 = 400000
    N0 = -100000
    F0 = 0.9996012717
    ϕ0 = 49 * (π/180)
    λ0 = -2 * (π/180)


    ϕ1 = (N - N0)/a*F0 + ϕ0
    n=(a-b)/(a+b)
    M_function(ϕ) = b*F0*( (1 + n + 5/4*n^2 + 5/4*n^3) * (ϕ-ϕ0)
        - (3*n + 3*n^2 + 21/8*n^3) * sin(ϕ-ϕ0) * cos(ϕ+ϕ0)
        + (15/8*n^2 + 15/8*n^3) * sin(2*(ϕ-ϕ0)) * cos(2*(ϕ+ϕ0))
        - 35/24*n^3 * sin(3*(ϕ-ϕ0))*cos(3*(ϕ+ϕ0)))
    residual(M) = (N-N0-M)
    M = M_function(ϕ1)


    while residual(M) > 0.00000001
        ϕ1 = (residual(M)/a*F0) + ϕ1
        M = M_function(ϕ1)
    end

    ϕ1 / (π/180)

    ν = a * F0 * abs(1-e2*sin(ϕ1)^2)^(-0.5) # \nu
    ρ = a * F0 * (1-e2) * (1-e2*sin(ϕ1)^2)^(-1.5)
    η2 = ν/ρ-1

    VII = tan(ϕ1)/(2*ρ*ν)
    VIII = tan(ϕ1)/(24*ρ*ν^3) * (5 + 3*tan(ϕ1)^2 + η2 - 9*(tan(ϕ1)^2)*η2)
    IX = tan(ϕ1)/(720*ρ*ν^5) * (61 + 90*tan(ϕ1)^2 + 45*(tan(ϕ1)^4))
    X = sec(ϕ1)/ν
    XI = sec(ϕ1)/(6*ν^3) * (ν/ρ + 2*tan(ϕ1)^2)
    XII = sec(ϕ1)/(120*ν^5) * (5 + 28*tan(ϕ1)^2 + 24*tan(ϕ1)^4)
    XIIA = sec(ϕ1)/(5040*ν^7) * (61 + 662*tan(ϕ1)^2 + 1320*tan(ϕ1)^4 + 720*tan(ϕ1)^6)

    ϕ = ϕ1 - VII*(E-E0)^2 + VIII*(E-E0)^4 - IX*(E-E0)^6
    λ = λ0 + X*(E-E0) - XI*(E-E0)^3 + XII*(E-E0)^5 - XIIA*(E-E0)^7

    return ϕ/(π/180), λ/(π/180)
end
