local notify = {}
local activeNotifications = {}
local currID = 0

-- Configurações modernas
local CONFIG = {
	NOTIFICATION_WIDTH = 280,
	NOTIFICATION_HEIGHT = 80,
	NOTIFICATION_SPACING = 10,
	ANIMATION_SPEED = 0.3,
	SLIDE_DISTANCE = 20,
	CORNER_RADIUS = 12,
	SHADOW_OFFSET = 4
}

-- Função para interpolar valores
local function lerp(a, b, t)
	return a + (b - a) * t
end

-- Easing function para animações suaves
local function easeOutCubic(t)
	return 1 - math.pow(1 - t, 3)
end

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

local function AddNotification(elements, id, duration, targetPos)
	local notifMain = elements.Main
	local data = {
		ID = id,
		Elements = elements,
		NotifMain = notifMain,
		Initialized = false,
		Duration = duration,
		Initializing = false,
		TargetPos = targetPos,
		CurrentPos = Vector2.new(targetPos.X + CONFIG.SLIDE_DISTANCE, targetPos.Y),
		AnimationProgress = 0,
		Opacity = 0
	}
	table.insert(activeNotifications, data)
end

local function UpdatePosition(data, pos, opacity)
	opacity = opacity or 1
	
	-- Main background
	data.Elements.Main.Position = pos
	data.Elements.Main.Transparency = 1 - (0.95 * opacity)
	
	-- Shadow
	data.Elements.Shadow.Position = pos + Vector2.new(CONFIG.SHADOW_OFFSET, CONFIG.SHADOW_OFFSET)
	data.Elements.Shadow.Transparency = 1 - (0.3 * opacity)
	
	-- Accent bar
	data.Elements.AccentBar.Position = pos
	data.Elements.AccentBar.Transparency = 1 - opacity
	
	-- Title
	data.Elements.Title.Position = pos + Vector2.new(15, 12)
	data.Elements.Title.Transparency = 1 - opacity
	
	-- Text content
	data.Elements.Text.Position = pos + Vector2.new(15, 35)
	data.Elements.Text.Transparency = 1 - opacity
	
	-- Progress bar background
	data.Elements.ProgressBg.Position = pos + Vector2.new(0, CONFIG.NOTIFICATION_HEIGHT - 3)
	data.Elements.ProgressBg.Transparency = 1 - (0.3 * opacity)
	
	-- Progress bar fill
	data.Elements.ProgressFill.Position = pos + Vector2.new(0, CONFIG.NOTIFICATION_HEIGHT - 3)
	data.Elements.ProgressFill.Transparency = 1 - opacity
	
	-- Icon (if exists)
	if data.Elements.Icon then
		data.Elements.Icon.Position = pos + Vector2.new(CONFIG.NOTIFICATION_WIDTH - 30, 12)
		data.Elements.Icon.Transparency = 1 - opacity
	end
end

function notify.CreateNotification(titleContent, textContent, duration, zIndex, titleColor, textContentColor, accentColor, backgroundColor, iconText)
	local processedText = wrapText(textContent, 38)
	zIndex = zIndex or 100
	duration = duration or 5
	
	-- Cores modernas padrão
	titleColor = titleColor or Color3.fromRGB(255, 255, 255)
	textContentColor = textContentColor or Color3.fromRGB(200, 200, 200)
	accentColor = accentColor or Color3.fromRGB(88, 101, 242) -- Discord-like blue
	backgroundColor = backgroundColor or Color3.fromRGB(30, 31, 34)
	
	local gameWindowSize = game.CoreGui.RobloxGui.SettingsClippingShield.AbsoluteSize
	local targetX = gameWindowSize.X - CONFIG.NOTIFICATION_WIDTH - 20
	local targetY = gameWindowSize.Y - CONFIG.NOTIFICATION_HEIGHT - 20
	
	local elements = {}
	
	-- Shadow (efeito de profundidade)
	local Shadow = Drawing.new("Square")
	Shadow.ZIndex = zIndex - 1
	Shadow.Size = Vector2.new(CONFIG.NOTIFICATION_WIDTH, CONFIG.NOTIFICATION_HEIGHT)
	Shadow.Position = Vector2.new(targetX + CONFIG.SHADOW_OFFSET, targetY + CONFIG.SHADOW_OFFSET)
	Shadow.Color = Color3.fromRGB(0, 0, 0)
	Shadow.Filled = true
	Shadow.Transparency = 0.7
	elements.Shadow = Shadow
	
	-- Background principal (glass effect)
	local NotifMain = Drawing.new("Square")
	NotifMain.ZIndex = zIndex
	NotifMain.Size = Vector2.new(CONFIG.NOTIFICATION_WIDTH, CONFIG.NOTIFICATION_HEIGHT)
	NotifMain.Position = Vector2.new(targetX, targetY)
	NotifMain.Color = backgroundColor
	NotifMain.Filled = true
	NotifMain.Transparency = 0.05 -- Quase opaco para efeito glass
	elements.Main = NotifMain
	
	-- Barra de acento lateral (mais fina e moderna)
	local AccentBar = Drawing.new("Square")
	AccentBar.ZIndex = zIndex + 1
	AccentBar.Size = Vector2.new(3, CONFIG.NOTIFICATION_HEIGHT)
	AccentBar.Position = Vector2.new(targetX, targetY)
	AccentBar.Color = accentColor
	AccentBar.Filled = true
	elements.AccentBar = AccentBar
	
	-- Título (fonte maior e bold)
	local Title = Drawing.new("Text")
	Title.ZIndex = zIndex + 2
	Title.Position = Vector2.new(targetX + 15, targetY + 12)
	Title.Color = titleColor
	Title.Text = titleContent or "Notification"
	Title.Size = 16
	Title.Outline = true
	Title.OutlineColor = Color3.fromRGB(0, 0, 0)
	elements.Title = Title
	
	-- Texto do conteúdo
	local Text = Drawing.new("Text")
	Text.ZIndex = zIndex + 2
	Text.Position = Vector2.new(targetX + 15, targetY + 35)
	Text.Color = textContentColor
	Text.Text = processedText or "Notification message"
	Text.Size = 13
	Text.Outline = false
	elements.Text = Text
	
	-- Ícone opcional (canto superior direito)
	if iconText then
		local Icon = Drawing.new("Text")
		Icon.ZIndex = zIndex + 2
		Icon.Position = Vector2.new(targetX + CONFIG.NOTIFICATION_WIDTH - 30, targetY + 12)
		Icon.Color = accentColor
		Icon.Text = iconText -- Pode ser emoji ou símbolo
		Icon.Size = 18
		Icon.Outline = false
		elements.Icon = Icon
	end
	
	-- Progress bar background
	local ProgressBg = Drawing.new("Square")
	ProgressBg.ZIndex = zIndex + 1
	ProgressBg.Size = Vector2.new(CONFIG.NOTIFICATION_WIDTH, 3)
	ProgressBg.Position = Vector2.new(targetX, targetY + CONFIG.NOTIFICATION_HEIGHT - 3)
	ProgressBg.Color = Color3.fromRGB(20, 20, 20)
	ProgressBg.Filled = true
	ProgressBg.Transparency = 0.7
	elements.ProgressBg = ProgressBg
	
	-- Progress bar fill (gradiente simulado)
	local ProgressFill = Drawing.new("Square")
	ProgressFill.ZIndex = zIndex + 2
	ProgressFill.Size = Vector2.new(CONFIG.NOTIFICATION_WIDTH, 3)
	ProgressFill.Position = Vector2.new(targetX, targetY + CONFIG.NOTIFICATION_HEIGHT - 3)
	ProgressFill.Color = accentColor
	ProgressFill.Filled = true
	elements.ProgressFill = ProgressFill
	
	AddNotification(elements, currID, duration, Vector2.new(targetX, targetY))
	currID = currID + 1
end

-- Helper functions para criar notificações com temas
function notify.Success(title, text, duration)
	notify.CreateNotification(
		title or "Success",
		text or "Operation completed successfully",
		duration or 4,
		nil,
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(200, 255, 200),
		Color3.fromRGB(67, 181, 129), -- Verde
		Color3.fromRGB(30, 31, 34),
		"✓"
	)
end

function notify.Error(title, text, duration)
	notify.CreateNotification(
		title or "Error",
		text or "An error occurred",
		duration or 5,
		nil,
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(255, 200, 200),
		Color3.fromRGB(237, 66, 69), -- Vermelho
		Color3.fromRGB(30, 31, 34),
		"✕"
	)
end

function notify.Warning(title, text, duration)
	notify.CreateNotification(
		title or "Warning",
		text or "Please pay attention",
		duration or 4,
		nil,
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(255, 240, 200),
		Color3.fromRGB(250, 166, 26), -- Laranja
		Color3.fromRGB(30, 31, 34),
		"⚠"
	)
end

function notify.Info(title, text, duration)
	notify.CreateNotification(
		title or "Info",
		text or "Information",
		duration or 4,
		nil,
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(200, 220, 255),
		Color3.fromRGB(88, 101, 242), -- Azul
		Color3.fromRGB(30, 31, 34),
		"ℹ"
	)
end

-- Sistema de animação e atualização
spawn(function()
	while true do
		task.wait()
		
		if #activeNotifications > 0 then
			-- Ordenar notificações por ID
			table.sort(activeNotifications, function(a, b)
				return a.ID > b.ID
			end)
			
			local gameWindowSize = game.CoreGui.RobloxGui.SettingsClippingShield.AbsoluteSize
			local baseX = gameWindowSize.X - CONFIG.NOTIFICATION_WIDTH - 20
			local baseY = gameWindowSize.Y - CONFIG.NOTIFICATION_HEIGHT - 20
			
			for index, notif in ipairs(activeNotifications) do
				local offsetY = (index - 1) * -(CONFIG.NOTIFICATION_HEIGHT + CONFIG.NOTIFICATION_SPACING)
				notif.TargetPos = Vector2.new(baseX, baseY + offsetY)
				
				-- Inicializar notificação
				if not notif.Initialized and not notif.Initializing then
					notif.Initializing = true
					notif.StartTime = os.clock()
					notif.Initialized = true
					
					-- Thread para animação de entrada e progresso
					spawn(function()
						local startTime = os.clock()
						local animationDuration = CONFIG.ANIMATION_SPEED
						
						-- Animação de entrada
						while notif.AnimationProgress < 1 do
							task.wait()
							local elapsed = os.clock() - startTime
							notif.AnimationProgress = math.min(elapsed / animationDuration, 1)
							local eased = easeOutCubic(notif.AnimationProgress)
							
							notif.CurrentPos = Vector2.new(
								lerp(notif.TargetPos.X + CONFIG.SLIDE_DISTANCE, notif.TargetPos.X, eased),
								notif.CurrentPos.Y
							)
							notif.Opacity = eased
						end
						
						-- Progress bar animation
						local progressStart = os.clock()
						while os.clock() - progressStart < notif.Duration do
							task.wait()
							local elapsed = os.clock() - progressStart
							local timeLeft = notif.Duration - elapsed
							local percent = math.clamp(timeLeft / notif.Duration, 0, 1)
							
							notif.Elements.ProgressFill.Size = Vector2.new(
								CONFIG.NOTIFICATION_WIDTH * percent,
								3
							)
						end
						
						-- Animação de saída
						local fadeStart = os.clock()
						while notif.Opacity > 0 do
							task.wait()
							local fadeProgress = (os.clock() - fadeStart) / CONFIG.ANIMATION_SPEED
							notif.Opacity = math.max(1 - fadeProgress, 0)
							notif.CurrentPos = Vector2.new(
								notif.CurrentPos.X + 1,
								notif.CurrentPos.Y
							)
						end
						
						-- Remover elementos
						for _, element in pairs(notif.Elements) do
							element:Remove()
						end
						table.remove(activeNotifications, table.find(activeNotifications, notif))
					end)
				end
				
				-- Smooth position interpolation
				if notif.Initialized then
					local lerpSpeed = 0.2
					notif.CurrentPos = Vector2.new(
						notif.CurrentPos.X,
						lerp(notif.CurrentPos.Y, notif.TargetPos.Y, lerpSpeed)
					)
					UpdatePosition(notif, notif.CurrentPos, notif.Opacity)
				end
			end
		end
	end
end)

return notify
