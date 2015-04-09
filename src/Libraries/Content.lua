local Content = {}

function Content:WaitForContent()

	local last = game:GetService("ContentProvider").RequestQueueSize
	while game:GetService("ContentProvider").RequestQueueSize > 0 do
		wait()
		if game:GetService("ContentProvider").RequestQueueSize ~= last then
			last = game:GetService("ContentProvider").RequestQueueSize
		end
	end
end

return Content