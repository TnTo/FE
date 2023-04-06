# Steps

# 1

function update_interest_rate!(cb::CentralBank)
    cb.i = circshift(cb.i, 1)
    cb.i[0] = (1 + cb.α) * get_inflation(cb.m, YEAR) - cb.α * cb.π + cb.β * get_output_gap(cb.m)
    return nothing
end

function update_interest_rate!(m::Model)
    update_interest_rate!(m.CB)
    return nothing
end