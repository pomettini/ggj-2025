import "CoreLibs/graphics"
import "CoreLibs/ui"

local pd <const> = playdate
local gfx <const> = playdate.graphics
local snd <const> = playdate.sound

local PAD_START <const> = 0.5
local NOISE_START <const> = 0.5
local CRANK_START <const> = 0.5

local pad_decay = 0.001
local noise_decay = 0.001
local crank_decay = 0.001

local pad_amount = 0
local pad_current = PAD_START

local noise_amount = 0
local noise_current = NOISE_START

local crank_amount = 0
local crank_current = CRANK_START

snd.micinput.startListening()

function math.clamp(x, min, max)
    return math.max(math.min(x, max), min)
end

function pd.update()
    gfx.clear()

    if pd.getButtonState() ~= 0 then
        pad_amount = 1
    else
        pad_amount = 0
    end

    noise_amount = math.clamp(snd.micinput.getLevel(), 0, math.maxinteger)
    crank_amount, _ = math.clamp(pd.getCrankChange(), 0, math.maxinteger)

    pad_current += pad_amount * 0.01
    noise_current += noise_amount * 0.1
    crank_current += crank_amount * 0.001

    pad_current -= pad_decay
    noise_current -= noise_decay
    crank_current -= crank_decay

    pad_current = math.clamp(pad_current, 0, 1)
    noise_current = math.clamp(noise_current, 0, 1)
    crank_current = math.clamp(crank_current, 0, 1)

    gfx.fillRect(0, 0, 133, 240 - (240 * pad_current))
    gfx.fillRect(133, 0, 133, 240 - (240 * noise_current))
    gfx.fillRect(266, 0, 134, 240 - (240 * crank_current))
end

function pd.deviceDidUnlock()
    snd.micinput.startListening()
end
