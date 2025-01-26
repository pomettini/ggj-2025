import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/ui"

local pd <const> = playdate
local gfx <const> = playdate.graphics
local snd <const> = playdate.sound

-- Font

local nontendo = gfx.font.new("font/Nontendo-Bold")
assert(nontendo)
gfx.setFont(nontendo)

local nontendo_2x = gfx.font.new("font/Nontendo-Bold-2x")
assert(nontendo_2x)

-- Image assets

local tt_turn_device = gfx.image.new("img/ui/T_RotatePlaydate")
assert(tt_turn_device)

local tt_base_panel = gfx.image.new("img/ui/T_BasePanel")
assert(tt_base_panel)

local tt_bubble = gfx.image.new("img/T_TutorialBubblet")
assert(tt_bubble)

local tt_dir_arrows = gfx.image.new("img/ui/T_DirectionalArrows")
assert(tt_dir_arrows)

local tt_turn_crank = gfx.image.new("img/ui/T_TurnCrank")
assert(tt_turn_crank)

local tt_mic_blow = gfx.image.new("img/ui/T_MicBlow")
assert(tt_mic_blow)

local bg_tower = gfx.image.new("img/T_Tower_BG")
assert(bg_tower)

local bg_tower_ruins = gfx.image.new("img/T_Tower_BG_Ruins")
assert(bg_tower_ruins)

local human = gfx.imagetable.new("img/T_Spritesheet_Human")
assert(human)

local stick = gfx.image.new("img/T_Stick")
assert(stick)

local bubble = gfx.image.new("img/T_Bubble")
assert(bubble)

local tower = gfx.imagetable.new("img/T_Spritesheet_Tower")
assert(tower)

local bubble_sheet = gfx.imagetable.new("img/T_Bubble-sheet")
assert(bubble_sheet)

local safe_area_bubble = gfx.image.new("img/T_SafeAreaBubble")
assert(safe_area_bubble)

local ui_button = gfx.image.new("img/ui/T_BTN_Directional")
assert(ui_button)

local ui_hourglass = gfx.imagetable.new("img/ui/T_Spritesheet_Hourglass")
assert(ui_hourglass)

local ui_btn_a = gfx.image.new("img/ui/T_BTN_A")
assert(ui_btn_a)

local ui_gameover = gfx.image.new("img/ui/T_GameOver")
assert(ui_gameover)

local ui_bg_factories = gfx.image.new("img/T_BG_Factories")
assert(ui_bg_factories)

local ui_tick = gfx.image.new("img/ui/T_Tick")
assert(ui_tick)

-- Sound assets

local music_main = snd.sampleplayer.new("sfx/mega")
assert(music_main)
music_main:setVolume(0.9)

local music_game_over = snd.sampleplayer.new("sfx/morte")
assert(music_game_over)
music_game_over:setVolume(0.9)

local sfx_factory = snd.sampleplayer.new("sfx/fabbrica")
assert(sfx_factory)

local sfx_tower_crash = snd.sampleplayer.new("sfx/crollo")
assert(sfx_tower_crash)

local sfx_input = snd.sampleplayer.new("sfx/input")
assert(sfx_input)

local sfx_fault = snd.sampleplayer.new("sfx/errore")
assert(sfx_fault)

local sfx_confirm = snd.sampleplayer.new("sfx/conferma")
assert(sfx_confirm)

local sfx_bubble = snd.sampleplayer.new("sfx/bolla")
assert(sfx_bubble)

local sfx_bubble_explode = snd.sampleplayer.new("sfx/scoppia")
assert(sfx_bubble_explode)

local sfx_smoke = snd.sampleplayer.new("sfx/fumo")
assert(sfx_smoke)

local KEYS <const> = { 4, 2, 8, 1 }
local KEYS_ANGLE <const> = { 0, 90, 180, 270 }

local HOURGLASS_SCALE <const> = 0.8

-- Start parameters to tweak

local PAD_START <const> = 0
local PAD_MAX_INPUTS <const> = 5

local NOISE_START <const> = 0.5
local NOISE_MULTIPLIER <const> = 0.05
local NOISE_DECAY <const> = 0.001
local NOISE_TOLERANCE <const> = 0.1

local CRANK_START <const> = 0.5
local CRANK_MULTIPLIER <const> = 0.001
local CRANK_DECAY <const> = 0.001

local AGING_START <const> = 0.5

local RANDOM_INTENSITY <const> = 5
local RANDOM_VARIANCE <const> = 100

local BASIC_SPEED_START <const> = 0.5
local BASIC_SPEED_INCREMENT <const> = 0.0002
local BASIC_SPEED_MAX <const> = 1.5

local BLINK_SPEED <const> = 1.0

-- End parameters to tweak

local score = 0

local tutorial_step = 1
local tutorial_completion = 0

local is_game_running = false

-- 1-4 NESO
local pad_combination
local pad_current_key

local pad_current

local noise_amount
local noise_current

local crank_amount
local crank_current

local aging_speed

local rand_reach_counter
local rand_value

local is_blowing

local blink_counter
local is_blinking

local basic_speed

local hourglass_counter

math.randomseed(playdate.getSecondsSinceEpoch())

function math.clamp(x, min, max)
    return math.max(math.min(x, max), min)
end

local function is_in_tutorial()
    return tutorial_step < 9
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
    pd.resetElapsedTime()

    score = 0

    pad_combination = {}
    generate_pad_combination()
    pad_current_key = 1

    pad_current = PAD_START

    noise_amount = 0
    noise_current = NOISE_START

    crank_amount = 0
    crank_current = CRANK_START

    aging_speed = AGING_START

    rand_reach_counter = 0
    rand_value = 0

    is_blowing = false

    basic_speed = BASIC_SPEED_START

    blink_counter = 0
    is_blinking = false

    hourglass_counter = 0

    is_game_running = true
end

local function process_inputs()
    local _, pressed, _ = pd.getButtonState()
    if pressed > 0 and pressed < 9 then
        if pressed == KEYS[pad_combination[pad_current_key]] then
            sfx_input:play()
            pad_current_key += 1
        else
            sfx_fault:play()
            pad_current_key = 1
        end
    end
    if pad_current_key >= #pad_combination + 1 then
        sfx_confirm:play()
        aging_speed -= 0.15
        generate_pad_combination()
        pad_current_key = 1
    end

    noise_amount = math.clamp(snd.micinput.getLevel(), 0, math.maxinteger)
    _, crank_amount = pd.getCrankChange()
    if math.abs(crank_amount) > 1 then
        sfx_factory:play(0)
    else
        sfx_factory:stop()
    end
end

local function process_increment()
    if noise_amount >= NOISE_TOLERANCE then
        noise_current += (noise_amount * NOISE_MULTIPLIER) * basic_speed
        sfx_bubble:play(0)
        is_blowing = true
    else
        sfx_bubble:stop()
        is_blowing = false
    end
    crank_current += (crank_amount * CRANK_MULTIPLIER) * basic_speed

    if basic_speed <= BASIC_SPEED_MAX then
        basic_speed += BASIC_SPEED_INCREMENT
    end

    blink_counter += BLINK_SPEED
    if blink_counter >= 10 then
        is_blinking = not is_blinking
        blink_counter = 0
    end

    hourglass_counter += (10 * aging_speed) * basic_speed
    if hourglass_counter >= 180 then
        hourglass_counter = -90
    end

    aging_speed += 0.0001 * basic_speed
    pad_current += (aging_speed * 0.001)
end

local function process_decay(rand)
    noise_current -= NOISE_DECAY * basic_speed
    crank_current -= (CRANK_DECAY * rand) * basic_speed
end

local function process_clamping()
    aging_speed = math.clamp(aging_speed, 0.01, 1)
end

local function play_game_over_music()
    music_game_over:play(1)
end

local function check_game_over()
    if pad_current <= 0 then
        play_game_over_music()
        is_game_running = false
    end
    if noise_current <= 0 or noise_current >= 1 then
        play_game_over_music()
        sfx_bubble_explode:play()
        is_game_running = false
    end
    if crank_current <= 0 or crank_current >= 1 then
        play_game_over_music()
        sfx_tower_crash:play()
        is_game_running = false
    end
end

local function draw_human()
    if is_game_running or is_in_tutorial() then
        local human_id = math.floor(pad_current * 4) + 1
        human_id = math.clamp(human_id, 1, 4)
        if is_blowing then
            human_id += 4
        end
        human:drawImage(human_id, 0, 0)
    end
end

local function draw_tower()
    if is_game_running or is_in_tutorial() then
        bg_tower:draw(264, 96)
    else
        bg_tower_ruins:draw(264, 96)
    end
    if (crank_current >= 0.1 and crank_current <= 0.9) or is_blinking or not is_game_running then
        for i = 1, 6 do
            tower:drawImage(2, 300, 240 - (240 * crank_current) + (41 * i))
        end
        tower:drawImage(1, 300, 240 - (240 * crank_current))
        tower:drawImage(3, 300, 199)
    end
end

local function draw_bubble()
    safe_area_bubble:draw(180, 110)
    stick:draw(158, 130)
    if (noise_current >= 0.1 and noise_current <= 0.9) or is_blinking or not is_game_running then
        bubble:drawScaled(180, 170 - (60 * noise_current), noise_current)
    end
end

local function draw_keys()
    for i = 1, #pad_combination do
        if pad_current_key <= i then
            ui_button:drawRotated((40 * i) - 10, 30, KEYS_ANGLE[pad_combination[i]])
        end
    end
end

local function draw_hourglass()
    if aging_speed <= 0.9 or is_blinking or not is_game_running then
        if hourglass_counter <= -60 then
            ui_hourglass:getImage(1):drawRotated(35, 205, 0, HOURGLASS_SCALE)
        elseif hourglass_counter <= -30 then
            ui_hourglass:getImage(2):drawRotated(35, 205, 0, HOURGLASS_SCALE)
        elseif hourglass_counter <= 0 then
            ui_hourglass:getImage(3):drawRotated(35, 205, 0, HOURGLASS_SCALE)
        else
            ui_hourglass:getImage(1):drawRotated(35, 205, 180 + hourglass_counter, HOURGLASS_SCALE)
        end
    end
end

local function process_tutorial(is_on, multiplier)
    if is_on then
        tutorial_completion += 0.02 * multiplier
        if tutorial_completion >= 1 then
            tutorial_completion = 0
            tutorial_step += 1
        end
    else
        if tutorial_completion >= 0 then
            tutorial_completion -= 0.01
        end
    end
end

local function draw_base_panel_tutorial()
    gfx.clear(gfx.kColorBlack)
    tt_base_panel:drawCentered(200, 120)
end

local function draw_bubble_tutorial()
    tt_bubble:drawRotated(200, 110, 0, math.clamp(tutorial_completion, 0, 0.85) * 1.5)
    if tutorial_completion >= 0.85 then
        ui_tick:drawCentered(200, 110)
    end
end

local function draw_score()
    gfx.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
    gfx.setFont(nontendo_2x)
    gfx.drawTextAligned(score, 385, 15, kTextAlignment.right)
    gfx.setImageDrawMode(playdate.graphics.kDrawModeCopy)
end

pd.resetElapsedTime()

snd.micinput.startListening()
pd.startAccelerometer()

pd.display.setRefreshRate(50)

reset()

is_game_running = false

function pd.update()
    gfx.clear(gfx.kColorBlack)

    if is_game_running then
        score = math.floor(pd.getElapsedTime() * 2 * basic_speed)
    end

    if tutorial_step > 8 then
        if is_game_running then
            if not music_main:isPlaying() then
                music_main:play(0)
            end
            if music_game_over:isPlaying() then
                music_game_over:stop()
            end
            process_random_counter()
            process_inputs()
            process_increment()
            process_decay(rand_value)
            process_clamping()
            check_game_over()
        else
            if music_main:isPlaying() then
                music_main:stop()
            end
            local _, pressed, _ = pd.getButtonState()
            if pressed >= 16 and tutorial_step > 5 then
                reset()
            end
        end

        ui_bg_factories:draw(0, 74)

        draw_human()
        draw_tower()
        draw_bubble()
        draw_keys()
        draw_hourglass()
        draw_score()
    end

    if is_game_running == false and tutorial_step > 8 then
        sfx_factory:stop()
        human:drawImage(9, 0, 0)
        gfx.setColor(gfx.kColorXOR)
        gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer8x8)
        gfx.fillRect(0, 0, 400, 240)
        ui_gameover:drawRotated(200, 100, math.sin(pd.getElapsedTime() * 5) * 5)
        gfx.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
        gfx.setFont(nontendo_2x)
        gfx.drawTextAligned("Press", 185, 200, kTextAlignment.center)
        gfx.setImageDrawMode(playdate.graphics.kDrawModeCopy)
        ui_btn_a:drawRotated(240, 210, 0, 0.75)
        draw_score()
    end

    -- tutorial_step = 9

    if tutorial_step == 1 then
        local _, y, _ = pd.readAccelerometer()
        if pd.accelerometerIsRunning() then
            process_tutorial(y >= 0.40 and y <= 0.50, 1)
        end
        draw_base_panel_tutorial()
        tt_turn_device:drawCentered(200, 110)
        gfx.drawTextAligned("Hold your Playdate like this!", 200, 195, kTextAlignment.center)
        draw_bubble_tutorial()
    elseif tutorial_step == 2 then
        process_tutorial(true, 0.33)
        draw_base_panel_tutorial()
        tt_dir_arrows:drawCentered(200, 110)
        gfx.drawTextAligned("Tap tap directionals tap tap idk man...", 200, 195, kTextAlignment.center)
    elseif tutorial_step == 3 then
        -- Tutorial pad
        process_tutorial(true, 0.33)
        draw_human()
        draw_keys()
        draw_hourglass()
    elseif tutorial_step == 4 then
        process_tutorial(true, 0.33)
        draw_base_panel_tutorial()
        tt_mic_blow:drawCentered(200, 120)
        gfx.drawTextAligned("Blow into the mic to keep the bubble inflated!", 200, 195, kTextAlignment.center)
    elseif tutorial_step == 5 then
        -- Tutorial bubble
        process_tutorial(true, 0.33)
        draw_bubble()
    elseif tutorial_step == 6 then
        process_tutorial(true, 0.33)
        draw_base_panel_tutorial()
        tt_turn_crank:drawCentered(200, 100)
        gfx.drawTextAligned("Turn the crank clock and counterclockwise to \nbalance industrial growth!", 200, 185,
            kTextAlignment.center)
    elseif tutorial_step == 7 then
        -- Tutorial crank
        process_tutorial(true, 0.33)
        draw_tower()
    elseif tutorial_step == 8 then
        reset()
        tutorial_step += 1
    end

    -- pd.drawFPS(0, 0)
end

function pd.deviceDidUnlock()
    snd.micinput.startListening()
    pd.startAccelerometer()
end
