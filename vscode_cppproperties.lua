local p = premake
local project = p.project
local config = p.config
local tree = p.tree
local vscode = p.modules.vscode

vscode.project = {}
vscode.project.cCppProperties = {}

local cCppProperties = vscode.project.cCppProperties

cCppProperties.cppStandards = {
	["C++98"]   = "c++98",
	["C++11"]   = "c++11",
	["C++14"]   = "c++14",
	["C++17"]   = "c++17",
	["C++20"]   = "c++20",
	["C++2a"]   = "c++20",
    ["gnu++98"]   = "gnu++98",
	["gnu++11"]   = "gnu++11",
	["gnu++14"]   = "gnu++14",
	["gnu++17"]   = "gnu++17",
	["gnu++20"]   = "gnu++20"
}

-- NOTE(Peter): This is trash, but I can't think of a better way of doing this right now other than asking people to put the relavant directories in some env var (which is also trash)
cCppProperties.toolsetPaths = {
    ["windows"] = {
        ["msc"] = "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.35.32215/bin/Hostx64/x64/cl.exe",
        ["clang"] = "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/Llvm/x64/bin/clang-cl.exe"
    },
    ["linux"] = {
        ["gcc"] = "/usr/bin/g++",
        ["clang"] = "/usr/bin/clang++"
    }
}

cCppProperties.configProps = function(prj, cfg)
    return {
        cCppProperties.intelliSenseMode,
        cCppProperties.includeDirs,
        cCppProperties.defines,
        cCppProperties.forceIncludes,
        cCppProperties.cppStandard,
        cCppProperties.compilerPath
    }
end

function cCppProperties.intelliSenseMode(prj, cfg)
    local supportedModes = {
        ["msc"] = "msvc-x64",
        ["clang"] = "clang-x64",
        ["gcc"] = "gcc-x64"
    }

    local toolset = vscode.getToolsetName(cfg)
    local mode = supportedModes[toolset]

    if mode == nil then
        error("Invalid toolset '" .. toolset "'")
    end

    p.w('"intelliSenseMode": "%s",', mode)
end

function cCppProperties.includeDirs(prj, cfg)

    local hasIncludeDirs = #cfg.sysincludedirs > 0 or #cfg.externalincludedirs > 0 or #cfg.includedirs > 0

    if hasIncludeDirs then
        p.push('"includePath": [')

        -- NOTE(Peter): VS Code currently doesn't have a property for external include dirs or system include dirs

        for _, includedir in ipairs(cfg.sysincludedirs) do
            p.w('"%s",', includedir:gsub([[\]], "/"))
        end

        for _, includedir in ipairs(cfg.externalincludedirs) do
            p.w('"%s",', includedir:gsub([[\]], "/"))
        end

        for _, includedir in ipairs(cfg.includedirs) do
            p.w('"%s",', includedir:gsub([[\]], "/"))
        end

        p.pop('],')
    end
end

function cCppProperties.defines(prj, cfg)
    if #cfg.defines > 0 then
        p.push('"defines": [')

        for _, define in ipairs(cfg.defines) do
            p.w('"%s",', p.esc(define):gsub(" ", "\\ "))
        end

        p.pop('],')
    end
end

function cCppProperties.forceIncludes(prj, cfg)
    local toolset = vscode.getCompiler(cfg)
    local forceIncludes = {}

    table.foreachi(cfg.forceincludes, function(file)
        tree.traverse(project.getsourcetree(prj), {
            onleaf = function(node, depth)
                if node.name == file then
                    table.insert(forceIncludes, p.quoted(node.abspath))
                end
            end
        })
    end)

    if #forceIncludes > 0 then
        p.push('"forcedInclude": [')

        for _, include in ipairs(forceIncludes) do
            p.w('"%s",', include)
        end

        p.pop('],')
    end
end

function cCppProperties.cppStandard(prj, cfg)
    if (cfg.cppdialect and cfg.cppdialect:len() > 0) or cfg.cppdialect == "Default" then
        p.w('"cppStandard": "%s",', cCppProperties.cppStandards[cfg.cppdialect])
    end
end

function cCppProperties.compilerPath(prj, cfg)
    local toolset = vscode.getToolsetName(cfg)
    local toolsetPath = cCppProperties.toolsetPaths[cfg.system][toolset]
    p.w('"compilerPath": "%s",', toolsetPath)
end

function cCppProperties.generate(prj)
    p.push('{')
    p.push('"configurations": [')

    for cfg in project.eachconfig(prj) do
        local configName = vscode.configName(cfg, #prj.workspace.platforms > 1)

        p.push('{')
        p.w('"name": "%s",', configName)

        p.callArray(cCppProperties.configProps, prj, cfg)

        p.pop('},')
    end

    p.pop('],')
    p.w('"version": 4')
    p.pop('}')
end
