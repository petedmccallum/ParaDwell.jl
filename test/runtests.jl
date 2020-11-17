using ParaDwell
using Test

@testset "ParaDwell.jl" begin
    # These need data - need light dummy data for CI
    ParaDwell.DIVA(adminLevel=0);
    ParaDwell.DIVA(adminLevel=1);
    ParaDwell.DIVA(adminLevel=2,exclShapeBelowLen=100);
end
