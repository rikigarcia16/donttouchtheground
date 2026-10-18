--!strict
-- Token bucket per key. Used to throttle every client -> server remote.

local RateLimiter = {}
RateLimiter.__index = RateLimiter

export type RateLimiter = typeof(setmetatable(
	{} :: {
		capacity: number,
		refillPerSecond: number,
		buckets: { [any]: { tokens: number, last: number } },
		clock: () -> number,
	},
	RateLimiter
))

function RateLimiter.new(capacity: number, refillPerSecond: number, clock: (() -> number)?): RateLimiter
	return setmetatable({
		capacity = capacity,
		refillPerSecond = refillPerSecond,
		buckets = {},
		clock = clock or os.clock,
	}, RateLimiter)
end

function RateLimiter.Check(self: RateLimiter, key: any): boolean
	local now = self.clock()
	local bucket = self.buckets[key]
	if not bucket then
		bucket = { tokens = self.capacity, last = now }
		self.buckets[key] = bucket
	end
	bucket.tokens = math.min(self.capacity, bucket.tokens + (now - bucket.last) * self.refillPerSecond)
	bucket.last = now
	if bucket.tokens >= 1 then
		bucket.tokens -= 1
		return true
	end
	return false
end

function RateLimiter.Forget(self: RateLimiter, key: any)
	self.buckets[key] = nil
end

return RateLimiter
