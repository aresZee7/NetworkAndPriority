
local Promise = {}

function Promise.new(executor)
	local self = setmetatable({}, {__index = Promise})
	self.state = "Pending"
	self.value = nil
	self.error = nil
	self.callbacks = {}

	local function resolve(value)
		if self.state == "Pending" then
			self.state = "Fulfilled"
			self.value = value
			for _, callback in ipairs(self.callbacks) do
				callback(value)
			end
		end
	end

	local function reject(error)
		if self.state == "Pending" then
			self.state = "Rejected"
			self.error = error
			for _, callback in ipairs(self.callbacks) do
				callback(nil, error)
			end
		end
	end

	local success, result = pcall(executor, resolve, reject)
	if not success then
		reject(result)
	end

	return self
end

function Promise:andThen(onFulfilled, onRejected)
	local function callbackWrapper(callback)
		return function(...)
			local success, valueOrError = pcall(callback, ...)
			if success then
				return valueOrError
			else
				error(valueOrError)
			end
		end
	end

	if self.state == "Pending" then
		table.insert(self.callbacks, callbackWrapper(onFulfilled))
		if onRejected then
			table.insert(self.callbacks, callbackWrapper(onRejected))
		end
	elseif self.state == "Fulfilled" then
		callbackWrapper(onFulfilled)(self.value)
	elseif self.state == "Rejected" then
		callbackWrapper(onRejected)(nil, self.error)
	end
end

return Promise
