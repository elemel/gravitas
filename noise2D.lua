-- Adapted from: https://github.com/ashima/webgl-noise

local function fract(x)
    local i, f = math.modf(x)
    return f
end

local function permute(x)
    return (((x * 34) + 1) * x) % 289
end

local function snoise(vx, vy)
    local Cx = 0.211324865405187
    local Cy = 0.366025403784439
    local Cz = -0.577350269189626
    local Cw = 0.024390243902439

    local ix = math.floor(vx + vx * Cy + vy * Cy)
    local iy = math.floor(vy + vx * Cy + vy * Cy)

    local x0x = vx - ix + ix * Cx + iy * Cx
    local x0y = vy - iy + ix * Cx + iy * Cx

    local i1x = (x0x > x0y) and 1 or 0
    local i1y = (x0x > x0y) and 0 or 1
    local x12x = x0x + Cx - i1x
    local x12y = x0y + Cx - i1y
    local x12z = x0x + Cz
    local x12w = x0y + Cz

    ix = ix % 289
    iy = iy % 289
    local px = permute(permute(iy) + ix)
    local py = permute(permute(iy + i1y) + ix + i1x)
    local pz = permute(permute(iy + 1) + ix + 1)

    local mx = math.max(0.5 - x0x * x0x - x0y * x0y, 0) ^ 4
    local my = math.max(0.5 - x12x * x12x - x12y * x12y, 0) ^ 4
    local mz = math.max(0.5 - x12z * x12z - x12w * x12w, 0) ^ 4

    local xx = 2 * fract(px * Cw) - 1
    local xy = 2 * fract(py * Cw) - 1
    local xz = 2 * fract(pz * Cw) - 1
    local hx = math.abs(xx) - 0.5
    local hy = math.abs(xy) - 0.5
    local hz = math.abs(xz) - 0.5
    local oxx = math.floor(xx + 0.5)
    local oxy = math.floor(xy + 0.5)
    local oxz = math.floor(xz + 0.5)
    local a0x = xx - oxx
    local a0y = xy - oxy
    local a0z = xz - oxz

    mx = mx * (1.79284291400159 - 0.85373472095314 * (a0x * a0x + hx * hx))
    my = my * (1.79284291400159 - 0.85373472095314 * (a0y * a0y + hy * hy))
    mz = mz * (1.79284291400159 - 0.85373472095314 * (a0z * a0z + hz * hz))

    local gx = a0x * x0x + hx * x0y
    local gy = a0y * x12x + hy * x12y
    local gz = a0z * x12z + hz * x12w
    return 130 * (mx * gx + my * gy + mz * gz)
end

return {snoise = snoise}
