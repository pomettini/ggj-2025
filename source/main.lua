import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/ui"

local pd <const> = playdate
local gfx <const> = playdate.graphics
local snd <const> = playdate.sound

local bg_tower = gfx.image.new("img/T_Tower_BG.png")
assert(bg_tower)

local human = gfx.imagetable.new("img/T_Spritesheet_Human")
assert(human)

local stick = gfx.image.new("img/T_Stick.png")
assert(stick)

local bubble = gfx.image.new("img/T_Bubble")
assert(bubble)

local tower = gfx.imagetable.new("img/T_Spritesheet_Tower")
assert(tower)

local ui_button = gfx.image.new("img/ui/T_BTN_Directional.png")
assert(ui_button)

local KEYS <const> = { 4, 2, 8, 1 }
local KEYS_ANGLE <const> = { 0, 90, 180, 270 }

-- Start parameters to tweak

local PAD_START <const> = 1
local PAD_GAIN <const> = 0.15
local PAD_DECAY <const> = 0.001
local PAD_MAX_INPUTS <const> = 5

local NOISE_START <const> = 0.5
local NOISE_MULTIPLIER <const> = 0.05
local NOISE_DECAY <const> = 0.001
local NOISE_TOLERANCE <const> = 0.1

local CRANK_START <const> = 0.5
local CRANK_MULTIPLIER <const> = 0.001
local CRANK_DECAY <const> = 0.001

local RANDOM_INTENSITY <const> = 5
local RANDOM_VARIANCE <const> = 100

local BASIC_SPEED_START <const> = 0.5
local BASIC_SPEED_INCREMENT <const> = 0.0001
local BASIC_SPEED_MAX <const> = 1.5

-- End parameters to tweak

local is_game_running = false

-- 1-4 NESO
local pad_combination
local pad_current_key

local pad_current

local noise_amount
local noise_current

local crank_amount
local crank_current

local rand_reach_counter
local rand_value

local blinking_counter
local is_blinking

local is_blowing

local basic_speed

math.randomseed(playdate.getSecondsSinceEpoch())

function math.clamp(x, min, max)
    return math.max(math.min(x, max), min)
end

local function process_random_counter()
    rand_reach_counter -= 1
    if rand_reach_counter <= 0 then
        rand_value = math.random(-RANDOM_INTENSITY, RANDOM_INTENSITY)
        rand_reach_counter = math.random(0, RANDOM_VARIANCE)
    end
end

local function generate_pad_combination()
    local curr_elements = #pad_combination + 1
    curr_elements = math.clamp(curr_elements, 0, PAD_MAX_INPUTS)
    pad_combination = {}
    for i = 1, curr_elements do
        table.insert(pad_combination, math.random(1, 4))
    end
end

local function reset()
    pad_combination = {}
    generate_pad_combination()
    pad_current_key = 1

    pad_current = PAD_START

    noise_amount = 0
    noise_current = NOISE_START

    crank_amount = 0
    crank_current = CRANK_START

    rand_reach_counter = 0
    rand_value = 0

    is_blowing = false

    basic_speed = BASIC_SPEED_START

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
    if noise_amount >= NOISE_TOLERANCE then
        noise_current += (noise_amount * NOISE_MULTIPLIER) * basic_speed
        is_blowing = true
    else
        is_blowing = false
    end
    crank_current += (crank_amount * CRANK_MULTIPLIER) * basic_speed

    if basic_speed <= BASIC_SPEED_MAX then
        basic_speed += BASIC_SPEED_INCREMENT
    end
end

local function process_decay(rand)
    pad_current -= PAD_DECAY * basic_speed
    noise_current -= NOISE_DECAY * basic_speed
    crank_current -= (CRANK_DECAY * rand) * basic_speed
end

local function process_clamping()
    pad_current = math.clamp(pad_current, 0, 1)
    noise_current = math.clamp(noise_current, 0, 1)
    crank_current = math.clamp(crank_current, 0, 1)
end

local function check_game_over()
    if pad_current <= 0 then
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

    bg_tower:draw(264, 96)

    -- test = { math.floor(0.1 * 4) + 1, math.floor(0.33 * 4) + 1, math.floor(0.66 * 4) + 1, math.floor(0.9 * 4) + 1 }
    -- printTable(test)

    if is_game_running then
        local human_id = 4 - (math.floor(pad_current * 4) + 1)
        human_id = math.clamp(human_id, 1, 4)
        if is_blowing then
            human_id += 4
        end
        human:drawImage(human_id, 0, 0)
    end

    for i = 1, 6 do
        tower:drawImage(2, 305, 240 - (240 * crank_current) + (37 * i))
    end

    tower:drawImage(1, 305, 240 - (240 * crank_current))

    tower:drawImage(3, 305, 203)

    stick:draw(158, 130)

    bubble:drawScaled(180, 170 - (60 * noise_current), noise_current)

    gfx.setColor(gfx.kColorWhite)
    gfx.setDitherPattern(0.8, gfx.image.kDitherTypeBayer8x8)
    gfx.drawCircleInRect(180, 110, 110, 110)

    for i = 1, #pad_combination do
        if pad_current_key <= i then
            ui_button:drawRotated((40 * i) - 10, 30, KEYS_ANGLE[pad_combination[i]])
        end
    end

    if is_game_running == false then
        human:drawImage(9, 0, 0)
        gfx.setColor(gfx.kColorXOR)
        gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer8x8)
        gfx.fillRect(0, 0, 400, 240)
    end

    pd.drawFPS(0, 0)
end

function pd.deviceDidUnlock()
    snd.micinput.startListening()
end
