# ─────────────────────────────────────────────────────────────────────────
#   Simulate the accelaration of a locomotive due to traction force
# ─────────────────────────────────────────────────────────────────────────
#   Notation "dt = 0.2f0":
#   This ensures that dt is of type: Float32
#   Remark: 
#   The code is used for preparation of structured text (ST) programming.
# ─────────────────────────────────────────────────────────────────────────
#   Scientific reference:
#   CUNILLERA, Alejandro, et al. 
#   Assessment of the worthwhileness of efficient driving in railway 
#   systems with high-receptivity power supplies. 
#   Energies, 2020, 13. Jg., Nr. 7, S. 1836.
#   Wikipedia: "Rail vehicle resistance"
#   https://en.wikipedia.org/wiki/Rail_vehicle_resistance
#
# ─────────────────────────────────────────────────────────────────────────
#   Author: Stefan Pofahl, Version 0.1, Date: 26-Feb-2026
# ─────────────────────────────────────────────────────────────────────────
using Plots
using Printf
# --- options: ------------------------------------------------------------
xDisplayPowerOutput = false  # if false plot various drag forces
# ─────────────────────────────────────────────────────────────────────────
#   Physical parameters of a freight electric loco
# ─────────────────────────────────────────────────────────────────────────

const CstM_train_t  = 3200.0f0             # total mass / tonnes  (loco + wagons)
const rTrainWeight  = Float32(CstM_train_t * 1000.0)  # kg

const rCst_gGravitAccel = Float32(9.81)    # gravitational acceleration, m/s²

# Davis formula coefficients  (very approximate for European freight)
const CstA_davis    = Float32(1.5)         # N/kN  (journal + rolling resistance)
const CstB_davis    = Float32(0.025)       # N/(kN·km/h)
const Cst_C_davis   = Float32(0.00045)     # N/(kN·(km/h)²)

const F_max_N       = Float32(320.0e3)     # maximum tractive effort  / N   (~320 kN)
const P_max         = Float32(6.4e6)       # maximum power            / W   (=6400 kW)
const v_base        = Float32(80.0 / 3.6)  # speed where power limit starts, m/s (~80 km/h)

const v_max_km_h    = Float32(120.0)
const v_max         = Float32(v_max_km_h / 3.6)   # m/s
const t_test        = 400                  # s

# ──────────────────────────────────────────────────────────────
#   Simulation settings
# ──────────────────────────────────────────────────────────────

const dt            = 1.0f0                # time step / s

# ──────────────────────────────────────────────────────────────
#   Persistent state structure (for ST/STX implementation)
# ──────────────────────────────────────────────────────────────
mutable struct LocomotiveState
    # Persistent variables (retained between calls)
    t::Float32          # current time
    s::Float32          # position
    v::Float32          # speed
    v_old::Float32      # previous speed
    a::Float32          # acceleration
    F_trct::Float32     # tractive force
    F_roll::Float32     # roll resistivity
    F_speed::Float32    # speed resisitivity
    F_air::Float32      # air resistivity
    F_res::Float32      # resulting force
    F_net::Float32      # net driving force
    P::Float32          # power
    
    # Constructor with initial values
    LocomotiveState() = new(0.0f0, 0.0f0, 0.0f0, 0.0f0, 0.0f0, 0.0f0, 0.0f0, 0.0f0, 0.0f0, 0.0f0, 0.0f0, 0.0f0)
end

# ────────────────────────────────────────────────────────────────────────────────────────────────
#   Main simulation function with persistent state
#   Input:  drive_force_request_N - scalar tractive effort request (N)
#   Output: current state values
#   Remark:
#   Exclamation mark "!" indicates, that the function can manipulate its input "state"
# ────────────────────────────────────────────────────────────────────────────────────────────────
function simulate_locomotive_step!(_state::LocomotiveState, _F_trac_SP_N::Float32)
    # --- Convert speed to km/h for Davis formula
    v_kmh = Float32(_state.v * 3.6)   # state.v, m/s
    
    # --- Calculate resistance using Davis formula
    _weight_kN = CstM_train_t * rCst_gGravitAccel          # Weight in kN
    _F_roll    = CstA_davis   * _weight_kN                 # Rolling resistance, N
    _F_speed   = CstB_davis   * _weight_kN * v_kmh         # Speed-dependent term, N
    _F_air     = Cst_C_davis  * _weight_kN * v_kmh^2       # Air resistance (Davis form), N
    _F_resist  = _F_roll      + _F_speed   + _F_air        # Summ of drag forces, N
    # println("F_roll: $F_roll")
    # --- Apply limits based on mode
    if _F_trac_SP_N >= 0  # Traction
        if _state.v > 0.1
            F_power_limit = P_max / _state.v
        else
            F_power_limit = F_max_N
        end
        # --- short form:
        # F_power_limit = state.v > 0.1 ? P_max / state.v : F_max_N
        # ---
        _state.F_trct = min(_F_trac_SP_N,   F_max_N, F_power_limit)
    else  # Braking
        _state.F_trct = max(_F_trac_SP_N, - F_max_N * 0.95f0)
    end
    
    # --- Informative Output variables:
    _state.F_roll    = _F_roll
    _state.F_speed   = _F_speed
    _state.F_air     = _F_air
    _state.F_res     = _F_resist
    # --- Physics update
    _state.F_net     = _state.F_trct - _F_resist
    _state.a         = _state.F_net / rTrainWeight
    
    # --- Update speed with limits
    _v_new    = _state.v + _state.a * dt    # "state.v" holds the previos value, initial value: 0.0 m/s
    _state.v = max(min(_v_new, v_max), 0.0f0)
    
    # --- Update position using trapezoidal integration
    _state.s = Float32(_state.s + (_state.v_old + _state.v) * dt / 2)
    
    # --- Update power and time
    _state.P = _state.F_trct * _state.v    # Output Power, W
    _state.t = _state.t + dt
    
    # Store current speed for next integration step
    _state.v_old = _state.v
    
    return (time= _state.t, position= _state.s, speed= _state.v * 3.6f0, 
            acceleration=  _state.a, force_traction_kN= _state.F_trct / 1000.0f0, 
            force_roll_kN= _state.F_roll / 1000.0f0, force_speed_kN=  _state.F_speed / 1000.0f0,
            force_air_kN=  _state.F_air  / 1000.0f0, force_resist_kN= _state.F_res   / 1000.0f0, 
            force_net_kN=  _state.F_net  / 1000.0f0,
            power_output_MW= Float32(_state.P / 1e6))
end

# ──────────────────────────────────────────────────────────────────
#   Compatibility wrapper for original test function
# ──────────────────────────────────────────────────────────────────
function simulate_locomotive(_dt::Float32=0.1f0)
    state = LocomotiveState()
    _N = round(Int, t_test / _dt) + 1  # t_end = 600.0
    # --- initialise the necessary vectors:
    _t, _s, _v, _a, _F_tracSP_kN, _F_tract_kN, _F_roll_kN, _F_speed_kN, _F_air_kN, _F_res_kN, _F_net_kN, _P = [Vector{Float32}(undef, _N) for _ in 1:12]
    for i = 1:_N-1
        # --- Original driver model as drive force request:
        # --- New value of "state.t" is incrementell increased inside function "simulate_locomotive_step!()"
        _F_trac_SP_N = requested_tractive_force_N(state.t)
        _result      = simulate_locomotive_step!(state, _F_trac_SP_N)  # struct as defined in this function
        # Store results
        _t[i]           = _result.time
        _s[i]           = _result.position
        _v[i]           = _result.speed
        _a[i]           = _result.acceleration
        _F_tracSP_kN[i] = _F_trac_SP_N / 1000.0
        _F_tract_kN[i]  = _result.force_traction_kN
        _F_roll_kN[i]   = _result.force_roll_kN
        _F_speed_kN[i]  = _result.force_speed_kN
        _F_air_kN[i]    = _result.force_air_kN
        _F_res_kN[i]    = _result.force_resist_kN
        _F_net_kN[i]    = _result.force_net_kN
        _P[i]           = _result.power_output_MW
    end
    
    # --- Fill last values:
    _t[end]             = _t[end-1] + _dt
    _s[end]             = _s[end-1]
    _v[end]             = _v[end-1]
    _a[end]             = _a[end-1]
    _F_tracSP_kN[end]   = _F_tracSP_kN[end-1]
    _F_tract_kN[end]    = _F_tract_kN[end-1]
    _F_roll_kN[end]     = _F_roll_kN[end-1]  
    _F_speed_kN[end]    = _F_speed_kN[end-1]  
    _F_air_kN[end]      = _F_air_kN[end-1]  
    _F_res_kN[end]      = _F_res_kN[end-1]  
    _F_net_kN[end]      = _F_net_kN[end-1]
    _P[end]             = _P[end-1]
    
    return _t, _s, _v, _a, _F_tracSP_kN, _F_tract_kN, _F_roll_kN, _F_speed_kN, _F_air_kN, _F_res_kN, _F_net_kN, _P
end

# --- Simple driver model – requested tractive effort (für Kompatibilität)
function requested_tractive_force_N(_t::Float32)
    if _t < 40
        return Float32(0.0f0)
    elseif _t < 140
        return Float32(F_max_N * 0.98f0)          # almost max TE
    elseif _t < 260
        return Float32(F_max_N * 0.4f0)           # cruising
    elseif _t < 340
        return Float32(- F_max_N * 0.6f0)         # moderate braking
    else
        return Float32(- F_max_N * 0.95f0)        # strong braking
    end
end

# ────────────────────────────────────────────────────────────
#   Run & plot
# ────────────────────────────────────────────────────────────

t, s, v_kmh, a_ms2, F_tracSP_kN, F_kN, F_roll_kN, F_speed_kN, F_air_kN, F_resist_kN, F_net_kN, P_MW = simulate_locomotive(dt)

p1 = Plots.plot(t,  v_kmh,    label="speed",    ylabel="Speed / km/h ", lw=2)
p2 = Plots.plot(t,  F_kN,     label="F_trac",   ylabel="Force / kN",    lw=2)
Plots.plot!(p2, t,  F_tracSP_kN, label="F_trac_SP")
Plots.plot!(p2, t,  F_net_kN, label="F_net")
Plots.plot!(p2, t,  F_kN.*0 .+ F_max_N/1000.0, ls=:dash, c=:gray, label="max TE") # F_kN.*0: Zero vector of length F_kN

p3 = Plots.plot(t, a_ms2,   label="accel",    ylabel="Accel / m/s²",   lw=2)
if xDisplayPowerOutput
    p4 = Plots.plot(t, P_MW,    label="power",    ylabel="Power / MW",     lw=2)
    Plots.plot!(p4, t, P_MW.*0 .+ P_max/1e6, ls=:dash, c=:gray, label="max P")  # second line "max P", P_MW.*0: Zero vector of length P_MW
    fig_titles = ["Locomotive speed" "Tractive / braking force" "Acceleration" "Output power"]
else
    p4 = Plots.plot(t, F_resist_kN,    label="F_resist",    ylabel="Force / kN",     lw=2)
    Plots.plot!(p4, t, F_roll_kN,      ls=:dash, label="F_roll")
    Plots.plot!(p4, t, F_speed_kN,     ls=:dash, label="F_speed")
    Plots.plot!(p4, t, F_air_kN,       ls=:dash, label="F_air")
    fig_titles = ["Locomotive speed" "Tractive / Braking force" "Acceleration" "Drag Forces"]
end

l = @layout [
    a      b
    c      d
]

fig = Plots.plot(p1, p2, p3, p4,
    layout = l,
    size = (1100, 800),
    title = fig_titles,
    leftmargin = 4Plots.mm, 
    bottommargin = 5Plots.mm,
    dpi = 120)

Plots.display(fig)
