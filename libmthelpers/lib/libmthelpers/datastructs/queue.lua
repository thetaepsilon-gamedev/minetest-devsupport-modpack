return {
	new = function(opts)
		if type(opts) ~= "table" then opts = {} end
		-- implement queue using a linked list.
		local self = {
			count = 0,
			head = nil,
			tail = nil,
		}
		local interface = {
			enqueue = function(item)
				if item == nil then return false end
				local currenttail = self.tail
				local element = { item, nil }
				-- add item on tail to enqueue at back.
				-- but might be nil if the queue is empty.
				if currenttail == nil then
					self.head = element
					self.tail = element
				else
					-- currenttail is the last element, so modify it's next ref
					currenttail[2] = element
					self.tail = element
				end
				self.count = self.count + 1
				return true
			end,
			next = function()
				local ret = nil
				local head = self.head
				-- fall through to returning nil if no head element exists
				if head ~= nil then
					local next = head[2]
					ret = head[1]
					self.head = next
					-- if this is the last element, tail is also referring to it
					if next == nil then self.tail = nil end
					self.count = self.count - 1
				end
				return ret
			end,
			size = function() return self.count end,
		}
		-- next() already satisfies iterator requirements, just return that
		interface.iterator = function()
			return interface.next
		end
		return interface
	end,
}
