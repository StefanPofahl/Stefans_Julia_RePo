function empty_row_tests(T::Type)

    # Build the following model
    #=
        min     x + y
        s.t.   -1 ⩽ 0 * x + 0 * y + 0 * z ⩽ 1
                1 ⩽ 0 * x + 0 * y + 0 * z ⩽ 2
    =#
    pb = Tulip.ProblemData{T}()

    m, n = 2, 3
    A = spzeros(T, m, n)

    b = ones(T, m)
    c = ones(T, n)

    Tulip.load_problem!(pb, "test",
        true, c, zero(T),
        A, T.([-1, 1]), T.([1, 2]), zeros(T, n), fill(T(Inf), n),
        ["c1", "c2"], ["x", "y", "z"]
    )

    ps = Tulip.PresolveData(pb)

    @test !ps.updated
    @test ps.nzrow[1] == ps.nzrow[2] == 0

    # Remove first empty row
    Tulip.remove_empty_row!(ps, 1)

    @test ps.updated
    @test ps.status == Tulip.Trm_Unknown
    @test ps.nrow == 1
    @test !ps.rowflag[1] && ps.rowflag[2]
    @test length(ps.ops) == 1

    op = ps.ops[1]
    @test isa(op, Tulip.EmptyRow{T})
    @test op.i == 1
    @test iszero(op.y)

    # Remove second empty row
    # This should detect infeasibility
    Tulip.remove_empty_row!(ps, 2)

    @test ps.status == Tulip.Trm_PrimalInfeasible
    @test ps.nrow == 1
    @test !ps.rowflag[1] && ps.rowflag[2]
    @test length(ps.ops) == 1

    # Check solution status & objective value
    sol = ps.solution
    @test sol.dual_status == Tulip.Sln_InfeasibilityCertificate
    @test sol.z_primal == sol.z_dual == T(Inf)

    # Check Farkas ray
    #   (current problem only has 1 row)
    @test sol.y_lower[1] >  zero(T)

    return
end


function test_empty_row_1(T::Type)
    # Empty row with l > 0
    #=
        min     x
        s.t.   1 ⩽ 0 * x ⩽ 2
        x >= 0
    =#
    pb = Tulip.ProblemData{T}()

    m, n = 1, 1
    A = spzeros(T, m, n)
    c = ones(T, n)

    Tulip.load_problem!(pb, "test",
        true, c, zero(T),
        A, T.([1]), T.([2]), zeros(T, n), fill(T(Inf), n),
        ["c1"], ["x"]
    )

    ps = Tulip.PresolveData(pb)
    Tulip.remove_empty_row!(ps, 1)

    @test ps.status == Tulip.Trm_PrimalInfeasible
    @test ps.nrow == 1
    @test ps.rowflag[1]
    @test length(ps.ops) == 0

    # Check solution status & objective value
    sol = ps.solution
    @test sol.dual_status == Tulip.Sln_InfeasibilityCertificate
    @test sol.z_primal == sol.z_dual == T(Inf)

    # Check Farkas ray
    #   (current problem only has 1 row)
    @test sol.y_lower[1] >  zero(T)

    return nothing
end

function test_empty_row_2(T::Type)
    # Empty row with u < 0
    #=
        min     x
        s.t.   -2 ⩽ 0 * x ⩽ -1
        x >= 0
    =#
    pb = Tulip.ProblemData{T}()

    m, n = 1, 1
    A = spzeros(T, m, n)
    c = ones(T, n)

    Tulip.load_problem!(pb, "test",
        true, c, zero(T),
        A, T.([-2]), T.([-1]), zeros(T, n), fill(T(Inf), n),
        ["c1"], ["x"]
    )

    ps = Tulip.PresolveData(pb)
    Tulip.remove_empty_row!(ps, 1)

    @test ps.status == Tulip.Trm_PrimalInfeasible
    @test ps.nrow == 1
    @test ps.rowflag[1]
    @test length(ps.ops) == 0

    # Check solution status & objective value
    sol = ps.solution
    @test sol.dual_status == Tulip.Sln_InfeasibilityCertificate
    @test sol.z_primal == sol.z_dual == T(Inf)

    # Check Farkas ray
    #   (current problem only has 1 row)
    @test sol.y_upper[1] >  zero(T)

    return nothing
end

function test_empty_row_tolerances(T::Type)
    # Adapted from https://github.com/ds4dm/Tulip.jl/issues/98
    #=
        min     x + y + z
        s.t.    x + y + z == 1
                x == ¹/₃
                y == ¹/₃
                z == ¹/₃
                x, y, z, ≥ 0

        In the absence of numerical tolerances, x, y, and z get eliminated,
        but rouding errors cause the first constraint to be 0 == ϵ ≈ 1e-16,
        thereby rendering the problem infeasible.
    =#
    pb = Tulip.ProblemData{T}()

    m, n = 4, 3
    A = sparse(
        [1, 1, 1, 2, 3, 4],
        [1, 2, 3, 1, 2, 3],
        T[1, 1, 1, 1, 1, 1],
        m, n
    )
    c = ones(T, n)

    Tulip.load_problem!(pb, "test",
        true, c, zero(T),
        A, T[1, 1//3, 1//3, 1//3], T[1, 1//3, 1//3, 1//3],
        zeros(T, n), fill(T(Inf), n),
        ["row1", "row2", "row3", "row4"], ["x", "y", "z"]
    )

    ps = Tulip.PresolveData(pb)
    Tulip.presolve!(ps)

    @test ps.status == Tulip.Trm_Optimal
    @test ps.nrow == 0
    @test ps.ncol == 0

    # Check solution status & objective value
    sol = ps.solution
    @test sol.primal_status == Tulip.Sln_Optimal
    @test sol.dual_status == Tulip.Sln_Optimal
    @test sol.z_primal ≈ 1
    @test sol.z_dual   ≈ 1

    return nothing
end

@testset "Empty row" begin
    for T in TvTYPES
        @testset "$T" begin
            empty_row_tests(T)
            test_empty_row_1(T)
            test_empty_row_2(T)
            test_empty_row_tolerances(T)
        end
    end
end
