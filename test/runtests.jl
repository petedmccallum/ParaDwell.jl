using ParaDwell
using Test

@testset "ParaDwell.jl" begin
    # These need data - need light dummy data for CI
    DIVA(adminLevel=0);
    DIVA(adminLevel=1);
    DIVA(adminLevel=2,exclShapeBelowLen=100);
end
