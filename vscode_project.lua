local p = premake
local project = p.project
local config = p.config
local tree = p.tree
local vscode = p.modules.vscode

vscode.project = {}
vscode.project.launch = {}
vscode.project.tasks = {}

local launch = vscode.project.launch

launch.configProps = function(prj, cfg)
    return {
        launch.type,
        launch.request,
        launch.program,
        launch.args,
        launch.stopAtEntry,
        launch.cwd,
        launch.environment,
        launch.console,
    }
end

function launch.type(prj, cfg)
    if cfg.system == "windows" then
        p.w('"type": "cppvsdbg",')
    else
        p.w('"type": "cppdbg",')
    end
end

function launch.request(prj, cfg)
    p.w('"request": "launch",')
end

function launch.program(prj, cfg)
    local targetdir = project.getrelative(prj, cfg.buildtarget.directory)
    local targetname = cfg.buildtarget.name
    p.w('"program": "%s",', path.join(targetdir, targetname))
end

function launch.args(prj, cfg)
    p.w('"args": [],')
end

function launch.stopAtEntry(prj, cfg)
    p.w('"stopAtEntry": false,')
end

function launch.cwd(prj, cfg)
    p.w('"cwd": "${workspaceFolder}",')
end

function launch.environment(prj, cfg)
    p.w('"environment": [],')
end

function launch.console(prj, cfg)
    p.w('"console": "integratedTerminal"')
end

function launch.generate(prj)
    p.push('{')
    p.w('"version": "0.2.0",')
    p.push('"configurations": [')

    for cfg in project.eachconfig(prj) do
        local configName = vscode.configName(cfg, #prj.workspace.platforms > 1)

        p.push('{')
        p.w('"name": "Launch %s",', configName)

        p.callArray(launch.configProps, prj, cfg)

        p.pop('},')
    end

    p.pop(']')
    p.pop('}')
end
