
local split = require('split')
local utils = require 'utils'
local persistTable = require 'persist-table'
local requirementCheck = require('events.requirements-check')
local findUnit = require('events.find-unit')
local findItem = require('events.find-item')
local findLocation = require('events.find-location')
local findBuilding = require('events.find-building')
local getValue = require('wrapper.getValue')

function permute(tab)
 n = #tab
 for i = 1, n do
  local j = math.random(i, n)
  tab[i], tab[j] = tab[j], tab[i]
 end
 return tab
end

validArgs = validArgs or utils.invert({
 'help',
 'event',
 'force',
 'verbose',
 'forceAll'
})
local args = utils.processArgs({...}, validArgs)

force = false
verbose = false
forceAll = false
if args.force then force = true end
if args.verbose then verbose = true end
if args.forceAll then
 force = true
 forceAll = true
end

triggered = {}
events = persistTable.GlobalTable.roses.EventTable
event = events[args.event]
if requirementCheck(event,0) or force then
 triggered[0] = true
 effects = tonumber(event.Effects)
 delay = 0
 if event.Delay then
  if event.Delay._children[1] == 'RANDOM' then
   delay = dfhack.random.new():random(tonumber(event.Delay.RANDOM))+1
  elseif event['Delay']._children[1] == 'STATIC' then
   delay = tonumber(event.Delay.STATIC)
  end
 end
 for i = 1,effects,1 do
  effect = event.Effect[tostring(i)]
  chance = effect.Chance
  contingency = effect.Contingent or 0
  if contingency > i then
   if verbose then print("can't have an effect contingent on a later effect, only on earlier effects") end
   contingency = 0
  elseif contingency == i then
   if verbose then print("Can't have an effect contingent on itself") end
   contingency = 0
  end
  local rando = dfhack.random.new()
  rnum = rando:random(100)+1
  if tonumber(chance) >= rnum and triggered[contingency] then
   triggered[i] = requirementCheck(event,i)
  end
  if triggered[i] or forceAll then
   if effect.Unit then unit = findUnit(effect.Unit) end
   if effect.Location then location = findLocation(effect.Location) end
   if effect.Building then building = findBuilding(effect.Building) end
   if effect.Item then item = findItem(effect.Item) end
   if effect.Delay then
    if effect.Delay._children[1] == 'RANDOM' then
     delay = delay + dfhack.random.new():random(tonumber(effect.Delay.RANDOM))+1
    elseif effect['Delay']._children[1] == 'STATIC' then
     delay = delay + tonumber(effect.Delay.STATIC)
    end
   end
   number = effect.Arguments
   scripts = effect.Scripts
   int = 0
   arg = {}
   while int < number do
    int = int+1
    argument = effect.Argument[tostring(int)]
    weighting = argument.Weighting or false
    wghtArray = split(weighting,',')
    temparray = {}
    tempint = 0
    for j = 1,#wghtArray,1 do
     for k = 1,wghtarray[j],1 do
      tempint = tempint+1
      temparray[tempint] = j
 	 end
    end
    argumentNum = permute(temparray)[1]
    if argument['Equation'] then
     arg[int] = getValue(split(argument.Equation,',')[argumentNum],unit,nil)
    elseif argument['Variable'] then
     arg[int] = split(argument.Value,',')[argumentNum]
    else
     print('Problem with selection of argument')
	 return
    end
   end
   for j = 1,scripts,1 do
    script = effect.Script[tostring(j)]
    script = script:gsub('%!UNIT',tostring(unit.id))
    script = script:gsub('%!LOCATION',location)
    script = script:gsub('%!BUILDING',tostring(building.id))
    script = script:gsub('%!ITEM',tostring(item.id))
    for k = 1,number,1 do
     script = script:gsub('%!ARG_'..tostring(k),tostring(arg[k]))
    end
    if delay == 0 then
     dfhack.run_script(script)
    else
     dfhack.timeout(delay,'ticks',function () dfhack.run_script(script) end)
    end
   end
  end
 end
end
