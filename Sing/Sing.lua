_addon.author = 'Ivaar'
_addon.commands = {'Singer','sing'}
_addon.name = 'Singer'
_addon.version = '1.15.06.15'

require('luau')
require('pack')
packets = require('packets')
texts = require('texts')
song_id = require('spells')

default = {
    delay=3,
    dummy1='Knight\'s Minne',
    dummy2='Knight\'s Minne II',
    marcato='valor minuet v',
    clarion='minuet',
    actions=false,
    pianissimo=false,
    precast=20,
    display = true,
    aoe=L{},
    song={},
    songs={march=2},
    min_ws_hp=20,
    max_ws_hp=99,
    text={}
    }

setting = config.load(default)

nexttime = os.clock()
del = 0
timers = {AoE = {},}

equipment = L{
    [21407] = 'Terpander',
    [20561] = 'Carnwenhan',--119
    [20562] = 'Carnwenhan',--119-2
    [20629] = 'Legato Dagger',
    [18575] = 'Daurdabla',--90
    [18576] = 'Daurdabla',--95
    [18571] = 'Daurdabla',--99
    [18839] = 'Daurdabla',--99-2
    [18572] = 'Gjallarhorn',--99
    [18840] = 'Gjallarhorn',--99-2
    [27672] = 'Brioso Roundlet',
    [27693] = 'Brioso Roundlet +1',
    [28232] = 'Brioso Slippers',
    [28253] = 'Brioso Slippers +1',
    [28074] = 'Mdk. Shalwar +1',
    [11113] = 'Ad. Mnchtte. +2',
    [11093] = 'Aoidos\' Hngrln. +2',
    [11073] = 'Aoidos\' Calot +2',
    [11133] = 'Aoidos\' Rhing. +2',
    [11153] = 'Aoidos\' Cothrn. +2',
    [11618] = 'Aoidos\' Matinee',
    [26758] = 'Fili Calot',
    [26759] = 'Fili Calot +1',
    [26916] = 'Fili Hongreline',
    [26917] = 'Fili Hongreline +1',
    [27070] = 'Fili Manchettes',
    [27071] = 'Fili Manchettes +1',
    [27255] = 'Fili Rhingrave',
    [27256] = 'Fili Rhingrave +1',
    [27429] = 'Fili Cothurnes',
    [27430] = 'Fili Cothurnes +1',
    }

buff_ids = L{
    [195] = 'Paeon',
    [196] = 'Ballad',
    [197] = 'Minne',
    [198] = 'Minuet',
    [199] = 'Madrigal',
    [200] = 'Prelude',
    [201] = 'Mambo',
    [202] = 'Aubade',
    [203] = 'Pastoral',
    [205] = 'Fantasia',
    [206] = 'Operetta',
    [207] = 'Capriccio',
    [209] = 'Round',
    [210] = 'Gavotte',
    [214] = 'March',
    [215] = 'Etude',
    [216] = 'Carol',
    [218] = 'Hymnus',
    [219] = 'Mazurka',
    [220] = 'Sirvente',
    [221] = 'Dirge',
    [222] = 'Scherzo',
    }

buff_songs = {
    Paeon = {[1]='Army\'s Paeon VI',[2]='Army\'s Paeon V',[3]='Army\'s Paeon IV',[4]='Army\'s Paeon III',[5]='Army\'s Paeon II',[6]='Army\'s Paeon'},
    Ballad = {[1]='Mage\'s Ballad III',[2]='Mage\'s Ballad II',[3]='Mage\'s Ballad'},
    Minne = {[1]='Knight\'s Minne V',[2]='Knight\'s Minne IV',[3]='Knight\'s Minne III',[4]='Knight\'s Minne II',[5]='Knight\'s Minne'},
    Minuet = {[1]='Valor Minuet V',[2]='Valor Minuet IV',[3]='Valor Minuet III',[4]='Valor Minuet II',[5]='Valor Minuet'}, 
    Madrigal = {[1]='Blade Madrigal',[2]='Sword Madrigal'},
    Prelude = {[1]='Archer\'s Prelude',[2]='Hunter\'s Prelude'},
    Mambo = {[1]='Dragonfoe Mambo',[2]='Sheepfoe Mambo'},
    Aubade = {[1]='Fowl Aubade'},
    Pastoral = {[1]='Herb Pastoral'},
    Fantasia = {[1]='Shining Fantasia'},
    Operetta = {[1]='Puppet\'s Operetta',[2]='Scop\'s Operetta'},
    Capriccio = {[1]='Gold Capriccio'},
    Round = {[1]='Warding Round'},
    Gavotte = {[1]='Shining Fantasia'},
    March = {[1]='Victory March',[2]='Advancing March'},
    Hymnus = {[1]='Goddess\'s Hymnus'},
    Mazurka = {[1]='Chocobo Mazurka'},
    Sirvente = {[1]='Foe Sirvente'},
    Dirge = {[1]='Adventurer\'s Dirge'},
    Scherzo = {[1]='Sentinel\'s Scherzo'},
    }

display_box = function()
    if setting.actions then
        return ' SING Auto-Songs [On] '
    else
        return ' SING Auto-Songs [Off] '
    end
end

bard_status = texts.new(display_box(),setting.text,setting)
bard_status:show()

function find_item(id)
    local items = windower.ffxi.get_items()
    for i,v in ipairs(items.inventory) do
        if v and v.id == id then
        return true
        end
    end
    for i,v in ipairs(items.wardrobe) do
        if v and v.id == id then
        return true
        end
    end
    return false
end

function find_extra_song_harp()
    if find_item(21407) or find_item(18575) or find_item(18576) then
        base_songs = 3
    elseif find_item(18571) or find_item(18839) then
        base_songs = 4
    else
        base_songs = 2
    end
end
find_extra_song_harp()

windower.register_event('prerender',function ()
    if not setting.actions then return end
    local curtime = os.clock()
    if nexttime + del <= curtime then
        nexttime = curtime
        del = 0.1
        for k,v in pairs(timers) do
            update_timers(k)
        end
        local play = windower.ffxi.get_player()
        if not play or play.main_job ~= 'BRD' or (play.status ~= 1 and play.status ~= 0) then return end
        local JA_WS_lock
        local moving = is_moving()
        local buffs = calculate_buffs(play.buffs)
        local maxsongs = aug_maxsongs('AoE',buffs)
        local spell_recasts = windower.ffxi.get_spell_recasts()
        local precast = math.random(setting.precast,setting.precast+10)+math.random()
        if moving or casting or buffs.stun or buffs.sleep or buffs.charm or buffs.terror or buffs.petrification then return end
        if buffs.amnesia or buffs.impairment then JA_WS_lock = true end
        if play.status == 1 and equip('main') == 'Carnwenhan' and not JA_WS_lock then
            local targ = windower.ffxi.get_mob_by_target('t')
            local Eye_Sight = eye_sight(windower.ffxi.get_mob_by_target('me'),targ)
            if not AM_start and buffs['aftermath: lv.3'] then
                AM_start = curtime
            end
            if buffs['aftermath: lv.3'] and AM_start and curtime - AM_start <= 140 then
                goal_tp = 1000
            else
                goal_tp = 3000
            end
            if Eye_Sight and play.vitals.tp >= goal_tp and targ and targ.valid_target and targ.hpp < setting.max_ws_hp and targ.hpp > setting.min_ws_hp and targ.is_npc and math.sqrt(targ.distance) <= 4 and ((goal_tp == 3000 and not buffs['aftermath: lv.3']) or goal_tp == 1000) then
                if goal_tp == 3000 then
                    AM_start = curtime
                end
                windower.send_command('input /ws "Mordant Rime" <t>')
                del = 4.2
                return
            end
        end
        if buffs.silence or buffs.mute or buffs.omerta then return end
        if not aoe_range() then
            local dummy = apply_dummy('AoE',maxsongs,spell_recasts)
            if dummy then cast_song(dummy,'<me>',buffs) return end
            for buff,num in pairs(setting.songs) do
                for x = 1,num do
                    local song = buff_songs[buff:ucfirst()][x]
                    local timer = timers['AoE'][song]
                    if (song and spell_recasts[get_song_id(song)] <= 0) and 
                       (not timer or os.time()-timer.ts+precast>0 or (buffs.troubadour and not timer.nt) or (buffs['soul voice'] and not timer.sv)) then--not buffs[buff] or buffs[buff] < x 
                        cast_song(song,'<me>',buffs,JA_WS_lock)
                        return
                    end
                end
            end
        end
        if not setting.pianissimo then return end
        for targ,songs in pairs(setting.song) do
            if valid_target(targ,20) then
                local dummy = apply_dummy(targ,maxsongs,spell_recasts)
                if dummy then cast_song(dummy,targ,buffs) return end
                for ind,song in ipairs(songs) do
                    local timer = timers[targ]
                    if (setting.song[targ][ind] and spell_recasts[get_song_id(song)] <= 0) and
                       (not timer or not timer[song] or os.time()-timer[song].ts+precast>0 or (buffs.troubadour and not timer[song].nt) or (buffs['soul voice'] and not timer[song].sv)) then
                        cast_song(song,targ,buffs,JA_WS_lock)
                        return
                    end
                end
            end
        end
    end
end)

function apply_dummy(targ,maxsongs,spell_recasts)
    if base_songs == 4 and timers[targ] and table.length(timers[targ]) == maxsongs-2 and spell_recasts[get_song_id(setting.dummy2)] <= 0 then
        return setting.dummy2
    elseif base_songs >= 3 and timers[targ] and table.length(timers[targ]) == maxsongs-1 and spell_recasts[get_song_id(setting.dummy1)] <= 0 then
        return setting.dummy1
    end
    return false
end

function get_coords()
    local play = windower.ffxi.get_mob_by_target('me')
    if play then
        return {play.x,play.z,play.y}
    else
        return {0,0,0}
    end 
end

function is_moving()
    local coords = get_coords()
    local clock = os.clock()
    lastcoords = lastcoords and lastcoords or coords
    for x=1,3 do if lastcoords[x] ~= coords[x] then lastcoords=coords ts=clock return true end end
    if ts and ts+1>clock then return true end
    return false
end


function valid_target(targ,dst)
    for ind,member in pairs(windower.ffxi.get_party()) do
        if type(member) == 'table' and member.mob and member.mob.name:lower() == targ:lower() and math.sqrt(member.mob.distance) < dst and not member.mob.charmed and member.mob.hpp > 0 and member.mob.in_party then
           return true
        end
    end
    return false
end

function eye_sight(player,target)
    if not target then return false end
    local xdif = target.x - player.x -- Negative if target is west
    local ydif = target.y - player.y -- Negative if target is south
    if math.abs(-math.atan2(ydif,xdif)-player.facing) < 0.76 then
        return true
    else
        return false
    end
end

windower.register_event('addon command', function(...)
    local commands = {...}
    if commands[1] then
        commands[1] = commands[1]:lower()
        if commands[1] == 'on' then
            find_extra_song_harp()
            setting.actions = true
        elseif commands[1] == 'off' then
            setting.actions = false
        elseif commands[1] == 'song' and commands[4] then
            local player = windower.ffxi.get_mob_by_name(commands[2]:ucfirst()).name
            local song = table.concat(commands,' ',3,#commands-1):lower()
            if commands[#commands] == '+' then
                if not setting.song[player] then setting.song[player] = L{} end
                if not setting.song[player]:find(song) then
                    setting.song[player]:append(song)
                    windower.add_to_chat(207, 'Will now Pianissimo %s for %s.':format(song,player))
                else
                    windower.add_to_chat(207, '%s is already for %s.':format(song,player))
                end 
            elseif commands[#commands] == '-' then
                if not setting.song[player] then return end
                local ind = setting.song[player]:find(song)
                if ind then
                    setting.song[player]:remove(ind)
                    windower.add_to_chat(207, 'Will no longer Pianissimo %s for %s.':format(song,player))
                else
                    windower.add_to_chat(207, 'Pianissimo %s is not set for %s.':format(song,player))
                end
            end
            for k,v in pairs(setting.song) do
                print(k,v)
            end
        elseif commands[1] == 'aoe' and commands[3] then
            local player = windower.ffxi.get_mob_by_name(commands[2]:ucfirst()).name
            if commands[3] == '+' then
                if not setting.aoe:find(player) then
                    setting.aoe:append(player)
                    windower.add_to_chat(207, 'Will now ensure %s is in AoE casting range.':format(player))
                else
                    windower.add_to_chat(207, '%s\'s range is already being watched.':format(player))
                end
            elseif commands[3] == '-' then
                local ind = setting.aoe:find(player)
                if ind then
                    setting.aoe:remove(ind)
                    windower.add_to_chat(207, '%s will now be ignored for AoE.':format(player))
                else
                    windower.add_to_chat(207, '%s\'s range is not being watched.':format(player))
                end
            end
        elseif commands[1] == 'save' then
            setting:save()
            windower.add_to_chat(207, 'settings saved.')
        elseif commands[1] == 'eval' then
             assert(loadstring(table.concat(commands, ' ',2)))()
        elseif buff_songs[commands[1]:ucfirst()] and commands[2] then
            if commands[2] ~= '0' and tonumber(commands[2]) then
                setting.songs[commands[1]] = tonumber(commands[2])
            elseif commands[2] == '0' or commands[2] == 'off' then
                setting.songs[commands[1]] = nil
            end
        elseif type(setting[commands[1]]) == 'number' and commands[2] and tonumber(commands[2]) then
            setting[commands[1]] = tonumber(commands[2])
            windower.add_to_chat(207, '%s is now set to %d':format(commands[1],setting[commands[1]]))
        elseif type(setting[commands[1]]) == 'string' then
            setting[commands[1]] = table.concat(commands, ' ',2):lower()
             windower.add_to_chat(207, '%s is now set to %s':format(commands[1],setting[commands[1]]))
        elseif type(setting[commands[1]]) == 'boolean' then
            if not commands[2] and setting[commands[1]] == true or commands[2] and commands[2]:lower() == 'off' then
                setting[commands[1]] = false
            elseif not commands[2] or commands[2] and commands[2]:lower() == 'on' then
                setting[commands[1]] = true 
            end
            windower.add_to_chat(207, '%s is now %s':format(commands[1],setting[commands[1]] and 'On' or 'Off'))
            print(setting.aoe)
        end
    end
    bard_status:text(display_box())
    local str = ''
    for k,v in pairs(setting.songs) do
        str = str..'%s x%d ':format(k:ucfirst(),v)
    end
    for k,v in pairs(default) do
        if k == 'pianissimo' then
            str = str..'%s:[%s] ':format(k:ucfirst(),setting[k] and 'On' or 'Off')
        elseif type(v) == 'string' then
            str = str..'%s:[%s] ':format(k:ucfirst(),setting[k]:ucfirst())
        elseif type(v) == 'number' then
            str = str..'%s:[%d] ':format(k:ucfirst(),setting[k])
        end
    end
    windower.add_to_chat(207, str)
end)

function calculate_buffs(curbuffs)
    local buffs = {}
    for i,v in pairs(curbuffs) do
        if res.buffs[v] and res.buffs[v].english then
            buffs[res.buffs[v].english:lower()] = (buffs[res.buffs[v].english:lower()] or 0) + 1
        end
    end
    return buffs
end

function use_JA(str)
    windower.send_command(str)
    del = 1.2
end

function use_MA(str,ta)
    windower.send_command('input /ma "%s" %s':format(str,ta))
    del = setting.delay
end

function cast_song(str,ta,buffs,JA_WS_lock)
    local recasts = windower.ffxi.get_ability_recasts()
    if not JA_WS_lock and not buffs.nightingale and recasts[109] <= 0 then
        use_JA('input /ja "Nightingale" <me>')
    elseif not JA_WS_lock and not buffs.troubadour and recasts[110] <= 0 then
        use_JA('input /ja "Troubadour" <me>')
    elseif not JA_WS_lock and str:lower() == setting.marcato and not buffs.marcato and not buffs['soul voice'] and recasts[48] <= 0 then
        use_JA('input /ja "Marcato" <me>')
    elseif ta ~= '<me>' and not buffs.pianissimo then--and recasts[112] <= 0 
         use_JA('input /ja "Pianissimo" <me>')
    else
        use_MA(str,ta)
    end
end

function aoe_range()
    for k,v in ipairs(setting.aoe) do
        if not valid_target(v,10) then
            return false
        end
    end
    return true
end

function song_to_buff(song,bool)
    for id,buff in ipairs(buff_ids) do
        if string.find(song,buff) then
            return bool and id,buff or buff
        end
    end
end

function get_song_id(song)
    for k,v in pairs(song_id) do
        if v:lower() == song:lower() then
            return k
        end
    end
    return nil
end

function equip(slot)
    local item = windower.ffxi.get_items().equipment
    return equipment[windower.ffxi.get_items(item[slot..'_bag'],item[slot]).id] or ''
end

function calculate_duration(name,buffs)
    local mult = 1
    if equip('range') == 'Daurdabla' then mult = mult + 0.3 end    -- 0.25 for 90, 0.3 for 99
    if equip('range') == 'Gjallarhorn' then mult = mult + 0.4 end  -- 0.3 for 95, 0.4 for 99
    if equip('main') == 'Carnwenhan' then mult = mult + 0.5 end    -- 0.1 for 75, 0.4 for 95, 0.5 for 99/119
    if equip('main') == 'Legato Dagger' then mult = mult + 0.05 end
    if equip('sub') == 'Legato Dagger' then mult = mult + 0.05 end
    if equip('neck') == 'Aoidos\' Matinee' then mult = mult + 0.1 end
    if equip('body') == 'Aoidos\' Hngrln. +2' then mult = mult + 0.1 end
    if equip('legs') == 'Mdk. Shalwar +1' then mult = mult + 0.1 end
    if equip('feet') == 'Brioso Slippers' then mult = mult + 0.1 end
    if equip('feet') == 'Brioso Slippers +1' then mult = mult + 0.11 end
    if equip('body') == 'Fili Hongreline' then mult = mult + 0.11 end
    if equip('body') == 'Fili Hongreline +1' then mult = mult + 0.12 end
    if string.find(name,'March') and equip('hands') == 'Ad. Mnchtte. +2' then mult = mult + 0.1 end
    if string.find(name,'Minuet') and equip('body') == 'Aoidos\' Hngrln. +2' then mult = mult + 0.1 end
    if string.find(name,'Madrigal') and equip('head') == 'Aoidos\' Calot +2' then mult = mult + 0.1 end
    if string.find(name,'Ballad') and equip('legs') == 'Aoidos\' Rhing. +2' then mult = mult + 0.1 end
    if string.find(name,'Scherzo') and equip('feet') == 'Aoidos\' Cothrn. +2' then mult = mult + 0.1 end
    if string.find(name,'March') and equip('hands') == 'Fili Manchettes' then mult = mult + 0.1 end
    if string.find(name,'Minuet') and equip('body') == 'Fili Hongreline' then mult = mult + 0.1 end
    if string.find(name,'Madrigal') and equip('head') == 'Fili Calot' then mult = mult + 0.1 end
    if string.find(name,'Ballad') and equip('legs') == 'Fili Rhingrave' then mult = mult + 0.1 end
    if string.find(name,'Scherzo') and equip('feet') == 'Fili Cothurnes' then mult = mult + 0.1 end 
    if string.find(name,'March') and equip('hands') == 'Fili Manchettes +1' then mult = mult + 0.1 end
    if string.find(name,'Minuet') and equip('body') == 'Fili Hongreline +1' then mult = mult + 0.1 end
    if string.find(name,'Madrigal') and equip('head') == 'Fili Calot +1' then mult = mult + 0.1 end
    if string.find(name,'Ballad') and equip('legs') == 'Fili Rhingrave +1' then mult = mult + 0.1 end
    if string.find(name,'Scherzo') and equip('feet') == 'Fili Cothurnes +1' then mult = mult + 0.1 end
    if string.find(name,'Paeon') and equip('head') == 'Brioso Roundlet' then mult = mult + 0.1 end
    if string.find(name,'Paeon') and equip('head') == 'Brioso Roundlet +1' then mult = mult + 0.1 end
    if buffs.troubadour then
        mult = mult*2
    end
    if string.find(name,'Scherzo') and buffs['soul voice'] then
        mult = mult*2
    elseif string.find(name,'Scherzo') and buffs.marcato then
        mult = mult*1.5
    end
    return math.floor(mult*120)
end

windower.register_event('incoming chunk', function(id,original,modified,injected,blocked)
    if id == 0x028 then
        local packet = packets.parse('incoming', original)
        local play = windower.ffxi.get_player()
        local targ = windower.ffxi.get_mob_by_id(packet['Target 1 ID']).name
        local actor = windower.ffxi.get_mob_by_id(packet['Actor']).name
        if packet['Category'] == 8 and actor == play.name then
            if (packet['Param'] == 24931) then
            -- Begin Casting
                casting = true
            elseif (packet['Param'] == 28787) then
            -- Failed Casting
                casting = false
                del = 1
            end
        elseif packet['Category'] == 4 and actor == play.name then
            -- Finish Casting
            casting = false
            del = setting.delay
            if not song_id[packet['Param']] then return end
            local buffs = calculate_buffs(play.buffs)
            local spell_name = song_id[packet['Param']]
            if packet['Target Count'] > 1 then
                adjust_timers(spell_name,'AoE',buffs)
            end
            for x = 1,packet['Target Count'] do
                local targ_name = windower.ffxi.get_mob_by_id(packet['Target '..x..' ID']).name
                adjust_timers(spell_name,targ_name,buffs)
            end
        elseif packet['Category'] == 7 and actor == play.name then
            casting = true
        elseif packet['Category'] == 9 and actor == play.name then
            casting = true
        elseif packet['Category'] == 3 and actor == play.name then
            casting = false
        elseif packet['Category'] == 5 and actor == play.name then
            casting = false
        end
    elseif id == 0x029 then
        local packet = packets.parse('incoming', original)
        --table.vprint(packet)
        local play = windower.ffxi.get_player().name
        local targ = windower.ffxi.get_mob_by_id(packet['Target']).name
        local actor = windower.ffxi.get_mob_by_id(packet['Actor']).name
        if (packet.Message) == 206 and actor == play then
            --print(targ_name,res.buffs[packet['Param 1']].en)
            buff_lost(targ,res.buffs[packet['Param 1']].en)
        end
    end
end)

function buff_lost(targ,buff)
    local buff = buff_songs[buff]
    if not buff or not timers[targ] then return end
    local minimum,song
    for k,song_name in pairs(buff) do
        local song_timer = timers[targ][song_name].ts
        if song_timer and (not minimum or song_timer < minimum) then
            minimum = song_timer
            song = song_name
        end
    end
    if not song then return end
    if not setting.song[targ] then delete_timer(song,'AoE') end
    delete_timer(song,targ)
end

function update_timers(targ)
    if not timers[targ] then timers[targ] = {} end
    local current_time = os.time()
    local temp_timer_list = {}
    for song_name,expires in pairs(timers[targ]) do
        if expires.ts < current_time then
            temp_timer_list[song_name] = true
        end
    end
    for song_name,expires in pairs(temp_timer_list) do
        timers[targ][song_name] = nil
    end
end

function aug_maxsongs(targ,buffs)
    local maxsongs = base_songs
    if buffs['clarion call'] then
        maxsongs = maxsongs + 1 
    end
    if maxsongs < table.length(timers[targ]) then
        maxsongs = table.length(timers[targ])
    end
    return maxsongs
end

function delete_timer(song,targ)
    timers[targ][song] = nil
    windower.send_command('timers delete "%s [%s]"':format(song,targ))
end

function create_timer(song,targ,dur,current_time,buffs)
    timers[targ][song] = {ts=current_time+dur,nt=buffs.troubadour,sv=buffs['soul voice']}
    if timers.AoE[song] and targ ~= 'AoE' or not setting.display then return end
    windower.send_command('timers create "%s [%s]" %s down':format(song,targ,dur))
end
              
function adjust_timers(spell_name,targ,buffs)
    local current_time = os.time()
    local dur = calculate_duration(spell_name,buffs)
    update_timers(targ)
    if timers[targ][spell_name] then
        if timers[targ][spell_name].ts < (current_time + dur) then
            create_timer(spell_name,targ,dur,current_time,buffs)
        end
    else
        if table.length(timers[targ]) < aug_maxsongs(targ,buffs) then
            create_timer(spell_name,targ,dur,current_time,buffs)
        else
            local rep,repsong
            for song_name,expires in pairs(timers[targ]) do
                if current_time + dur > expires.ts then
                    if not rep or rep > expires.ts then
                        rep = expires.ts
                        repsong = song_name
                    end
                end
            end
            if repsong then
                delete_timer(repsong,targ)
                create_timer(spell_name,targ,dur,current_time,buffs)
            end
        end
    end
end

function reset_timers()
    for k,targ in pairs(timers) do
        for i,v in pairs(targ) do
            windower.send_command('timers delete "%s [%s]"':format(i,k))
        end
    end
    timers = {}
    timers['AoE'] = {}
    casting = false
end

function change()
    setting.actions = false
    casting = false
    reset_timers()
    bard_status:text(display_box())
end

function status_change(new,old)
    casting = false
    if new == 2 or new == 3 then
        change()
    end
end

windower.register_event('unload', reset_timers)
windower.register_event('status change', status_change)
windower.register_event('zone change','job change','logout', change)
