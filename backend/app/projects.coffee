Path  = require 'path'
fs    = require 'fs'
async = require 'async'

nextProjectId = 1

PREF_KEY = 'projects'

class Project
  constructor: (memento={}) ->
    @path = memento.path
    @id   = "P#{nextProjectId++}"
    @name = Path.basename(@path)
    LR.client.monitoring.add({ @id, @path })

  dispose: ->
    LR.client.monitoring.remove({ @id })

  toJSON: ->
    { @id, @name, @path }

  toMemento: ->
    { @path }

projects = []

loadModel = (callback) ->
  LR.preferences.get PREF_KEY, (memento) ->
    for projectMemento in memento.projects || []
      projects.push new Project(projectMemento)
    callback()

saveModel = ->
  memento = {
    projects: (p.toMemento() for p in projects)
  }
  LR.preferences.set PREF_KEY, memento

modelDidChange = (callback) ->
  saveModel()
  updateProjectList callback

projectListJSON = ->
  (project.toJSON() for project in projects)

findById = (projectId) ->
  for project in projects
    if project.id is projectId
      return project
  null

exports.init = (callback) ->
  async.series [loadModel, updateProjectList], callback

exports.updateProjectList = updateProjectList = (callback) ->
  LR.client.mainwnd.set_project_list { projects: projectListJSON() }
  callback(null)

exports.add = ({ path }, callback) ->
  fs.stat path, (err, stat) ->
    if err or not stat
      callback(err || new Error("The path does not exist"))
    else
      projects.push new Project({ path })
      modelDidChange callback

exports.remove = ({ projectId }, callback) ->
  if project = findById(projectId)
    projects.splice projects.indexOf(project), 1
    modelDidChange callback
  else
    callback(new Error("The given project id does not exist"))

exports.changeDetected = ({ id, changes }, callback) ->
  if project = findById(id)
    process.stderr.write "Node: change detected in #{project.path}: #{JSON.stringify(changes)}\n"
  else
    process.stderr.write "Node: change detected in unknown id #{id}\n"
  callback(null)
