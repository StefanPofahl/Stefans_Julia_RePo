# ─────────────────────────────────────────────────────────────────────────
#   Simulate the accelaration of a locomotive due to traction force
# ─────────────────────────────────────────────────────────────────────────
#   Notation "dt = 0.2f0":
#   This ensures that dt is of type: Float32
#   Remark: 
#   The code is used for preparation of structured text (ST) programming.
# ─────────────────────────────────────────────────────────────────────────
using Plots
using Printf

# ─────────────────────────────────────────────────────────────────────────
#   Physical parameters of a freight electric loco
# ─────────────────────────────────────────────────────────────────────────

const M_train_t     = 3200.0f0             # total mass / tonnes  (loco + wagons)
const rTrainWeight  = Float32(M_train_t * 1000.0)  # kg

const g             = Float32(9.81)        # gravitational acceleration, m/s²
const rho           = Float32(1.225)       # air density, kg/m³
const CdA           = Float32(12.5)        # rough equivalent for freight train m²

# Davis formula coefficients  (very approximate for European freight)
const A             = Float32(1.5)         # N/kN  (journal + rolling resistance)
const B             = Float32(0.025)       # N/(kN·km/h)
const C             = Float32(0.00045)     # N/(kN·(km/h)²)

const F_max         = Float32(320.0e3)     # maximum tractive effort  / N  (~320 kN)
const P_max         = Float32(6.4e6)       # maximum power            / W   6400 kW
const v_base        = Float32(80.0 / 3.6)  # speed where power limit starts, m/s (~80 km/h)

const v_max_km_h    = Float32(120.0)
const v_max         = Float32(v_max_km_h / 3.6)   # m/s

# ──────────────────────────────────────────────────────────────
#   Simulation settings
# ──────────────────────────────────────────────────────────────

const dt            = 0.2f0                # time step / s

# ──────────────────────────────────────────────────────────────
#   Persistent state structure (for ST/STX implementation)
# ──────────────────────────────────────────────────────────────
mutable struct LocomotiveState
    # Persistent variables (retained between calls)
    t::Float32      # current time
    s::Float32      # position
    v::Float32      # speed
    v_old::Float32  # previous speed
    a::Float32      # acceleration
    F::Float32      # tractive force
    P::Float32      # power
    
    # Constructor with initial values
    LocomotiveState() = new(0.0f0, 0.0f0, 0.0f0, 0.0f0, 0.0f0, 0.0f0, 0.0f0)
end

# ────────────────────────────────────────────────────────────────────────────────────────────────
#   Main simulation function with persistent state
#   Input:  drive_force_request - scalar tractive effort request (N)
#   Output: current state values
#   Remark:
#   Exclamation mark "!" indicates, that the function can manipulate its input "state"
# ────────────────────────────────────────────────────────────────────────────────────────────────
function simulate_locomotive_step!(state::LocomotiveState, drive_force_request::Float32)
    # --- Convert speed to km/h for Davis formula
    v_kmh = Float32(state.v * 3.6)
    
    # Calculate resistance using Davis formula
    weight_kN = M_train_t * g                  # Weight in kN
    F_roll    = A * weight_kN                  # Rolling resistance
    F_speed   = B * weight_kN * v_kmh          # Speed-dependent term
    F_air     = C * weight_kN * v_kmh^2        # Air resistance (Davis form)
    F_resist  = F_roll + F_speed + F_air
    
    # Apply limits based on mode
    if drive_force_request >= 0  # Traction
        F_power_limit = state.v > 0.1 ? P_max / state.v : F_max
        state.F = min(drive_force_request, F_max, F_power_limit)
    else  # Braking
        state.F = max(drive_force_request, - F_max * 0.95f0)
    end
    
    # Physics update
    F_net = state.F - F_resist
    state.a = F_net / rTrainWeight
    
    # Update speed with limits
    v_new = state.v + state.a * dt
    state.v = max(min(v_new, v_max), 0.0f0)
    
    # Update position using trapezoidal integration
    state.s = Float32(state.s + (state.v_old + state.v) * dt / 2)
    
    # Update power and time
    state.P = state.F * state.v
    state.t = state.t + dt
    
    # Store current speed for next integration step
    state.v_old = state.v
    
    return (time=state.t, position=state.s, speed=state.v * 3.6f0, 
            acceleration=state.a, force=state.F / 1000.f0, power=Float32(state.P / 1e6))
end

# ──────────────────────────────────────────────────────────────────
#   Compatibility wrapper for original test function
# ──────────────────────────────────────────────────────────────────
function simulate_locomotive(_dt::Float32=0.1f0)
    state = LocomotiveState()
    N = round(Int, 600.0 / _dt) + 1  # t_end = 600.0
    # --- initialise the necessary vectors:
    t, s, v, a, F, P = [Vector{Float32}(undef, N) for _ in 1:6]
    for i = 1:N-1
        # --- Original driver model as drive force request:
        # --- New value of "state.t" is incrementell increased inside function "simulate_locomotive_step!()"
        drive_req = requested_tractive_force(state.t)
        result = simulate_locomotive_step!(state, drive_req)
        # Store results
        t[i] = result.time
        s[i] = result.position
        v[i] = result.speed
        a[i] = result.acceleration
        F[i] = result.force
        P[i] = result.power
    end
    
    # Fill last values
    t[end] = t[end-1] + _dt
    s[end] = s[end-1]
    v[end] = v[end-1]
    a[end] = a[end-1]
    F[end] = F[end-1]
    P[end] = P[end-1]
    
    return t, s, v, a, F, P
end

# Simple driver model – requested tractive effort (für Kompatibilität)
function requested_tractive_force(_t::Float32)
    if _t < 40
        return Float32(0.0f0)
    elseif _t < 140
        return Float32(F_max * 0.98f0)          # almost max TE
    elseif _t < 260
        return Float32(F_max * 0.4f0)           # cruising
    elseif _t < 340
        return Float32(- F_max * 0.6f0)         # moderate braking
    else
        return Float32(- F_max * 0.95f0)        # strong braking
    end
end

# --- simulate:
t, s, v, a, F, P = simulate_locomotive(dt);

# fig = plot(t, v)
# display(fig)

# ────────────────────────────────────────────────────────────
#   Run & plot
# ────────────────────────────────────────────────────────────

t, s, v_kmh, a_ms2, F_kN, P_MW = simulate_locomotive(dt)

p1 = plot(t, v_kmh,   label="speed",    ylabel="Speed  / km/h ", lw=2)
p2 = plot(t, F_kN,    label="tractive", ylabel="Force  / kN",    lw=2)
plot!(p2, t, -F_kN.*0 .+ 320, ls=:dash, c=:gray, label="max TE")

p3 = plot(t, a_ms2,   label="accel",    ylabel="Accel / m/s²",   lw=2)
p4 = plot(t, P_MW,    label="power",    ylabel="Power / MW",     lw=2)
plot!(p4, t, P_MW.*0 .+ 6.4, ls=:dash, c=:gray, label="max P")

l = @layout [
    a      b
    c      d
]

fig = plot(p1, p2, p3, p4,
    layout = l,
    size = (1100, 800),
    title = ["Locomotive speed" "Tractive / braking force" "Acceleration" "Output power"],
    leftmargin = 4Plots.mm, 
    bottommargin = 5Plots.mm,
    dpi = 120)

display(fig)
