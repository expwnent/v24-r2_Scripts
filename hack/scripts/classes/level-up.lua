
local split = require('split')
local utils = require 'utils'
local establishclass = require('classes.establish-class')
local checkclass = require('classes.requirements-class')
local checkspell = require('classes.requirements-spell')
local persistTable = require 'persist-table'
        
function levelup(unit)
 local unitClasses = persistTable.GlobalTable.roses.UnitTable[tostring(unit)]['Classes']
 local currentClass = unitClasses['Current']
 local classes = persistTable.GlobalTable.roses.ClassTable
 local currentClassName = currentClass['Name']
 local currentClassLevel = tonumber(unitClasses[currentClassName]['Level'])+1
 unitClasses[currentClassName]['Level'] = tostring(currentClassLevel)
  for _,x in pairs(classes[currentClassName]['BonusPhysical']._children) do
   local i = classes[currentClassName]['BonusPhysical'][x]
   dfhack.run_script('unit/attribute-change -unit '..tostring(unit)..' -physical '..x..' -fixed \\'..tostring(tonumber(i[currentClassLevel+1])-tonumber(i[currentClassLevel])))
  end
  for _,x in pairs(classes[currentClassName]['LevelBonus']['Physical']._children) do
   local i = classes[currentClassName]['LevelBonus']['Physical'][x]
   dfhack.run_script('unit/attribute-change -unit '..tostring(unit)..' -physical '..x..' -fixed \\'..i)
  end
  for _,x in pairs(classes[currentClassName]['BonusMental']._children) do
   local i = classes[currentClassName]['BonusMental'][x]
   dfhack.run_script('unit/attribute-change -unit '..tostring(unit)..' -mental '..x..' -fixed \\'..tostring(tonumber(i[currentClassLevel+1])-tonumber(i[currentClassLevel])))
  end
  for _,x in pairs(classes[currentClassName]['LevelBonus']['Mental']._children) do
   local i = classes[currentClassName]['LevelBonus']['Mental'][x]
   dfhack.run_script('unit/attribute-change -unit '..tostring(unit)..' -mental '..x..' -fixed \\'..i)
  end
  for _,x in pairs(classes[currentClassName]['BonusSkill']._children) do
   local i = classes[currentClassName]['BonusSkill'][x]
   dfhack.run_script('unit/skill-change -unit '..tostring(unit)..' -skill '..x..' -fixed \\'..tostring(tonumber(i[currentClassLevel+1])-tonumber(i[currentClassLevel])))
  end
  for _,x in pairs(classes[currentClassName]['LevelBonus']['Skill']._children) do
   local i = classes[currentClassName]['LevelBonus']['Skill'][x]
   dfhack.run_script('unit/skill-change -unit '..tostring(unit)..' -skill '..x..' -fixed \\'..i)
  end
  for _,x in pairs(classes[currentClassName]['BonusTrait']._children) do
   local i = classes[currentClassName]['BonusTrait'][x]
   dfhack.run_script('unit/trait-change -unit '..tostring(unit)..' -trait '..x..'-fixed \\'..tostring(tonumber(i[currentClassLevel+1])-tonumber(i[currentClassLevel])))
  end
  for _,x in pairs(classes[currentClassName]['LevelBonus']['Trait']._children) do
   local i = classes[currentClassName]['LevelBonus']['Trait'][x]
   dfhack.run_script('unit/trait-change -unit '..tostring(unit)..' -trait '..x..'-fixed \\'..i)
  end
  for _,x in pairs(classes[currentClassName]['Spells']._children) do
   local i = classes[currentClassName]['Spells'][x]
   if tonumber(i['RequiredLevel']) <= currentClassLevel then
    if verbose then
     if i['AutoLearn'] then dfhack.run_script('classes/learn-skill -unit '..tostring(unit)..' -spell '..x..' -verbose') end
	else
	 if i['AutoLearn'] then dfhack.run_script('classes/learn-skill -unit '..tostring(unit)..' -spell '..x) end
	end
   end
  end
 if currentClassLevel == tonumber(classes[currentClassName]['Levels']) then 
  if verbose then 
   print('REACHED MAX LEVEL FOR CLASS '..currentClassName)
   if classes[currentClassName]['AutoUpgrade'] then dfhack.run_script('classes/change-class -unit '..tostring(unit)..' -class '..classes[currentClassName]['AutoUpgrade']..' -verbose') end
  else
   if classes[currentClassName]['AutoUpgrade'] then dfhack.run_script('classes/change-class -unit '..tostring(unit)..' -class '..classes[currentClassName]['AutoUpgrade']) end
  end
 end
end

validArgs = validArgs or utils.invert({
 'help',
 'unit',
 'verbose'
})
local args = utils.processArgs({...}, validArgs)

verbose = false
if args.verbose then verbose = true end

unit = df.unit.find(tonumber(args.unit))
establishclass(unit,verbose)
levelup(tonumber(args.unit),verbose)