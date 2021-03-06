X = 0
Y = 0
Width = 1
Height = 1
Parent = nil
OnClick = nil
Visible = true
Name = nil 
ClipDrawing = true
UpdateDrawBlacklist = {}

DrawCache = {}

NeedsDraw = function(self)
	if not self.Visible then
		return false
	end
	
	if not self.DrawCache.Buffer or self.DrawCache.AlwaysDraw or self.DrawCache.NeedsDraw then
		return true
	end

	if self.OnNeedsUpdate then
		if self.OnNeedsUpdate() then
			return true
		end
	end

	if self.Children then
		for i, v in ipairs(self.Children) do
			if v:NeedsDraw() then
				return true
			end
		end
	end
end

GetPosition = function(self)
	return self.Bedrock:GetAbsolutePosition(self)
end

Draw = function(self)
	if not self.Visible then
		return
	end

	if self.X > Drawing.Screen.Width or self.Y > Drawing.Screen.Height or self.X + self.Width < 1 or self.Y + self.Height < 1 then
	elseif self:NeedsDraw() then
		self.DrawCache.NeedsDraw = false
		local pos = self:GetPosition()
		Drawing.StartCopyBuffer()
		if self.ClipDrawing then
			Drawing.AddConstraint(pos.X, pos.Y, self.Width, self.Height)
		end
		if self.OnDraw then
			self:OnDraw(pos.X, pos.Y)
		end
		if self.ClipDrawing then
			Drawing.RemoveConstraint()
		end
		self.DrawCache.Buffer = Drawing.EndCopyBuffer()
	else
		Drawing.DrawCachedBuffer(self.DrawCache.Buffer)
	end

	if self.Children then
		for i, child in ipairs(self.Children) do
			child:Draw()
		end
	end
end

ForceDraw = function(self, ignoreChildren, ignoreParent, ignoreBedrock)
	if not ignoreBedrock and self.Bedrock then
		self.Bedrock:ForceDraw()
	end
	self.DrawCache.NeedsDraw = true
	if not ignoreParent and self.Parent then
		self.Parent:ForceDraw(true, nil, ignoreBedrock)
	end
	if not ignoreChildren and self.Children then
		for i, child in ipairs(self.Children) do
			child:ForceDraw(nil, true, ignoreBedrock)
		end
	end
end

OnRemove = function(self)
	if self == self.Bedrock:GetActiveObject() then
		self.Bedrock:SetActiveObject()
	end
end

Initialise = function(self, values)
	local _new = values    -- the new instance
	_new.DrawCache = {
		NeedsDraw = true,
		AlwaysDraw = false,
		Buffer = nil
	}
	setmetatable(_new, {__index = self} )

	local new = {} -- the proxy
	setmetatable(new, {
		__index = _new,

		__newindex = function (t,k,v)
			if v ~= _new[k] then
				if t.OnUpdate then
					t:OnUpdate(k)
				end
				_new[k] = v

				if t.UpdateDrawBlacklist[k] == nil then
					t:ForceDraw()
				end
			end
		end
	})
	if new.OnInitialise then
		new:OnInitialise()
	end

	return new
end

Click = function(self, event, side, x, y)
	if self.Visible then
		if event == 'mouse_click' and self.OnClick and self:OnClick(event, side, x, y) ~= false then
			return true
		elseif event == 'mouse_drag' and self.OnDrag and self:OnDrag(event, side, x, y) ~= false then
			return true
		else
			return false
		end
	else
		return false
	end
end

ToggleMenu = function(self, name, x, y)
	return self.Bedrock:ToggleMenu(name, self, x, y)
end