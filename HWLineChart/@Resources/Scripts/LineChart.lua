-- 初始化函数
function Initialize()
    -- 获取缩放系数
    Scale = tonumber(SKIN:GetVariable("Scale"))
    -- 获取表类型变量
    ChartType = SKIN:GetVariable("ChartType")
    -- 获取折线图X轴坐标节点数
    CoordCount = tonumber(SKIN:GetVariable("CoordCount"))
    -- 获取数据范围
    UsageRange = tonumber(SKIN:GetVariable("UsageRange"))
    ClockSpeedRange = tonumber(SKIN:GetVariable("ClockSpeedRange"))
    TempRange = tonumber(SKIN:GetVariable("TempRange"))
    PowerRange = tonumber(SKIN:GetVariable("PowerRange"))
    -- 根据表的类型，判断需要创建数据源对象
    Hardware = {
        Usage = SKIN:GetMeasure("UsageValue"),
        ClockSpeed = SKIN:GetMeasure("ClockSpeedValue"),
        Temp = SKIN:GetMeasure("TempValue"),
        Power = SKIN:GetMeasure("PowerValue"),

        UsageArr = CreateArray(CoordCount, 0),
        ClockSpeedArr = CreateArray(CoordCount, 0),
        TempArr = CreateArray(CoordCount, 0),
        PowerArr = CreateArray(CoordCount, 0),
    }
end

-- 更新函数
function Update()
    -- 更新数组
    table.insert(Hardware.UsageArr, Hardware.Usage:GetValue())
    table.remove(Hardware.UsageArr, 1)

    table.insert(Hardware.ClockSpeedArr, Hardware.ClockSpeed:GetValue())
    table.remove(Hardware.ClockSpeedArr, 1)

    table.insert(Hardware.TempArr, Hardware.Temp:GetValue())
    table.remove(Hardware.TempArr, 1)

    table.insert(Hardware.PowerArr, Hardware.Power:GetValue())
    table.remove(Hardware.PowerArr, 1)

    -- 更新折线图路径数据
    SKIN:Bang("!SetOption", "LineChartShapePath1", "String",
        CoordCalc(CoordCount, Hardware.UsageArr, UsageRange, Scale, 0))
    SKIN:Bang("!SetOption", "LineChartBackgroundShapePath1", "String",
        CoordCalc(CoordCount, Hardware.UsageArr, UsageRange, Scale, 1))
    SKIN:Bang("!SetOption", "LineChartShapePath2", "String",
        CoordCalc(CoordCount, Hardware.ClockSpeedArr, ClockSpeedRange, Scale, 0))
    SKIN:Bang("!SetOption", "LineChartBackgroundShapePath2", "String",
        CoordCalc(CoordCount, Hardware.ClockSpeedArr, ClockSpeedRange, Scale, 1))
    SKIN:Bang("!SetOption", "LineChartShapePath3", "String", CoordCalc(CoordCount, Hardware.TempArr, TempRange, Scale, 0))
    SKIN:Bang("!SetOption", "LineChartBackgroundShapePath3", "String",
        CoordCalc(CoordCount, Hardware.TempArr, TempRange, Scale, 1))
    SKIN:Bang("!SetOption", "LineChartShapePath4", "String",
        CoordCalc(CoordCount, Hardware.PowerArr, PowerRange, Scale, 0))
    SKIN:Bang("!SetOption", "LineChartBackgroundShapePath4", "String",
        CoordCalc(CoordCount, Hardware.PowerArr, PowerRange, Scale, 1))
end

-- 创建数组函数
function CreateArray(size, value)
    local arr = {}
    for i = 1, size do
        arr[i] = value
    end
    return arr
end

-- 计算坐标函数
function CoordCalc(CoordCount, DataArr, Range, Scale, Flag)
    -- CoordCount 折线图X轴坐标节点数
    -- DataArr 数据数组
    -- Range 数据范围 （0 ~ Range 之间）
    -- Scale 缩放系数
    -- Flag 用于判断返回 线条 或 形状
    -- 0 线条
    -- 1 形状
    local Result = {}
    local Width = 489 * Scale
    local Height = 200 * Scale
    local calc_y = CalcYAxis
    local StartPoint = 10 * Scale
    local NodeSpacing = (479 / (CoordCount - 1)) * Scale
    local ControlPointSpacing = (NodeSpacing / 2)

    for index, value in ipairs(DataArr) do
        local y_value = calc_y(value, Range, Height, true)
        local prev_y_value = calc_y(DataArr[index - 1] or value, Range, Height, true)

        if index == 1 then
            Result[index] = table.concat({ StartPoint, y_value }, ",") .. " | CurveTo "
        else
            Result[index] = table.concat({
                StartPoint,
                y_value,
                StartPoint - ControlPointSpacing,
                prev_y_value,
                StartPoint - ControlPointSpacing,
                y_value
            }, ",")
            if index ~= CoordCount then
                Result[index] = table.concat({Result[index], " | CurveTo "})
            end
        end
        StartPoint = StartPoint + NodeSpacing
    end
    StartPoint = 10 * Scale

    if Flag == 0 then
        return table.concat(Result)
    elseif Flag == 1 then
        Result[#Result + 1] = table.concat({
            " | LineTo ",
            Width,
            ",",
            Height,
            " | LineTo ",
            Width,
            ",",
            0,
            " | LineTo ",
            Width,
            ",",
            Height,
            " | LineTo ",
            StartPoint,
            ",",
            Height,
            " | ClosePath 1"
        })
        return table.concat(Result)
    end
end

-- 计算 Y 轴 高度
function CalcYAxis(NumCalc, Range, RefSize, Invert)
    NumCalc = math.min(NumCalc, Range)
    local Proportion = NumCalc / Range
    local factor = (Invert ~= false) and (1 - Proportion) or Proportion
    local result = RefSize * factor
    return math.floor(result + 0.5)
end
