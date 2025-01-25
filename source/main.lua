import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/ui"

local pd <const> = playdate
local gfx <const> = playdate.graphics
local snd <const> = playdate.sound

local PAD_START <const> = 0.5
local NOISE_START <const> = 0.5
local CRANK_START <const> = 0.5

local KEYS <const> = { 4, 2, 8, 1 }
local KEYS_GFX <const> = { "^", ">", "v", "<" }

-- 1-4 NESO
local pad_combination = { 0, 0, 0, 0 }
local pad_current_key = 0

local pad_decay = 0.001
local noise_decay = 0.001
local crank_decay = 0.001

local pad_amount = 0
local pad_current = PAD_START

local noise_amount = 0
local noise_current = NOISE_START

local crank_amount = 0
local crank_current = CRANK_START

local rand_reach_counter = 0
local rand_value = 0

function math.clamp(x, min, max)
    return math.max(math.min(x, max), min)
end

local function process_random_counter()
    rand_reach_counter -= 1
    if rand_reach_counter <= 0 then
        rand_value = math.random(-5, 5)
        rand_reach_counter = math.random(0, 100)
    end
end

local function generate_pad_combination()
    local value = { math.random(1, 4), math.random(1, 4), math.random(1, 4), math.random(1, 4) }
    return value
end

local function reset()
    pad_combination = generate_pad_combination()
    pad_current_key = 0

    pad_amount = 0
    pad_current = PAD_START

    noise_amount = 0
    noise_current = NOISE_START

    crank_amount = 0
    crank_current = CRANK_START

    rand_reach_counter = 0
    rand_value = 0
end

local function process_inputs()
    local _, pressed, _ = pd.getButtonState()
    if pressed >= 16 then
        reset()
    end
    if pressed ~= 0 then
        if pressed == KEYS[pad_combination[pad_current_key + 1]] then
            pad_current_key += 1
        else
            pad_current_key = 0
        end
    end
    if pad_current_key >= 4 then
        pad_current += 0.15
        pad_combination = generate_pad_combination()
        pad_current_key = 0
    end

    noise_amount = math.clamp(snd.micinput.getLevel(), 0, math.maxinteger)
    _, crank_amount = pd.getCrankChange()
end

local function process_increment()
    pad_current += pad_amount * 0.01
    noise_current += noise_amount * 0.1
    crank_current += crank_amount * 0.001
end

local function process_decay(rand)
    pad_current -= pad_decay
    noise_current -= noise_decay
    crank_current -= crank_decay * rand
end

local function process_clamping()
    pad_current = math.clamp(pad_current, 0, 1)
    noise_current = math.clamp(noise_current, 0, 1)
    crank_current = math.clamp(crank_current, 0, 1)
end

pad_combination = generate_pad_combination()

snd.micinput.startListening()

function pd.update()
    gfx.clear()

    process_random_counter()
    process_inputs()
    process_increment()
    process_decay(rand_value)
    process_clamping()

    gfx.fillRect(0, 0, 133, 240 - (240 * pad_current))
    gfx.fillRect(133, 0, 133, 240 - (240 * noise_current))
    gfx.fillRect(266, 0, 134, 240 - (240 * crank_current))

    gfx.setImageDrawMode(gfx.kDrawModeNXOR)

    if pad_current_key == 0 then
        gfx.drawText(KEYS_GFX[pad_combination[1]], 30, 30)
    end
    if pad_current_key <= 1 then
        gfx.drawText(KEYS_GFX[pad_combination[2]], 50, 30)
    end
    if pad_current_key <= 2 then
        gfx.drawText(KEYS_GFX[pad_combination[3]], 70, 30)
    end
    if pad_current_key <= 3 then
        gfx.drawText(KEYS_GFX[pad_combination[4]], 90, 30)
    end
end

function pd.deviceDidUnlock()
    snd.micinput.startListening()
end
