import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/ui"

local pd <const> = playdate
local gfx <const> = playdate.graphics
local snd <const> = playdate.sound

local human = gfx.imagetable.new("img/T_Spritesheet_Human")
assert(human)

local stick = gfx.image.new("img/T_Stick.png")
assert(stick)

local bubble = gfx.image.new("img/T_Bubble")
assert(bubble)

local tower = gfx.imagetable.new("img/T_Spritesheet_Tower")
assert(tower)

local PAD_START <const> = 0.5
local NOISE_START <const> = 0.5
local CRANK_START <const> = 0.5

local KEYS <const> = { 4, 2, 8, 1 }
local KEYS_GFX <const> = { "^", ">", "v", "<" }

-- Start parameters to tweak

local PAD_GAIN <const> = 0.15

local PAD_DECAY <const> = 0.001
local NOISE_DECAY <const> = 0.001
local CRANK_DECAY <const> = 0.001

local NOISE_TOLERANCE <const> = 0.1

-- End parameters to tweak

local is_game_running = false

-- 1-4 NESO
local pad_combination
local pad_current_key

local pad_amount
local pad_current

local noise_amount
local noise_current

local crank_amount
local crank_current

local rand_reach_counter
local rand_value

math.randomseed(playdate.getSecondsSinceEpoch())

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
    local curr_elements = #pad_combination + 1
    pad_combination = {}
    for i = 1, curr_elements do
        table.insert(pad_combination, math.random(1, 4))
    end
end

local function reset()
    pad_combination = {}
    generate_pad_combination()
    pad_current_key = 1

    pad_amount = 0
    pad_current = PAD_START

    noise_amount = 0
    noise_current = NOISE_START

    crank_amount = 0
    crank_current = CRANK_START

    rand_reach_counter = 0
    rand_value = 0

    is_game_running = true
end

local function process_inputs()
    local _, pressed, _ = pd.getButtonState()
    if pressed ~= 0 then
        if pressed == KEYS[pad_combination[pad_current_key]] then
            pad_current_key += 1
        else
            pad_current_key = 1
        end
    end
    if pad_current_key >= #pad_combination + 1 then
        pad_current += PAD_GAIN
        generate_pad_combination()
        pad_current_key = 1
    end

    noise_amount = math.clamp(snd.micinput.getLevel(), 0, math.maxinteger)
    _, crank_amount = pd.getCrankChange()
end

local function process_increment()
    pad_current += pad_amount * 0.01
    if noise_amount >= NOISE_TOLERANCE then
        noise_current += noise_amount * 0.1
    end
    crank_current += crank_amount * 0.001
end

local function process_decay(rand)
    pad_current -= PAD_DECAY
    noise_current -= NOISE_DECAY
    crank_current -= CRANK_DECAY * rand
end

local function process_clamping()
    pad_current = math.clamp(pad_current, 0, 1)
    noise_current = math.clamp(noise_current, 0, 1)
    crank_current = math.clamp(crank_current, 0, 1)
end

local function check_game_over()
    if pad_current >= 1 then
        is_game_running = false
    end
    if noise_current <= 0 or noise_current >= 1 then
        is_game_running = false
    end
    if crank_current <= 0 or crank_current >= 1 then
        is_game_running = false
    end
end

snd.micinput.startListening()

pd.display.setRefreshRate(50)

reset()

function pd.update()
    gfx.clear(playdate.graphics.kColorBlack)

    if is_game_running then
        process_random_counter()
        process_inputs()
        process_increment()
        process_decay(rand_value)
        -- process_clamping()
        check_game_over()
    else
        local _, pressed, _ = pd.getButtonState()
        if pressed >= 16 then
            reset()
        end
    end

    -- gfx.fillRect(0, 0, 133, 240 - (240 * pad_current))
    -- gfx.fillRect(133, 0, 133, 240 - (240 * noise_current))
    -- gfx.fillRect(266, 0, 134, 240 - (240 * crank_current))

    -- test = { math.floor(0.1 * 4) + 1, math.floor(0.33 * 4) + 1, math.floor(0.66 * 4) + 1, math.floor(0.9 * 4) + 1 }
    -- printTable(test)

    local human_id = 4 - (math.floor(pad_current * 4) + 1)
    human:drawImage(math.clamp(human_id, 1, 4), 0, 0)

    for i = 1, 6 do
        tower:drawImage(2, 305, 240 - (240 * crank_current) + (37 * i))
    end

    tower:drawImage(1, 305, 240 - (240 * crank_current))

    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(305, 203, 95, 37)

    tower:drawImage(3, 305, 203)

    stick:draw(133, 130)

    bubble:drawScaled(180, 120, noise_current)

    gfx.setColor(gfx.kColorWhite)
    gfx.setDitherPattern(0.8, gfx.image.kDitherTypeBayer8x8)
    gfx.drawCircleInRect(180, 120, 110, 110)

    gfx.setImageDrawMode(gfx.kDrawModeNXOR)

    for i = 1, #pad_combination do
        if pad_current_key <= i then
            gfx.drawText(KEYS_GFX[pad_combination[i]], 10 + (20 * i), 30)
        end
    end

    gfx.setImageDrawMode(gfx.kDrawModeBlackTransparent)

    if is_game_running == false then
        gfx.setColor(gfx.kColorXOR)
        gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer8x8)
        gfx.fillRect(0, 0, 400, 240)
    end

    pd.drawFPS(0, 0)
end

function pd.deviceDidUnlock()
    snd.micinput.startListening()
end
