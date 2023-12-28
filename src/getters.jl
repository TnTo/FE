# Model

function state(m::Model, t::Int)
    if t >= 0
        return m.states[t]
    else
        return m.states[m.t-t]
    end
end

state(m::Model) = state(m, m.t)

s = state

