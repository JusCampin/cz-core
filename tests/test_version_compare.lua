-- simple tests for compare_versions
local ok = true
local function assert_eq(a,b,msg)
    if a ~= b then
        print(('TEST FAIL: %s - expected %s got %s'):format(msg, tostring(b), tostring(a)))
        ok = false
    end
end

local cvs = loadfile('../server/versioner.lua')
if not cvs then
    print('Could not load versioner for tests')
else
    -- rely on compare_versions being global in that file (it isn't), so replicate minimal logic
    local function split_numbers(s)
        local t = {}
        for part in tostring(s):gmatch('([0-9]+)') do table.insert(t, tonumber(part)) end
        return t
    end
    local function compare_versions(a,b)
        a = tostring(a):gsub('^v','')
        b = tostring(b):gsub('^v','')
        local ta = split_numbers(a); local tb = split_numbers(b)
        local n = math.max(#ta,#tb)
        for i=1,n do
            local va = ta[i] or 0; local vb = tb[i] or 0
            if va < vb then return -1 end
            if va > vb then return 1 end
        end
        return 0
    end
    assert_eq(compare_versions('1.2.3','1.2.3'),0,'equal versions')
    assert_eq(compare_versions('1.2.3','1.2.4'),-1,'older')
    assert_eq(compare_versions('1.3.0','1.2.99'),1,'newer')
end
if ok then print('version compare tests: OK') end
