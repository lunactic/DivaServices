# ParameterHelper
# =======
#
# **ParameterHelper** Provides access to different parameter matching helper methodl
# Copyright &copy; Marcel Würsch, GPL v3.0 licensed.

# Module dependencies
fs      = require 'fs'
nconf   = require 'nconf'
path    = require 'path'
_       = require 'lodash'
ImageHelper = require './imageHelper'
IoHelper    = require './ioHelper'

# expose parameterHelper
parameterHelper = exports = module.exports = class ParameterHelper

  # ---
  # **getParamValue**</br>
  # Gets the value of an input parameter</br>
  # `params`
  #   *parameter* the parameter to get the value for
  #   *inputParameters* the list of input parameters with all its values
  getParamValue: (parameter, inputParameters) ->
    if inputParameters.hasOwnProperty(parameter)
      return inputParameters[parameter]
    return

  # ---
  # **getReservedParamValue**</br>
  # Gets the value of a reserved parameter as defined in conf/server.NODE_ENV.json</br>
  # `params`
  #   *parameter* reserved parameter
  #   *neededParameters* the required parameters
  #   *imagePath* path to the input image
  #   *md5* md5 hash of the input image
  #   *req* the request
  getReservedParamValue: (parameter, neededParameters, imagePath,outputPath, md5, req) ->
    switch parameter
      when 'matlabPath'
        return nconf.get('paths:matlabPath')
      when 'matlabScriptsPath'
        return nconf.get('paths:matlabScriptsPath')
      when 'inputFileExtension'
        return path.extname(imagePath).slice(1)
      when 'inputImage'
        return imagePath
      when 'inputImageUrl'
        imageHelper = new ImageHelper()
        return imageHelper.getInputImageUrl(md5)
      when 'imageRootPath'
        return nconf.get('paths:imageRootPath')
      when 'outputFolder'
        return outputPath
      when 'host'
        return req.get('host')
      when 'ocropyLanguageModelsPath'
        return nconf.get('paths:ocropyLanguageModelsPath')
      when 'startUp'
        return neededParameters['startUp']
      when 'resultFile'
        return '##resultFile##'
      when 'outputImage'
        return path.dirname(imagePath) + '/output.png'
      when 'noisingXmlFile'
        return nconf.get('paths:noisingXmlPath')
  # ---
  # **matchParams**</br>
  # Matches the received parameter values to the needed parameters</br>
  # `params`
  #   *inputParameters* The received parameters and its values
  #   *inputHighlighter* The received input highlighter
  #   *neededParameters*  The needed parameteres
  #   *imagePath* path to the input image
  #   *md5* md5 hash of the input image
  #   *req* incoming request
  matchParams: (inputParameters, inputHighlighter, neededParameters,imagePath,outputPath, md5,  req) ->
    params = {}
    data = {}
    for parameter of neededParameters
      #build parameters
      if checkReservedParameters parameter
        #check if highlighter
        if parameter is 'highlighter'
          params[neededParameters[parameter]] = this.getHighlighterParamValues(neededParameters[parameter], inputHighlighter)
        else
          data[parameter] = this.getReservedParamValue(parameter, neededParameters, imagePath,outputPath, md5, req)
      else
        value = this.getParamValue(parameter, inputParameters)
        if value?
          params[parameter] = value
    result =
      params: params
      data: data
    return result

  buildGetUrl: (process) ->
    getUrl = 'http://' + nconf.get('server:rootUrl') + process.req.originalUrl

    #append md5
    getUrl += '?md5=' + process.image.md5

    #append highlighter
    if(!_.isEmpty(process.inputHighlighters))
      getUrl += '&highlighter=' + JSON.stringify(process.inputHighlighters['segments'])

    filtered = _.filter(process.parameters.params, (value,key) ->
      return !key in ['rectangle','circle','polygon']
    )
    #append other parameters
    for key,value of filtered
      getUrl += '&' + key + '=' + value

    return getUrl

  buildGetUrlCollection: (collection) ->
    #get the first process for parameter information
    process = collection.processes[0]

    getUrl = 'http://' + nconf.get('server:rootUrl') + process.req.originalUrl

    #append collection name
    getUrl += '?collection=' + collection.name
    #append highlighter
    if(!_.isEmpty(process.inputHighlighters))
      getUrl += '&highlighter=' + JSON.stringify(process.inputHighlighters['segments'])

    filtered = _.filter(process.parameters.params, (value,key) ->
      return !key in ['rectangle','circle','polygon']
    )
    #append other parameters
    for key,value of filtered
      getUrl += '&' + key + '=' + value

    return getUrl

# ---
  # **getHighlighterParamValues**</br>
  # Gets Parameter values for highlighters.
  # The values will be as follow:
  #  for 'rectangle':
  #    topLeft.x topLeft.y topRight.x topRight.y bottomRight.x bottomRight.y bottomLeft.x bottomRight.y
  #  for 'circle':
  #    position.x position.y radius
  #  for 'polygon'
  #    point1.x point1.y point2.x point2.y, ..., pointN.x, pointN.y</br>
  # `params`
  #   *neededHighlighter* required highlighter as defined by the method
  #   *inputHighlighter*  received highlighter with its value from the request
  getHighlighterParamValues: (neededHighlighter, inputHighlighter) ->
    switch neededHighlighter
      when 'rectangle'
        merged = []
        merged = merged.concat.apply(merged,inputHighlighter)
        merged = merged.map(Math.round)
        return merged.join(' ')
      when 'circle'
        position = inputHighlighter.position
        position = position.map(Math.round)
        radius = inputHighlighter.radius
        radius = Math.round(radius)
        return position[0] + ' ' + position[1] + ' ' + radius
      when 'polygon'
        merged = []
        merged = merged.concat.apply(merged, inputHighlighter)
        merged = merged.map(Math.round)
        return merged.join(' ')


  getMethodName: (algorithm) ->
    return algorithm.replace(/\//g, '')

  saveParamInfo: (process, parameters, rootFolder,outputFolder,method ) ->
    if process.result?
      return

    try
      fs.mkdirSync(outputFolder)
    catch error
      #no need to handle the error

    methodPath = nconf.get('paths:imageRootPath') + '/'+ rootFolder + '/' + method + '.json'
    content = []
    data =
      parameters: parameters.params
      folder: outputFolder
    try
      fs.statSync(methodPath).isFile()
      content = JSON.parse(fs.readFileSync(methodPath,'utf8'))
      #only save the information if its not already present
      if(_.where(content,data).length == 0)
        content.push data
        fs.writeFileSync(methodPath, JSON.stringify(content))
    catch error
      content.push data
      fs.writeFileSync(methodPath, JSON.stringify(content))

  loadParamInfo: (process) ->
    paramPath = nconf.get('paths:imageRootPath') + '/' + process.rootFolder + '/' + process.method + '.json'
    data =
      parameters: process.parameters.params
    try
      fs.statSync(paramPath).isFile()
      content = JSON.parse(fs.readFileSync(paramPath,'utf8'))
      if((info = _.where(content,{'parameters':data.parameters})).length > 0)
        #found some information about this method
        ioHelper = new IoHelper()
        if(process.image?)
          process.resultFile = ioHelper.buildFilePath(info[0].folder, process.image.name)
        process.outputFolder = info[0].folder
      else
        #found no information about that method
        return
    catch error
      #no information found
      return
# ---
  # **checkReservedParameters**</br>
  # Checks if a parameter is in the list of reserverd words as defined in server.NODE_ENV.json</br>
  # `params`
  #   *parameter* the parameter to check
  checkReservedParameters = (parameter) ->
    reservedParameters = nconf.get('reservedWords')
    return parameter in reservedParameters


