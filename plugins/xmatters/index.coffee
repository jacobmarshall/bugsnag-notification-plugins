NotificationPlugin = require "../../notification-plugin"

class xMatters extends NotificationPlugin

  # Flatten properties e.g. srcObj.project.name -> dstObject.project_name
  flatten = (dstObj, srcObj, prefix) ->     
    for property of srcObj
      if typeof srcObj[property] == "object"
        # for stacktrace, pick first object
        if property == "stacktrace" && srcObj[property].length > 0
          flatten(dstObj, srcObj[property][0], property)
        continue if prefix	# other nested objects are not supported
        flatten(dstObj, srcObj[property], property)
      else if prefix 
        dstObj[ prefix + "." + property] = srcObj[property] 
    
    dstObj
    
  @receiveEvent = (config, event, callback) ->
    # Set event priority
    if event.error? 
      xm_priority = 'high'
    else
      xm_priority = 'medium'
      
    # Build the message
    payload = 
      priority : xm_priority
      properties : flatten({}, event)
      
    # Inject new event
    @request
      .post config.form
      .set 'Accept', 'application/json'
      .timeout(4000)
      .auth(config.initiator, config.password)
      .send(payload)
      .on "error", (err) ->
        callback(err)
      .end (res) ->
        # console.log "End: " + JSON.stringify(res.body)
        callback(res.errorDetails)

    # console.log payload
          
module.exports = xMatters
