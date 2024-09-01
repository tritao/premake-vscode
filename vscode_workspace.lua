local p = premake
local project = p.project
local workspace = p.workspace
local tree = p.tree
local vscode = p.modules.vscode

vscode.workspace = {}
vscode.workspace.tasks = {}
vscode.workspace.launch = {}

local m = vscode.workspace

function m.generate(wks)
	p.utf8()

    p.push('{')
    p.push('"folders": [')

    -- Project List
    tree.traverse(workspace.grouptree(wks), {
        onleaf = function(n)
            local prj = n.project

            local prjpath = path.getrelative(prj.workspace.location, prj.location)
            p.push('{')
            p.w('"path": "%s"', prjpath)
            p.pop('},')
        end,
    })

    -- HACK(Peter): Hack around the tasks not being picked up when workspace is opened
    local prjpath = path.getrelative(wks.location, "Tasks")
    p.push('{')
    p.w('"path": "%s"', prjpath)
    p.pop('}')

    p.pop(']')
    p.pop('}')
end

local tasks = vscode.workspace.tasks

function tasks.buildSolutionTask(wks)
    local solutionFile = p.filename(wks, ".sln")

    local enablePreReleases = _OPTIONS["enable_prereleases"]
    local vswhere = '"C:\\Program Files (x86)\\Microsoft Visual Studio\\Installer\\vswhere.exe" -latest';

    if enablePreReleases then
        vswhere = vswhere .. ' -prerelease'
    end

    vswhere = vswhere .. ' -find MSBuild'

    local msBuildPath, err = os.outputof(vswhere)
    msBuildPath = path.normalize(path.join(msBuildPath, "Current", "Bin", "MSBuild.exe"))

    for cfg in workspace.eachconfig(wks) do
        p.push('{')
        p.w('"type": "shell",')
        p.w('"label": "Build All (%s)",', cfg.name)
        p.w('"command": "%s",', msBuildPath)
        p.w('"args": ["%s", "-p:Configuration=%s"],', solutionFile, cfg.name)
        p.w('"problemMatcher": "$msCompile",')
        p.w('"group": "build"')
        p.pop('},') 
    end
end

function tasks.buildMakefileTask(wks)
    local builddir = path.getrelative(wks.basedir, wks.location)
    local vscode_builddir = path.join("${workspaceFolder}", builddir)

    for cfg in workspace.eachconfig(wks) do
        p.push('{')
        p.w('"type": "shell",')
        p.w('"label": "Build All (%s)",', cfg.name)
        p.w('"command": "make",')
        p.w('"args": ["config=%s", "-j%s"],', cfg.shortname, os.getnumcpus())
        p.w('"options": {')
        p.push(nil)
        p.w('"cwd": "%s"', vscode_builddir)
        p.pop('},')
        p.w('"problemMatcher": {')
        p.push(nil)
        p.w('"base": "$gcc",')
        p.w('"fileLocation": ["relative", "%s"],', vscode_builddir)
        p.pop('},')
        p.w('"group": "build"')
        p.pop('},')
    end

    for prj in workspace.eachproject(wks) do
        for cfg in project.eachconfig(prj) do
            p.push('{')
            p.w('"type": "shell",')
            p.w('"label": "Build %s (%s)",', prj.name, cfg.name)
            p.w('"command": "make",')
            p.w('"args": ["config=%s", "-j%s", "%s"],', cfg.shortname, os.getnumcpus(), prj.name)
            p.w('"options": {')
            p.push(nil)
            p.w('"cwd": "%s"', vscode_builddir)
            p.pop('},')
            p.w('"problemMatcher": {')
            p.push(nil)
            p.w('"base": "$gcc",')
            p.w('"fileLocation": ["relative", "%s"],', vscode_builddir)
            p.pop('},')
            p.w('"group": "build"')
            p.pop('},')
        end
    end
end

tasks.buildTasks = function(wks)
    if _TARGET_OS == "windows" then
        return {
            tasks.buildSolutionTask
        }
    else
        return {
            tasks.buildMakefileTask
        }
    end

end

function tasks.generate(wks)
    p.push('{')
    p.w('"version": "2.0.0",')
    p.push('"tasks": [')

    p.callArray(tasks.buildTasks, wks)

    p.pop(']')
    p.pop('}')
end

local launch = vscode.workspace.launch

function launch.generate(wks)
    p.push('{')
    p.w('"version": "0.2.0",')
    p.push('"configurations": [')

    for prj in workspace.eachproject(wks) do
        local isLaunchable = false
        for cfg in project.eachconfig(prj) do
            isLaunchable = cfg.kind == "ConsoleApp" or cfg.kind == "WindowedApp"
            if isLaunchable then
                break
            end
        end

        if isLaunchable then
            vscode.project.launch.generate(prj)
        end
    end

    p.pop(']')
    p.pop('}')
end


