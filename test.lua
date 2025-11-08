-- notification system made by @jurylol on discord
--[[

HOW TO USE

only 1 function

notify.CreateNotification("Notification Title", "Notification Body text", notification duration, notification Zindex, title text color, body text color, the bar on the side color, background color, divider color, progress bar color)

Example code:
notify.CreateNotification("67 notification", "blah blah blah blah blah", 5, 10)

]]

local notify = {}
local activeNotifications = {}
local currID = 0

local function wrapText(text, limit)
	local result = ""
	local lineLength = 0
	local lastSpace = 0
	for i = 1, #text do
		local char = text:sub(i, i)
		result = result .. char
		lineLength = lineLength + 1
		if char == " " then
			lastSpace = #result
		end
		if lineLength >= limit then
			if lastSpace > 0 then
				result = result:sub(1, lastSpace - 1) .. "\n" .. result:sub(lastSpace + 1)
				lineLength = #result - lastSpace
				lastSpace = 0
			else
				result = result .. "\n"
				lineLength = 0
			end
		end
	end
	return result
end

local function AddNotification(elements, id, duration)
	local notifMain = elements[3]
	local offsets = {}

	for _, element in ipairs(elements) do
		offsets[element] = element.Position - notifMain.Position
	end

	local data = {
		ID = id,
		Elements = elements,
		Offsets = offsets,
		NotifMain = notifMain,
		Initialized = false,
		Duration = duration,
		Initializing = false
	}

	table.insert(activeNotifications, data)
end

local function UpdateRelativePosition(data, pos)
	for _, element in ipairs(data.Elements) do
		local offset = data.Offsets[element]
		element.Position = pos + offset
	end
end


function notify.CreateNotification(titleContent:string, textContent:string, duration:number, zIndex:number ,titleColor:Color3, textContentColor:Color3, barColor:Color3, backgroundColor:Color3, lineColor:Color3, progressBarColor:Color3) 
	
	local processedText = wrapText(textContent, 35)
	if zIndex == nil then
		zIndex = 67
	end
	local xPos = -100
	local yPos = -100
	
	local ColorBar = Drawing.new("Square")
	ColorBar.ZIndex = zIndex
	ColorBar.Size = Vector2.new(5, 60)
	ColorBar.Position = Vector2.new(xPos - 5, yPos)
	ColorBar.Color = barColor or Color3.fromRGB(255, 255, 255)
	ColorBar.Filled = true

	local Title = Drawing.new("Text")
	Title.ZIndex = zIndex + 1
	Title.Position = Vector2.new(xPos + 5, yPos + 2)
	Title.Color = titleColor or Color3.fromRGB(255, 255, 255)
	Title.Text = titleContent or "Title"
	Title.Outline = false

	local NotifMain = Drawing.new("Square")
	NotifMain.ZIndex = zIndex
	NotifMain.Size = Vector2.new(200, 60)
	NotifMain.Position = Vector2.new(xPos, yPos)
	NotifMain.Color = backgroundColor or Color3.fromRGB(30, 30, 30)
	NotifMain.Filled = true

	local BorderLine1 = Drawing.new("Square")
	BorderLine1.ZIndex = zIndex + 1
	BorderLine1.Size = Vector2.new(190, 2)
	BorderLine1.Position = Vector2.new(xPos + 5, yPos + 20)
	BorderLine1.Color = barColor or Color3.fromRGB(255, 255, 255)
	BorderLine1.Filled = true

	local Text = Drawing.new("Text")
	Text.ZIndex = zIndex + 1
	Text.Position = Vector2.new(xPos + 5, yPos + 25)
	Text.Color = textContentColor or Color3.fromRGB(255, 255, 255)
	Text.Text = processedText or "hi"
	Text.Outline = false

	local ProgressBarTop = Drawing.new("Square")
	ProgressBarTop.ZIndex = zIndex + 2
	ProgressBarTop.Size = Vector2.new(190, 2)
	ProgressBarTop.Position = Vector2.new(xPos + 5, yPos + 55)
	ProgressBarTop.Color = progressBarColor or Color3.fromRGB(255, 255, 255)
	ProgressBarTop.Filled = true

	local ProgressBarBottom = Drawing.new("Square")
	ProgressBarBottom.ZIndex = zIndex + 1
	ProgressBarBottom.Size = Vector2.new(190, 2)
	ProgressBarBottom.Position = Vector2.new(xPos + 5, yPos + 55)
	ProgressBarBottom.Color = progressBarColor or Color3.fromRGB(255, 255, 255)
	ProgressBarBottom.Filled = true
	ProgressBarBottom.Transparency = 0.5
	
	AddNotification({ColorBar, Title, NotifMain, BorderLine1, Text, ProgressBarTop, ProgressBarBottom}, currID, duration)
	
	currID = currID + 1
	
end

-- notif initializer
spawn(function()
	while true do
		task.wait()
		if #activeNotifications > 0 then
			for _, v in ipairs(activeNotifications) do
				if v.Initialized == false and v.Initializing == false then
					v.Initializing = true
					local gameWindowSize = game.CoreGui.RobloxGui.SettingsClippingShield.AbsoluteSize
					UpdateRelativePosition(v, Vector2.new(gameWindowSize.X - 200, gameWindowSize.Y - 60))
					v.Initialized = true
					spawn(function()
						local startTime = os.clock()
						while os.clock() - startTime < v.Duration do
							task.wait()
							local elapsed = os.clock() - startTime
							local timeLeft = v.Duration - elapsed

							local percent = math.clamp(timeLeft / v.Duration, 0, 1)
							local progressBar = v.Elements[6]
							progressBar.Size = Vector2.new(190 * percent, progressBar.Size.Y)
						end

						for _, element in ipairs(v.Elements) do
							element:Remove()
						end
						table.remove(activeNotifications, table.find(activeNotifications, v))
					end)

				end
			end
		end
	end
end)
-- notif updates
spawn(function()
	while true do
		if #activeNotifications > 0 then
			for _, v in ipairs(activeNotifications) do
				if v.Initialized == true then		
					table.sort(activeNotifications, function(a, b)
						return a.ID > b.ID
					end)
					local baseY = game.CoreGui.RobloxGui.SettingsClippingShield.AbsoluteSize.Y - 60
					for index, notif in ipairs(activeNotifications) do
						local offsetY = (index - 1) * -63
						local gameWindowSize = game.CoreGui.RobloxGui.SettingsClippingShield.AbsoluteSize
						local pos = Vector2.new(gameWindowSize.X - 200, baseY + offsetY)
						UpdateRelativePosition(notif, pos)
					end

				end
			end
		end
		task.wait()
	end
end)
