local M
split = require('split')
local function checkSkills(unit,array,unitTarget) -- CHECK 1
 local rtempa,itempa,r,i,required,immune = {},{},1,1,false,false
 local rtext = 'Targeting failed, ' .. tostring(unit.name.first_name) .. "'s skills are too low."
 local itext = 'Targeting failed, ' .. tostring(unit.name.first_name) .. "'s skills are too high."
 if type(array) ~= 'table' then array = {array} end
 for _,x in ipairs(array) do
  local utemp = dfhack.units.getEffectiveSkill(unit,df.job_skill[split(x,':')[2]])
  if split(x,':')[1] == 'min' then
   if tonumber(split(age,':')[3]) > utemp then
    rtempa[r] = true
   else
    rtempa[r] = false
   end
   r = r + 1
  elseif split(x,':')[1] == 'max' then
   if tonumber(split(age,':')[3]) < utemp then
    itempa[i] = true
   else
    itempa[i] = false
   end
   i = i + 1
  elseif split(x,':')[1] == 'greater' then
   if utemp/dfhack.units.getEffectiveSkill(unitTarget,df.job_skill[split(x,':')[2]]) >= tonumber(split(x,':')[3]) then
    rtempa[r] = true
   else
    rtempa[r] = false
   end
   r = r + 1
  elseif split(x,':')[1] == 'less' then
   if utemp/dfhack.units.getEffectiveSkill(unitTarget,df.job_skill[split(x,':')[2]]) <= tonumber(split(x,':')[3]) then
    itempa[i] = true
   else
    itempa[i] = false
   end
   i = i + 1
  end
 end
 for _,x in ipairs(rtempa) do
  if x then required = true end
 end
 for _,x in ipairs(itempa) do
  if x then immune = true end
 end
 if required and not immune then return false,itext end
 if required and immune then return true,'NONE' end
 if not required and immune then return false,rtext end
 if not required and not immune then return false,rtext end
end
M = checkSkills

return M