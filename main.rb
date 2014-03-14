require 'leap-motion-ws'

def attr objObject, strAttributeName
  return objObject.instance_variable_get(strAttributeName)
end

class LeapTest < LEAP::Motion::WS
  
  def on_connect
    @floatGestureCooldownStartTime = nil
    @strCurrentGesture = ""
    
    puts "Connect"
  end

  def detectInstantGesture objLeapFrame
    
    floatPalmVelocityThreshold = 400.0
    floatHandDirectionThreshold = 0.4
    
    return "" if objLeapFrame.pointables.size > 1
    
    return "" if objLeapFrame.hands[0].nil?
    
    arrPalmPosition = attr(objLeapFrame.hands[0], :@palmPosition)
    arrHandDirection = attr(objLeapFrame.hands[0], :@direction)
    
    return "" if arrHandDirection[0].abs > floatHandDirectionThreshold
    return "" if arrHandDirection[1].abs > floatHandDirectionThreshold
    return "" if (arrHandDirection[2] + 1).abs > floatHandDirectionThreshold
    
    return "" if arrPalmPosition[2] > 100
    
    floatX = attr(objLeapFrame.hands[0], :@palmVelocity)[0]
    floatY = attr(objLeapFrame.hands[0], :@palmVelocity)[1]
    floatZ = attr(objLeapFrame.hands[0], :@palmVelocity)[2]
    
    strNewGesture = ""
    if floatX.abs > floatY.abs && floatX.abs > floatZ.abs && floatX.abs > floatPalmVelocityThreshold
      strNewGesture = (floatX > 0 ? "RIGHT" : "LEFT")
    end
    
    if floatY.abs > floatX.abs && floatY.abs > floatZ.abs && floatY.abs > floatPalmVelocityThreshold
      strNewGesture = floatY > 0 ? "UP" : "DOWN"
    end
    
    if floatZ.abs > floatX.abs && floatZ.abs > floatY.abs && floatZ.abs > floatPalmVelocityThreshold
      strNewGesture = floatZ > 0 ? "BACKWARD" : "FORWARD"
    end
    
    return strNewGesture
  end

  def on_frame objLeapFrame
    
    if !@floatGestureCooldownStartTime.nil? && Time.now.to_f - @floatGestureCooldownStartTime >= 0.3
      # successfully waited for the cooldown time and no instant gestures were detected
      # stop the gesture
      
      @strCurrentGesture = ""
      @floatGestureCooldownStartTime = nil
    end
      
    strInstantGesture = detectInstantGesture objLeapFrame
      
    if !@floatGestureCooldownStartTime.nil?
      # we're inside the cooldown time
      
      if !strInstantGesture.empty?
        # we got an instant gesture during cooldown time
        # disable cooldown time but continue the gesture streak
        
        @floatGestureCooldownStartTime = nil
      end
        
      return
    end
    
    if !@strCurrentGesture.empty?
      # We were on a gesture streak
      
      if strInstantGesture.empty?
        # Gesture streak stopped
        # Let's wait for cooldown time
        
        @floatGestureCooldownStartTime = Time.now.to_f
      end
      
      return
    end
    
    @strCurrentGesture = strInstantGesture
    
    return if strInstantGesture.empty? # not on a gesture streak and no instant gesture
    
    puts "Successfully detected gesture " + strInstantGesture
    
    #puts "[" + arrPalmPosition.map{|i| (i/50).to_i}.join(" ") + "]"
    #puts "Hand direction: " + arrHandDirection.inspect
    
    handleGesture(strInstantGesture, objLeapFrame)
    
  end
  
  def handleGesture(strGesture, objLeapFrame)
    if "RIGHT" == strGesture
      `automator /Users/eugenel/Documents/Launch_PHPStorm.workflow`
    end
  end

  def on_disconnect
    puts "disconect"
    stop
  end
end

leap = LeapTest.new()

Signal.trap("TERM") do
  puts "Terminating..."
  leap.stop
end

Signal.trap("KILL") do
  puts "Terminating..."
  leap.stop
end

Signal.trap("INT") do
  puts "Terminating..."
  leap.stop
end

leap.start
