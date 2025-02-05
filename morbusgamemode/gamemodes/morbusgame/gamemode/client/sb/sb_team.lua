
---- Unlike sandbox, we have teams to deal with, so here's an extra panel in the
---- hierarchy that handles a set of player rows belonging to its team.

include("sb_row.lua")

local function CompareScore(pa, pb)
   if not ValidPanel(pa) then return false end
   if not ValidPanel(pb) then return true end

   local a = pa:GetPlayer()
   local b = pb:GetPlayer()

   if not IsValid(a) then return false end
   if not IsValid(b) then return true end

   if a:Frags() == b:Frags() then return a:Deaths() < b:Deaths() end

   return a:Frags() > b:Frags()
end

local PANEL = {}

function PANEL:Init()
   self.name = "Unnamed"

   self.color = COLOR_WHITE

   self.rows = {}
   self.rowcount = 0

   self.rows_sorted = {}
   
   self.group = "spec"
end

function PANEL:SetGroupInfo(name, color, group)
   self.name = name
   self.color = color
   self.group = group
end

local bgcolor = Color(20,20,20, 150)
function PANEL:Paint()
   -- Darkened background
   draw.RoundedBox(0, 0, 0, self:GetWide(), self:GetTall(), bgcolor)

   surface.SetFont("treb_small")

   -- Header bg
   local txt = self.name .. " (" .. self.rowcount .. ")"
   local w, h = surface.GetTextSize(txt)
   draw.RoundedBox(0, 0, 0, w + self:GetWide(), 20, self.color)
   
   -- Shadow
   surface.SetTextPos(4, 11 - h/2)
   surface.SetTextColor(0,0,0, 200)
   surface.DrawText(txt)

   -- Text
   surface.SetTextPos(4, 10 - h/2)
   surface.SetTextColor(255,255,255,255)
   surface.DrawText(txt)

   if self.name == "Humans" then

   -- Shadow Text
   surface.SetTextPos(201, 11 - h/2)
   surface.SetTextColor(0,0,0,255)
   surface.DrawText("[Human Wins]: " .. GetGlobalInt("human_wins"))

   -- Text
   surface.SetTextPos(200, 10 - h/2)
   surface.SetTextColor(125,255,125,255)
   surface.DrawText("[Human Wins]: " .. GetGlobalInt("human_wins"))

   -- Shadow Text
   surface.SetTextPos(401, 11 - h/2)
   surface.SetTextColor(0,0,0,255)
   surface.DrawText("[Alien Wins]: " .. GetGlobalInt("alien_wins"))

   -- Text
   surface.SetTextPos(400, 10 - h/2)
   surface.SetTextColor(255,115,115,255)
   surface.DrawText("[Alien Wins]: " .. GetGlobalInt("alien_wins"))

   end


   -- Alternating row background
   local y = 24
   for i, row in ipairs(self.rows_sorted) do
      if (i % 2) != 0 then
         surface.SetDrawColor(25,125,125,80)
         surface.DrawRect(0, y, self:GetWide(), row:GetTall())
      end
      
      y = y + row:GetTall() + 1
   end

   -- Column darkening
   surface.SetDrawColor(0,0,0,50)
   //surface.DrawRect(self:GetWide() - 175, 0, 50, self:GetTall())
   //surface.DrawRect(self:GetWide() - 75, 0, 50, self:GetTall())
   surface.DrawRect(self:GetWide() - 130, 0, 100, self:GetTall())
end

function PANEL:AddPlayerRow(ply)
   if ScoreGroup(ply) == self.group and not self.rows[ply] then
      local row = vgui.Create("MScorePlayerRow", self)
      row:SetPlayer(ply)
      self.rows[ply] = row
      self.rowcount = table.Count(self.rows)

--      row:InvalidateLayout()

      -- must force layout immediately or it takes its sweet time to do so
      self:PerformLayout()
      --self:InvalidateLayout()
   end
end

function PANEL:HasPlayerRow(ply)
   return self.rows[ply] != nil
end

function PANEL:HasRows()
   return self.rowcount > 0
end

function PANEL:UpdateSortCache()
   self.rows_sorted = {}
   for k,v in pairs(self.rows) do
      table.insert(self.rows_sorted, v)
   end

   table.sort(self.rows_sorted, CompareScore)
end

function PANEL:UpdatePlayerData()
   local to_remove = {}
   for k,v in pairs(self.rows) do
      -- Player still belongs in this group?
      if ValidPanel(v) and IsValid(v:GetPlayer()) and ScoreGroup(v:GetPlayer()) == self.group then
         v:UpdatePlayerData()
      else
         -- can't remove now, will break pairs
         table.insert(to_remove, k)
      end
   end

   if #to_remove == 0 then return end

   for k,ply in pairs(to_remove) do
      local pnl = self.rows[ply]
      if ValidPanel(pnl) then
         pnl:Remove()
      end

--      print(CurTime(), "Removed player", ply)

      self.rows[ply] = nil
   end
   self.rowcount = table.Count(self.rows)

   self:UpdateSortCache()

   self:InvalidateLayout()
end


function PANEL:PerformLayout()
   if self.rowcount < 1 then
      self:SetVisible(false)
      return
   end

   self:SetSize(self:GetWide(), 30 + self.rowcount + self.rowcount * SB_ROW_HEIGHT)

   -- Sort and layout player rows
   self:UpdateSortCache()

   local y = 24
   for k, v in ipairs(self.rows_sorted) do
      v:SetPos(0, y)
      v:SetSize(self:GetWide(), v:GetTall())

      y = y + v:GetTall() + 1
   end

   self:SetSize(self:GetWide(), 30 + (y - 24))
end

vgui.Register("MScoreGroup", PANEL, "Panel")
