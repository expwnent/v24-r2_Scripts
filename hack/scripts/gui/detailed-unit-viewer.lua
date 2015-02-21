local gui = require 'gui'
local dialog = require 'gui.dialogs'
local widgets =require 'gui.widgets'
local guiScript = require 'gui.script'
local split = require 'split'
local center = require 'center'

checkclass = true

function tchelper(first, rest)
  return first:upper()..rest:lower()
end

function Set (list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

function getTargetName(tar)
 if tar.name.has_name then
  f_name = tar.name.first_name
  l_name = ''
  for i,x in pairs(tar.name.words) do
   if x >= 0 then
    l_name = l_name..df.global.world.raws.language.translations[tonumber(tar.name.language)].words[tonumber(x)].value
   end
  end
  name = f_name:gsub("^%l", string.upper)..' '..l_name:gsub("^%l", string.upper)
 else
  name = df.global.world.raws.creatures.all[tonumber(tar.race)].name[0]
 end
 return name
end
function getTargetCaste(tar)
 race = df.global.world.raws.creatures.all[tonumber(tar.race)].name[0]
 if tar.sex == 1 then 
  sex = 'Male '
 elseif tar.sex == 0 then 
  sex = 'Female ' 
 else
  sex = ''
 end
 caste = df.global.world.raws.creatures.all[tonumber(tar.race)].caste[tonumber(tar.caste)].caste_name[0]
 name = race:gsub("^%l", string.upper)..', '..sex..caste:gsub("(%a)([%w_']*)", tchelper)
 return name
end
function getTargetSyndromes(tar)
 syn = {}
 syn_detail = {}
 for i,x in pairs(tar.syndromes.active) do
  curticks = x.ticks
  endticks = -1
  for j,y in pairs(df.global.world.raws.syndromes.all[tonumber(x.type)].ce) do
   if y['end'] > endticks then endticks = y['end'] end
  end
  if endticks == -1 then
   duration = 'Permenant'
  else
   duration = tostring(endticks-curticks)
  end
  syn[i+1] = {df.global.world.raws.syndromes.all[tonumber(x.type)].syn_name:gsub("(%a)([%w_']*)", tchelper),duration,curticks}
  if syn[i+1][1] == '' then
   syn[i+1][1] = 'Unknown'
  end
  syn_detail[i+1] = df.global.world.raws.syndromes.all[tonumber(x.type)].ce
 end
 if #syn == 0 then
  syn[1] = {'None','',''}
  syn_detail[1] = {}
 end
 return syn, syn_detail
end
function getTargetInteractions(tar)
 ints = {}
 t_ints = {}
 for i,x in pairs(df.global.world.raws.creatures.all[tonumber(tar.race)].caste[tonumber(tar.caste)].body_info.interactions) do
  s = -1
  check = false
  name = false
  for j,y in pairs(df.global.world.raws.creatures.all[tonumber(tar.race)].raws) do
   if split(y.value,':')[1] == '[CAN_DO_INTERACTION' then
    s = s + 1
    if s == i then
     check = true
    elseif s > i then
     break
    end
   end
   if check then
    if split(y.value,':')[2] == 'ADV_NAME' then
     ints[i+1] = split(split(y.value,':')[3],']')[1]
     name = true
	end
   end
  end
  if not name then
   ints[i+1] = 'Unknown'
  end
 end
 if #ints == 0 then
  ints[1] = 'None'
 end
 s = 0
 for i,x in pairs(tar.syndromes.active) do
  for j,y in pairs(df.global.world.raws.syndromes.all[tonumber(x.type)].ce) do
   if y._type == df['creature_interaction_effect_can_do_interactionst'] then
    t_ints[s+1] = y.name
	s = s + 1
   end
  end
 end 
 if #t_ints == 0 then
  t_ints[1] = 'None'
 end
 return ints, t_ints
end
function getTargetAttributes(tar)
 p_atts = {}
 m_atts = {}
 for i,x in pairs(tar.body.physical_attrs) do
  p_atts[i:gsub("%_"," "):gsub("(%a)([%w_']*)", tchelper)] = dfhack.units.getPhysicalAttrValue(tar,df.physical_attribute_type[i])
 end
 for i,x in pairs(tar.status.current_soul.mental_attrs) do
  m_atts[i:gsub("%_"," "):gsub("(%a)([%w_']*)", tchelper)] = dfhack.units.getMentalAttrValue(tar,df.mental_attribute_type[i])
 end
 return p_atts, m_atts
end
function getTargetSkills(tar)
 skl = {}
 for i,x in pairs(tar.status.current_soul.skills) do
  skl[df.job_skill.attrs[x.id].caption_noun] = {df.skill_rating[dfhack.units.getEffectiveSkill(tar,x.id)],dfhack.units.getExperience(tar,x.id),df.job_skill[x.id]}
 end
 return skl
end
function getTargetEntity(tar)
 ent = ''
 civ = ''
-- if tar.civ_id >= 0 then
--  ent = df.global.world.raws.entities[tar.civ_id].code
-- end
 if tar.population_id >= 0 then
  for i,x in pairs(df.global.world.entities.all[tar.population_id].name.words) do
   if x >= 0 then
    civ = civ..' '..df.global.world.raws.language.translations[tonumber(df.global.world.entities.all[tar.population_id].name.language)].words[tonumber(x)].value:gsub("^%l", string.upper)
   end
  end
 end
 return ent, "Member of "..civ
end
function getTargetClasses(tar)
 local persistTable = require 'persist-table'
 local establishclass = require('classes.establish-class')
 local s = 0
 local class = {}
 establishclass(tar)
 local totexp = 0
 local skillpnts = 0
 local key = tostring(tar.id)
 local unitClasses = persistTable.GlobalTable.roses.UnitTable[key]['Classes']
 local currentClass = unitClasses.Current
 local classes = persistTable.GlobalTable.roses.ClassTable
 if currentClass.Name ~= 'None' then
  local curlevel = unitClasses[currentClass.Name]['Level']
  local curexp = currentClass.CurrentExp
  totexp = currentClass.TotalExp
  skillpnts = currentClass.SkillExp
  local nextexp = curexp
  if curlevel < classes[currentClass.Name]['Levels'] then nextexp = classes[currentClass.Name]['Experience'][curlevel+1] end
  class[s+1] = {classes[currentClass.Name]['Name']:gsub("(%a)([%w_']*)", tchelper),tostring(curlevel),tostring(curexp)..'/'..tostring(nextexp),totexp,skillpnts}
  s = s + 1
 end
 for _,x in pairs(classes._children) do
  local checkClass = unitClasses[x]
  if (tonumber(checkClass.Experience) > 0 or tonumber(checkClass.Level) > 0) and x ~= currentClass.Name then
   local classname = x
   local curlevel = checkClass.Level
   local curexp = checkClass.Experience
   local nextexp = classes[x]['Experience'][curlevel]
   if curlevel < classes[x]['Levels'] then nextexp = classes[x]['Experience'][curlevel+1] end
   class[s+1] = {classes[x]['Name']:gsub("(%a)([%w_']*)", tchelper),tostring(curlevel),tostring(curexp)..'/'..tostring(nextexp)}
   s = s + 1
  end
 end
 if #class == 0 then class[1] = {'None', '0', '0/0', '0','0'} end
 return class
end

function getTargetFromScreens()
 local my_trg
 if dfhack.gui.getSelectedUnit(true) then
  my_trg=dfhack.gui.getSelectedUnit(true)
 else
  qerror("No valid target found")
 end
 return my_trg
end

UnitViewUi = defclass(UnitViewUi, gui.FramedScreen)
UnitViewUi.ATTRS={
                  frame_style = gui.GREY_LINE_FRAME,
                  frame_title = "Detailed unit viewer",
	             }

function UnitViewUi:init(args)
-- Gather data
 full_name = getTargetName(args.target)
 caste = getTargetCaste(args.target)
 syndromes, syndromes_detail = getTargetSyndromes(args.target)
 interactions, t_interactions = getTargetInteractions(args.target)
 p_attributes, m_attributes = getTargetAttributes(args.target)
 skills = getTargetSkills(args.target)
 entity, civilization = getTargetEntity(args.target)
 classes = getTargetClasses(args.target)
-- Set unit frame size
 unit_len = math.max(#full_name,#caste,#civilization)
 unit_hgt = 4
-- Set attribute frame size
 attribute_len = 25
 attribute_hgt = 23
-- Set skill frame size
 skill_hgt, s1, s2, s3 = 5, 0, 0, 0
 for i,x in pairs(skills) do
  skill_hgt = skill_hgt+1
  if #i > s1 then s1 = #i end
  if #x[1] > s2 then s2 = #x[1] end
  if #tostring(x[2]) > s3 then s3 = #tostring(x[2]) end
 end
 skill_len = s1+s2+s3+3+4
-- Set syndrome frame size
 y1 = #"Active Syndromes"
 y2 = #'Permenant'
 for i,x in pairs(syndromes) do
  if #x[1] > y1 then y1 = #x[1] end
  if #x[2] > y2 then y1 = #x[2] end
 end
 syndrome_len = y1 + y2 + 1
 syndrome_hgt = #syndromes + 2
-- Set interaction frame size
 i1 = #"Interactions"
 for i,x in pairs(interactions) do
  if #x > i1 then i1 = #x end
 end
 for i,x in pairs(t_interactions) do
  if #x > i1 then i1 = #x end
 end
 interaction_hgt = #interactions+#t_interactions+2
 interaction_len = i1 + 1
-- Set class frame size
 if checkclass then
  c1, c2, c3 = 5, 5, 3
  for i,x in pairs(classes) do
   if #x[1] > c1 then c1 = #x[1] end
   if #x[2] > c2 then c2 = #x[2] end
   if #x[3] > c3 then c3 = #x[3] end
  end
  class_len = c1 + c2 + c3 + 3
  class_hgt = #classes + 3
 else
  class_len = skill_len
  class_hgt = 0
 end
 column_1 = math.max(table.unpack({unit_len,attribute_len}))
 column_2 = math.max(table.unpack({class_len,skill_len}))
 column_3 = math.max(table.unpack({syndrome_len,interaction_len}))
 row_1 = math.max(table.unpack({unit_hgt,class_hgt}))
 row_2 = math.max(table.unpack({attribute_hgt,skill_hgt,interaction_hgt+syndrome_hgt}))
-- Create frames
 self:addviews{
       widgets.Panel{
	   view_id = 'main',
       frame = { l = 0, r = 0 },
       frame_inset = 1,
       subviews = {
        widgets.Label{
		 view_id = 'unit',
         frame = { l = 0, t = 0, w = column_1, h = row_1},
         text = {
                { text = full_name, width = column_1 },
                NEWLINE,
                { text = caste, width = column_1 },
				NEWLINE,
				{ text = civilization, width = column_1 },
                }
                },
		widgets.List{
		 view_id = 'classes',
         frame = { l = column_1+2, t = 0, w = column_2, h = row_1},
                },
		widgets.List{
		 view_id = 'attributes',
         frame = { l = 0, t = row_1+1, w = column_1, h = row_2},
                },
		widgets.List{
		 view_id = 'skills',
         frame = { l = column_1+2, t = row_1+1, w = column_2, h = row_2},
                },
		widgets.List{
		 view_id = 'syndromes',
         frame = { l = column_1+column_2+4, t = row_1+1, w = column_3, h = row_2},
                },
		widgets.List{
		 view_id = 'interactions',
         frame = { l = column_1+column_2+4, t = row_1+syndrome_hgt+2, w = column_3, h = row_2},
                },
		widgets.Label{
                    view_id = 'bottom_ui',
                    frame = { b = 0, h = 1 },
                    text = 'filled by updateBottom()'
                }
            }
		}
	}
 self:addviews{
       widgets.Panel{
	   view_id = 'interactionView',
       frame = { l = 0, r = 0 },
       frame_inset = 1,
	   subviews = {
		    }
        }
    }
 self:addviews{
       widgets.Panel{
	   view_id = 'syndromeView',
       frame = { l = 0, r = 0 },
       frame_inset = 1,
	   subviews = {
	   	widgets.List{
		 view_id = 'syndromeViewDetailed',
         frame = { l = 0, t = 0},
                },
		    }
        }
    }
 self.subviews.interactionView.visible = false
 self.subviews.syndromeView.visible = false
 self.subviews.main.visible = true
 self:insertAttributes(p_attributes,m_attributes)
 self:insertSkills(skills)
 self:insertSyndromes(syndromes)
 self:insertInteractions(interactions,t_interactions)
 if checkclass then self:insertClasses(classes) end
 self:syndromeDetail(syndromes, syndromes_detail)
 self:updateBottom()
end

function UnitViewUi:updateBottom()
    self.subviews.bottom_ui:setText(
        {
            { key = 'CUSTOM_SHIFT_I', text = ': Detailed Interaction Information',
              on_activate = self:callback('interactionView') }, NEWLINE,
            { key = 'CUSTOM_SHIFT_S', text = ': Detailed Syndrome Information',
              on_activate = self:callback('syndromeView') }
        })
end

function UnitViewUi:interactionView()
 self.subviews.interactionView.visible = true
 self.subviews.main.visible = false
end

function UnitViewUi:syndromeView()
 self.subviews.syndromeView.visible = true
 self.subviews.main.visible = false
end

function UnitViewUi:syndromeDetail(syndromes,details)
 detail = {}
 table.insert(detail, {
     text = {
	     {text=center('Active Syndromes',20), pen=COLOR_LIGHTCYAN},
		 {text=center('Start',6), pen=COLOR_LIGHTCYAN},
		 {text=center('Peak',6), pen=COLOR_LIGHTCYAN},
		 {text=center('Severity',10), pen=COLOR_LIGHTCYAN},
		 {text=center('End',6), pen=COLOR_LIGHTCYAN},
		 {text=center('Duration',10), pen=COLOR_LIGHTCYAN}
     }
   })
 for i,x in pairs(syndromes) do
  table.insert(detail, {
      text = {
	      {text = x[1],width = 20,pen=fgc}
      }
  })
  for j,y in pairs(details[i]) do
   if pcall(function() return y.sev end) then
    severity = y.sev
   else
    severity = 'NA'
   end
   effect = split(split(tostring(y._type),'creature_interaction_effect_')[2],'st>')[1]:gsub("(%a)([%w_']*)", tchelper)
   if y['end'] == -1 then
    ending = 'Permanent'
	duration = x[3]
   else
    ending = y['end']
    duration = x[3]
   end
   if y.start-x[3] <0 then
--    starting = 0
	startcolor = COLOR_LIGHTGREEN
   else
--    starting = y.start-x[3]
	startcolor = COLOR_LIGHTRED
   end
   if y.peak-x[3] <0 then
--    starting = 0
	peakcolor = COLOR_LIGHTGREEN
   else
--    starting = y.peak-x[3]
	peakcolor = COLOR_LIGHTRED
   end
   if y['end']-x[3] <0 then
	endcolor = COLOR_LIGHTGREEN
   else
	endcolor = COLOR_LIGHTRED
   end
   table.insert(detail, {
       text = {
	       {text = "    "..effect, width = 20,pen=COLOR_WHITE},
		   {text = y.start, rjustify=true,width = 6,pen=startcolor},
		   {text = y.peak, rjustify=true,width = 6,pen=peakcolor},
		   {text = severity, rjustify=true,width = 10,pen=COLOR_WHITE},
		   {text = ending, rjustify=true,width = 6,pen=endcolor},
		   {text = duration, rjustify=true,width = 10,pen=COLOR_WHITE}
           
       }
   })
  end
 end
 local list = self.subviews.syndromeViewDetailed
 list:setChoices(detail)
end

function UnitViewUi:insertAttributes(p_attributes,m_attributes)
 attributes = {}
 a_len = 19
 n_len = 5
 table.insert(attributes, {
     text = {
	     {text=center('Attributes',a_len+n_len), width = attribute_len,pen=COLOR_LIGHTCYAN}
     }
   })
 table.insert(attributes, {
     text = {
	     {text=center('Physical',a_len+n_len), width = attribute_len,pen=COLOR_LIGHTMAGENTA}
     }
   })
 fgc = COLOR_GREY
 for i,x in pairs(p_attributes) do
  if fgc == COLOR_WHITE then
   fgc = COLOR_GREY
  elseif fgc == COLOR_GREY then
   fgc = COLOR_WHITE
  end
  table.insert(attributes, {
      text = {
	      {text = i, width = a_len,pen = fgc},
		  {text = tostring(x), rjustify=true, width=n_len,pen = fgc}
      }
  })
 end
 table.insert(attributes, {
     text = {
	     {text=center('Mental',a_len+n_len), width = attribute_len,pen={fg = COLOR_LIGHTMAGENTA, bg = COLOR_BLACK}}
     }
   })
 fgc = COLOR_GREY
 for i,x in pairs(m_attributes) do
  if fgc == COLOR_WHITE then
   fgc = COLOR_GREY
  elseif fgc == COLOR_GREY then
   fgc = COLOR_WHITE
  end
  table.insert(attributes, {
      text = {
	      {text = i,width = a_len,pen=fgc},
		  {text=tostring(x),rjustify=true,width=n_len,pen=fgc}
      }
  })
 end
 local list = self.subviews.attributes
 list:setChoices(attributes)
end
function UnitViewUi:insertSkills(skills)
 skill = {}
 misc_skl = {}
 blue_collar_skl = Set {"MINING","WOODCUTTING","CARPENTRY","DETAILSTONE","MASONRY","ANIMALTRAIN","ANIMALCARE",
                    "DISSECT_FISH","DISSECT_VERMIN","PROCESSFISH","BUTCHER","TRAPPING","TANNER","WEAVING",
					"BREWING,ALCHEMY","CLOTHESMAKING","MILLING","PROCESSPLANTS","CHEESEMAKING","MILK","COOK",
					"PLANT,HERBALISM","FISH","SMELT","EXTRACT_STRAND","FORGE_WEAPON","FORGE_ARMOR",
					"FORGE_FURNITURE","CUTGEM","ENCRUSTGEM","WOODCRAFT","STONECRAFT","METALCRAFT","GLASSMAKER",
					"LEATHERWORK","BONECARVE","SIEGECRAFT","BOWYER","MECHANICS","WOOD_BURNING","LYE_MAKING",
					"SOAP_MAKING","POTASH_MAKING","DYER","OPERATE_PUMP","KNAPPING","SHEARING","SPINNING","POTTERY",
					"GLAZING","PRESSING","BEEKEEPING","WAX_WORKING"
				   }
 white_collar_skl = Set {"APPRAISAL","TEACHING","DESIGNBUILDING","ORGANIZATION","RECORD_KEEPING","WRITING",
                     "PROSE","POETRY","READING","SPEAKING","LEADERSHIP","TEACHING"
					}
 social_skl = Set {"COMEDY","CONSOLE","CONVERSATION","FLATTERY","INTIMIDATION","JUDGING_INTENT",
             "LYING","NEGOTIATION","PACIFY","PERSUASION"
			}
 personal_skl = Set {"KNOWLEDGE_ACQUISITION","CONCENTRATION","DISCIPLINE","SITUATIONAL_AWARENESS","COORDINATION",
                 "BALANCE","MAGIC_NATURE","SWIMMING"
			    }
 military_skl = Set {"ARMOR","AXE","BITE","BLOWGUN","BOW","CROSSBOW","DAGGER","DODGING","GRASP_STRIKE","HAMMER",
             "MACE","MELEE_COMBAT","MILITARY_TACTICS","MISC_WEAPON","PIKE","RANGED_COMBAT","SHIELD","SNEAK",
			 "SIEGEOPERATE","SPEAR","STANCE_STRIKE","SWORD","THROW","TRACKING","WHIP","WRESTLING"
			}
 medical_skl = Set {"CRUTCH_WALK","DIAGNOSE","DRESS_WOUNDS","SET_BONE","SURGERY","SUTURE"}
 table.insert(skill, {
     text = {
	     {text=center('Skills',skill_len), width = skill_len,pen=COLOR_LIGHTCYAN}
     }
   })
 fgc = COLOR_GREY
 --Check Blue Collar Skills
 local check = true
 for i,x in pairs(skills) do
  if blue_collar_skl[x[3]] then
   if check then
    table.insert(skill, {
     text = {
	     {text=center('Blue Collar',skill_len), width = skill_len,pen=COLOR_LIGHTMAGENTA}
     }
    })
   end
   if fgc == COLOR_WHITE then
    fgc = COLOR_GREY
   elseif fgc == COLOR_GREY then
    fgc = COLOR_WHITE
   end
   table.insert(skill, {
       text = {
	       {text = i,width = s1+1,pen=fgc},
	 	   {text=x[1]..'('..tostring(df.skill_rating[x[1]])..')',rjustify=true,width=s2+5,pen=fgc},
	 	   {text=tostring(x[2]),rjustify=true,width=s3+1,pen=fgc}
       }
   })
   check = false
  end
 end
 fgc = COLOR_GREY
 --Check White Collar Skills
 check = true
 for i,x in pairs(skills) do
  if white_collar_skl[x[3]] then
   if check then
    table.insert(skill, {
     text = {
		 {text=center('White Collar',skill_len), width = skill_len,pen=COLOR_LIGHTMAGENTA}
     }
    })
   end
   if fgc == COLOR_WHITE then
    fgc = COLOR_GREY
   elseif fgc == COLOR_GREY then
    fgc = COLOR_WHITE
   end
   table.insert(skill, {
       text = {
	       {text = i,width = s1+1,pen=fgc},
	 	   {text=x[1]..'('..tostring(df.skill_rating[x[1]])..')',rjustify=true,width=s2+5,pen=fgc},
	 	   {text=tostring(x[2]),rjustify=true,width=s3+1,pen=fgc}
       }
   })
   check = false
  end
 end
 fgc = COLOR_GREY
 --Check Social Skills
 check = true
 for i,x in pairs(skills) do
  if social_skl[x[3]] then
   if check then
    table.insert(skill, {
     text = {
		 {text=center('Social',skill_len), width = skill_len,pen=COLOR_LIGHTMAGENTA}
     }
    })
   end
   if fgc == COLOR_WHITE then
    fgc = COLOR_GREY
   elseif fgc == COLOR_GREY then
    fgc = COLOR_WHITE
   end
   table.insert(skill, {
       text = {
	       {text = i,width = s1+1,pen=fgc},
	 	   {text=x[1]..'('..tostring(df.skill_rating[x[1]])..')',rjustify=true,width=s2+5,pen=fgc},
	 	   {text=tostring(x[2]),rjustify=true,width=s3+1,pen=fgc}
       }
   })
   check = false
  end
 end
 fgc = COLOR_GREY
 --Check Personal Skills
 check = true
 for i,x in pairs(skills) do
  if personal_skl[x[3]] then
   if check then
    table.insert(skill, {
     text = {
		 {text=center('Personal',skill_len), width = skill_len,pen=COLOR_LIGHTMAGENTA}
     }
    })
   end
   if fgc == COLOR_WHITE then
    fgc = COLOR_GREY
   elseif fgc == COLOR_GREY then
    fgc = COLOR_WHITE
   end
   table.insert(skill, {
       text = {
	       {text = i,width = s1+1,pen=fgc},
	 	   {text=x[1]..'('..tostring(df.skill_rating[x[1]])..')',rjustify=true,width=s2+5,pen=fgc},
	 	   {text=tostring(x[2]),rjustify=true,width=s3+1,pen=fgc}
       }
   })
   check = false
  end
 end
 fgc = COLOR_GREY
 --Check Military Skills
 check = true
 for i,x in pairs(skills) do
  if military_skl[x[3]] then
   if check then
    table.insert(skill, {
     text = {
		 {text=center('Military',skill_len), width = skill_len,pen=COLOR_LIGHTMAGENTA}
     }
    })
   end
   if fgc == COLOR_WHITE then
    fgc = COLOR_GREY
   elseif fgc == COLOR_GREY then
    fgc = COLOR_WHITE
   end
   table.insert(skill, {
       text = {
	       {text = i,width = s1+1,pen=fgc},
	 	   {text=x[1]..'('..tostring(df.skill_rating[x[1]])..')',rjustify=true,width=s2+5,pen=fgc},
	 	   {text=tostring(x[2]),rjustify=true,width=s3+1,pen=fgc}
       }
   })
   check = false
  end
 end
 fgc = COLOR_GREY
 --Check Medical Skills
 check = true
 for i,x in pairs(skills) do
  if medical_skl[x[3]] then
   if check then
    table.insert(skill, {
     text = {
		 {text=center('Medical',skill_len), width = skill_len,pen=COLOR_LIGHTMAGENTA}
     }
    })
   end
   if fgc == COLOR_WHITE then
    fgc = COLOR_GREY
   elseif fgc == COLOR_GREY then
    fgc = COLOR_WHITE
   end
   table.insert(skill, {
       text = {
	       {text = i,width = s1+1,pen=fgc},
	 	   {text=x[1]..'('..tostring(df.skill_rating[x[1]])..')',rjustify=true,width=s2+5,pen=fgc},
	 	   {text=tostring(x[2]),rjustify=true,width=s3+1,pen=fgc}
       }
   })
   check = false
  end
 end
 local list = self.subviews.skills
 list:setChoices(skill)
end
function UnitViewUi:insertSyndromes(syndromes)
 syndrome = {}
 table.insert(syndrome, {
     text = {
	     {text=center('Active Syndromes',syndrome_len), width = syndrome_len,pen=COLOR_LIGHTCYAN}
     }
   })
 fgc = COLOR_GREY
 for i,x in pairs(syndromes) do
  if fgc == COLOR_WHITE then
   fgc = COLOR_GREY
  elseif fgc == COLOR_GREY then
   fgc = COLOR_WHITE
  end
  table.insert(syndrome, {
      text = {
	      {text = x[1],width = y1,pen=fgc},
		  {text = x[3],width = y2,rjustify=true,pen=fgc}
      }
  })
 end
 local list = self.subviews.syndromes
 list:setChoices(syndrome)
end
function UnitViewUi:insertInteractions(interactions,t_interactions)
 interaction = {}
 table.insert(interaction, {
     text = {
	     {text=center('Interactions',interaction_len), width = interaction_len,pen=COLOR_LIGHTCYAN}
     }
   })
 fgc = COLOR_GREY
 if interactions[1] == 'None' and t_interactions[1] == 'None' then
  table.insert(interaction, {
      text = {
	      {text = x,width = y1,pen=COLOR_WHITE}
      }
  })
 else
  if interactions[1] ~= 'None' then
   for i,x in pairs(interactions) do
    if fgc == COLOR_WHITE then
     fgc = COLOR_GREY
    elseif fgc == COLOR_GREY then
     fgc = COLOR_WHITE
    end
    table.insert(interaction, {
        text = {
	        {text = x,width = y1,pen=fgc}
        }
    })
   end
  end
  if t_interactions[1] ~= 'None' then 
   for i,x in pairs(t_interactions) do
    if fgc == COLOR_WHITE then
     fgc = COLOR_GREY
    elseif fgc == COLOR_GREY then
     fgc = COLOR_WHITE
    end
    table.insert(interaction, {
        text = {
	        {text = x,width = y1,pen=fgc}
        }
    })
   end
  end
 end
 local list = self.subviews.interactions
 list:setChoices(interaction)
end
function UnitViewUi:insertClasses(classes)
 class = {}
 table.insert(class, {
     text = {
	     {text=center('Class',c1), width = c1+1,pen=COLOR_LIGHTCYAN},
		 {text='Level', width = c2+1,rjustify=true,pen=COLOR_LIGHTCYAN},
		 {text='Exp', width = c3+1,rjustify=true,pen=COLOR_LIGHTCYAN}
     }
   })
 fgc = COLOR_GREY
 for i,x in pairs(classes) do
  if fgc == COLOR_WHITE then
   fgc = COLOR_GREY
  elseif fgc == COLOR_GREY then
   fgc = COLOR_WHITE
  end
  if i == 1 then 
   append = '*'
  else
   append = ''
  end
  table.insert(class, {
      text = {
	      {text = append..x[1],width = c1+1,pen=fgc},
		  {text = x[2],width = c2+1,rjustify = true,pen=fgc},
		  {text = x[3],width = c3+1,rjustify = true,pen=fgc}
      }
  })
 end
 table.insert(class, {
     text = {
	     {text='Total Exp:', width = 10,pen=COLOR_LIGHTCYAN},
		 {text=classes[1][4], width = #classes[1][4]+1,rjustify=true,pen=COLOR_LIGHTCYAN},
		 NEWLINE,
		 {text='Skill Points:', width = 13,rjustify=true,pen=COLOR_LIGHTCYAN},
		 {text=classes[1][5], width = #classes[1][5]+1,rjustify=true,pen=COLOR_LIGHTCYAN}
     }
   }) 
 local list = self.subviews.classes
 list:setChoices(class)
end
function UnitViewUi:onInput(keys)
 if keys.LEAVESCREEN then
  if self.subviews.interactionView.visible then
   self.subviews.interactionView.visible = false
   self.subviews.main.visible = true
  elseif self.subviews.syndromeView.visible then
   self.subviews.syndromeView.visible = false
   self.subviews.main.visible = true
  else
   self:dismiss()
  end
 else
  UnitViewUi.super.onInput(self, keys)
 end
end
function show_editor(trg)
 local screen = UnitViewUi{target=trg}
 screen:show()
end

show_editor(getTargetFromScreens())