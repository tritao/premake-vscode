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
        launch.preLaunchTask,
        launch.program,
        launch.args,
        launch.stopOnEntry,
        launch.cwd,
        launch.environment,
        launch.console,
    }
end

function launch.type(prj, cfg)
    if cfg.debugger == "Default" then
        if cfg.system == "windows" then
            p.w('"type": "cppvsdbg",')
        else
            p.w('"type": "cppdbg",')
        end
    elseif cfg.debugger == "GDB" then
        p.w('"type": "cppdbg",')
    elseif cfg.debugger == "LLDB" then
        p.w('"type": "lldb",')
    end
end

function launch.request(prj, cfg)
    p.w('"request": "launch",')
end

function launch.preLaunchTask(prj, cfg)
    local task = string.format("Build %s (%s)", prj.name, cfg.name)
    p.w('"preLaunchTask": \"%s\",', task)
end

function launch.program(prj, cfg)
    local wks = prj.workspace
    local builddir = path.getrelative(wks.basedir, prj.location)
    local targetdir = project.getrelative(prj, cfg.linktarget.directory)
    local targetname = cfg.buildtarget.name
    p.w('"program": "%s",', path.join("${workspaceFolder}", builddir,
        targetdir, targetname))
end

function launch.args(prj, cfg)
    p.w('"args": [],')
end

function launch.stopOnEntry(prj, cfg)
    p.w('"stopOnEntry": false,')
end

function launch.cwd(prj, cfg)
    p.w('"cwd": "${workspaceFolder}",')
end

function launch.environment(prj, cfg)
    p.w('"env": {},')
end

function launch.console(prj, cfg)
    p.w('"console": "integratedTerminal"')
end

function launch.generate(prj)
    for cfg in project.eachconfig(prj) do
        local configName = vscode.configName(cfg, #prj.workspace.platforms > 1)

        p.push('{')
        p.w('"name": "Launch %s (%s)",', prj.name, configName)

        p.callArray(launch.configProps, prj, cfg)

        p.pop('},')
    end
end

function launch.generate_tasks(prj)
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
