using StaticArrays
using Test

using CLIMA
using CLIMA.Atmos
using CLIMA.PlanetParameters
using CLIMA.MoistThermodynamics
using CLIMA.PlanetParameters
using CLIMA.VariableTemplates
using CLIMA.Grids

function init_test!(bl, state, aux, (x, y, z), t)
    FT = eltype(state)

    z = FT(z)

    # These constants are those used by Stevens et al. (2005)
    qref = FT(9.0e-3)
    q_pt_sfc = PhasePartition(qref)
    Rm_sfc = FT(gas_constant_air(q_pt_sfc))
    T_sfc = FT(290.4)
    P_sfc = FT(MSLP)

    # Specify moisture profiles
    q_liq = FT(0)
    q_ice = FT(0)

    θ_liq = FT(289.0)
    q_tot = qref

    ugeo = FT(7)
    vgeo = FT(-5.5)
    u, v, w = ugeo, vgeo, FT(0)

    # Pressure
    H = Rm_sfc * T_sfc / grav
    p = P_sfc * exp(-z / H)

    # Density, Temperature
    ts = LiquidIcePotTempSHumEquil_given_pressure(θ_liq, p, q_tot, bl.param_set)
    ρ = air_density(ts)

    e_kin = FT(1 / 2) * FT((u^2 + v^2 + w^2))
    e_pot = grav * z
    E = ρ * total_energy(e_kin, e_pot, ts)

    state.ρ = ρ
    state.ρu = SVector(ρ * u, ρ * v, ρ * w)
    state.ρe = E
    state.moisture.ρq_tot = ρ * q_tot

    return nothing
end

function main()
    CLIMA.init()

    FT = Float64

    # DG polynomial order
    N = 4

    # Domain resolution and size
    Δh = FT(40)
    Δv = FT(40)
    resolution = (Δh, Δh, Δv)

    xmax = 320
    ymax = 320
    zmax = 400

    t0 = FT(0)
    timeend = FT(10)
    CFL = FT(0.4)

    ode_solver = CLIMA.ExplicitSolverType()
    driver_config = CLIMA.AtmosLESConfiguration(
        "Driver test",
        N,
        resolution,
        xmax,
        ymax,
        zmax,
        init_test!,
        solver_type = ode_solver,
    )
    solver_config =
        CLIMA.setup_solver(t0, timeend, driver_config, Courant_number = CFL)

    # Test the courant wrapper
    # by default the CFL should be less than what asked for
    CFL_nondiff = CLIMA.DGmethods.courant(
        CLIMA.Courant.nondiffusive_courant,
        solver_config,
    )
    @test CFL_nondiff < CFL
    CFL_adv =
        CLIMA.DGmethods.courant(CLIMA.Courant.advective_courant, solver_config)
    CFL_adv_v = CLIMA.DGmethods.courant(
        CLIMA.Courant.advective_courant,
        solver_config;
        direction = VerticalDirection(),
    )
    CFL_adv_h = CLIMA.DGmethods.courant(
        CLIMA.Courant.advective_courant,
        solver_config;
        direction = HorizontalDirection(),
    )

    # compute known advective Courant number (based on initial conditions)
    ugeo_abs = FT(7)
    vgeo_abs = FT(5.5)
    Δt = solver_config.dt
    caₕ = ugeo_abs * (Δt / Δh) + vgeo_abs * (Δt / Δh)
    # vertical velocity is 0
    caᵥ = FT(0.0)
    @test isapprox(CFL_adv_v, caᵥ)
    @test isapprox(CFL_adv_h, caₕ, atol = 0.0005)
    @test isapprox(CFL_adv, caₕ, atol = 0.0005)

    cb_test = 0
    result = CLIMA.invoke!(solver_config)
    # cb_test should be zero since user_info_callback not specified
    @test cb_test == 0

    result = CLIMA.invoke!(
        solver_config,
        user_info_callback = (init) -> cb_test += 1,
    )
    # cb_test should be greater than one if the user_info_callback got called
    @test cb_test > 0

    # Test that if dt is not adjusted based on final time the CFL is correct
    solver_config = CLIMA.setup_solver(
        t0,
        timeend,
        driver_config,
        Courant_number = CFL,
        timeend_dt_adjust = false,
    )

    CFL_nondiff = CLIMA.DGmethods.courant(
        CLIMA.Courant.nondiffusive_courant,
        solver_config,
    )
    @test CFL_nondiff ≈ CFL
end

main()
